import 'dart:convert';

import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/plan_importer.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalog/exercise_fixtures.dart';

/// AI köprüsünün gerçek depolarla uçtan uca sınanması.
///
/// Diğer testler katmanları tek tek doğruluyor; bu test aradaki
/// **bağlantıyı** doğruluyor: provider'lar gerçek veritabanına bağlanmış
/// mı, doğrulayıcı gerçek katalogla kuruluyor mu, importer yazdığını
/// gerçekten yazıyor mu.
///
/// Yalnız `appDatabaseProvider` override ediliyor; gerisi üretimdeki
/// bağlantının aynısı.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    await CatalogRepository(db).seedFromJson(fixtureSeedJson());
  });

  tearDown(() {
    container.dispose();
    return db.close();
  });

  /// Fixture katalogundaki id'lerle kurulmuş, bir haftalık geçerli plan.
  String planJson({String startDate = '2026-09-01'}) {
    final start = DateTime.parse(startDate);
    String iso(int offset) {
      final date = start.add(Duration(days: offset));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    return jsonEncode({
      'schemaVersion': 1,
      'meta': {'title': 'AI Planı', 'startDate': startDate, 'weeks': 1},
      'goals': <String, dynamic>{
        'dailyKcal': 2300,
        'proteinG': 165,
        'waterL': 3,
        'weeklyGym': 3,
        'weeklyHome': 4,
        'targetLossKg': 3,
      },
      'rules': <String, dynamic>{
        'forbidden': ['Alkol'],
        'free': ['Su'],
      },
      'days': [
        for (var index = 0; index < 7; index++)
          {
            'date': iso(index),
            'type': index == 6 ? 'rest' : 'home',
            'weekIndex': 1,
            'headline': 'Test haftası',
            'slots': [
              {'time': '06:30', 'kind': 'meal', 'label': 'Kahvaltı'},
              if (index != 6)
                {'time': '19:00', 'kind': 'workout', 'label': 'Antrenman'},
            ],
            'exercises': [
              if (index != 6)
                {
                  'exerciseId': 'incline_pushup',
                  'sets': 3,
                  'reps': 12,
                  'restSec': 60,
                },
            ],
          },
      ],
      'newExercises': <Object>[],
    });
  }

  Future<ImportSummary> importPlan(String json) async {
    final validator = await container.read(planValidatorProvider.future);
    final result = validator.validate(json);

    if (result is! Ok<ValidatedPlan>) {
      fail('Doğrulama geçmeliydi: '
          '${(result as Err<ValidatedPlan>).failure.message}');
    }

    final imported = await container
        .read(planImporterProvider)
        .import(result.value, acceptedNewExerciseIds: const {});

    if (imported is! Ok<ImportSummary>) {
      fail('İçe alma geçmeliydi: '
          '${(imported as Err<ImportSummary>).failure.message}');
    }
    return imported.value;
  }

  group('doğrulayıcı gerçek katalogla kurulur', () {
    test('tohumdaki hareket kabul edilir', () async {
      final validator = await container.read(planValidatorProvider.future);
      expect(validator.catalog.containsKey('incline_pushup'), isTrue);
      expect(validator.validate(planJson()).isOk, isTrue);
    });

    test('katalogda olmayan hareket gerçek alternatiflerle reddedilir',
        () async {
      final broken = planJson().replaceAll('incline_pushup', 'barbell_squat');
      final validator = await container.read(planValidatorProvider.future);
      final result = validator.validate(broken);

      final message = (result as Err<ValidatedPlan>).failure.message;
      expect(message, contains('barbell_squat'));
      // Öneriler uydurma değil, gerçekten katalogdaki id'ler.
      expect(message, contains('incline_pushup'));
    });
  });

  group('içe alma gerçekten yazar', () {
    test('plan, günler, slotlar ve hareketler veritabanına düşer', () async {
      final summary = await importPlan(planJson());
      expect(summary.dayCount, 7);

      final stored = await PlanRepository(db).activePlan();
      expect(stored, isNotNull);
      expect(stored!.title, 'AI Planı');
      expect(stored.days, hasLength(7));
      expect(stored.days.first.slots, hasLength(2));
      expect(stored.days.first.exercises.single.exerciseId, 'incline_pushup');
      expect(stored.days.last.type.name, 'rest');
    });

    test('ham JSON sourceRaw olarak saklanır', () async {
      final json = planJson();
      await importPlan(json);

      final stored = await PlanRepository(db).activePlan();
      expect(stored!.sourceRaw, json);
    });

    test('Bugün ekranının gördüğü gün oluşur', () async {
      await importPlan(planJson());

      final day = await PlanRepository(db).watchDay('2026-09-01').first;
      expect(day, isNotNull);
      expect(day!.workoutSlot?.label, 'Antrenman');
      expect(day.exercises.single.targetLabel, '3 × 12');
    });

    test('ikinci plan içeri alınınca ilki pasifleşir', () async {
      await importPlan(planJson());
      await importPlan(planJson(startDate: '2026-09-08'));

      final stored = await PlanRepository(db).activePlan();
      expect(stored!.startDate, DateTime(2026, 9, 8));

      // Eski planın günü artık aktif değil.
      expect(await PlanRepository(db).watchDay('2026-09-01').first, isNull);
    });
  });

  group('yeni hareket kataloğa yazılır', () {
    String planWithNewExercise() {
      final document =
          jsonDecode(planJson()) as Map<String, dynamic>;

      (document['newExercises'] as List).add({
        'id': 'custom_burpee',
        'nameTr': 'Burpee',
        'nameEn': 'Burpee',
        'category': 'strength',
        'location': 'home',
        'equipment': ['bodyOnly'],
        'primaryMuscles': ['tüm vücut'],
        'secondaryMuscles': <String>[],
        'difficulty': 4,
        'summary': 'Tüm vücut hareketi.',
        'setup': ['Ayakta dur.'],
        'execution': ['Çömel.', 'Plank pozisyonuna geç.', 'Ayağa kalk.'],
        'breathing': 'İnerken al, kalkarken ver.',
        'tempo': 'Akıcı',
        'cues': ['Karın sıkı'],
        'commonMistakes': [
          {'mistake': 'Bel çöküyor', 'why': 'Karın gevşiyor.', 'fix': 'Sık.'},
          {'mistake': 'Hızlı iniş', 'why': 'Diz zorlanır.', 'fix': 'Yavaşla.'},
        ],
        'safety': 'Diz ağrısında yapma.',
        'regressions': <String>[],
        'progressions': <String>[],
      });

      return jsonEncode(document);
    }

    test('onaylanan hareket katalogda kalıcı olur', () async {
      final validator = await container.read(planValidatorProvider.future);
      final result =
          validator.validate(planWithNewExercise()) as Ok<ValidatedPlan>;

      await container.read(planImporterProvider).import(
        result.value,
        acceptedNewExerciseIds: const {'custom_burpee'},
      );

      final saved = await CatalogRepository(db).getById('custom_burpee');
      expect(saved, isNotNull);
      expect(saved!.nameTr, 'Burpee');
      expect(saved.isUserDefined, isTrue);
      expect(saved.commonMistakes, hasLength(2));

      // Bir sonraki doğrulama artık bu hareketi tanır.
      final refreshed = await ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      ).read(planValidatorProvider.future);
      expect(refreshed.catalog.containsKey('custom_burpee'), isTrue);
    });
  });

  group('context.md gerçek verilerden üretilir', () {
    test('kayıtlar bağlam dosyasına yansır', () async {
      await container
          .read(profileRepositoryProvider)
          .setAll({'heightCm': '184', 'currentWeightKg': '110', 'age': '34'});

      await TodayRepository(db).setFlags('2026-08-30', workoutDone: true);
      await TodayRepository(db).setNote('2026-08-30', 'Şınavda zorlandım.');
      await BodyMetricsRepository(db).upsert(
        isoDate: '2026-08-30',
        kind: MetricKinds.weight,
        value: 109.4,
        unit: 'kg',
      );
      await WorkoutRepository(db).logSet(
        isoDate: '2026-08-30',
        exerciseId: 'incline_pushup',
        setIndex: 0,
        reps: 11,
      );
      await importPlan(planJson(startDate: '2026-08-30'));

      final markdown = await container
          .read(contextMdBuilderProvider)
          .build(today: DateTime(2026, 8, 31));

      // Profil
      expect(markdown, contains('Boy: 184 cm'));
      // Not düzenlenmeden
      expect(markdown, contains('Şınavda zorlandım.'));
      // Kilo serisi
      expect(markdown, contains('109.4'));
      // Gerçekleşen set
      expect(markdown, contains('incline_pushup'));
      // Etkin planın devamı isteniyor
      expect(markdown, contains('AI Planı'));
      // Katalog gerçek hareketlerle listeleniyor
      expect(markdown, contains('Eğimli Şınav'));
    });

    test('tahliller altıncı bölüme referans aralığıyla düşer', () async {
      // M5 senkron maddesinin kapanışı: `recentLabs()` M4'te boş liste
      // dönüyordu, `context.md` "tahlil kaydı yok" yazıyordu. Artık
      // gerçek tabloyu okuyor.
      final labs = LabRepository(db);
      await labs.add(
        const LabEntry(
          id: 'lab-1',
          date: '2026-08-01',
          marker: 'Vitamin D',
          value: 18.4,
          unit: 'ng/mL',
          refLow: 30,
          refHigh: 100,
          panel: LabPanels.vitamin,
        ),
      );

      final markdown = await container
          .read(contextMdBuilderProvider)
          .build(today: DateTime(2026, 8, 31));

      expect(markdown, contains('Vitamin D: 18.4 ng/mL'));
      expect(markdown, contains('referans 30.0-100.0'));
      expect(markdown, isNot(contains('(tahlil kaydı yok)')));
    });

    test('marker başına yalnız son sonuç gönderilir', () async {
      final labs = LabRepository(db);
      for (final (date, value) in [('2026-01-10', 8.0), ('2026-08-01', 42.0)]) {
        await labs.add(
          LabEntry(
            id: 'lab-$date',
            date: date,
            marker: 'Vitamin D',
            value: value,
            unit: 'ng/mL',
            panel: LabPanels.vitamin,
          ),
        );
      }

      final markdown = await container
          .read(contextMdBuilderProvider)
          .build(today: DateTime(2026, 8, 31));

      expect(markdown, contains('42.0'));
      // Eski değer belgeye girmiyor: AI'ı güncel durumdan uzaklaştırır.
      expect(markdown, isNot(contains('8.0 ng/mL')));
    });

    test('veri yokken de geçerli belge üretir', () async {
      final markdown = await container
          .read(contextMdBuilderProvider)
          .build(today: DateTime(2026, 8, 31));

      expect(markdown, contains('## 7. Görev ve format'));
      expect(markdown, contains('(not yazılmamış)'));
      expect(markdown, contains('(tahlil kaydı yok)'));
    });
  });
}
