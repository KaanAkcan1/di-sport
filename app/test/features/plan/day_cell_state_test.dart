import 'package:disport/features/plan/domain/day_cell_state.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter_test/flutter_test.dart';

FullPlanDay dayWith({
  required DateTime date,
  int slots = 3,
  int exercises = 0,
}) => FullPlanDay(
  id: 'd',
  date: date,
  type: exercises > 0 ? PlanDayType.home : PlanDayType.rest,
  weekIndex: 1,
  slots: [
    for (var i = 0; i < slots; i++)
      PlanSlot(
        id: 's$i',
        time: '0$i:00',
        kind: SlotKind.meal,
        label: 'Öğün $i',
      ),
  ],
  exercises: [
    for (var i = 0; i < exercises; i++)
      PlanExercise(id: 'e$i', exerciseId: 'pushup', sets: 3, reps: 10),
  ],
);

void main() {
  final today = DateTime(2026, 9, 1);

  test('gelecek gün future', () {
    expect(
      resolveDayFill(
        day: dayWith(date: DateTime(2026, 9, 5)),
        checkedCount: 0,
        today: today,
      ),
      DayCellFill.future,
    );
  });

  test('slotu olmayan gün serbest', () {
    expect(
      resolveDayFill(
        day: dayWith(date: DateTime(2026, 8, 30), slots: 0),
        checkedCount: 0,
        today: today,
      ),
      DayCellFill.free,
    );
  });

  test('hepsi işaretliyse done', () {
    expect(
      resolveDayFill(
        day: dayWith(date: DateTime(2026, 8, 30)),
        checkedCount: 3,
        today: today,
      ),
      DayCellFill.done,
    );
  });

  test('bir kısmı işaretliyse partial', () {
    expect(
      resolveDayFill(
        day: dayWith(date: DateTime(2026, 8, 30)),
        checkedCount: 1,
        today: today,
      ),
      DayCellFill.partial,
    );
  });

  test('geçmiş ve boş gün empty', () {
    expect(
      resolveDayFill(
        day: dayWith(date: DateTime(2026, 8, 30)),
        checkedCount: 0,
        today: today,
      ),
      DayCellFill.empty,
    );
  });

  test('BUGÜN boşken empty DEĞİL — gün henüz bitmedi', () {
    // Sabah 09:00'da kırmızı bir hücre yanlış sinyal verirdi: kullanıcı
    // henüz bir şey kaçırmadı, günü yaşamaya başladı.
    expect(
      resolveDayFill(
        day: dayWith(date: today),
        checkedCount: 0,
        today: today,
      ),
      DayCellFill.partial,
    );
  });

  test('saat bileşeni sonucu değiştirmez', () {
    // `today` bir `DateTime.now()` olabilir; gün karşılaştırması
    // saatten bağımsız olmalı.
    expect(
      resolveDayFill(
        day: dayWith(date: DateTime(2026, 9, 1)),
        checkedCount: 3,
        today: DateTime(2026, 9, 1, 23, 47),
      ),
      DayCellFill.done,
    );
  });
}
