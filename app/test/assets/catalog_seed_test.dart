import 'dart:convert';
import 'dart:io';

import 'package:disport/features/catalog/domain/equipment_kind.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tohum kataloğunun sözleşmesi — **iki kademeli** (spec §4.3).
///
/// **Her kayıtta zorunlu:** `id`, `nameEn`, `category`, `location`,
/// `equipment`, `primaryMuscles`, `difficulty`, `execution`. Bunlar
/// olmadan kayıt işlevsizdir — plana konamaz, filtrelenemez.
///
/// **Çekirdek listede ayrıca zorunlu:** `nameTr`, `summary`, `setup`,
/// `breathing`, `cues`, `commonMistakes`, `safety`. Çekirdek =
/// programda fiilen geçen hareketler; kullanıcının yapacağı hareketlerde
/// eksik alan kabul edilmez.
///
/// Çekirdek dışında alan **boş bırakılabilir**: kaynakta yok ve
/// araştırmayla bulunamadıysa uydurulmuyor. Uydurma bir "sık yapılan
/// hata" gerçeğiyle aynı görünür ve kullanıcı ikisini ayırt edemez.
void main() {
  late Map<String, dynamic> doc;
  late List<Map<String, dynamic>> exercises;

  setUpAll(() {
    final raw = File('assets/catalog.json').readAsStringSync();
    doc = jsonDecode(raw) as Map<String, dynamic>;
    exercises = (doc['exercises'] as List).cast<Map<String, dynamic>>();
  });

  /// Programda geçen hareketler — zenginlik çıtası bunlara uygulanıyor.
  ///
  /// Liste açıkça yazılı: bir hareket programa girerse buraya eklenir ve
  /// test onu doldurmaya zorlar. Otomatik türetilseydi (ör. "görseli
  /// olanlar") çıta sessizce kayardı.
  const coreIds = {
    'wall_pushup',
    'incline_pushup',
    'knee_pushup',
    'pushup',
    'chair_squat',
    'goblet_squat',
    'glute_bridge',
    'dumbbell_row',
    'band_row',
    'plank',
    'side_plank',
    'bird_dog',
    'wall_sit',
    'step_up',
    'calf_raise',
    'treadmill_incline_walk',
    'stationary_bike',
  };

  List<dynamic> listAt(Map<String, dynamic> exercise, String field) =>
      (exercise[field] as List?) ?? const [];

  test('tohum sürümü tanımlı ve pozitif', () {
    // Sürüm yeniden tohumlamayı tetikliyor; sabit bir sayı beklemek
    // her katalog güncellemesinde bu testi düzeltmeyi gerektirirdi.
    expect(doc['version'], isA<int>());
    expect(doc['version'] as int, greaterThan(0));
  });

  test('katalog kapsama tabanını tutuyor', () {
    // Spec §4.3'ün tabanı. Sayı değil kapsamanın vekili: 100 kaydın
    // altına düşmek bir hareket kalıbının ya da bir ekipmanın tamamen
    // düştüğü anlamına gelir.
    expect(exercises.length, greaterThanOrEqualTo(100));
  });

  test('her ekipman türü en az bir harekette temsil ediliyor', () {
    // Envanterde işaretlenebilen ama hiçbir hareketi olmayan ekipman,
    // kullanıcıya boş bir filtre sonucu vaat eder.
    final used = {
      for (final exercise in exercises)
        ...listAt(exercise, 'equipment').cast<String>(),
    };

    for (final kind in EquipmentKind.values.where((k) => k.needsInventory)) {
      expect(used, contains(kind.name), reason: '${kind.name} hiç kullanılmıyor');
    }
  });

  test('her kalıp ve yer için hareket var', () {
    for (final category in ['strength', 'cardio', 'mobility', 'core']) {
      expect(
        exercises.where((e) => e['category'] == category),
        isNotEmpty,
        reason: '$category kategorisi boş',
      );
    }
    for (final location in ['home', 'gym', 'both']) {
      expect(
        exercises.where((e) => e['location'] == location).length,
        greaterThanOrEqualTo(10),
        reason: '$location yerinde yeterli hareket yok',
      );
    }
  });

  test('kardiyo dışındaki her kayıtta MET ya da MET modeli var', () {
    // Kalori tahmini (M9) bunlara dayanacak; eksik MET sessizce sıfır
    // harcama demek olurdu.
    for (final exercise in exercises) {
      final hasMet = exercise['met'] != null;
      final hasModel = (exercise['metModel'] as String?) != null &&
          exercise['metModel'] != 'fixed';
      expect(
        hasMet || hasModel,
        isTrue,
        reason: '${exercise['id']}: MET de metModel de yok',
      );
    }
  });

  test('id\'ler benzersiz ve snake_case', () {
    final ids = exercises.map((e) => e['id'] as String).toList();
    expect(ids.toSet().length, ids.length, reason: 'yinelenen id');
    for (final id in ids) {
      expect(
        RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id),
        isTrue,
        reason: '$id snake_case değil',
      );
    }
  });

  test('her kayıt modele çözülür', () {
    // Ölçüt sabit sayı değil "hepsi çözüldü": model ile elle yazılmış
    // veri arasındaki uyum ancak gerçek dosya okunarak doğrulanabilir.
    final parsed = [for (final e in exercises) Exercise.fromJson(e)];
    expect(parsed, hasLength(exercises.length));
  });

  test('her kayıtta zorunlu alanlar dolu ve geçerli', () {
    const categories = {'strength', 'cardio', 'mobility', 'core'};
    const locations = {'home', 'gym', 'both'};
    final kinds = EquipmentKind.values.map((k) => k.name).toSet();

    for (final exercise in exercises) {
      final id = exercise['id'];

      expect(exercise['nameEn'], isNotEmpty, reason: '$id: nameEn boş');
      expect(categories, contains(exercise['category']), reason: '$id');
      expect(locations, contains(exercise['location']), reason: '$id');
      expect(
        exercise['difficulty'],
        allOf(greaterThanOrEqualTo(1), lessThanOrEqualTo(5)),
        reason: '$id: difficulty aralık dışı',
      );

      final equipment = listAt(exercise, 'equipment');
      expect(equipment, isNotEmpty, reason: '$id: equipment boş');
      for (final kind in equipment) {
        expect(kinds, contains(kind), reason: '$id: bilinmeyen ekipman $kind');
      }

      expect(
        listAt(exercise, 'primaryMuscles'),
        isNotEmpty,
        reason: '$id: primaryMuscles boş',
      );
      // v3 (T16.4): içerik iki dilli; adımlar iki dilden en az
      // birinde olmalı. TR zorunluluğu çekirdekte, EN zorunluluğu
      // içerik yazımı bitince açılacak (kademeli çıta).
      final steps = listAt(exercise, 'executionTr').isNotEmpty
          ? listAt(exercise, 'executionTr')
          : listAt(exercise, 'executionEn');
      expect(
        steps.length,
        greaterThanOrEqualTo(2),
        reason: '$id: execution (Tr ya da En) en az 2 adım olmalı',
      );
    }
  });

  test('çekirdek listede zenginlik alanları da dolu', () {
    final byId = {for (final e in exercises) e['id'] as String: e};

    for (final id in coreIds) {
      final exercise = byId[id];
      expect(exercise, isNotNull, reason: '$id çekirdekte ama katalogda yok');
      if (exercise == null) continue;

      for (final field in [
        'nameTr',
        'summaryTr',
        'breathingTr',
        'safetyTr',
      ]) {
        expect(
          exercise[field],
          isNotNull,
          reason: '$id: çekirdek kayıtta $field boş olamaz',
        );
        expect((exercise[field] as String).trim(), isNotEmpty, reason: id);
      }

      expect(
        listAt(exercise, 'setupTr'),
        isNotEmpty,
        reason: '$id: çekirdek kayıtta setupTr boş olamaz',
      );
      expect(
        listAt(exercise, 'executionTr').length,
        greaterThanOrEqualTo(3),
        reason: '$id: çekirdekte en az 3 Türkçe adım',
      );
      expect(
        listAt(exercise, 'cuesTr').length,
        greaterThanOrEqualTo(2),
        reason: '$id: çekirdekte en az 2 ipucu',
      );

      final mistakes = listAt(exercise, 'commonMistakesTr');
      expect(
        mistakes.length,
        greaterThanOrEqualTo(2),
        reason: '$id: çekirdekte en az 2 hata kaydı',
      );
      for (final raw in mistakes) {
        final mistake = raw as Map<String, dynamic>;
        for (final field in ['mistake', 'why', 'fix']) {
          expect(
            (mistake[field] as String?)?.trim(),
            isNotEmpty,
            reason: '$id: hata kaydında $field boş',
          );
        }
      }
    }
  });

  test('varyant referansları katalogda mevcut', () {
    final ids = exercises.map((e) => e['id'] as String).toSet();

    for (final exercise in exercises) {
      for (final field in ['regressions', 'progressions']) {
        for (final ref in listAt(exercise, field)) {
          expect(
            ids,
            contains(ref),
            reason: '${exercise['id']}.$field → $ref katalogda yok',
          );
        }
      }
    }
  });

  test('varyant zinciri tutarlı: A ilerlemesi B ise B gerilemesi A', () {
    final byId = {for (final e in exercises) e['id'] as String: e};

    for (final exercise in exercises) {
      final id = exercise['id'] as String;
      for (final ref in listAt(exercise, 'progressions')) {
        final target = byId[ref];
        if (target == null) continue;
        expect(
          listAt(target, 'regressions'),
          contains(id),
          reason: '$id ilerlemesi $ref ama $ref gerilemesinde $id yok',
        );
      }
    }
  });

  test('bildirilen görseller diskte var', () {
    for (final exercise in exercises) {
      final path = exercise['imagePath'] as String?;
      if (path == null) continue;
      expect(
        File(path).existsSync(),
        isTrue,
        reason: '${exercise['id']}: $path bulunamadı',
      );
    }
  });

  test('MET değerleri makul aralıkta', () {
    // Dinlenme 1.0, çok yoğun aktivite ~15. Bu aralığın dışı bir
    // yazım hatasıdır ve kalori hesabını sessizce bozar.
    for (final exercise in exercises) {
      final met = exercise['met'] as num?;
      if (met == null) continue;
      expect(
        met,
        allOf(greaterThanOrEqualTo(1.0), lessThanOrEqualTo(15.0)),
        reason: '${exercise['id']}: met=$met aralık dışı',
      );
    }
  });

  test('PDF programındaki hareketlerin tamamı katalogda', () {
    final ids = exercises.map((e) => e['id'] as String).toSet();
    expect(ids, containsAll(coreIds));
  });
}
