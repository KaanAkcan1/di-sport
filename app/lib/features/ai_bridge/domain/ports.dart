/// `ai_bridge`'in dış dünyadan veri almak için tanımladığı arayüzler.
///
/// Bağımlılık oku bilinçli olarak tersine çevrilmiş (spec 4.3):
/// `ai_bridge` altı feature'dan veri toplar; doğrudan bağlansaydı
/// hepsine kenetlenir ve izole test edilemezdi. Bunun yerine ihtiyacını
/// arayüz olarak yazıyor, feature'lar kendi adaptörlerini yazıyor.
///
/// Tipler de bilinçli olarak yalın: `FullPlan` ya da `Exercise` gibi
/// zengin nesneler yerine `context.md`'nin ihtiyacı kadar alan. Böylece
/// bir feature'ın iç modeli değişince bu dosya etkilenmiyor.
library;

/// Kullanıcının kim olduğu — profil ve yaşam tarzı.
abstract interface class ProfileSource {
  /// Anahtar-değer; eksik alanlar hiç bulunmaz.
  Future<Map<String, String>> profile();
}

/// Bir günün uyum özeti.
class DayCompliance {
  const DayCompliance({
    required this.date,
    required this.dayType,
    required this.workoutDone,
    required this.waterTargetMet,
    required this.noAlcoholSugar,
    required this.checkedSlots,
    required this.totalSlots,
  });

  final String date;
  final String dayType;
  final bool workoutDone;
  final bool waterTargetMet;
  final bool noAlcoholSugar;
  final int checkedSlots;
  final int totalSlots;
}

/// Gerçekleşen tek set.
class SetActualDump {
  const SetActualDump({
    required this.date,
    required this.exerciseId,
    required this.setIndex,
    this.reps,
    this.durationSec,
  });

  final String date;
  final String exerciseId;
  final int setIndex;
  final int? reps;
  final int? durationSec;
}

/// Bir günün gerçeklik dökümü (v3.1 §8) — uyku saatleri, his,
/// belirti, stres, atlanan öğünler. `sleepHours` burada değil:
/// o bir `body_metrics` serisi ve `HealthSource` zaten taşıyor.
class DayRealityDump {
  const DayRealityDump({
    required this.date,
    this.bedTime,
    this.wakeTime,
    this.napMinutes,
    this.moodScore,
    this.symptoms = '',
    this.stressedDay = false,
    this.skippedMeals = const {},
  });

  final String date;
  final String? bedTime;
  final String? wakeTime;
  final int? napMinutes;
  final int? moodScore;
  final String symptoms;
  final bool stressedDay;

  /// `MealKind.name` → neden.
  final Map<String, String> skippedMeals;

  /// Belgeye girecek bir şey var mı — tamamen boş gün yazılmaz.
  bool get isEmpty =>
      bedTime == null &&
      wakeTime == null &&
      napMinutes == null &&
      moodScore == null &&
      symptoms.isEmpty &&
      !stressedDay &&
      skippedMeals.isEmpty;
}

/// Kapanmış bir antrenman seansı (v3.1 §8) — süre + değerlendirme.
class SessionDump {
  const SessionDump({
    required this.date,
    required this.minutes,
    this.rpe,
    this.painNote = '',
  });

  final String date;
  final int minutes;
  final int? rpe;
  final String painNote;
}

/// Günlük kayıtlar ve antrenman gerçekleşmeleri.
abstract interface class LogSource {
  Future<List<DayCompliance>> compliance({required int lastDays});

  /// Kullanıcının serbest notları — **düzenlenmeden**.
  ///
  /// AI'ın en değerli girdisi kullanıcının kendi ifadesi; özetlenmiş
  /// hali değil (spec 7.1, beşinci bölüm).
  Future<List<({String date, String text})>> userNotes({
    required int lastDays,
  });

  Future<List<SetActualDump>> actuals({required int lastDays});

  /// Gün gün gerçeklik (v3.1 §8) — yalnız dolu günler.
  Future<List<DayRealityDump>> reality({required int lastDays});

  /// Kapanmış seanslar RPE ve ağrı notuyla (v3.1 §8) — seans kavramı
  /// başka hiçbir portta yok.
  Future<List<SessionDump>> sessions({required int lastDays});
}

/// Tarihli sayısal ölçüm.
class MetricPoint {
  const MetricPoint({
    required this.date,
    required this.kind,
    required this.value,
    required this.unit,
  });

  final String date;
  final String kind;
  final double value;
  final String unit;
}

/// Tahlil sonucu.
class LabValueDump {
  const LabValueDump({
    required this.date,
    required this.marker,
    required this.value,
    required this.unit,
    this.refLow,
    this.refHigh,
  });

  final String date;
  final String marker;
  final double value;
  final String unit;
  final double? refLow;
  final double? refHigh;
}

/// Vücut ölçümleri ve tahliller.
abstract interface class HealthSource {
  Future<List<MetricPoint>> bodyMetrics({required int lastDays});

  /// M5'e kadar boş liste döner; tahlil tablosu orada geliyor.
  Future<List<LabValueDump>> recentLabs();
}

/// Katalogdan AI'a sunulacak hareket.
class ExerciseRef {
  const ExerciseRef({
    required this.id,
    required this.name,
    required this.location,
    required this.equipment,
    required this.primaryMuscles,
  });

  final String id;

  /// **İngilizce** ad. AI bu adı web'de arayabilmeli ve dönen planda
  /// aynı adı kullanabilmeli; Türkçe ad yalnız kullanıcının ekranına
  /// ait (spec §4.1).
  final String name;

  final String location;
  final List<String> equipment;
  final List<String> primaryMuscles;
}

/// Egzersiz kataloğu.
abstract interface class CatalogSource {
  /// Kullanıcının ortamına uyan alt küme.
  ///
  /// v2'nin varsayılanıydı; v3 belgesi tam listeyi basıyor ama bu
  /// süzgeç "ekipmana uyanlar" işareti için duruyor.
  Future<List<ExerciseRef>> selectable();

  /// Tam katalog (v3 §9.3 — 161 hareket). Kullanıcı kararı: AI her
  /// hareketi görsün, yapılamayanlar içe almada uyarıyla yakalanır.
  Future<List<ExerciseRef>> all();
}

/// Etkin planın özeti — yeni plan isterken AI'ın neyin devamını
/// yazdığını bilmesi için.
class ActivePlanSummary {
  const ActivePlanSummary({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.weeks,
  });

  final String title;
  final String startDate;
  final String endDate;
  final int weeks;
}

abstract interface class PlanSource {
  Future<ActivePlanSummary?> activePlanSummary();
}

/// Haftalık uygunluk penceresi — mesai ya da yasaklı saat.
class WindowDump {
  const WindowDump({
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.kind,
    required this.label,
  });

  /// 1 = Pazartesi … 7 = Pazar.
  final int weekday;
  final String startTime;
  final String endTime;

  /// `work` ya da `blocked`.
  final String kind;
  final String label;
}

/// Kullanıcının haftalık uygunluğu.
///
/// v1'de AI'a "sabah 06:30 kahvaltı" diyebiliyorduk ama kullanıcının
/// 08:00-18:00 arası fabrikada olduğunu söyleyemiyorduk; plan bu yüzden
/// mesai saatine antrenman koyabiliyordu.
abstract interface class AvailabilitySource {
  Future<List<WindowDump>> windows();
}

// --- v3 (§9.3) — context.md v2 kaynakları ---

/// Medikal gerçek dökümü.
class MedicalFactDump {
  const MedicalFactDump({
    required this.kind,
    required this.label,
    this.note,
    this.factDate,
  });

  /// `condition` | `diagnosis` | `restriction` | `allergy` | `bloodType`.
  final String kind;
  final String label;
  final String? note;

  /// Teşhis tarihi (v3.1 §7); diğer türlerde null.
  final String? factDate;
}

abstract interface class MedicalSource {
  Future<List<MedicalFactDump>> facts();
}

/// İlaç/takviye dökümü — sınır satırıyla birlikte basılır: AI ilaç
/// önerisi vermez, yalnız zamanlama ve beslenme bağlamı olarak kullanır.
class MedicationDump {
  const MedicationDump({
    required this.name,
    required this.isPrescription,
    required this.doseLabel,
    required this.times,
  });

  final String name;
  final bool isPrescription;
  final String doseLabel;
  final List<String> times;
}

abstract interface class MedicationSource {
  Future<List<MedicationDump>> medications();
}

/// Ortam: ekipman envanteri (enum adlarıyla) + sevilen sporlar.
abstract interface class EnvironmentSource {
  Future<({List<String> home, List<String> gym})> equipment();
  Future<List<({String name, String? note})>> favoriteSports();
}

/// Öğün davranışı dökümü (v3 §3.4).
class MealBehaviorDump {
  const MealBehaviorDump({
    required this.meal,
    required this.behavior,
    this.time,
    this.fixedNote,
  });

  final String meal;

  /// `planned` | `fixed` | `external`.
  final String behavior;
  final String? time;
  final String? fixedNote;
}

abstract interface class RoutineSource {
  Future<List<MealBehaviorDump>> mealBehaviors();
}

/// Besin dökümü — AI plana besin id'siyle kalem yazabilsin (§5.0).
class FoodDump {
  const FoodDump({
    required this.id,
    required this.name,
    required this.kcal100,
    this.defaultPortion,
  });

  final String id;
  final String name;
  final double kcal100;

  /// "1 kase = 250 g" gibi; yoksa 100 g tabanı.
  final String? defaultPortion;
}

/// Bir günün alım özeti — son 14 gün bölümü.
class DayIntakeDump {
  const DayIntakeDump({
    required this.date,
    required this.kcalEaten,
    this.waterMl,
    this.dosesTaken,
    this.dosesPlanned,
  });

  final String date;
  final double kcalEaten;
  final int? waterMl;
  final int? dosesTaken;
  final int? dosesPlanned;
}

abstract interface class NutritionSource {
  Future<List<FoodDump>> foods();
  Future<List<DayIntakeDump>> dailyIntake({required int lastDays});
}

/// Yasaklı listesi — plandan (§5.4). AI'a "bunları asla önerme" diye
/// basılır; sözleşmede string listesi kalır.
abstract interface class RulesSource {
  Future<List<String>> forbidden();
}
