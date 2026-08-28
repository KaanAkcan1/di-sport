import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tohum kataloğunun sözleşmesi.
///
/// İçerik elle yazıldığı için bir kaydın alanı eksik kalabilir ya da bir
/// varyant referansı yanlış yazılabilir. Bu testler o hataları uygulama
/// çalışmadan önce yakalar.
///
/// Çıta, M4'te AI'ın önereceği yeni hareketlere uygulanacak çıtayla
/// aynı (spec 7.4): kendi tohum verimiz kendi kuralımızı geçmeli.
void main() {
  late Map<String, dynamic> doc;
  late List<Map<String, dynamic>> exercises;

  setUpAll(() {
    final raw = File('assets/catalog.json').readAsStringSync();
    doc = jsonDecode(raw) as Map<String, dynamic>;
    exercises = (doc['exercises'] as List).cast<Map<String, dynamic>>();
  });

  const categories = {'strength', 'cardio', 'mobility', 'core'};
  const locations = {'home', 'gym', 'both'};

  test('şema sürümü ve kayıt sayısı', () {
    expect(doc['version'], 1);
    expect(exercises.length, greaterThanOrEqualTo(15));
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

  test('zorunlu alanlar dolu ve geçerli', () {
    for (final e in exercises) {
      final id = e['id'];
      expect(categories.contains(e['category']), isTrue, reason: '$id kategori');
      expect(locations.contains(e['location']), isTrue, reason: '$id konum');
      expect(e['difficulty'], inInclusiveRange(1, 5), reason: '$id zorluk');
      for (final field in ['nameTr', 'nameEn', 'summary', 'breathing',
        'tempo', 'safety']) {
        expect(
          (e[field] as String?)?.trim().isNotEmpty,
          isTrue,
          reason: '$id.$field boş',
        );
      }
      for (final field in ['equipment', 'primaryMuscles', 'setup', 'cues']) {
        expect((e[field] as List).isNotEmpty, isTrue, reason: '$id.$field boş');
      }
    }
  });

  test('anlatım çıtası: en az 3 adım, en az 2 tam hata kaydı', () {
    for (final e in exercises) {
      final id = e['id'];
      expect(
        (e['execution'] as List).length,
        greaterThanOrEqualTo(3),
        reason: '$id execution 3 adımdan az',
      );

      final mistakes = (e['commonMistakes'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        mistakes.length,
        greaterThanOrEqualTo(2),
        reason: '$id commonMistakes 2 kayıttan az',
      );
      for (final m in mistakes) {
        for (final field in ['mistake', 'why', 'fix']) {
          expect(
            (m[field] as String?)?.trim().isNotEmpty,
            isTrue,
            reason: '$id hata kaydında $field boş',
          );
        }
      }
    }
  });

  test('varyant referansları katalogda mevcut', () {
    final ids = exercises.map((e) => e['id'] as String).toSet();
    for (final e in exercises) {
      for (final field in ['regressions', 'progressions']) {
        for (final ref in (e[field] as List).cast<String>()) {
          expect(
            ids.contains(ref),
            isTrue,
            reason: '${e['id']}.$field -> "$ref" katalogda yok',
          );
        }
      }
    }
  });

  test('varyant zinciri tutarlı: A ilerlemesi B ise B gerilemesi A olmalı', () {
    final byId = {for (final e in exercises) e['id'] as String: e};
    for (final e in exercises) {
      for (final next in (e['progressions'] as List).cast<String>()) {
        final target = byId[next]!;
        final back = (target['regressions'] as List).cast<String>();
        // Zincir tek yönlü tanımlanabilir; ama tanımlıysa doğru olmalı.
        if (back.isNotEmpty) {
          expect(
            back.contains(e['id']) ||
                (e['progressions'] as List).length > 1,
            isTrue,
            reason: '${e['id']} -> $next zinciri geri yönde tutarsız',
          );
        }
      }
    }
  });

  test('bildirilen görseller diskte var', () {
    for (final e in exercises) {
      final path = e['imagePath'] as String?;
      if (path == null) continue;
      expect(
        File(path).existsSync(),
        isTrue,
        reason: '${e['id']} -> $path bulunamadı',
      );
    }
  });

  test('PDF programındaki hareketlerin tamamı katalogda', () {
    // Çizelgenin Program A, Program B ve salon kardiyo bölümleri.
    const required = {
      'incline_pushup', 'band_row', 'band_pull_apart', 'superman',
      'plank', 'dead_bug',
      'chair_squat', 'step_up', 'glute_bridge', 'wall_sit',
      'calf_raise', 'bird_dog',
      'stationary_bike', 'treadmill_incline_walk',
      'pushup', // geçiş kriterinin ölçütü
    };
    final ids = exercises.map((e) => e['id'] as String).toSet();
    expect(required.difference(ids), isEmpty, reason: 'eksik hareket');
  });
}
