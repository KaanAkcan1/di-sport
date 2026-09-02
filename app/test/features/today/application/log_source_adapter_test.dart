import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/today/application/log_source_adapter.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LogSourceAdapter adapter;
  late TodayRepository today;
  late WorkoutRepository workout;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    today = TodayRepository(db);
    workout = WorkoutRepository(db);
    adapter = LogSourceAdapter(
      today: today,
      plan: PlanRepository(db),
      workout: workout,
      now: () => DateTime(2026, 9, 2),
    );
  });
  tearDown(() => db.close());

  group('reality (v3.1 §8)', () {
    test('dolu gün alanlarıyla döner, boş gün elenir', () async {
      await today.setSleepTimes(
        '2026-09-01',
        bedTime: '23:45',
        wakeTimeActual: '06:11',
        napMinutes: 30,
      );
      await today.setWellbeing(
        '2026-09-01',
        moodScore: 2,
        symptoms: 'baş ağrısı',
        stressedDay: true,
      );
      await today.setMealSkipped(
        '2026-09-01',
        mealKindName: 'ogle',
        reason: 'mesai',
      );
      // Yalnız not girilen gün gerçeklik dökümünde boş sayılır — not
      // zaten §8'de.
      await today.setNote('2026-08-30', 'sadece not');

      final reality = await adapter.reality(lastDays: 14);
      final day = reality.singleWhere((d) => d.date == '2026-09-01');
      expect(day.bedTime, '23:45');
      expect(day.wakeTime, '06:11');
      expect(day.napMinutes, 30);
      expect(day.moodScore, 2);
      expect(day.symptoms, 'baş ağrısı');
      expect(day.stressedDay, isTrue);
      expect(day.skippedMeals, {'ogle': 'mesai'});
      expect(reality.any((d) => d.date == '2026-08-30'), isFalse);
    });
  });

  group('sessions (v3.1 §8)', () {
    test('kapalı seans süre + değerlendirmeyle döner', () async {
      final id = await workout.setSessionTimes(
        isoDate: '2026-09-01',
        start: DateTime(2026, 9, 1, 18),
        end: DateTime(2026, 9, 1, 18, 52),
      );
      await workout.setSessionDebrief(
        sessionId: id,
        rpe: 8,
        painNote: 'omuz',
      );

      final sessions = await adapter.sessions(lastDays: 14);
      expect(sessions.single.minutes, 52);
      expect(sessions.single.rpe, 8);
      expect(sessions.single.painNote, 'omuz');
    });

    test('açık seans dökümde yok — süresi bilinmiyor', () async {
      await workout.startSession('2026-09-01');
      expect(await adapter.sessions(lastDays: 14), isEmpty);
    });
  });
}
