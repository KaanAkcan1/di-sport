import 'package:disport/features/plan/domain/day_cell_state.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter_test/flutter_test.dart';

FullPlanDay dayWith({
  required DateTime date,
  PlanDayType type = PlanDayType.home,
  int exercises = 1,
}) => FullPlanDay(
  id: 'd',
  date: date,
  type: type,
  weekIndex: 1,
  slots: [
    if (exercises > 0)
      const PlanSlot(
        id: 's-workout',
        time: '22:00',
        kind: SlotKind.workout,
        label: 'Antrenman',
      ),
  ],
  exercises: [
    for (var i = 0; i < exercises; i++)
      PlanExercise(id: 'e$i', exerciseId: 'pushup', sets: 3, reps: 10),
  ],
);

/// v3 §6.1: hücre yalnız antrenman bilgisi taşıyor.
void main() {
  final today = DateTime(2026, 9, 1);

  test('gelecek gün future', () {
    expect(
      resolveWorkoutFill(
        day: dayWith(date: DateTime(2026, 9, 5)),
        workoutDone: false,
        today: today,
      ),
      DayCellFill.future,
    );
  });

  test('dinlenme günü serbest — kaçırılacak antrenman yok', () {
    expect(
      resolveWorkoutFill(
        day: dayWith(
          date: DateTime(2026, 8, 30),
          type: PlanDayType.rest,
          exercises: 0,
        ),
        workoutDone: false,
        today: today,
      ),
      DayCellFill.free,
    );
  });

  test('antrenman yapıldıysa done', () {
    expect(
      resolveWorkoutFill(
        day: dayWith(date: DateTime(2026, 8, 30)),
        workoutDone: true,
        today: today,
      ),
      DayCellFill.done,
    );
  });

  test('geçmiş ve yapılmamış gün empty', () {
    expect(
      resolveWorkoutFill(
        day: dayWith(date: DateTime(2026, 8, 30)),
        workoutDone: false,
        today: today,
      ),
      DayCellFill.empty,
    );
  });

  test('BUGÜN yapılmamışken empty DEĞİL — gün henüz bitmedi', () {
    // Sabah 09:00'da kırmızı bir hücre yanlış sinyal verirdi: kullanıcı
    // henüz bir şey kaçırmadı, günü yaşamaya başladı.
    expect(
      resolveWorkoutFill(
        day: dayWith(date: today),
        workoutDone: false,
        today: today,
      ),
      DayCellFill.partial,
    );
  });

  test('saat bileşeni sonucu değiştirmez', () {
    // `today` bir `DateTime.now()` olabilir; gün karşılaştırması
    // saatten bağımsız olmalı.
    expect(
      resolveWorkoutFill(
        day: dayWith(date: DateTime(2026, 9, 1)),
        workoutDone: true,
        today: DateTime(2026, 9, 1, 23, 47),
      ),
      DayCellFill.done,
    );
  });
}
