import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/workout/application/recent_exercise_adapter.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('özetleme', () {
    test('setler aynıysa "3×12" biçiminde toplanır', () {
      expect(
        RecentExerciseAdapter.summarise(const [
          SetActual(setIndex: 0, reps: 12),
          SetActual(setIndex: 1, reps: 12),
          SetActual(setIndex: 2, reps: 12),
        ]),
        '3×12',
      );
    });

    test('setler farklıysa tek tek yazılır', () {
      expect(
        RecentExerciseAdapter.summarise(const [
          SetActual(setIndex: 0, reps: 12),
          SetActual(setIndex: 1, reps: 10),
          SetActual(setIndex: 2, reps: 8),
        ]),
        '12/10/8',
      );
    });

    test('ağırlık tek değerse eklenir, Türkçe ondalıkla', () {
      expect(
        RecentExerciseAdapter.summarise(const [
          SetActual(setIndex: 0, reps: 12, weightKg: 12.5),
          SetActual(setIndex: 1, reps: 12, weightKg: 12.5),
        ]),
        '2×12 · 12,5 kg',
      );
    });

    test('ağırlıklar farklıysa hiç yazılmaz', () {
      // "12,5/15/15 kg" bir satıra sığmıyor; ortalama almak da yanlış
      // bilgi üretirdi.
      expect(
        RecentExerciseAdapter.summarise(const [
          SetActual(setIndex: 0, reps: 12, weightKg: 12.5),
          SetActual(setIndex: 1, reps: 12, weightKg: 15),
        ]),
        '2×12',
      );
    });

    test('süreli hareket saniyeyle yazılır', () {
      expect(
        RecentExerciseAdapter.summarise(const [
          SetActual(setIndex: 0, durationSec: 45),
          SetActual(setIndex: 1, durationSec: 45),
        ]),
        '2×45 sn',
      );
    });

    test('boş liste tire', () {
      expect(RecentExerciseAdapter.summarise(const []), '—');
    });
  });

  group('son seanslar', () {
    late AppDatabase db;
    late RecentExerciseAdapter adapter;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      adapter = RecentExerciseAdapter(WorkoutRepository(db));
    });

    tearDown(() => db.close());

    Future<void> log(String date, String exerciseId, int reps) =>
        WorkoutRepository(db).logSet(
          isoDate: date,
          exerciseId: exerciseId,
          setIndex: 0,
          reps: reps,
        );

    test('kayıt yokken boş liste', () async {
      expect(await adapter.watchRecent().first, isEmpty);
    });

    test('aynı hareket iki kez listelenmez — yalnız son seans', () async {
      await log('2026-08-20', 'pushup', 8);
      await log('2026-08-28', 'pushup', 12);

      final recent = await adapter.watchRecent().first;
      expect(recent, hasLength(1));
      expect(recent.single.date, '2026-08-28');
      expect(recent.single.summary, '1×12', reason: 'eski seans sızmamalı');
    });

    test('en son çalışılan başta', () async {
      await log('2026-08-20', 'pushup', 10);
      await log('2026-08-28', 'squat', 10);

      final recent = await adapter.watchRecent().first;
      expect(recent.map((e) => e.exerciseId), ['squat', 'pushup']);
    });

    test('limit uygulanır', () async {
      for (var i = 1; i <= 4; i++) {
        await log('2026-08-2$i', 'ex$i', 10);
      }

      expect(await adapter.watchRecent(limit: 2).first, hasLength(2));
    });
  });
}
