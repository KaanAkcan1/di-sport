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
    required this.nameTr,
    required this.location,
    required this.equipment,
    required this.primaryMuscles,
  });

  final String id;
  final String nameTr;
  final String location;
  final List<String> equipment;
  final List<String> primaryMuscles;
}

/// Egzersiz kataloğu.
abstract interface class CatalogSource {
  /// Kullanıcının ortamına uyan alt küme.
  ///
  /// Katalogun tamamını `context.md`'ye basmak hem gereksiz uzun olur
  /// hem de AI'ı elindeki ekipmanla yapamayacağı hareketlere yöneltir.
  Future<List<ExerciseRef>> selectable();
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
