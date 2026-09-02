import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/today/domain/day_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PlanSlot slot(String id, String time, SlotKind kind, [String? label]) =>
      PlanSlot(id: id, time: time, kind: kind, label: label ?? id);

  SupplementDose dose(String name, String time, {bool taken = false}) =>
      SupplementDose(
        supplement: Supplement(
          id: name,
          name: name,
          dose: '1000',
          unit: 'mg',
          times: [time],
          weekdays: const {},
          note: '',
        ),
        time: time,
        takenAt: taken ? DateTime(2026, 9, 1, 8, 31) : null,
      );

  group('buildDayFlow', () {
    test('slotlar, dozlar ve tartı saate göre tek çizgide', () {
      final rows = buildDayFlow(
        slots: [
          slot('m1', '08:00', SlotKind.meal, 'Kahvaltı'),
          slot('w1', '18:30', SlotKind.workout, 'Salon'),
        ],
        doses: [dose('D vitamini', '08:30')],
        checkedSlotIds: const {},
        workoutDone: false,
        weighInTime: '06:30',
      );

      expect(rows.map((r) => r.time), ['06:30', '08:00', '08:30', '18:30']);
      expect(rows.map((r) => r.kind), [
        DayFlowKind.weighIn,
        DayFlowKind.meal,
        DayFlowKind.dose,
        DayFlowKind.workout,
      ]);
    });

    test('tartı satırı kilo girilince yapılmış sayılır', () {
      final without = buildDayFlow(
        slots: const [],
        doses: const [],
        checkedSlotIds: const {},
        workoutDone: false,
      );
      final withWeight = buildDayFlow(
        slots: const [],
        doses: const [],
        checkedSlotIds: const {},
        workoutDone: false,
        weightLabel: '108,9',
      );

      expect(without.single.done, isFalse);
      expect(withWeight.single.done, isTrue);
      expect(withWeight.single.detail, '108,9');
    });

    test('antrenman satırı slot işaretinden değil kutudan okur', () {
      // v1'den beri antrenmanın "yapıldı"sı slot işareti değil ayrı
      // kutu — seans akışı onu dolduruyor.
      final rows = buildDayFlow(
        slots: [slot('w1', '18:30', SlotKind.workout)],
        doses: const [],
        checkedSlotIds: const {'w1'},
        workoutDone: false,
      );

      final workout = rows.firstWhere((r) => r.kind == DayFlowKind.workout);
      expect(workout.done, isFalse);
    });

    test('doz satırı doz + birim detayı taşır', () {
      final rows = buildDayFlow(
        slots: const [],
        doses: [dose('Metformin', '20:30')],
        checkedSlotIds: const {},
        workoutDone: false,
      );

      final row = rows.firstWhere((r) => r.kind == DayFlowKind.dose);
      expect(row.detail, '1000 mg');
      expect(row.doseTime, '20:30');
    });
  });

  group('nextFlowRow', () {
    test('saati gelmemiş ilk yapılmamış iş', () {
      final rows = buildDayFlow(
        slots: [
          slot('m1', '08:00', SlotKind.meal),
          slot('m2', '13:00', SlotKind.meal),
          slot('m3', '19:00', SlotKind.meal),
        ],
        doses: const [],
        checkedSlotIds: const {'m2'},
        workoutDone: false,
        weightLabel: '108,9',
      );

      // Saat 10:00: 08:00 kaçtı (sırada değil), 13:00 işaretli,
      // sıradaki 19:00.
      expect(nextFlowRow(rows, '10:00')?.slotId, 'm3');
    });

    test('saati geçmiş yapılmamış iş sırada sayılmaz', () {
      // Kaçmış işi vurgulamak kullanıcıyı geriye çağırır; günün sorusu
      // hep "şimdi ne var".
      final rows = buildDayFlow(
        slots: [slot('m1', '08:00', SlotKind.meal)],
        doses: const [],
        checkedSlotIds: const {},
        workoutDone: false,
        weightLabel: '108,9',
      );

      expect(nextFlowRow(rows, '09:00'), isNull);
    });

    test('her şey yapılmışsa sırada bir şey yok', () {
      final rows = buildDayFlow(
        slots: [slot('m1', '23:00', SlotKind.meal)],
        doses: const [],
        checkedSlotIds: const {'m1'},
        workoutDone: false,
        weightLabel: '108,9',
      );

      expect(nextFlowRow(rows, '10:00'), isNull);
    });
  });

  group('öğün satırı — yapıldı demek kayıt demek (T19.0)', () {
    PlanSlot mealSlot(String id, String time, MealKind kind) => PlanSlot(
      id: id,
      time: time,
      kind: SlotKind.meal,
      label: id,
      mealKind: kind,
    );

    test('kayıtlı öğün done + kcal detayı taşır, işaret önemsiz', () {
      final rows = buildDayFlow(
        slots: [mealSlot('kahvalti', '08:00', MealKind.kahvalti)],
        doses: const [],
        // İşaretli DEĞİL — yapılmışlık kayıttan gelmeli.
        checkedSlotIds: const {},
        workoutDone: false,
        mealKcalByKind: const {MealKind.kahvalti: 486.4},
      );

      final meal = rows.singleWhere((r) => r.kind == DayFlowKind.meal);
      expect(meal.done, isTrue);
      expect(meal.detail, '486 kcal');
      expect(meal.mealKind, MealKind.kahvalti);
    });

    test('kayıtsız öğün done değil — işaretli olsa bile', () {
      final rows = buildDayFlow(
        slots: [mealSlot('kahvalti', '08:00', MealKind.kahvalti)],
        doses: const [],
        checkedSlotIds: const {'kahvalti'},
        workoutDone: false,
      );

      expect(rows.singleWhere((r) => r.kind == DayFlowKind.meal).done, isFalse);
    });

    test('mealKind olmayan eski öğün slotu kutucuk davranışında kalır', () {
      final rows = buildDayFlow(
        slots: [slot('m1', '08:00', SlotKind.meal)],
        doses: const [],
        checkedSlotIds: const {'m1'},
        workoutDone: false,
      );

      final meal = rows.singleWhere((r) => r.kind == DayFlowKind.meal);
      expect(meal.done, isTrue);
      expect(meal.mealKind, isNull);
    });
  });

  test('antrenman satırı hareket sayısı detayını taşır', () {
    final rows = buildDayFlow(
      slots: [slot('w', '18:30', SlotKind.workout)],
      doses: const [],
      checkedSlotIds: const {},
      workoutDone: false,
      workoutDetail: '6 hareket',
    );

    expect(
      rows.singleWhere((r) => r.kind == DayFlowKind.workout).detail,
      '6 hareket',
    );
  });

  test('flowProgress yapılmış/toplam sayar', () {
    final rows = buildDayFlow(
      slots: [
        slot('m1', '08:00', SlotKind.meal),
        slot('m2', '13:00', SlotKind.meal),
      ],
      doses: [dose('D', '08:30', taken: true)],
      checkedSlotIds: const {'m1'},
      workoutDone: false,
      weightLabel: '108,9',
    );

    expect(flowProgress(rows), (3, 4));
  });
}
