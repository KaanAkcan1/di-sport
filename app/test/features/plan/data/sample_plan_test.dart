import 'dart:convert';
import 'dart:io';

import 'package:disport/features/plan/data/sample_plan.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 31 Ağustos 2026 Pazartesi — PDF çizelgesinin başlangıcı.
  final monday = DateTime(2026, 8, 31);

  test('28 gün, ardışık tarihler', () {
    final plan = buildSamplePlan(monday);

    expect(plan.days, hasLength(28));
    for (var i = 0; i < 28; i++) {
      expect(plan.days[i].date, monday.add(Duration(days: i)));
    }
    expect(plan.endDate, DateTime(2026, 9, 27));
  });

  test('haftalık desen PDF ile aynı: Pzt/Çar/Cmt salon, kalanı ev', () {
    final plan = buildSamplePlan(monday);

    expect(plan.days.take(7).map((d) => d.type), [
      PlanDayType.gym, // Pazartesi
      PlanDayType.home, // Salı
      PlanDayType.gym, // Çarşamba
      PlanDayType.home, // Perşembe
      PlanDayType.home, // Cuma
      PlanDayType.gym, // Cumartesi
      PlanDayType.home, // Pazar
    ]);
  });

  test('desen başlangıç gününden bağımsız — perşembeden başlasa da tutar', () {
    // Plan hangi günden başlarsa başlasın salon günleri takvim gününe
    // göre belirlenmeli; indekse göre değil.
    final plan = buildSamplePlan(DateTime(2026, 9, 3)); // Perşembe

    expect(plan.days.first.type, PlanDayType.home); // Perşembe = ev
    expect(plan.days[2].type, PlanDayType.gym); // Cumartesi = salon
  });

  test('ev günleri Program A ve B arasında dönüşümlü', () {
    final plan = buildSamplePlan(monday);

    // Salı ve Cuma → Program A (üst vücut)
    for (final index in [1, 4]) {
      expect(
        plan.days[index].exercises.map((e) => e.exerciseId),
        containsAll(['incline_pushup', 'band_row', 'plank']),
        reason: '${index + 1}. gün Program A olmalı',
      );
    }

    // Perşembe ve Pazar → Program B (alt vücut)
    for (final index in [3, 6]) {
      expect(
        plan.days[index].exercises.map((e) => e.exerciseId),
        containsAll(['chair_squat', 'glute_bridge', 'wall_sit']),
        reason: '${index + 1}. gün Program B olmalı',
      );
    }
  });

  test('salon günleri kardiyo hareketleri taşır, direnç haftayla artar', () {
    final plan = buildSamplePlan(monday);

    final week1Monday = plan.days[0];
    expect(week1Monday.exercises.map((e) => e.exerciseId), [
      'stationary_bike',
      'treadmill_incline_walk',
    ]);
    expect(week1Monday.exercises.first.intensity, 'direnç 5');
    expect(week1Monday.exercises.last.intensity, 'eğim %5');

    // 3. hafta pazartesi (14. gün): interval ve %10 eğim
    final week3Monday = plan.days[14];
    expect(week3Monday.exercises.first.intensity, 'interval ×6');
    expect(week3Monday.exercises.last.intensity, 'eğim %10');
  });

  test('her günde öğün slotları ve tek bir antrenman slotu var', () {
    final plan = buildSamplePlan(monday);

    for (final day in plan.days) {
      expect(
        day.slots.where((s) => s.kind == SlotKind.meal),
        isNotEmpty,
        reason: '${day.date} öğünsüz',
      );
      expect(
        day.slots.where((s) => s.kind == SlotKind.workout),
        hasLength(1),
        reason: '${day.date} antrenman slotu sayısı yanlış',
      );
      expect(day.workoutSlot, isNotNull);
    }
  });

  test('slotlar saate göre sıralı', () {
    for (final day in buildSamplePlan(monday).days) {
      final times = day.slots.map((s) => s.time).toList();
      expect(times, orderedEquals(List.of(times)..sort()));
    }
  });

  test('antrenman saati gün tipine göre: salon 22:00, ev 05:45', () {
    final plan = buildSamplePlan(monday);

    expect(plan.days[0].workoutSlot!.time, '22:00'); // Pzt salon
    expect(plan.days[1].workoutSlot!.time, '05:45'); // Sal ev
    expect(plan.days[5].workoutSlot!.time, '10:00'); // Cmt uzun kardiyo
    expect(plan.days[6].workoutSlot!.time, '10:00'); // Paz rahat tempo
  });

  test('ölçüm günleri PDF ile aynı: başlangıç, orta, bitiş', () {
    final plan = buildSamplePlan(monday);

    final measurementDays = [
      for (final (index, day) in plan.days.indexed)
        if (day.slots.any((s) => s.kind == SlotKind.measurement)) index,
    ];
    expect(measurementDays, [0, 13, 27]);
  });

  test('tahlil hatırlatması plana gömülü', () {
    final plan = buildSamplePlan(monday);
    final labSlots = [
      for (final day in plan.days)
        ...day.slots.where((s) => s.kind == SlotKind.lab),
    ];
    expect(labSlots, hasLength(1));
    expect(labSlots.single.label, contains('D vitamini'));
  });

  test('kullanılan tüm hareket id\'leri katalogda var', () {
    // Örnek plan katalogdan kopuk olursa Antrenman ekranı boş hareket
    // kartları gösterir. Gerçek katalog dosyasıyla doğrulanıyor.
    final raw = File('assets/catalog.json').readAsStringSync();
    final catalogIds = {
      for (final e
          in (jsonDecode(raw) as Map<String, dynamic>)['exercises'] as List)
        (e as Map<String, dynamic>)['id'] as String,
    };

    final usedIds = {
      for (final day in buildSamplePlan(monday).days)
        ...day.exercises.map((e) => e.exerciseId),
    };

    expect(usedIds.difference(catalogIds), isEmpty);
  });

  test('hedefler ve kurallar PDF ile aynı', () {
    final plan = buildSamplePlan(monday);

    expect(plan.goals.dailyKcal, 2400);
    expect(plan.goals.proteinG, 170);
    expect(plan.goals.waterL, 3);
    expect(plan.goals.weeklyGym, 3);
    expect(plan.goals.weeklyHome, 4);
    expect(plan.goals.targetLossKg, 3.5);
    expect(plan.rules.forbidden, contains('Alkol'));
    expect(plan.rules.free.first, contains('3 litre'));
  });

  test('id\'ler benzersiz — insertFullPlan çakışma yaşamamalı', () {
    final plan = buildSamplePlan(monday);

    final dayIds = plan.days.map((d) => d.id).toList();
    expect(dayIds.toSet().length, dayIds.length);

    final slotIds = [for (final d in plan.days) ...d.slots.map((s) => s.id)];
    expect(slotIds.toSet().length, slotIds.length);

    final exerciseIds = [
      for (final d in plan.days) ...d.exercises.map((e) => e.id),
    ];
    expect(exerciseIds.toSet().length, exerciseIds.length);
  });
}
