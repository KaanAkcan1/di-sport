import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });
  tearDown(() => db.close());

  Future<void> logSet(
    String date,
    String exerciseId,
    int setIndex, {
    int? reps,
    int? durationSec,
  }) => repo.logSet(
    isoDate: date,
    exerciseId: exerciseId,
    setIndex: setIndex,
    reps: reps,
    durationSec: durationSec,
  );

  group('set kaydı', () {
    test('setler sayılır', () async {
      await logSet('2026-09-01', 'incline_pushup', 0, reps: 10);
      await logSet('2026-09-01', 'incline_pushup', 1, reps: 9);

      final counts = await repo.watchDoneSetCounts('2026-09-01').first;
      expect(counts['incline_pushup'], 2);
    });

    test('hareketler bağımsız sayılır', () async {
      await logSet('2026-09-01', 'incline_pushup', 0, reps: 10);
      await logSet('2026-09-01', 'plank', 0, durationSec: 30);

      final counts = await repo.watchDoneSetCounts('2026-09-01').first;
      expect(counts['incline_pushup'], 1);
      expect(counts['plank'], 1);
    });

    test('başka günün kaydı bugüne karışmaz', () async {
      await logSet('2026-08-31', 'incline_pushup', 0, reps: 10);
      final counts = await repo.watchDoneSetCounts('2026-09-01').first;
      expect(counts, isEmpty);
    });
  });

  group('geri alma', () {
    test('son seti siler', () async {
      await logSet('2026-09-01', 'incline_pushup', 0, reps: 10);
      await logSet('2026-09-01', 'incline_pushup', 1, reps: 9);

      await repo.undoLastSet('2026-09-01', 'incline_pushup');

      final counts = await repo.watchDoneSetCounts('2026-09-01').first;
      expect(counts['incline_pushup'], 1);
    });

    test('kayıt yokken hata vermez', () async {
      await repo.undoLastSet('2026-09-01', 'incline_pushup');
      expect(await repo.watchDoneSetCounts('2026-09-01').first, isEmpty);
    });

    test('yalnız o hareketin setini siler', () async {
      await logSet('2026-09-01', 'incline_pushup', 0, reps: 10);
      await logSet('2026-09-01', 'plank', 0, durationSec: 30);

      await repo.undoLastSet('2026-09-01', 'plank');

      final counts = await repo.watchDoneSetCounts('2026-09-01').first;
      expect(counts['incline_pushup'], 1);
      expect(counts.containsKey('plank'), isFalse);
    });
  });

  group('lastActuals', () {
    test('yalnız bir önceki seansı verir, daha eskiyi değil', () async {
      await logSet('2026-08-25', 'incline_pushup', 0, reps: 7);
      await logSet('2026-08-27', 'incline_pushup', 0, reps: 9);
      await logSet('2026-08-27', 'incline_pushup', 1, reps: 8);

      final actuals = await repo.lastActuals(
        'incline_pushup',
        beforeIso: '2026-09-01',
      );

      expect(actuals.map((a) => a.reps), [9, 8]);
    });

    test('bugünün kayıtlarını saymaz', () async {
      await logSet('2026-08-27', 'incline_pushup', 0, reps: 9);
      await logSet('2026-09-01', 'incline_pushup', 0, reps: 12);

      final actuals = await repo.lastActuals(
        'incline_pushup',
        beforeIso: '2026-09-01',
      );
      expect(actuals.single.reps, 9);
    });

    test('geçmiş yoksa boş liste', () async {
      expect(
        await repo.lastActuals('incline_pushup', beforeIso: '2026-09-01'),
        isEmpty,
      );
    });

    test('süreli hareketin etiketi saniye gösterir', () async {
      await logSet('2026-08-27', 'plank', 0, durationSec: 30);
      final actuals = await repo.lastActuals('plank', beforeIso: '2026-09-01');
      expect(actuals.single.shortLabel, '30 sn');
    });

    test('tekrarlı hareketin etiketi sayı gösterir', () async {
      await logSet('2026-08-27', 'incline_pushup', 0, reps: 10);
      final actuals = await repo.lastActuals(
        'incline_pushup',
        beforeIso: '2026-09-01',
      );
      expect(actuals.single.shortLabel, '10');
    });
  });

  group('logsBetween', () {
    test('aralıktaki kayıtları tarih ve set sırasına göre verir', () async {
      await logSet('2026-09-02', 'plank', 0, durationSec: 30);
      await logSet('2026-09-01', 'incline_pushup', 1, reps: 9);
      await logSet('2026-09-01', 'incline_pushup', 0, reps: 10);

      final logs = await repo.logsBetween('2026-09-01', '2026-09-02');

      expect(logs, hasLength(3));
      expect(logs.first.date, '2026-09-01');
      expect(logs.first.actual.setIndex, 0);
      expect(logs.last.exerciseId, 'plank');
    });

    test('aralık dışını içermez', () async {
      await logSet('2026-08-30', 'plank', 0, durationSec: 30);
      expect(await repo.logsBetween('2026-09-01', '2026-09-05'), isEmpty);
    });
  });

  group('Planlanan/Yapılan (v3 §6.2)', () {
    test('geçmiş güne set yazılır, düzeltilir ve silinir', () async {
      await logSet('2026-08-15', 'pushup', 0, reps: 10);
      await logSet('2026-08-15', 'pushup', 1, reps: 8);

      var logs = await repo.watchDayLogs('2026-08-15').first;
      expect(logs, hasLength(2));

      await repo.updateSet(logs.first.id, reps: 12, weightKg: 20);
      logs = await repo.watchDayLogs('2026-08-15').first;
      expect(logs.first.reps, 12);
      expect(logs.first.weightKg, 20);
      // Verilmeyen alanlara dokunulmaz.
      expect(logs.last.reps, 8);

      await repo.deleteSet(logs.last.id);
      expect(await repo.watchDayLogs('2026-08-15').first, hasLength(1));
    });

    test('geçmiş güne elle seans girilir ve düzeltilir', () async {
      await repo.setSessionTimes(
        isoDate: '2026-08-15',
        start: DateTime(2026, 8, 15, 18),
        end: DateTime(2026, 8, 15, 18, 45),
      );

      var sessions = await repo.watchSessions('2026-08-15').first;
      expect(sessions.single.duration, const Duration(minutes: 45));

      await repo.setSessionTimes(
        isoDate: '2026-08-15',
        sessionId: sessions.single.id,
        start: DateTime(2026, 8, 15, 18),
        end: DateTime(2026, 8, 15, 19),
      );
      sessions = await repo.watchSessions('2026-08-15').first;
      expect(sessions.single.duration, const Duration(hours: 1));
      // Güncelleme yeni satır açmaz.
      expect(sessions, hasLength(1));
    });

    test('elle girilen seans kapalıdır — süre hesabına girer', () async {
      await repo.setSessionTimes(
        isoDate: '2026-08-15',
        start: DateTime(2026, 8, 15, 18),
        end: DateTime(2026, 8, 15, 18, 30),
      );
      final durations = await repo.watchSessionDurations('2026-08-15').first;
      expect(durations.single, const Duration(minutes: 30));
    });
  });
}
