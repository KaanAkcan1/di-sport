import 'package:disport/features/catalog/domain/exercise.dart' show Effort;
import 'package:disport/features/plan/domain/meal_kind.dart';

/// Günün tipi. PDF çizelgesindeki salon / ev ayrımı.
enum PlanDayType { gym, home, rest }

/// Gün içindeki bir zaman diliminin türü.
///
/// Ölçüm ve tahlil de birer slot: "ay sonu göbek çevreni ölç" ve
/// "D vitamini baktır" plana gömülünce ayrı bir hatırlatma mekanizması
/// gerekmiyor (spec 5.2).
enum SlotKind { meal, workout, sleep, measurement, lab, other }

/// Planın sayısal hedefleri.
class PlanGoals {
  const PlanGoals({
    required this.dailyKcal,
    required this.proteinG,
    required this.waterL,
    required this.weeklyGym,
    required this.weeklyHome,
    required this.targetLossKg,
  });

  factory PlanGoals.fromJson(Map<String, dynamic> json) => PlanGoals(
    dailyKcal: json['dailyKcal'] as int,
    proteinG: json['proteinG'] as int,
    waterL: (json['waterL'] as num).toDouble(),
    weeklyGym: json['weeklyGym'] as int,
    weeklyHome: json['weeklyHome'] as int,
    targetLossKg: (json['targetLossKg'] as num).toDouble(),
  );

  final int dailyKcal;
  final int proteinG;
  final double waterL;
  final int weeklyGym;
  final int weeklyHome;
  final double targetLossKg;

  Map<String, dynamic> toJson() => {
    'dailyKcal': dailyKcal,
    'proteinG': proteinG,
    'waterL': waterL,
    'weeklyGym': weeklyGym,
    'weeklyHome': weeklyHome,
    'targetLossKg': targetLossKg,
  };
}

/// Beslenme kuralları — PDF'in "kesinlikle yok" ve "serbest" listeleri.
class PlanRules {
  const PlanRules({required this.forbidden, required this.free});

  factory PlanRules.fromJson(Map<String, dynamic> json) => PlanRules(
    forbidden: (json['forbidden'] as List).cast<String>(),
    free: (json['free'] as List).cast<String>(),
  );

  final List<String> forbidden;
  final List<String> free;

  Map<String, dynamic> toJson() => {'forbidden': forbidden, 'free': free};
}

/// Günün bir zaman dilimi: saat, tür, etiket.
class PlanSlot {
  const PlanSlot({
    required this.id,
    required this.time,
    required this.kind,
    required this.label,
    this.mealKind,
    this.note,
  });

  final String id;

  /// `HH:mm`. Metin olarak tutuluyor çünkü sıralaması sözlük sırasıyla
  /// aynı ve saat dilimi taşımıyor — plan yerel saate göre yazılır.
  final String time;

  final SlotKind kind;

  /// Öğün slotlarında hangi öğün. Diğer türlerde null.
  final MealKind? mealKind;

  final String label;
  final String? note;
}

/// Planlanan bir hareket: katalog id'si + hedef.
class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.exerciseId,
    this.sets,
    this.reps,
    this.durationSec,
    this.restSec,
    this.intensity,
    this.speedKmh,
    this.gradePct,
    this.effort,
    this.note,
  });

  final String id;

  /// Katalogdaki hareketin id'si. Hareketin anlatımı burada tekrarlanmaz;
  /// planlar arası tutarlılığı sağlayan da bu (spec 7.2).
  final String exerciseId;

  final int? sets;

  /// Tekrar sayısı. Süreli hareketlerde (plank, duvar oturuşu) null olur
  /// ve [durationSec] dolar.
  final int? reps;

  final int? durationSec;
  final int? restSec;

  /// Kardiyoda direnç kademesi ya da bant eğimi — "d6", "%8".
  ///
  /// **Serbest metin ve öyle kalıyor:** AI'ın ve kullanıcının yazdığı
  /// her şeyi bir sayıya çevirmeye çalışmak sessizce yanlış kalori
  /// üretirdi. Hesap yapılabilir değerler ayrı üç alanda.
  final String? intensity;

  /// Kalori hesabının girdileri (spec §5.5).
  final double? speedKmh;
  final double? gradePct;

  /// `Effort` enum adı — bisiklette hız/eğim yerine efor.
  final Effort? effort;

  final String? note;

  /// Ekranda gösterilecek hedef metni.
  ///
  /// Süre birimi uzunluğa göre seçilir: 25 dakikalık bir bisiklet
  /// seansını "1500 sn" diye göstermek okunabilir değil. Eşik iki
  /// dakika — altındaki plank ve duvar oturuşu saniyeyle, üstündeki
  /// kardiyo dakikayla anlamlı.
  ///
  /// Tek setli hareketlerde "1 ×" öneki düşer; kardiyoda set kavramı
  /// zaten yok.
  String get targetLabel {
    final count = sets ?? 1;

    if (reps != null) return '$count × $reps';

    if (durationSec case final seconds?) {
      final duration = seconds >= 120
          ? '${(seconds / 60).round()} dk'
          : '$seconds sn';
      return count > 1 ? '$count × $duration' : duration;
    }

    return '$count set';
  }
}

/// Planın bir günü.
class FullPlanDay {
  const FullPlanDay({
    required this.id,
    required this.date,
    required this.type,
    required this.weekIndex,
    this.headline = '',
    this.dinnerSuggestion = '',
    this.slots = const [],
    this.exercises = const [],
  });

  final String id;
  final DateTime date;
  final PlanDayType type;

  /// 1'den başlar.
  final int weekIndex;

  /// Haftanın notu — "Tempoyu bul. Saatleri oturt."
  final String headline;

  final String dinnerSuggestion;
  final List<PlanSlot> slots;
  final List<PlanExercise> exercises;

  bool get hasWorkout => type != PlanDayType.rest && exercises.isNotEmpty;

  /// Günde planlanmış öğün var mı.
  bool get hasMeals => slots.any((slot) => slot.kind == SlotKind.meal);

  /// Diyeti boş gün — "serbest gün".
  ///
  /// AI dört haftalık planda bazı günlere bilerek öğün yazmıyor:
  /// sosyal yemek, bayram, seyahat. v1'de bu gün diğerlerinden ayırt
  /// edilemiyordu; kullanıcı "plan eksik mi geldi" diye düşünüyordu.
  ///
  /// Türetilmiş bir özellik, saklanmıyor: kaynak zaten slot listesi ve
  /// ayrı bir bayrak tutmak ikisinin ayrışma riskini getirirdi.
  bool get isDietFree => !hasMeals;

  /// Ne antrenman ne öğün — tamamen serbest.
  bool get isFullyFree => isDietFree && !hasWorkout;

  /// Antrenman slotu — Bugün ekranında karta dönüşen slot.
  PlanSlot? get workoutSlot {
    for (final slot in slots) {
      if (slot.kind == SlotKind.workout) return slot;
    }
    return null;
  }
}

/// 28 günlük programın tamamı.
///
/// Veritabanından bağımsız saf sınıf. Üç kaynaktan aynı tiple üretilir:
/// örnek plan üreteci (M3), AI importer'ı (M4), veritabanı (her ikisi).
class FullPlan {
  const FullPlan({
    required this.id,
    required this.title,
    required this.startDate,
    required this.weeks,
    required this.goals,
    required this.rules,
    required this.days,
    required this.sourceRaw,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final int weeks;
  final PlanGoals goals;
  final PlanRules rules;
  final List<FullPlanDay> days;

  /// AI'ın verdiği ham JSON. Bilinçli fazlalık: içe alma sonrası sorun
  /// çıkarsa ya da aylar sonra "AI bunu neden böyle demiş" sorusu
  /// doğarsa orijinal elde kalsın (spec 5.2).
  final String sourceRaw;

  int get dayCount => weeks * 7;

  DateTime get endDate => startDate.add(Duration(days: dayCount - 1));

  /// Verilen günün planı; plan o tarihi kapsamıyorsa null.
  FullPlanDay? dayAt(DateTime date) {
    for (final day in days) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day;
      }
    }
    return null;
  }
}
