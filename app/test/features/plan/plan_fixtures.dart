import 'package:disport/features/plan/domain/full_plan.dart';

/// Testlerde kullanılan plan üreteci.
///
/// Varsayılan: 31 Ağustos 2026 Pazartesi'den başlayan bir hafta;
/// tek günler ev, çift günler salon.
FullPlan fixturePlan({
  String id = 'pl1',
  String title = 'Test Planı',
  DateTime? start,
  int weeks = 1,
}) {
  final startDate = start ?? DateTime(2026, 8, 31);

  return FullPlan(
    id: id,
    title: title,
    startDate: startDate,
    weeks: weeks,
    goals: const PlanGoals(
      dailyKcal: 2400,
      proteinG: 170,
      waterL: 3,
      weeklyGym: 3,
      weeklyHome: 4,
      targetLossKg: 1,
    ),
    rules: const PlanRules(forbidden: ['alkol'], free: ['su']),
    sourceRaw: '{}',
    days: [
      for (var i = 0; i < weeks * 7; i++)
        FullPlanDay(
          id: '$id-d$i',
          date: startDate.add(Duration(days: i)),
          type: i.isEven ? PlanDayType.gym : PlanDayType.home,
          weekIndex: i ~/ 7 + 1,
          headline: 'Hafta ${i ~/ 7 + 1} notu',
          dinnerSuggestion: 'Izgara tavuk + salata',
          slots: [
            PlanSlot(
              id: '$id-d$i-s0',
              time: '06:30',
              kind: SlotKind.meal,
              label: '4 haşlanmış yumurta',
            ),
            PlanSlot(
              id: '$id-d$i-s1',
              time: '12:00',
              kind: SlotKind.meal,
              label: 'Fabrika menüsü',
            ),
            PlanSlot(
              id: '$id-d$i-s2',
              time: '22:00',
              kind: SlotKind.workout,
              label: i.isEven ? 'Salon — kardiyo' : 'Ev antrenmanı',
            ),
          ],
          exercises: [
            PlanExercise(
              id: '$id-d$i-e0',
              exerciseId: 'incline_pushup',
              sets: 3,
              reps: 10,
              restSec: 60,
            ),
            PlanExercise(
              id: '$id-d$i-e1',
              exerciseId: 'plank',
              sets: 3,
              durationSec: 30,
              restSec: 60,
            ),
          ],
        ),
    ],
  );
}
