import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/plan_adherence.dart';
import 'package:flutter_test/flutter_test.dart';

FullPlanDay day(DateTime date, {PlanDayType type = PlanDayType.home}) =>
    FullPlanDay(
      id: 'd-${date.day}',
      date: date,
      type: type,
      weekIndex: 1,
      exercises: type == PlanDayType.rest
          ? const []
          : const [
              PlanExercise(id: 'e', exerciseId: 'pushup', sets: 3, reps: 10),
            ],
    );

void main() {
  final today = DateTime(2026, 9, 4);

  test('geçen antrenman günleri sayılır, dinlenme sayılmaz', () {
    final result = workoutAdherence(
      days: [
        day(DateTime(2026, 9, 1)),
        day(DateTime(2026, 9, 2), type: PlanDayType.rest),
        day(DateTime(2026, 9, 3)),
        day(DateTime(2026, 9, 5)), // gelecek
      ],
      workoutDoneDates: {'2026-09-01'},
      today: today,
    );
    expect(result.planned, 2);
    expect(result.done, 1);
  });

  test('bugün yalnız yapılmışsa paydaya girer', () {
    // Sabah 09:00'da "bugün daha yapmadın" diye oranı düşürmek
    // haksızlık; akşam yapılan antrenman oranı hemen yükseltmeli.
    final notDone = workoutAdherence(
      days: [day(today)],
      workoutDoneDates: const {},
      today: today,
    );
    expect(notDone.planned, 0);

    final done = workoutAdherence(
      days: [day(today)],
      workoutDoneDates: {'2026-09-04'},
      today: today,
    );
    expect(done.planned, 1);
    expect(done.done, 1);
  });

  test('hiç geçen antrenman günü yoksa payda sıfır', () {
    final result = workoutAdherence(
      days: [day(DateTime(2026, 9, 10))],
      workoutDoneDates: const {},
      today: today,
    );
    expect(result.planned, 0);
    expect(result.done, 0);
  });
}
