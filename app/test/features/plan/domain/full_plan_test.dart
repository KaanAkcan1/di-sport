import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../plan_fixtures.dart';

void main() {
  group('PlanExercise.targetLabel', () {
    PlanExercise exercise({int? sets, int? reps, int? durationSec}) =>
        PlanExercise(
          id: 'e',
          exerciseId: 'x',
          sets: sets,
          reps: reps,
          durationSec: durationSec,
        );

    test('tekrarlı hareket: set × tekrar', () {
      expect(exercise(sets: 3, reps: 10).targetLabel, '3 × 10');
    });

    test('kısa süreli hareket saniyeyle: plank, duvar oturuşu', () {
      expect(exercise(sets: 3, durationSec: 30).targetLabel, '3 × 30 sn');
      expect(exercise(sets: 2, durationSec: 45).targetLabel, '2 × 45 sn');
    });

    test('uzun süre dakikaya çevrilir — 1500 sn okunabilir değil', () {
      expect(exercise(sets: 1, durationSec: 1500).targetLabel, '25 dk');
      expect(exercise(sets: 1, durationSec: 900).targetLabel, '15 dk');
    });

    test('tek setli hareketten "1 ×" öneki düşer', () {
      expect(exercise(sets: 1, durationSec: 1500).targetLabel, '25 dk');
      expect(exercise(sets: 1, durationSec: 60).targetLabel, '60 sn');
    });

    test('iki dakika eşiğinin iki yanı', () {
      expect(exercise(sets: 1, durationSec: 119).targetLabel, '119 sn');
      expect(exercise(sets: 1, durationSec: 120).targetLabel, '2 dk');
    });

    test('süre ve tekrar yoksa set sayısı', () {
      expect(exercise(sets: 4).targetLabel, '4 set');
    });
  });

  group('FullPlan', () {
    test('gün sayısı ve bitiş tarihi hafta sayısından türer', () {
      final plan = fixturePlan(weeks: 4, start: DateTime(2026, 8, 31));
      expect(plan.dayCount, 28);
      expect(plan.endDate, DateTime(2026, 9, 27));
    });

    test('dayAt tarihe göre günü bulur', () {
      final plan = fixturePlan(weeks: 1, start: DateTime(2026, 8, 31));
      expect(plan.dayAt(DateTime(2026, 9, 2))!.date, DateTime(2026, 9, 2));
      expect(plan.dayAt(DateTime(2026, 10, 2)), isNull);
    });
  });

  group('FullPlanDay', () {
    test('workoutSlot antrenman slotunu bulur', () {
      final day = fixturePlan().days.first;
      expect(day.workoutSlot, isNotNull);
      expect(day.workoutSlot!.kind, SlotKind.workout);
    });

    test('dinlenme günü antrenman saymaz', () {
      final day = FullPlanDay(
        id: 'd',
        date: DateTime(2026, 9, 1),
        type: PlanDayType.rest,
        weekIndex: 1,
      );
      expect(day.hasWorkout, isFalse);
    });
  });
}
