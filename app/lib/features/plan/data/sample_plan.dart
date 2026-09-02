import 'package:disport/features/plan/domain/full_plan.dart';

/// Kaynak çizelgenin (`kaan-eylul-2026-cizelge.pdf`) dört haftalık
/// dijital karşılığı.
///
/// M4'te AI köprüsü gelene kadar uygulamayı gerçekçi veriyle dolduran
/// plan budur. Kod olarak üretilmesi bilinçli: 28 günün 28'ini elle JSON
/// yazmak yerine haftalık desen bir kez tanımlanıyor, tarihler ve gün
/// tipleri ondan türüyor. Böylece plan hangi pazartesiden başlarsa
/// başlasın desen bozulmuyor.
///
/// PDF'in kuralları:
///   Pzt · Çar → salon, 22:00 kardiyo
///   Cmt       → salon, 10:00 uzun kardiyo
///   Sal · Cum → ev, 05:45 Program A (üst vücut)
///   Per · Paz → ev, Program B (alt vücut); pazar 10:00, rahat tempo
FullPlan buildSamplePlan(DateTime start) {
  return FullPlan(
    id: 'sample-${PlanRepositoryDateKey.of(start)}',
    title: '4 Haftalık Çizelge',
    startDate: start,
    weeks: 4,
    goals: const PlanGoals(
      dailyKcal: 2400,
      proteinG: 170,
      waterL: 3,
      weeklyGym: 3,
      weeklyHome: 4,
      targetLossKg: 3.5,
    ),
    rules: const PlanRules(
      forbidden: [
        'Alkol',
        'Kola, gazoz, meyve suyu, şekerli çay',
        'Bal, reçel, pekmez, tatlı, dondurma',
        'Sıkma, poğaça, börek, simit, pide',
        'Kızartma — patates, tavuk, kroket',
        'Salam, sucuk, sosis, jambon',
        'Cips, kraker, hazır atıştırmalık',
        'Fabrikada tatlı ve ikinci porsiyon pilav',
      ],
      free: [
        'Su — günde 3 litre',
        'Sade çay, sade kahve, şekersiz ayran',
        'Marul, roka, semizotu, tere, maydanoz',
        'Salatalık, domates, biber, kabak, brokoli',
        'Çorba — kremasız, unlu değil',
        'Yumurta ve sade yoğurt',
        'Turşu — ölçülü, tuz yüzünden',
        'Günde 2 porsiyon katı meyve',
      ],
    ),
    sourceRaw: '',
    days: [for (var i = 0; i < 28; i++) _buildDay(start, i)],
  );
}

FullPlanDay _buildDay(DateTime start, int dayIndex) {
  final date = start.add(Duration(days: dayIndex));
  final weekday = date.weekday;
  final weekIndex = dayIndex ~/ 7 + 1;
  final dayId = 'sample-d$dayIndex';

  final isGym =
      weekday == DateTime.monday ||
      weekday == DateTime.wednesday ||
      weekday == DateTime.saturday;
  final isSaturday = weekday == DateTime.saturday;
  final isSunday = weekday == DateTime.sunday;

  return FullPlanDay(
    id: dayId,
    date: date,
    type: isGym ? PlanDayType.gym : PlanDayType.home,
    weekIndex: weekIndex,
    headline: _weekHeadline(weekIndex),
    dinnerSuggestion: _dinner(weekday),
    slots: _slots(
      dayId: dayId,
      isGym: isGym,
      isSaturday: isSaturday,
      isSunday: isSunday,
      weekIndex: weekIndex,
      dayIndex: dayIndex,
    ),
    exercises: _exercises(
      dayId: dayId,
      weekday: weekday,
      isGym: isGym,
      isSaturday: isSaturday,
      weekIndex: weekIndex,
    ),
  );
}

String _weekHeadline(int weekIndex) => switch (weekIndex) {
  1 => 'Tempoyu bul. Ağırlık ve hız peşinde koşma, saatleri oturt.',
  2 => 'Bant eğimi %8, bisiklet direnci 6. Kahvaltı artık otomatik olmalı.',
  3 => 'Bisiklette interval başlıyor. Cumartesi ilk koşu denemesi.',
  _ => 'Ayın kapanışı. Göbek çevreni ölç.',
};

String _dinner(int weekday) => switch (weekday) {
  DateTime.monday => 'Izgara tavuk 200 g + fırın sebze + 3 kaşık bulgur',
  DateTime.tuesday => 'Mercimek çorbası + 3 yumurtalı omlet + salata',
  DateTime.wednesday => 'Izgara hamsi veya uskumru 200 g + roka salata',
  DateTime.thursday => 'Ton balıklı büyük salata + 2 haşlanmış yumurta',
  DateTime.friday => 'Fırında köfte 200 g + cacık + bol salata',
  DateTime.saturday => 'Somon veya uskumru + 1 fırın patates + salata',
  _ => 'Kuru fasulye 1 kepçe + 3 kaşık bulgur + cacık',
};

List<PlanSlot> _slots({
  required String dayId,
  required bool isGym,
  required bool isSaturday,
  required bool isSunday,
  required int weekIndex,
  required int dayIndex,
}) {
  final slots = <PlanSlot>[];
  var counter = 0;

  void add(String time, SlotKind kind, String label, {String? note}) {
    slots.add(
      PlanSlot(
        id: '$dayId-s${counter++}',
        time: time,
        kind: kind,
        label: label,
        note: note,
      ),
    );
  }

  // Antrenman saati gün tipine göre değişiyor (PDF "günün saatleri").
  if (!isGym) {
    add(
      isSunday ? '10:00' : '05:45',
      SlotKind.workout,
      isSunday ? 'Ev antrenmanı — rahat tempo' : 'Ev antrenmanı 25 dk',
    );
  }

  add('06:30', SlotKind.meal, '4 haşlanmış yumurta + yoğurt');
  add('10:00', SlotKind.meal, '20 badem veya 1 elma + ayran');
  add('12:00', SlotKind.meal, 'Fabrika menüsü — pilav yarım');
  add(
    '16:00',
    SlotKind.meal,
    isGym ? 'Protein shake veya 200 g yoğurt' : '200 g yoğurt veya 1 avuç ceviz',
  );
  add('19:50', SlotKind.meal, 'Akşam yemeği, ailece');

  if (isGym) {
    add(
      isSaturday ? '10:00' : '22:00',
      SlotKind.workout,
      isSaturday ? 'Salon — uzun kardiyo 60-70 dk' : 'Salon — kardiyo 45 dk',
    );
    if (!isSaturday) add('23:15', SlotKind.meal, '1 kase yoğurt');
  }

  add(isGym && !isSaturday ? '23:45' : '22:15', SlotKind.sleep, 'Uyku');

  // Ay sonu ölçümleri ve tahlil hatırlatması plana gömülü (spec 5.2):
  // ayrı bir hatırlatma mekanizması gerekmiyor.
  if (dayIndex == 0 || dayIndex == 13 || dayIndex == 27) {
    add(
      '07:00',
      SlotKind.measurement,
      'Ölçüm günü: kilo, göbek ve bel çevresi, şınav, plank',
    );
  }
  if (weekIndex == 2 && dayIndex % 7 == 0) {
    add(
      '09:00',
      SlotKind.lab,
      'D vitamini tahlili — son değer 10 ve bir yıl öncesine ait',
    );
  }

  slots.sort((a, b) => a.time.compareTo(b.time));
  return slots;
}

/// PDF'in Program A ve Program B listeleri, katalog id'leriyle.
///
/// `(exerciseId, sets, reps, durationSec)` — süreli hareketlerde reps
/// null, durationSec dolu.
const _programA = <(String, int, int?, int?)>[
  ('incline_pushup', 3, 10, null),
  ('band_row', 3, 12, null),
  ('band_pull_apart', 2, 15, null),
  ('superman', 3, 12, null),
  ('plank', 3, null, 30),
  ('dead_bug', 3, 10, null),
];

const _programB = <(String, int, int?, int?)>[
  ('chair_squat', 3, 12, null),
  ('step_up', 3, 10, null),
  ('glute_bridge', 3, 15, null),
  ('wall_sit', 2, null, 30),
  ('calf_raise', 2, 20, null),
  ('bird_dog', 3, 10, null),
];

List<PlanExercise> _exercises({
  required String dayId,
  required int weekday,
  required bool isGym,
  required bool isSaturday,
  required int weekIndex,
}) {
  if (isGym) {
    return _cardio(
      dayId: dayId,
      weekIndex: weekIndex,
      isLongSession: isSaturday,
    );
  }

  final program = switch (weekday) {
    DateTime.tuesday || DateTime.friday => _programA,
    _ => _programB,
  };

  return [
    for (final (index, (exerciseId, sets, reps, durationSec))
        in program.indexed)
      PlanExercise(
        id: '$dayId-e$index',
        exerciseId: exerciseId,
        sets: sets,
        reps: reps,
        durationSec: durationSec,
        restSec: 60,
      ),
  ];
}

/// Salon kardiyo protokolü — hafta ilerledikçe direnç ve eğim artıyor
/// (PDF "salon — kardiyo protokolü" tablosu).
List<PlanExercise> _cardio({
  required String dayId,
  required int weekIndex,
  required bool isLongSession,
}) {
  final (bikeMinutes, bikeIntensity) = switch (weekIndex) {
    1 => (isLongSession ? 35 : 25, 'direnç 5'),
    2 => (isLongSession ? 40 : 25, 'direnç 6'),
    3 => (isLongSession ? 40 : 25, 'interval ×6'),
    _ => (isLongSession ? 40 : 25, 'interval ×8'),
  };

  final treadmillIncline = switch (weekIndex) {
    1 => '%5',
    2 => '%8',
    _ => '%10',
  };

  return [
    PlanExercise(
      id: '$dayId-e0',
      exerciseId: 'stationary_bike',
      sets: 1,
      durationSec: bikeMinutes * 60,
      intensity: bikeIntensity,
    ),
    PlanExercise(
      id: '$dayId-e1',
      exerciseId: 'treadmill_incline_walk',
      sets: 1,
      durationSec: (isLongSession ? 20 : 15) * 60,
      intensity: 'eğim $treadmillIncline',
    ),
  ];
}

/// Plan id'sini tarihten türetmek için küçük yardımcı.
///
/// `PlanRepository.iso` kullanılmıyor çünkü bu dosya `data/` katmanının
/// geri kalanına bağımlı olmamalı: örnek plan saf bir üreteç.
abstract final class PlanRepositoryDateKey {
  static String of(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
