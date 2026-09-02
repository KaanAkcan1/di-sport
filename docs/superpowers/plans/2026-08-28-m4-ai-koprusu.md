# di@sport M4 — AI Köprüsü Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AI döngüsü kapanır: uygulama `context.md` üretir ve paylaşır; kullanıcının yapıştırdığı `plan.json` dört kapılı doğrulamadan geçer, önizlenir, tek transaction'la içeri alınır; `newExercises` onay akışıyla kataloğa eklenir.

**Architecture:** `ai_bridge` hiçbir feature'ı import etmez (spec 4.3). Dört port arayüzü tanımlar; her feature kendi adaptörünü `application/` katmanında kaydeder ve bağlama `app/` seviyesinde (provider override değil, doğrudan provider tanımlarıyla) yapılır. JSON modelleri freezed + json_serializable ile — projede yalnızca burada (spec 4.6). Onboarding (profil + yaşam tarzı formu) bu kilometre taşındadır çünkü `context.md`'nin 1. bölümü onsuz boş kalır.

**Tech Stack:** M3 yığını + freezed, freezed_annotation, json_serializable, json_annotation, share_plus.

**Spec:** `docs/superpowers/specs/2026-08-28-disport-tasarim.md` (özellikle 7, 6-İlk açılış, 10)


## M3 Sonrası Senkron Notu

Bu plan M2 ve M3 yürütülmeden önce yazıldı. Yürütmeden önce değişenler:

**Planın "eklenecek" dediği yöntemler zaten var.** Task 3 adım 5,
`TodayRepository.rowsBetween` ve `WorkoutRepository.logsBetween`
eklenmesini istiyordu; ikisi de M3'te yazıldı ve testli. Ayrıca hazır:
`PlanRepository.insertFullPlan` (transaction'lı), `FullPlan` ailesi,
`BodyMetricsRepository.series` / `latestPerKind`,
`CatalogRepository.upsertUserDefined` ve `getByIds`.

**freezed kullanılmayacak.** Spec 4.6 `ai_bridge`'de freezed +
json_serializable öngörüyordu. Gerekçe "elle JSON ayrıştırmak hataya
açık"tı; bu genelde doğru ama burada tam tersi geçerli:

> Bu ayrıştırıcının hata mesajları **AI'a geri yapıştırılacak**
> (spec 7.3). `json_serializable` bozuk girdide
> `type 'Null' is not a subtype of type 'String'` der; hangi günün
> hangi alanının eksik olduğunu söylemez. Kullanıcı bu mesajı AI'a
> yapıştırdığında AI da neyi düzelteceğini bilemez ve döngü tıkanır.

Bunun yerine alan yolunu izleyen küçük bir okuyucu (`JsonReader`)
yazılıyor: `days[2].exercises[0].exerciseId` gibi yollarla Türkçe
mesaj üretiyor. Ek bağımlılık da gerekmiyor.

Spec 4.6 buna göre güncellendi.

**Bağımlılık kuralı hatırlatması.** `ai_bridge` feature'ların yalnız
`domain/` katmanını import eder. `PlanRepository`, `TodayRepository` gibi
`data/` sınıflarına doğrudan dokunmaz — port arayüzleri üstünden erişir.

---

## Global Constraints

- M1-M3 Global Constraints geçerli
- `plan.json` şeması spec 7.2; `schemaVersion: 1`
- Doğrulama sınırları: `dailyKcal` 1200-4000, `proteinG` 50-300, `waterL` 1-6; saat biçimi `^([01]\d|2[0-3]):[0-5]\d$`; gün başına en çok 1 workout slotu; `rest` günü egzersiz içeremez
- `newExercises` çıtası (spec 7.4): `execution` ≥ 3, `commonMistakes` ≥ 2 (üç alan dolu), `breathing`/`safety`/`primaryMuscles`/`equipment` boş olamaz — ekipmansız hareket `["vücut ağırlığı"]` yazar; bu kural `context.md` görev bölümünde AI'a bildirilir
- Hata mesajları Türkçe ve AI'a geri yapıştırılabilir (spec 7.3)
- Her görev sonunda `flutter analyze` temiz, `flutter test` yeşil

**Önkoşul:** M3 tamamlanmış — `PlanRepository.insertFullPlan`, `FullPlan` ailesi, `CatalogRepository`, `TodayRepository`, `BodyMetricsRepository`, örnek plan akışı çalışıyor.

---

### Task 1: freezed altyapısı + plan.json modelleri

**Files:**
- Modify: `app/pubspec.yaml`
- Create: `app/lib/features/ai_bridge/domain/plan_json.dart`
- Test: `app/test/features/ai_bridge/domain/plan_json_test.dart`

**Interfaces:**
- Produces: `PlanJson`, `PlanMetaJson`, `PlanGoalsJson`, `PlanRulesJson`, `PlanDayJson`, `PlanSlotJson`, `PlanExerciseJson`, `NewExerciseJson` — hepsi freezed, `fromJson` üretilmiş. Task 2 (validator) ve Task 4 (importer) tüketir.

- [ ] **Step 1: Paketler**

```powershell
cd C:\Source\Kaan\di@sport\app
flutter pub add freezed_annotation json_annotation share_plus
flutter pub add --dev freezed json_serializable
```

- [ ] **Step 2: Failing test**

`app/test/features/ai_bridge/domain/plan_json_test.dart`:

```dart
import 'dart:convert';

import 'package:disport/features/ai_bridge/domain/plan_json.dart';
import 'package:flutter_test/flutter_test.dart';

String validPlanJson() => jsonEncode({
      'schemaVersion': 1,
      'meta': {'title': 'Eylül', 'startDate': '2026-08-31', 'weeks': 1},
      'goals': {
        'dailyKcal': 2400,
        'proteinG': 170,
        'waterL': 3,
        'weeklyGym': 3,
        'weeklyHome': 4,
        'targetLossKg': 1
      },
      'rules': {
        'forbidden': ['alkol'],
        'free': ['su']
      },
      'days': [
        for (var i = 0; i < 7; i++)
          {
            'date': '2026-0${i < 1 ? '8-31' : '9-0$i'}',
            'type': i == 6 ? 'rest' : (i.isEven ? 'gym' : 'home'),
            'weekIndex': 1,
            'headline': '',
            'slots': [
              {'time': '06:30', 'kind': 'meal', 'label': 'Kahvaltı'},
              if (i != 6)
                {'time': '22:00', 'kind': 'workout', 'label': 'Antrenman'},
            ],
            'exercises': [
              if (i != 6 && i.isOdd)
                {
                  'exerciseId': 'incline_pushup',
                  'sets': 3,
                  'reps': 10,
                  'restSec': 60
                },
            ],
          }
      ],
      'newExercises': <Object>[],
    });

void main() {
  test('parses a valid document', () {
    final p = PlanJson.fromJson(
        jsonDecode(validPlanJson()) as Map<String, dynamic>);
    expect(p.schemaVersion, 1);
    expect(p.meta.weeks, 1);
    expect(p.days, hasLength(7));
    expect(p.days[1].exercises.single.exerciseId, 'incline_pushup');
    expect(p.newExercises, isEmpty);
  });

  test('missing required field throws', () {
    final broken = jsonDecode(validPlanJson()) as Map<String, dynamic>;
    (broken['meta'] as Map<String, dynamic>).remove('startDate');
    expect(() => PlanJson.fromJson(broken), throwsA(anything));
  });
}
```

- [ ] **Step 3: FAIL doğrula**

- [ ] **Step 4: Modeller**

`app/lib/features/ai_bridge/domain/plan_json.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_json.freezed.dart';
part 'plan_json.g.dart';

/// AI'ın döndürdüğü plan belgesi (spec 7.2). Yalnızca taşıma; doğrulama
/// PlanValidator'da, domain'e çeviri PlanImporter'dadır.
@freezed
abstract class PlanJson with _$PlanJson {
  const factory PlanJson({
    required int schemaVersion,
    required PlanMetaJson meta,
    required PlanGoalsJson goals,
    required PlanRulesJson rules,
    required List<PlanDayJson> days,
    @Default([]) List<NewExerciseJson> newExercises,
  }) = _PlanJson;

  factory PlanJson.fromJson(Map<String, dynamic> json) =>
      _$PlanJsonFromJson(json);
}

@freezed
abstract class PlanMetaJson with _$PlanMetaJson {
  const factory PlanMetaJson({
    required String title,
    required String startDate,
    required int weeks,
  }) = _PlanMetaJson;

  factory PlanMetaJson.fromJson(Map<String, dynamic> json) =>
      _$PlanMetaJsonFromJson(json);
}

@freezed
abstract class PlanGoalsJson with _$PlanGoalsJson {
  const factory PlanGoalsJson({
    required int dailyKcal,
    required int proteinG,
    required double waterL,
    required int weeklyGym,
    required int weeklyHome,
    required double targetLossKg,
  }) = _PlanGoalsJson;

  factory PlanGoalsJson.fromJson(Map<String, dynamic> json) =>
      _$PlanGoalsJsonFromJson(json);
}

@freezed
abstract class PlanRulesJson with _$PlanRulesJson {
  const factory PlanRulesJson({
    required List<String> forbidden,
    required List<String> free,
  }) = _PlanRulesJson;

  factory PlanRulesJson.fromJson(Map<String, dynamic> json) =>
      _$PlanRulesJsonFromJson(json);
}

@freezed
abstract class PlanDayJson with _$PlanDayJson {
  const factory PlanDayJson({
    required String date,
    required String type,
    required int weekIndex,
    @Default('') String headline,
    @Default('') String dinnerSuggestion,
    @Default([]) List<PlanSlotJson> slots,
    @Default([]) List<PlanExerciseJson> exercises,
  }) = _PlanDayJson;

  factory PlanDayJson.fromJson(Map<String, dynamic> json) =>
      _$PlanDayJsonFromJson(json);
}

@freezed
abstract class PlanSlotJson with _$PlanSlotJson {
  const factory PlanSlotJson({
    required String time,
    required String kind,
    required String label,
    String? note,
  }) = _PlanSlotJson;

  factory PlanSlotJson.fromJson(Map<String, dynamic> json) =>
      _$PlanSlotJsonFromJson(json);
}

@freezed
abstract class PlanExerciseJson with _$PlanExerciseJson {
  const factory PlanExerciseJson({
    required String exerciseId,
    int? sets,
    int? reps,
    int? durationSec,
    int? restSec,
    String? intensity,
    String? note,
  }) = _PlanExerciseJson;

  factory PlanExerciseJson.fromJson(Map<String, dynamic> json) =>
      _$PlanExerciseJsonFromJson(json);
}

/// AI'ın önerdiği yeni hareket — Exercise.toJson şemasıyla aynı alanlar
/// (spec 7.4). Map olarak taşınır, çıtayı Task 2'deki validator denetler.
@freezed
abstract class NewExerciseJson with _$NewExerciseJson {
  const factory NewExerciseJson({
    required Map<String, dynamic> data,
  }) = _NewExerciseJson;

  factory NewExerciseJson.fromJson(Map<String, dynamic> json) =>
      NewExerciseJson(data: json);
}
```

Not: `NewExerciseJson` bilinçli olarak ham Map taşır — katalogdaki `Exercise.fromJson` (M2) zaten bu şemayı çözüyor; şemayı iki yerde tanımlamak süreklilik hatası üretir (DRY).

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: PASS doğrula**

- [ ] **Step 6: Commit**

```powershell
git add app/pubspec.yaml app/pubspec.lock app/lib/features/ai_bridge app/test/features/ai_bridge
git commit -m "feat: freezed plan.json transport models"
```

### Task 2: Dört kapılı doğrulayıcı

**Files:**
- Create: `app/lib/features/ai_bridge/domain/plan_validator.dart`
- Test: `app/test/features/ai_bridge/domain/plan_validator_test.dart`

**Interfaces:**
- Consumes: `PlanJson` (Task 1), `Result`/`Failure` (M1)
- Produces:
  - `class ValidatedPlan { final PlanJson plan; final List<Map<String, dynamic>> approvedNewExercises; }`
  - `class PlanValidator`:
    - kurucu: `PlanValidator({required Set<String> catalogIds, required Set<String> homeCompatibleIds, required Set<String> gymCompatibleIds})`
    - `Result<ValidatedPlan> validate(String rawJson)` — kapı 1-3; hatalar `Failure.message` içinde satır satır, AI'a geri yapıştırılabilir Türkçe
  - Kapı 4 (önizleme + onay) UI'dadır (Task 5); kapı 1-3 burada, saf ve sınanabilir.

- [ ] **Step 1: Failing testler**

`app/test/features/ai_bridge/domain/plan_validator_test.dart`:

```dart
import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_json_test.dart' show validPlanJson;

PlanValidator validator() => PlanValidator(
      catalogIds: {'incline_pushup', 'chair_squat', 'stationary_bike'},
      homeCompatibleIds: {'incline_pushup', 'chair_squat'},
      gymCompatibleIds: {'stationary_bike'},
    );

Map<String, dynamic> valid() =>
    jsonDecode(validPlanJson()) as Map<String, dynamic>;

void main() {
  test('gate 1: invalid json rejected', () {
    final r = validator().validate('{bozuk');
    expect(r.isOk, isFalse);
    expect((r as Err).failure.message, contains('JSON ayrıştırılamadı'));
  });

  test('gate 2: missing field rejected with field name', () {
    final doc = valid();
    (doc['meta'] as Map<String, dynamic>).remove('weeks');
    final r = validator().validate(jsonEncode(doc));
    expect((r as Err).failure.message, contains('weeks'));
  });

  test('gate 2: unsupported schemaVersion rejected', () {
    final doc = valid()..['schemaVersion'] = 99;
    final r = validator().validate(jsonEncode(doc));
    expect((r as Err).failure.message, contains('schemaVersion'));
  });

  test('gate 3: day count must equal weeks*7', () {
    final doc = valid();
    (doc['days'] as List).removeLast();
    final r = validator().validate(jsonEncode(doc));
    expect((r as Err).failure.message, contains('7 gün bekleniyordu, 6'));
  });

  test('gate 3: dates must be consecutive from startDate', () {
    final doc = valid();
    ((doc['days'] as List)[2] as Map<String, dynamic>)['date'] = '2026-09-15';
    final r = validator().validate(jsonEncode(doc));
    expect((r as Err).failure.message, contains('ardışık'));
  });

  test('gate 3: unknown exerciseId lists alternatives', () {
    final doc = valid();
    final day1 = (doc['days'] as List)[1] as Map<String, dynamic>;
    ((day1['exercises'] as List)[0] as Map<String, dynamic>)['exerciseId'] =
        'barbell_squat';
    final r = validator().validate(jsonEncode(doc));
    final msg = (r as Err).failure.message;
    expect(msg, contains('barbell_squat'));
    expect(msg, contains('katalogda yok'));
  });

  test('gate 3: gym-only exercise on home day rejected', () {
    final doc = valid();
    final day1 = (doc['days'] as List)[1] as Map<String, dynamic>; // home
    (day1['exercises'] as List).add({
      'exerciseId': 'stationary_bike',
      'sets': 1,
      'durationSec': 1500,
    });
    final r = validator().validate(jsonEncode(doc));
    expect((r as Err).failure.message, contains('ev günü'));
  });

  test('gate 3: kcal outside 1200-4000 rejected', () {
    final doc = valid();
    (doc['goals'] as Map<String, dynamic>)['dailyKcal'] = 800;
    final r = validator().validate(jsonEncode(doc));
    expect((r as Err).failure.message, contains('dailyKcal'));
  });

  test('gate 3: two workout slots in one day rejected', () {
    final doc = valid();
    final day0 = (doc['days'] as List)[0] as Map<String, dynamic>;
    (day0['slots'] as List)
        .add({'time': '18:00', 'kind': 'workout', 'label': 'İkinci'});
    final r = validator().validate(jsonEncode(doc));
    expect((r as Err).failure.message, contains('birden fazla antrenman'));
  });

  test('gate 3: exercises on a rest day rejected', () {
    final doc = valid();
    final day6 = (doc['days'] as List)[6] as Map<String, dynamic>; // rest
    (day6['exercises'] as List).add(
        {'exerciseId': 'incline_pushup', 'sets': 1, 'reps': 5});
    final r = validator().validate(jsonEncode(doc));
    expect((r as Err).failure.message, contains('dinlenme günü'));
  });

  test('newExercises below the bar rejected with reason', () {
    final doc = valid();
    (doc['newExercises'] as List).add({
      'id': 'custom_burpee',
      'nameTr': 'Burpee',
      'nameEn': 'Burpee',
      'category': 'strength',
      'location': 'home',
      'equipment': ['vücut ağırlığı'],
      'primaryMuscles': ['tüm vücut'],
      'secondaryMuscles': <String>[],
      'difficulty': 4,
      'summary': 's',
      'setup': ['a'],
      'execution': ['tek adım'], // < 3 → red
      'breathing': 'b',
      'tempo': 't',
      'cues': <String>[],
      'commonMistakes': [
        {'mistake': 'm', 'why': 'w', 'fix': 'f'}
      ], // < 2 → red
      'safety': 'g',
      'regressions': <String>[],
      'progressions': <String>[],
    });
    final r = validator().validate(jsonEncode(doc));
    final msg = (r as Err).failure.message;
    expect(msg, contains('custom_burpee'));
    expect(msg, contains('execution'));
    expect(msg, contains('commonMistakes'));
  });

  test('valid plan with valid newExercise passes; new id usable in days',
      () {
    final doc = valid();
    (doc['newExercises'] as List).add({
      'id': 'custom_burpee',
      'nameTr': 'Burpee',
      'nameEn': 'Burpee',
      'category': 'strength',
      'location': 'home',
      'equipment': ['vücut ağırlığı'],
      'primaryMuscles': ['tüm vücut'],
      'secondaryMuscles': <String>[],
      'difficulty': 4,
      'summary': 's',
      'setup': ['a'],
      'execution': ['1', '2', '3'],
      'breathing': 'b',
      'tempo': 't',
      'cues': ['c'],
      'commonMistakes': [
        {'mistake': 'm1', 'why': 'w1', 'fix': 'f1'},
        {'mistake': 'm2', 'why': 'w2', 'fix': 'f2'},
      ],
      'safety': 'g',
      'regressions': <String>[],
      'progressions': <String>[],
    });
    final day1 = (doc['days'] as List)[1] as Map<String, dynamic>;
    (day1['exercises'] as List)
        .add({'exerciseId': 'custom_burpee', 'sets': 2, 'reps': 8});

    final r = validator().validate(jsonEncode(doc));
    expect(r.isOk, isTrue, reason: (r is Err) ? (r as Err).failure.message : '');
    expect((r as Ok<ValidatedPlan>).value.approvedNewExercises, hasLength(1));
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon**

`app/lib/features/ai_bridge/domain/plan_validator.dart`:

```dart
import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_json.dart';

class ValidatedPlan {
  const ValidatedPlan({required this.plan, required this.approvedNewExercises});

  final PlanJson plan;
  final List<Map<String, dynamic>> approvedNewExercises;
}

class PlanValidator {
  PlanValidator({
    required this.catalogIds,
    required this.homeCompatibleIds,
    required this.gymCompatibleIds,
  });

  final Set<String> catalogIds;
  final Set<String> homeCompatibleIds;
  final Set<String> gymCompatibleIds;

  static const supportedSchemaVersion = 1;
  static final _timeRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static const _dayTypes = {'gym', 'home', 'rest'};
  static const _slotKinds = {
    'meal', 'workout', 'sleep', 'measurement', 'lab', 'other'
  };

  Result<ValidatedPlan> validate(String rawJson) {
    // Kapı 1 — ayrıştırma
    final Object decoded;
    try {
      decoded = jsonDecode(rawJson) as Object;
    } on FormatException catch (e) {
      return Err(Failure(
          message: 'JSON ayrıştırılamadı: ${e.message}\n'
              'Lütfen yalnızca geçerli JSON gönder, açıklama metni ekleme.'));
    }

    // Kapı 2 — şema
    final PlanJson plan;
    try {
      plan = PlanJson.fromJson(decoded as Map<String, dynamic>);
    } catch (e) {
      return Err(Failure(
          message: 'Şema hatası: $e\n'
              'Zorunlu alanları ve tipleri şemadaki gibi gönder.'));
    }
    if (plan.schemaVersion != supportedSchemaVersion) {
      return Err(Failure(
          message: 'schemaVersion ${plan.schemaVersion} desteklenmiyor; '
              'beklenen: $supportedSchemaVersion.'));
    }

    // Kapı 3 — anlam
    final errors = <String>[];

    // 3a: newExercises çıtası (spec 7.4) — id'leri katalog kümesine eklenmeden önce
    final newIds = <String>{};
    for (final ne in plan.newExercises) {
      final d = ne.data;
      final id = d['id'] as String? ?? '(id yok)';
      final problems = <String>[];
      if ((d['execution'] as List? ?? const []).length < 3) {
        problems.add('execution en az 3 adım olmalı');
      }
      final mistakes = (d['commonMistakes'] as List? ?? const []);
      final mistakesOk = mistakes.length >= 2 &&
          mistakes.every((m) =>
              m is Map &&
              (m['mistake'] as String? ?? '').isNotEmpty &&
              (m['why'] as String? ?? '').isNotEmpty &&
              (m['fix'] as String? ?? '').isNotEmpty);
      if (!mistakesOk) {
        problems.add('commonMistakes en az 2 kayıt, üç alanı da dolu olmalı');
      }
      for (final field in ['breathing', 'safety']) {
        if ((d[field] as String? ?? '').isEmpty) {
          problems.add('$field boş olamaz');
        }
      }
      for (final field in ['primaryMuscles', 'equipment']) {
        if ((d[field] as List? ?? const []).isEmpty) {
          problems.add('$field boş olamaz '
              '(ekipmansız hareket için ["vücut ağırlığı"] yaz)');
        }
      }
      if (problems.isNotEmpty) {
        errors.add('newExercises "$id": ${problems.join('; ')}.');
      } else {
        newIds.add(id);
      }
    }
    final knownIds = {...catalogIds, ...newIds};

    // 3b: gün sayısı ve ardışıklık
    final expectedDays = plan.meta.weeks * 7;
    if (plan.days.length != expectedDays) {
      errors.add('${plan.meta.weeks} hafta için $expectedDays gün '
          'bekleniyordu, ${plan.days.length} gün geldi.');
    }
    final start = DateTime.tryParse(plan.meta.startDate);
    if (start == null) {
      errors.add('meta.startDate geçersiz tarih: "${plan.meta.startDate}".');
    } else {
      for (final (i, day) in plan.days.indexed) {
        final expected = start.add(Duration(days: i));
        if (DateTime.tryParse(day.date) != expected) {
          errors.add('${i + 1}. gün: tarihler ardışık olmalı — '
              '"${day.date}" yerine '
              '"${expected.toIso8601String().substring(0, 10)}" bekleniyordu.');
          break; // ilk kopukluk yeter; kaskad hatayı boğma
        }
      }
    }

    // 3c: hedef aralıkları
    if (plan.goals.dailyKcal < 1200 || plan.goals.dailyKcal > 4000) {
      errors.add('goals.dailyKcal ${plan.goals.dailyKcal} makul aralık '
          'dışında (1200-4000).');
    }
    if (plan.goals.proteinG < 50 || plan.goals.proteinG > 300) {
      errors.add('goals.proteinG ${plan.goals.proteinG} makul aralık '
          'dışında (50-300).');
    }
    if (plan.goals.waterL < 1 || plan.goals.waterL > 6) {
      errors.add('goals.waterL ${plan.goals.waterL} makul aralık '
          'dışında (1-6).');
    }

    // 3d: gün içi kurallar
    for (final (i, day) in plan.days.indexed) {
      final label = '${i + 1}. gün (${day.date})';

      if (!_dayTypes.contains(day.type)) {
        errors.add('$label: type "${day.type}" geçersiz '
            '(gym | home | rest).');
        continue;
      }

      final workoutSlots =
          day.slots.where((s) => s.kind == 'workout').length;
      if (workoutSlots > 1) {
        errors.add('$label: birden fazla antrenman slotu var '
            '($workoutSlots). Günde en çok 1.');
      }
      if (day.type == 'rest' && day.exercises.isNotEmpty) {
        errors.add('$label: dinlenme günü egzersiz içeremez.');
      }

      for (final s in day.slots) {
        if (!_timeRe.hasMatch(s.time)) {
          errors.add('$label: slot saati "${s.time}" HH:mm değil.');
        }
        if (!_slotKinds.contains(s.kind)) {
          errors.add('$label: slot kind "${s.kind}" geçersiz.');
        }
      }

      for (final e in day.exercises) {
        if (!knownIds.contains(e.exerciseId)) {
          final pool =
              day.type == 'home' ? homeCompatibleIds : gymCompatibleIds;
          final alternatives = pool.take(3).join(', ');
          errors.add('$label: "${e.exerciseId}" katalogda yok. '
              'Uygun alternatifler: $alternatives.');
          continue;
        }
        if (day.type == 'home' &&
            catalogIds.contains(e.exerciseId) &&
            !homeCompatibleIds.contains(e.exerciseId)) {
          errors.add('$label: "${e.exerciseId}" ev günü yapılamaz '
              '(salon ekipmanı gerektirir).');
        }
        if (day.type == 'gym' &&
            catalogIds.contains(e.exerciseId) &&
            !gymCompatibleIds.contains(e.exerciseId) &&
            !homeCompatibleIds.contains(e.exerciseId)) {
          errors.add('$label: "${e.exerciseId}" salon günü için uygun değil.');
        }
        if (e.sets == null || (e.reps == null && e.durationSec == null)) {
          errors.add('$label: "${e.exerciseId}" sets ve '
              '(reps veya durationSec) zorunlu.');
        }
      }
    }

    if (errors.isNotEmpty) {
      return Err(Failure(
          message: 'Plan doğrulanamadı. Aşağıdaki maddeleri düzeltip '
              'JSON\'u yeniden gönder:\n${errors.map((e) => '• $e').join('\n')}'));
    }

    return Ok(ValidatedPlan(
      plan: plan,
      approvedNewExercises: [for (final ne in plan.newExercises) ne.data],
    ));
  }
}
```

- [ ] **Step 4: PASS doğrula** — tüm validator testleri.

- [ ] **Step 5: Commit**

```powershell
git add app/lib/features/ai_bridge app/test/features/ai_bridge
git commit -m "feat: three-gate plan validator with paste-back error messages"
```

### Task 3: Portlar, context.md üreticisi, feature adaptörleri

**Files:**
- Create: `app/lib/features/ai_bridge/domain/ports.dart`
- Create: `app/lib/features/ai_bridge/domain/context_md_builder.dart`
- Create: `app/lib/features/ai_bridge/application/ai_bridge_providers.dart`
- Create: `app/lib/features/settings/data/profile_repository.dart`
- Create: `app/lib/features/plan/application/plan_source_adapter.dart`
- Create: `app/lib/features/today/application/log_source_adapter.dart`
- Create: `app/lib/features/health/application/health_source_adapter.dart`
- Create: `app/lib/features/catalog/application/catalog_source_adapter.dart`
- Test: `app/test/features/ai_bridge/domain/context_md_builder_test.dart`
- Test: `app/test/features/ai_bridge/goldens/context_sample.md` (golden dosya)

**Interfaces:**
- Consumes: her adaptör kendi feature repository'sini
- Produces (`ports.dart` — ai_bridge dışa açtığı sözleşme, spec 4.3):

```dart
abstract interface class ProfileSource {
  Future<Map<String, String>> profile(); // key-value: boy, yaş, yaşam tarzı…
}

class DayCompliance {
  const DayCompliance({
    required this.date, required this.dayType,
    required this.workoutDone, required this.waterTargetMet,
    required this.noAlcoholSugar, required this.checkedSlots,
    required this.totalSlots,
  });
  final String date; final String dayType;
  final bool workoutDone; final bool waterTargetMet;
  final bool noAlcoholSugar; final int checkedSlots; final int totalSlots;
}

class SetActualDump {
  const SetActualDump({required this.date, required this.exerciseId,
      required this.setIndex, this.reps, this.durationSec});
  final String date; final String exerciseId;
  final int setIndex; final int? reps; final int? durationSec;
}

abstract interface class LogSource {
  Future<List<DayCompliance>> compliance({required int lastDays});
  Future<List<String>> userNotes({required int lastDays});
  Future<List<SetActualDump>> actuals({required int lastDays});
}

class MetricPoint {
  const MetricPoint({required this.date, required this.kind,
      required this.value, required this.unit});
  final String date; final String kind;
  final double value; final String unit;
}

class LabValueDump {
  const LabValueDump({required this.date, required this.marker,
      required this.value, required this.unit, this.refLow, this.refHigh});
  final String date; final String marker; final double value;
  final String unit; final double? refLow; final double? refHigh;
}

abstract interface class HealthSource {
  Future<List<MetricPoint>> bodyMetrics({required int lastDays});
  Future<List<LabValueDump>> recentLabs();
}

class ExerciseRef {
  const ExerciseRef({required this.id, required this.nameTr,
      required this.location, required this.equipment});
  final String id; final String nameTr;
  final String location; final List<String> equipment;
}

abstract interface class CatalogSource {
  Future<List<ExerciseRef>> selectable(); // kullanıcının ortamına uyan alt küme
}
```

  - `class ContextMdBuilder { ContextMdBuilder({required this.profile, required this.logs, required this.health, required this.catalog}); Future<String> build({required DateTime today, required int weeks}); }` — yedi bölümlü `context.md` (spec 7.1)
  - `ProfileRepository` (`Future<Map<String,String>> all()`, `Future<void> set(String key, String value)`) — ProfileEntries tablosu üstünde
  - Dört adaptör sınıfı + `contextMdBuilderProvider` (hepsini bağlar)
  - Not: M5'te `lab_results` gelmeden `HealthSourceAdapter.recentLabs()` boş liste döner — builder "tahlil kaydı yok" yazar; M5 planı adaptörü genişletir.

- [ ] **Step 1: Failing golden testi**

`app/test/features/ai_bridge/domain/context_md_builder_test.dart`:

```dart
import 'dart:io';

import 'package:disport/features/ai_bridge/domain/context_md_builder.dart';
import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfile implements ProfileSource {
  @override
  Future<Map<String, String>> profile() async => {
        'age': '34',
        'heightCm': '184',
        'currentWeightKg': '110',
        'targetWeightKg': '95',
        'wakeTime': '06:11',
        'sleepTime': '23:45',
        'workSchedule': 'Fabrika, 07:30-17:30',
        'gymAccessHours': '22:00 sonrası ve Cmt sabah',
        'familyDinnerTime': '19:50',
        'equipmentAtHome': 'direnç bandı, sandalye',
        'healthConstraints': 'karaciğer yağlanması; diz/incik hassasiyeti',
      };
}

class _FakeLogs implements LogSource {
  @override
  Future<List<DayCompliance>> compliance({required int lastDays}) async => [
        const DayCompliance(
            date: '2026-09-01', dayType: 'home', workoutDone: true,
            waterTargetMet: true, noAlcoholSugar: true,
            checkedSlots: 5, totalSlots: 6),
        const DayCompliance(
            date: '2026-09-02', dayType: 'gym', workoutDone: false,
            waterTargetMet: false, noAlcoholSugar: true,
            checkedSlots: 3, totalSlots: 6),
      ];

  @override
  Future<List<String>> userNotes({required int lastDays}) async =>
      ['Şınavda son set zor geldi.', 'Akşam bir dilim baklava yedim.'];

  @override
  Future<List<SetActualDump>> actuals({required int lastDays}) async => [
        const SetActualDump(
            date: '2026-09-01', exerciseId: 'incline_pushup',
            setIndex: 0, reps: 10),
      ];
}

class _FakeHealth implements HealthSource {
  @override
  Future<List<MetricPoint>> bodyMetrics({required int lastDays}) async => [
        const MetricPoint(
            date: '2026-09-01', kind: 'weight', value: 110, unit: 'kg'),
        const MetricPoint(
            date: '2026-09-02', kind: 'weight', value: 109.6, unit: 'kg'),
      ];

  @override
  Future<List<LabValueDump>> recentLabs() async => [
        const LabValueDump(
            date: '2026-06-15', marker: 'Vitamin D', value: 10,
            unit: 'ng/mL', refLow: 30, refHigh: 100),
      ];
}

class _FakeCatalog implements CatalogSource {
  @override
  Future<List<ExerciseRef>> selectable() async => [
        const ExerciseRef(
            id: 'incline_pushup', nameTr: 'Eğimli Şınav',
            location: 'home', equipment: []),
        const ExerciseRef(
            id: 'stationary_bike', nameTr: 'Kondisyon Bisikleti',
            location: 'gym', equipment: ['bisiklet']),
      ];
}

void main() {
  test('context.md matches golden file', () async {
    final builder = ContextMdBuilder(
      profile: _FakeProfile(),
      logs: _FakeLogs(),
      health: _FakeHealth(),
      catalog: _FakeCatalog(),
    );

    final md = await builder.build(today: DateTime(2026, 9, 28), weeks: 4);

    final goldenFile =
        File('test/features/ai_bridge/goldens/context_sample.md');
    if (!goldenFile.existsSync()) {
      goldenFile
        ..createSync(recursive: true)
        ..writeAsStringSync(md);
      fail('Golden oluşturuldu; içeriği gözden geçirip testi yeniden koş.');
    }
    expect(md, goldenFile.readAsStringSync());
  });

  test('all seven sections present', () async {
    final builder = ContextMdBuilder(
      profile: _FakeProfile(),
      logs: _FakeLogs(),
      health: _FakeHealth(),
      catalog: _FakeCatalog(),
    );
    final md = await builder.build(today: DateTime(2026, 9, 28), weeks: 4);

    for (final heading in [
      '## 1. Kim',
      '## 2. Hedef',
      '## 3. Kısıtlar',
      '## 4. Geçen dönem',
      '## 5. Kendi sözlerim',
      '## 6. Son tahliller',
      '## 7. Görev ve format',
    ]) {
      expect(md, contains(heading));
    }
    expect(md, contains('```json')); // bölüm 4 makine-okunur blok
    expect(md, contains('schemaVersion')); // bölüm 7 şema örneği
    expect(md, contains('vücut ağırlığı')); // newExercises kuralı bildirimi
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Builder implementasyonu**

`app/lib/features/ai_bridge/domain/context_md_builder.dart`:

```dart
import 'dart:convert';

import 'package:disport/features/ai_bridge/domain/ports.dart';

/// Yedi bölümlü context.md üretir (spec 7.1). Sağlayıcı-bağımsız:
/// çıktı herhangi bir AI sohbetine yapıştırılabilir.
class ContextMdBuilder {
  ContextMdBuilder({
    required this.profile,
    required this.logs,
    required this.health,
    required this.catalog,
  });

  final ProfileSource profile;
  final LogSource logs;
  final HealthSource health;
  final CatalogSource catalog;

  Future<String> build({required DateTime today, required int weeks}) async {
    final p = await profile.profile();
    final compliance = await logs.compliance(lastDays: 28);
    final notes = await logs.userNotes(lastDays: 28);
    final actuals = await logs.actuals(lastDays: 28);
    final metrics = await health.bodyMetrics(lastDays: 28);
    final labs = await health.recentLabs();
    final exercises = await catalog.selectable();

    final b = StringBuffer()
      ..writeln('# Antrenman ve Beslenme Planı İsteği')
      ..writeln()
      ..writeln('## 1. Kim')
      ..writeln('- Yaş: ${p['age'] ?? '?'}')
      ..writeln('- Boy: ${p['heightCm'] ?? '?'} cm')
      ..writeln('- Mevcut kilo: ${p['currentWeightKg'] ?? '?'} kg')
      ..writeln('- Uyanma: ${p['wakeTime'] ?? '?'} · '
          'Uyku: ${p['sleepTime'] ?? '?'}')
      ..writeln('- İş: ${p['workSchedule'] ?? '?'}')
      ..writeln('- Salon erişimi: ${p['gymAccessHours'] ?? '?'}')
      ..writeln('- Aile yemeği: ${p['familyDinnerTime'] ?? '?'}')
      ..writeln('- Evdeki ekipman: ${p['equipmentAtHome'] ?? 'yok'}')
      ..writeln()
      ..writeln('## 2. Hedef')
      ..writeln('- Hedef kilo: ${p['targetWeightKg'] ?? '?'} kg')
      ..writeln('- $weeks haftalık plan istiyorum; '
          'haftada 0,7-1 kg sürdürülebilir kayıp.')
      ..writeln()
      ..writeln('## 3. Kısıtlar')
      ..writeln('- Sağlık: ${p['healthConstraints'] ?? 'bilinen yok'}')
      ..writeln('- Zıplamalı hareket yok (geçiş kriteri sağlanana kadar).')
      ..writeln()
      ..writeln('## 4. Geçen dönem')
      ..writeln('Aşağıdaki blok makine üretimidir, gün gün uyum verisi:')
      ..writeln('```json')
      ..writeln(const JsonEncoder.withIndent('  ').convert({
        'days': [
          for (final c in compliance)
            {
              'date': c.date,
              'type': c.dayType,
              'workoutDone': c.workoutDone,
              'water3L': c.waterTargetMet,
              'noAlcoholSugar': c.noAlcoholSugar,
              'slotsChecked': '${c.checkedSlots}/${c.totalSlots}',
            }
        ],
        'weightSeries': [
          for (final m in metrics.where((m) => m.kind == 'weight'))
            {'date': m.date, 'kg': m.value}
        ],
        'setActuals': [
          for (final a in actuals)
            {
              'date': a.date,
              'exerciseId': a.exerciseId,
              'set': a.setIndex + 1,
              if (a.reps != null) 'reps': a.reps,
              if (a.durationSec != null) 'durationSec': a.durationSec,
            }
        ],
      }))
      ..writeln('```')
      ..writeln()
      ..writeln('## 5. Kendi sözlerim')
      ..writeln(notes.isEmpty
          ? '(not yok)'
          : notes.map((n) => '- $n').join('\n'))
      ..writeln()
      ..writeln('## 6. Son tahliller')
      ..writeln(labs.isEmpty
          ? '(tahlil kaydı yok)'
          : labs
              .map((l) => '- ${l.marker}: ${l.value} ${l.unit} '
                  '(referans ${l.refLow ?? '?'}-${l.refHigh ?? '?'}, '
                  '${l.date})')
              .join('\n'))
      ..writeln()
      ..writeln('## 7. Görev ve format')
      ..writeln('Bana ${weeks} haftalık, gün gün bir plan üret. '
          'Kurallar:')
      ..writeln('1. Yanıtın YALNIZCA aşağıdaki şemaya uyan tek bir JSON '
          'belgesi olsun. Açıklama metni, markdown çiti dışında hiçbir '
          'şey ekleme.')
      ..writeln('2. `exercises[].exerciseId` için YALNIZCA aşağıdaki '
          'katalog listesindeki id\'leri kullan.')
      ..writeln('3. Katalogda olmayan bir hareket önermek istersen onu '
          '`newExercises` dizisine tam tanımıyla ekle: `execution` en az '
          '3 adım, `commonMistakes` en az 2 kayıt (mistake/why/fix üçü de '
          'dolu), `breathing`, `safety`, `primaryMuscles`, `equipment` '
          'boş olamaz — ekipmansız hareket için `["vücut ağırlığı"]` yaz.')
      ..writeln('4. Saatleri benim yaşam düzenime göre koy '
          '(bölüm 1). Dinlenme günü egzersiz içermesin; günde en fazla '
          '1 antrenman slotu.')
      ..writeln()
      ..writeln('Kullanılabilir katalog (id · ad · yer · ekipman):')
      ..writeln('```')
      ..writeln(exercises
          .map((e) => '${e.id} · ${e.nameTr} · ${e.location} · '
              '${e.equipment.isEmpty ? 'ekipmansız' : e.equipment.join('+')}')
          .join('\n'))
      ..writeln('```')
      ..writeln()
      ..writeln('JSON şeması (örnek değerlerle):')
      ..writeln('```json')
      ..writeln(const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': 1,
        'meta': {
          'title': 'Ekim Planı',
          'startDate': _iso(today.add(const Duration(days: 1))),
          'weeks': weeks,
        },
        'goals': {
          'dailyKcal': 2400, 'proteinG': 170, 'waterL': 3,
          'weeklyGym': 3, 'weeklyHome': 4, 'targetLossKg': 3.5,
        },
        'rules': {
          'forbidden': ['alkol', '...'],
          'free': ['su', '...'],
        },
        'days': [
          {
            'date': _iso(today.add(const Duration(days: 1))),
            'type': 'home',
            'weekIndex': 1,
            'headline': 'Tempoyu bul.',
            'dinnerSuggestion': 'Izgara tavuk + salata',
            'slots': [
              {'time': '06:30', 'kind': 'meal', 'label': 'Kahvaltı'},
              {'time': '05:45', 'kind': 'workout', 'label': 'Ev antrenmanı'},
            ],
            'exercises': [
              {
                'exerciseId': 'incline_pushup',
                'sets': 3, 'reps': 10, 'restSec': 60,
              }
            ],
          }
        ],
        'newExercises': <Object>[],
      }))
      ..writeln('```');

    return b.toString();
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
```

`ports.dart` içeriği Interfaces bölümündeki gibi aynen yazılır.

- [ ] **Step 4: Golden'ı üret, gözden geçir, testleri PASS'la**

İlk koşu golden'ı yazar ve `fail` ile durur; `context_sample.md`'yi elle oku (yedi bölüm mantıklı mı), sonra tekrar koş → PASS.

- [ ] **Step 5: ProfileRepository + dört adaptör**

`app/lib/features/settings/data/profile_repository.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:disport/core/db/app_database.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  Future<Map<String, String>> all() async {
    final rows = await _db.select(_db.profileEntries).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> set(String key, String value) async {
    final existing = await (_db.select(_db.profileEntries)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing == null) {
      await _db.into(_db.profileEntries).insert(ProfileEntriesCompanion.insert(
          id: const Uuid().v4(), updatedAt: now, key: key, value: value));
    } else {
      await (_db.update(_db.profileEntries)
            ..where((t) => t.id.equals(existing.id)))
          .write(ProfileEntriesCompanion(
              value: Value(value), updatedAt: Value(now)));
    }
  }
}
```

Adaptörler (her biri kendi feature'ının `application/` klasöründe; ai_bridge'i import eder, tersi asla):

`app/lib/features/catalog/application/catalog_source_adapter.dart`:

```dart
import 'dart:convert';

import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';

class CatalogSourceAdapter implements CatalogSource {
  CatalogSourceAdapter(this._repo);

  final CatalogRepository _repo;

  @override
  Future<List<ExerciseRef>> selectable() async {
    final all = await _repo.watchFiltered().first;
    return [
      for (final e in all)
        ExerciseRef(
          id: e.id,
          nameTr: e.nameTr,
          location: e.location.name,
          equipment: e.equipment,
        ),
    ];
  }
}
```

`app/lib/features/today/application/log_source_adapter.dart` — `TodayRepository`, `WorkoutRepository` ve `PlanRepository`'den `DayCompliance`/`userNotes`/`actuals` üretir: son `lastDays` günün `daily_logs` satırlarını okur, aynı tarihli `plan_days`+`plan_slots` ile `totalSlots`'u sayar, notları toplar, `exercise_logs`'u `SetActualDump`'a çevirir. (M3 repository'lerine iki küçük sorgu eklenir: `TodayRepository.rowsBetween(fromIso, toIso)` ve `WorkoutRepository.logsBetween(fromIso, toIso)` — aynı görevde, testli.)

`app/lib/features/health/application/health_source_adapter.dart` — `BodyMetricsRepository.series`'ten `MetricPoint` listesi; `recentLabs()` M4'te `const []` döner (M5 genişletir — plan senkron notu).

`app/lib/features/plan/application/plan_source_adapter.dart` — bu kilometre taşında `ContextMdBuilder` plan detayına ihtiyaç duymadığı için adaptör YAZILMAZ; port listesinden `PlanSource` çıkarıldı (YAGNI — spec 4.3'teki port fikri korunuyor, kullanılmayan port tanımlanmıyor). Dosya oluşturulmaz.

`app/lib/features/ai_bridge/application/ai_bridge_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:disport/app/app.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/application/catalog_source_adapter.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/health/application/health_source_adapter.dart';
import 'package:disport/features/settings/data/profile_repository.dart';
import 'package:disport/features/today/application/log_source_adapter.dart';
import 'package:disport/features/today/application/today_providers.dart';

part 'ai_bridge_providers.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepository(ref.watch(appDatabaseProvider));

@riverpod
ContextMdBuilder contextMdBuilder(Ref ref) => ContextMdBuilder(
      profile: ProfileSourceAdapter(ref.watch(profileRepositoryProvider)),
      logs: LogSourceAdapter(
        today: ref.watch(todayRepositoryProvider),
        db: ref.watch(appDatabaseProvider),
      ),
      health: HealthSourceAdapter(
          ref.watch(bodyMetricsRepositoryProvider)),
      catalog:
          CatalogSourceAdapter(ref.watch(catalogRepositoryProvider)),
    );

@riverpod
Future<PlanValidator> planValidator(Ref ref) async {
  final all =
      await ref.watch(catalogRepositoryProvider).watchFiltered().first;
  return PlanValidator(
    catalogIds: {for (final e in all) e.id},
    homeCompatibleIds: {
      for (final e in all)
        if (e.location != ExerciseLocation.gym) e.id
    },
    gymCompatibleIds: {
      for (final e in all)
        if (e.location != ExerciseLocation.home) e.id
    },
  );
}
```

(`ProfileSourceAdapter` — `ProfileRepository.all()`'ı `ProfileSource.profile()`'a bağlayan üç satırlık sınıf, `settings/application/` içinde.)

- [ ] **Step 6: Tüm testler + analyze** — `flutter test`, `flutter analyze`, `dart run custom_lint`

- [ ] **Step 7: Commit**

```powershell
git add app/lib/features app/test/features
git commit -m "feat: ai_bridge ports, context.md builder, feature adapters"
```

### Task 4: Plan importer — ValidatedPlan → veritabanı

**Files:**
- Create: `app/lib/features/ai_bridge/domain/plan_importer.dart`
- Test: `app/test/features/ai_bridge/domain/plan_importer_test.dart`

**Interfaces:**
- Consumes: `ValidatedPlan` (Task 2), `FullPlan` ailesi (M3), M2 `Exercise`
- Produces: `class PlanImporter`:
  - kurucu: `PlanImporter({required Future<void> Function(FullPlan) insertPlan, required Future<void> Function(Exercise) addExercise})` — fonksiyon enjeksiyonu: ai_bridge feature repository tiplerini değil, imzaları bilir
  - `Future<Result<ImportSummary>> import(ValidatedPlan v, {required String rawJson, required Set<String> acceptedNewExerciseIds})`
  - `class ImportSummary { final String planId; final int dayCount; final int addedExercises; }`
  - Kabul edilmeyen `newExercises` id'si planın `days`'inde kullanılmışsa import reddedilir (tutarlılık).

- [ ] **Step 1: Failing test**

`app/test/features/ai_bridge/domain/plan_importer_test.dart`:

```dart
import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_importer.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import 'plan_json_test.dart' show validPlanJson;
import 'plan_validator_test.dart' show validator;

void main() {
  late List<FullPlan> insertedPlans;
  late List<Exercise> addedExercises;
  late PlanImporter importer;

  setUp(() {
    insertedPlans = [];
    addedExercises = [];
    importer = PlanImporter(
      insertPlan: (p) async => insertedPlans.add(p),
      addExercise: (e) async => addedExercises.add(e),
    );
  });

  test('maps days, slots, exercises into FullPlan and stores raw', () async {
    final v = validator().validate(validPlanJson());
    final r = await importer.import(
      (v as Ok<ValidatedPlan>).value,
      rawJson: validPlanJson(),
      acceptedNewExerciseIds: {},
    );

    expect(r.isOk, isTrue);
    final plan = insertedPlans.single;
    expect(plan.days, hasLength(7));
    expect(plan.sourceRaw, validPlanJson());
    expect(plan.days[1].exercises.single.exerciseId, 'incline_pushup');
    expect(plan.days[0].slots.first.time, '06:30');
  });

  test('accepted new exercises are added to catalog before plan insert',
      () async {
    final doc = jsonDecode(validPlanJson()) as Map<String, dynamic>;
    (doc['newExercises'] as List).add({
      'id': 'custom_burpee', 'nameTr': 'Burpee', 'nameEn': 'Burpee',
      'category': 'strength', 'location': 'home',
      'equipment': ['vücut ağırlığı'], 'primaryMuscles': ['tüm vücut'],
      'secondaryMuscles': <String>[], 'difficulty': 4, 'summary': 's',
      'setup': ['a'], 'execution': ['1', '2', '3'], 'breathing': 'b',
      'tempo': 't', 'cues': ['c'],
      'commonMistakes': [
        {'mistake': 'm1', 'why': 'w1', 'fix': 'f1'},
        {'mistake': 'm2', 'why': 'w2', 'fix': 'f2'},
      ],
      'safety': 'g', 'regressions': <String>[], 'progressions': <String>[],
    });
    final v = validator().validate(jsonEncode(doc)) as Ok<ValidatedPlan>;

    final r = await importer.import(v.value,
        rawJson: jsonEncode(doc),
        acceptedNewExerciseIds: {'custom_burpee'});

    expect(r.isOk, isTrue);
    expect(addedExercises.single.id, 'custom_burpee');
    expect(addedExercises.single.isUserDefined, isTrue);
  });

  test('rejecting a new exercise that the plan uses fails the import',
      () async {
    final doc = jsonDecode(validPlanJson()) as Map<String, dynamic>;
    (doc['newExercises'] as List).add({
      'id': 'custom_burpee', 'nameTr': 'Burpee', 'nameEn': 'Burpee',
      'category': 'strength', 'location': 'home',
      'equipment': ['vücut ağırlığı'], 'primaryMuscles': ['tüm vücut'],
      'secondaryMuscles': <String>[], 'difficulty': 4, 'summary': 's',
      'setup': ['a'], 'execution': ['1', '2', '3'], 'breathing': 'b',
      'tempo': 't', 'cues': ['c'],
      'commonMistakes': [
        {'mistake': 'm1', 'why': 'w1', 'fix': 'f1'},
        {'mistake': 'm2', 'why': 'w2', 'fix': 'f2'},
      ],
      'safety': 'g', 'regressions': <String>[], 'progressions': <String>[],
    });
    final day1 = (doc['days'] as List)[1] as Map<String, dynamic>;
    (day1['exercises'] as List)
        .add({'exerciseId': 'custom_burpee', 'sets': 2, 'reps': 8});
    final v = validator().validate(jsonEncode(doc)) as Ok<ValidatedPlan>;

    final r = await importer.import(v.value,
        rawJson: jsonEncode(doc), acceptedNewExerciseIds: {});

    expect(r.isOk, isFalse);
    expect((r as Err).failure.message, contains('custom_burpee'));
    expect(insertedPlans, isEmpty);
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon**

`app/lib/features/ai_bridge/domain/plan_importer.dart`:

```dart
import 'package:uuid/uuid.dart';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_json.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/plan/domain/full_plan.dart';

class ImportSummary {
  const ImportSummary({
    required this.planId,
    required this.dayCount,
    required this.addedExercises,
  });

  final String planId;
  final int dayCount;
  final int addedExercises;
}

/// ValidatedPlan'ı domain'e çevirip kayıt kapılarına verir.
/// Feature tiplerini değil, fonksiyon imzalarını bilir (spec 4.3).
class PlanImporter {
  PlanImporter({required this.insertPlan, required this.addExercise});

  final Future<void> Function(FullPlan plan) insertPlan;
  final Future<void> Function(Exercise exercise) addExercise;

  Future<Result<ImportSummary>> import(
    ValidatedPlan v, {
    required String rawJson,
    required Set<String> acceptedNewExerciseIds,
  }) async {
    final plan = v.plan;

    // Reddedilen newExercise planda kullanılmış mı?
    final rejectedIds = {
      for (final ne in v.approvedNewExercises)
        if (!acceptedNewExerciseIds.contains(ne['id'])) ne['id'] as String
    };
    for (final day in plan.days) {
      for (final e in day.exercises) {
        if (rejectedIds.contains(e.exerciseId)) {
          return Err(Failure(
              message: 'Plan "${e.exerciseId}" hareketini kullanıyor ama '
                  'bu yeni hareketi onaylamadın. Ya onayla ya da '
                  'AI\'dan hareketsiz yeni bir sürüm iste.'));
        }
      }
    }

    var added = 0;
    for (final ne in v.approvedNewExercises) {
      if (acceptedNewExerciseIds.contains(ne['id'])) {
        final data = Map<String, dynamic>.from(ne)..['isUserDefined'] = true;
        await addExercise(Exercise.fromJson(data));
        added++;
      }
    }

    final planId = const Uuid().v4();
    final full = FullPlan(
      id: planId,
      title: plan.meta.title,
      startDate: DateTime.parse(plan.meta.startDate),
      weeks: plan.meta.weeks,
      goals: PlanGoals(
        dailyKcal: plan.goals.dailyKcal,
        proteinG: plan.goals.proteinG,
        waterL: plan.goals.waterL,
        weeklyGym: plan.goals.weeklyGym,
        weeklyHome: plan.goals.weeklyHome,
        targetLossKg: plan.goals.targetLossKg,
      ),
      rules: PlanRules(
        forbidden: plan.rules.forbidden,
        free: plan.rules.free,
      ),
      sourceRaw: rawJson,
      days: [
        for (final (di, d) in plan.days.indexed)
          FullPlanDay(
            id: '$planId-d$di',
            date: DateTime.parse(d.date),
            type: PlanDayType.values.byName(d.type),
            weekIndex: d.weekIndex,
            headline: d.headline,
            dinnerSuggestion: d.dinnerSuggestion,
            slots: [
              for (final (si, s) in d.slots.indexed)
                PlanSlot(
                  id: '$planId-d$di-s$si',
                  time: s.time,
                  kind: SlotKind.values.byName(s.kind),
                  label: s.label,
                  note: s.note,
                ),
            ],
            exercises: [
              for (final (ei, e) in d.exercises.indexed)
                PlanExercise(
                  id: '$planId-d$di-e$ei',
                  exerciseId: e.exerciseId,
                  sets: e.sets,
                  reps: e.reps,
                  durationSec: e.durationSec,
                  restSec: e.restSec,
                  intensity: e.intensity,
                  note: e.note,
                ),
            ],
          ),
      ],
    );

    await insertPlan(full);
    return Ok(ImportSummary(
      planId: planId,
      dayCount: full.days.length,
      addedExercises: added,
    ));
  }
}
```

- [ ] **Step 4: PASS doğrula**

- [ ] **Step 5: Commit**

```powershell
git add app/lib/features/ai_bridge app/test/features/ai_bridge
git commit -m "feat: plan importer with new-exercise approval consistency"
```

### Task 5: Plan ekranı AI eylemleri — üret/paylaş, yapıştır/önizle/onayla

**Files:**
- Modify: `app/lib/features/plan/presentation/plan_screen.dart`
- Create: `app/lib/features/ai_bridge/presentation/import_plan_sheet.dart`
- Test: `app/test/features/ai_bridge/presentation/import_plan_sheet_test.dart`

**Interfaces:**
- Consumes: `contextMdBuilderProvider`, `planValidatorProvider`, `PlanImporter`, `planRepositoryProvider`, `catalogRepositoryProvider`
- Produces: Plan ekranında iki eylem düğmesi. "Yeni plan iste" → `context.md` üretir, `SharePlus.instance.share(ShareParams(text: md))` + panoya kopyalama seçeneği. "Planı içeri al" → `ImportPlanSheet` (tam ekran modal): yapıştırma alanı → Doğrula → hata varsa AI'a-yapıştırılabilir mesaj + "Hatayı kopyala" düğmesi; geçerse önizleme (gün sayısı, tip dağılımı, hedefler, `newExercises` onay listesi checkbox'lı) → "İçeri al" → başarıda snackbar + `activePlanProvider` invalidate. "Örnek planı yükle" düğmesi yalnız plan yokken ve `kDebugMode`'da kalır.

- [ ] **Step 1: Failing widget testi**

`app/test/features/ai_bridge/presentation/import_plan_sheet_test.dart`:

```dart
import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/ai_bridge/presentation/import_plan_sheet.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../catalog/data/catalog_repository_test.dart' show seedJson;
import '../domain/plan_json_test.dart' show validPlanJson;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await CatalogRepository(db).seedFromJson(seedJson());
  });
  tearDown(() => db.close());

  Widget wrap() => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: Scaffold(body: ImportPlanSheet())),
      );

  testWidgets('invalid json shows paste-back error', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.enterText(
        find.byKey(const Key('plan-json-field')), '{bozuk');
    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();

    expect(find.textContaining('JSON ayrıştırılamadı'), findsOneWidget);
    expect(find.text('Hatayı kopyala'), findsOneWidget);
  });

  testWidgets('valid json shows preview then imports', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.enterText(
        find.byKey(const Key('plan-json-field')), validPlanJson());
    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();

    expect(find.textContaining('7 gün'), findsOneWidget);

    await tester.tap(find.text('İçeri al'));
    await tester.pumpAndSettle();

    expect(await db.select(db.plans).get(), hasLength(1));
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: ImportPlanSheet implementasyonu**

`app/lib/features/ai_bridge/presentation/import_plan_sheet.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/plan_importer.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/plan/application/plan_providers.dart';

class ImportPlanSheet extends ConsumerStatefulWidget {
  const ImportPlanSheet({super.key});

  @override
  ConsumerState<ImportPlanSheet> createState() => _ImportPlanSheetState();
}

class _ImportPlanSheetState extends ConsumerState<ImportPlanSheet> {
  final _controller = TextEditingController();
  String? _error;
  ValidatedPlan? _validated;
  final _acceptedNewIds = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final validator = await ref.read(planValidatorProvider.future);
    final r = validator.validate(_controller.text);
    setState(() {
      switch (r) {
        case Ok(:final value):
          _validated = value;
          _error = null;
          _acceptedNewIds
            ..clear()
            ..addAll(
                value.approvedNewExercises.map((e) => e['id'] as String));
        case Err(:final failure):
          _validated = null;
          _error = failure.message;
      }
    });
  }

  Future<void> _import() async {
    final v = _validated!;
    final importer = PlanImporter(
      insertPlan: ref.read(planRepositoryProvider).insertFullPlan,
      addExercise: ref.read(catalogRepositoryProvider).addUserDefined,
    );
    final r = await importer.import(v,
        rawJson: _controller.text,
        acceptedNewExerciseIds: _acceptedNewIds);

    if (!mounted) return;
    switch (r) {
      case Ok(:final value):
        ref.invalidate(activePlanProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${value.dayCount} günlük plan içeri alındı'
                '${value.addedExercises > 0 ? ', ${value.addedExercises} yeni hareket eklendi' : ''}.')));
        Navigator.of(context).maybePop();
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _validated;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Planı içeri al',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          key: const Key('plan-json-field'),
          controller: _controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'AI\'ın verdiği JSON\'u buraya yapıştır…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _validate, child: const Text('Doğrula')),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: _error!)),
                    child: const Text('Hatayı kopyala'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (v != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Önizleme',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('${v.plan.meta.title} — '
                      '${v.plan.days.length} gün, '
                      '${v.plan.meta.weeks} hafta'),
                  Text('Salon: ${v.plan.days.where((d) => d.type == 'gym').length} · '
                      'Ev: ${v.plan.days.where((d) => d.type == 'home').length} · '
                      'Dinlenme: ${v.plan.days.where((d) => d.type == 'rest').length}'),
                  Text('${v.plan.goals.dailyKcal} kcal · '
                      '${v.plan.goals.proteinG} g protein · '
                      '${v.plan.goals.waterL} L su'),
                  if (v.approvedNewExercises.isNotEmpty) ...[
                    const Divider(),
                    Text('Yeni hareket önerileri',
                        style: Theme.of(context).textTheme.titleSmall),
                    for (final ne in v.approvedNewExercises)
                      CheckboxListTile(
                        value: _acceptedNewIds.contains(ne['id']),
                        onChanged: (checked) => setState(() {
                          if (checked ?? false) {
                            _acceptedNewIds.add(ne['id'] as String);
                          } else {
                            _acceptedNewIds.remove(ne['id']);
                          }
                        }),
                        title: Text('${ne['nameTr']} (${ne['id']})'),
                        subtitle: Text('Kataloğa kalıcı eklenecek'),
                      ),
                  ],
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: _import, child: const Text('İçeri al')),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Plan ekranına eylemler**

`plan_screen.dart` üstüne iki düğme (plan varken de görünür):

```dart
Row(children: [
  Expanded(
    child: FilledButton.icon(
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Yeni plan iste'),
      onPressed: () async {
        final md = await ref
            .read(contextMdBuilderProvider)
            .build(today: DateTime.now(), weeks: 4);
        await SharePlus.instance.share(ShareParams(text: md));
      },
    ),
  ),
  const SizedBox(width: 8),
  Expanded(
    child: OutlinedButton.icon(
      icon: const Icon(Icons.file_download_outlined),
      label: const Text('Planı içeri al'),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const FractionallySizedBox(
            heightFactor: 0.9, child: ImportPlanSheet()),
      ),
    ),
  ),
]),
```

"Örnek planı yükle" düğmesini `if (kDebugMode)` koşuluna al (`package:flutter/foundation.dart`).

- [ ] **Step 5: PASS + analyze** — `flutter test`, `flutter analyze`

- [ ] **Step 6: Commit**

```powershell
git add app/lib/features app/test/features
git commit -m "feat: plan screen AI actions - generate context, import with preview"
```

### Task 6: Onboarding — profil ve yaşam tarzı

**Files:**
- Create: `app/lib/features/settings/presentation/onboarding_screen.dart`
- Create: `app/lib/features/settings/presentation/settings_screen.dart`
- Modify: `app/lib/app/app.dart` (ilk açılış yönlendirme + AppBar ayar ikonu)
- Test: `app/test/features/settings/presentation/onboarding_screen_test.dart`

**Interfaces:**
- Consumes: `profileRepositoryProvider` (Task 3)
- Produces: İlk açılışta (profilde `heightCm` yoksa) `OnboardingScreen` gösterilir: alanlar — yaş, boy, mevcut/hedef kilo, uyanma/uyku saati, iş düzeni, salon saatleri, aile yemeği saati, evdeki ekipman, sağlık kısıtları. Kaydet → profile yazılır → kabuğa geçilir ve Plan sekmesi açılır ("İlk planını al" akışı, spec 6-İlk açılış). `SettingsScreen` aynı formun düzenleme hali; AppBar'daki dişli ikonundan açılır.

- [ ] **Step 1: Failing test**

`app/test/features/settings/presentation/onboarding_screen_test.dart`:

```dart
import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/settings/presentation/onboarding_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('saving the form writes profile entries', (tester) async {
    var completed = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
          home: OnboardingScreen(onDone: () => completed = true)),
    ));

    await tester.enterText(find.byKey(const Key('field-age')), '34');
    await tester.enterText(find.byKey(const Key('field-heightCm')), '184');
    await tester.enterText(
        find.byKey(const Key('field-currentWeightKg')), '110');
    await tester.enterText(
        find.byKey(const Key('field-targetWeightKg')), '95');
    await tester.dragUntilVisible(find.text('Kaydet'),
        find.byType(ListView), const Offset(0, -200));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    final rows = await db.select(db.profileEntries).get();
    final map = {for (final r in rows) r.key: r.value};
    expect(map['heightCm'], '184');
    expect(map['targetWeightKg'], '95');
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon**

`OnboardingScreen({required VoidCallback onDone})`: `ListView` içinde `TextField`'lar — her alan `Key('field-<profileKey>')` ile; profil anahtarları `context_md_builder`'ın okuduklarıyla birebir: `age, heightCm, currentWeightKg, targetWeightKg, wakeTime, sleepTime, workSchedule, gymAccessHours, familyDinnerTime, equipmentAtHome, healthConstraints`. "Kaydet" tüm dolu alanları `ProfileRepository.set` ile yazar, `onDone()` çağırır. Zorunlu alan yalnız `heightCm` — gerisi boş bırakılabilir (builder '?' basar).

`SettingsScreen`: aynı form, `ProfileRepository.all()` ile önceden doldurulmuş; ayrıca M5'te bildirim tercihleri buraya eklenecek.

`app/app.dart` — `DisportApp.build`, `FutureBuilder` ile profili kontrol eder:

```dart
home: FutureBuilder<Map<String, String>>(
  future: ProfileRepository(ref.watch(appDatabaseProvider)).all(),
  builder: (context, snap) {
    if (!snap.hasData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return snap.data!.containsKey('heightCm')
        ? const _Shell()
        : OnboardingScreen(onDone: () { /* setState ile _Shell'e geç */ });
  },
),
```

(`DisportApp` bunun için `ConsumerStatefulWidget`'a çevrilir; `onDone` bir `setState` bayrağı çevirir.) `_Shell`'in AppBar'ına `IconButton(icon: Icon(Icons.settings), onPressed: → SettingsScreen)` eklenir.

- [ ] **Step 4: PASS + tüm testler + analyze**

- [ ] **Step 5: Emülatörde uçtan uca**

Temiz kurulum → onboarding → kaydet → Plan → "Yeni plan iste" → paylaşım sayfası açılır, md içeriğini gözle kontrol et → md'yi bir AI'a ver → dönen JSON'u "Planı içeri al"a yapıştır → önizleme → içeri al → Bugün ekranı gerçek planla dolu.

- [ ] **Step 6: Commit**

```powershell
git add app/lib app/test
git commit -m "feat: onboarding and settings forms feeding context.md"
```

---

## Self-Review Notları

- **Spec kapsaması:** 7.1 ✓ (yedi bölüm + katalog alt kümesi + şema örneği + newExercises kuralı bildirimi), 7.2 ✓, 7.3 ✓ (kapı 1-3 validator, kapı 4 önizleme UI), 7.4 ✓ (çıta + onay checkbox'ları + tutarlılık reddi), 6-İlk açılış ✓, 10 ✓ (bozuk JSON, kısmi yazma yok — insertFullPlan M3'te zaten transaction). 7.5 BYOK bu planda YOK — M5 planının son görevi (spec "isteğe bağlı" diyor; çekirdek döngü önce).
- **Bağımlılık kuralı denetimi:** ai_bridge yalnız `core/` + kendi dosyalarını + `catalog/domain/exercise.dart` ve `plan/domain/full_plan.dart`'ı import ediyor. Bu iki domain importu spec 4.3'ün "port" kuralının bilinçli gevşetmesidir: importer'ın ürettiği tipler bu domain sınıflarıdır; onları porta kopyalamak DRY ihlali olurdu. Kural şöyle daralır ve spec'e işlenecek: **ai_bridge feature'ların yalnız `domain/` katmanını import edebilir; `data/`, `application/`, `presentation/` asla.** (Spec 4.3'e bu cümle eklenecek — senkronizasyon maddesi.)
- **Tip tutarlılığı:** `validator()` ve `validPlanJson()` test yardımcıları cross-import; `SharePlus.instance.share(ShareParams(...))` share_plus 12.x güncel API'si; `PlanRepository.insertFullPlan` imzası M3 ile aynı; `MetricKinds.weight` = `'weight'` context builder'daki string ile tutarlı.
- **Açık senkron maddeleri (yürütmede M3/M5'e dokunur):** (1) M3 `TodayRepository`/`WorkoutRepository`'ye `rowsBetween`/`logsBetween` sorguları Task 3'te ekleniyor — M3 planına değil bu plana ait, çakışma yok. (2) M5 `HealthSourceAdapter.recentLabs()`'ı gerçek lab_results ile dolduracak.
