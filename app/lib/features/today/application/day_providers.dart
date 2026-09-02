/// Herhangi bir günün verisi — Bugün bunun `dateKey = bugün` hâli.
///
/// **Neden aile:** kullanıcı geçmiş bir güne girip tartısını
/// düzeltebilmeli (spec §6.2). Bugün'e özel bir provider seti
/// tutmak, aynı ekranı iki kez yazmak demek olurdu.
///
/// **Argüman `String`, `DateTime` değil.** Riverpod aile argümanlarını
/// `==` ile karşılaştırıyor; `DateTime` saat bileşeni taşıdığı için
/// aynı günün iki örneği eşit çıkmaz ve provider sonsuza dek yeniden
/// kurulur. `'2026-09-01'` değer eşitliği olan bir tip.
library;

import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/today/domain/sleep_duration.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_providers.g.dart';


/// `yyyy-MM-dd`.
String dateKeyOf(DateTime date) => PlanRepository.iso(date);

/// Ekranın **baktığı** gün.
///
/// Varsayılanı bugün; `DayScreen` bir `ProviderScope` ile bunu geçmiş
/// bir güne çeviriyor. Böylece gün ekranının içindeki her parça
/// "hangi gün" sorusunu tek yerden soruyor ve `dateKey`'i onlarca
/// widget yapıcısından geçirmek gerekmiyor.
@riverpod
String viewedDate(Ref ref) => ref.watch(todayIsoProvider);

/// O günün plan günü — plan yoksa ya da günü kapsamıyorsa null.
@riverpod
Stream<FullPlanDay?> dayPlanDay(Ref ref, String dateKey) =>
    ref.watch(planRepositoryProvider).watchDay(dateKey);

/// O günün işaret ve not durumu.
///
/// `null` değil boş görünüm dönüyor: "kayıt yok" ile "boş kayıt"
/// ekranda aynı şey ve çağıran her yerde null kontrolü yazmasın.
@riverpod
Stream<DailyLogView> dayLog(Ref ref, String dateKey) =>
    ref.watch(todayRepositoryProvider).watchDay(dateKey);

@riverpod
Stream<double?> dayWeight(Ref ref, String dateKey) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchValue(dateKey, MetricKinds.weight);

@riverpod
Stream<double?> daySleep(Ref ref, String dateKey) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchValue(dateKey, MetricKinds.sleepHours);

/// O günün adım sayısı (v3.1 §4) — elle girilen NEAT göstergesi.
@riverpod
Stream<double?> daySteps(Ref ref, String dateKey) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchValue(dateKey, MetricKinds.steps);

/// Seçili gün bugüne göre nerede duruyor.
enum DayPosition { past, today, future }

DayPosition positionOf(String dateKey, String todayKey) {
  final compared = dateKey.compareTo(todayKey);
  if (compared < 0) return DayPosition.past;
  if (compared > 0) return DayPosition.future;
  return DayPosition.today;
}

@riverpod
DayPosition dayPosition(Ref ref, String dateKey) =>
    positionOf(dateKey, ref.watch(todayIsoProvider));

/// His bloğunun yazım işlevi (v3.1 §3).
///
/// Fonksiyon tipli ki widget testleri Drift'e bağlanmadan tek satırla
/// kaydedici sahtesi koyabilsin (`importWarningsCollector` kalıbı).
typedef WellbeingWriter =
    Future<void> Function(
      String isoDate, {
      int? moodScore,
      bool clearMood,
      String? symptoms,
      bool? stressedDay,
    });

@riverpod
WellbeingWriter wellbeingWriter(Ref ref) {
  final repository = ref.watch(todayRepositoryProvider);
  return (
    String isoDate, {
    int? moodScore,
    bool clearMood = false,
    String? symptoms,
    bool? stressedDay,
  }) => repository.setWellbeing(
    isoDate,
    moodScore: moodScore,
    clearMood: clearMood,
    symptoms: symptoms,
    stressedDay: stressedDay,
  );
}

/// Öğün atlama yazımı (v3.1 §5).
///
/// Sütunun sahibi `today` ama okuyup yazan Diyet akışı: `nutrition`
/// bu sağlayıcıyı çağırır, repository'yi doğrudan import etmez.
/// `reason` null = işaret silinir (öğüne kayıt girildi).
typedef MealSkipWriter =
    Future<void> Function(
      String isoDate, {
      required String mealKindName,
      String? reason,
    });

@riverpod
MealSkipWriter mealSkipWriter(Ref ref) {
  final repository = ref.watch(todayRepositoryProvider);
  return (String isoDate, {required String mealKindName, String? reason}) =>
      repository.setMealSkipped(
        isoDate,
        mealKindName: mealKindName,
        reason: reason,
      );
}

/// Uyku yazımlarının **tek** noktası (v3.1 §2.2 — son yazan kazanır).
///
/// İki depo birden güncelleniyor: saatler `daily_logs`'a, türetilen
/// süre `body_metrics.sleepHours`'a. İki ekran ayrı ayrı yazsaydı
/// yarış doğar, iki ekran farklı süre gösterirdi. Widget testleri
/// bunu sahtesiyle değiştirir — Drift'e bağlanmaz.
@riverpod
SleepWriter sleepWriter(Ref ref) => SleepWriter(
  today: ref.watch(todayRepositoryProvider),
  metrics: ref.watch(bodyMetricsRepositoryProvider),
);

class SleepWriter {
  const SleepWriter({required this.today, required this.metrics});

  final TodayRepository today;
  final BodyMetricsRepository metrics;

  /// Saat girişi: saatler yazılır, süre türetilip ölçüme geçirilir.
  ///
  /// İki saat de silindiyse türetilmiş `sleepHours` kaydı da silinir
  /// (spec §2.2). Kısmi giriş (yalnız yatış) mevcut ölçüme dokunmaz —
  /// kullanıcı henüz yazmayı bitirmedi.
  Future<void> saveTimes(
    String isoDate, {
    required String? bedTime,
    required String? wakeTime,
    required int? napMinutes,
  }) async {
    await today.setSleepTimes(
      isoDate,
      bedTime: bedTime,
      wakeTimeActual: wakeTime,
      napMinutes: napMinutes,
    );

    final derived = sleepHoursFrom(
      bedTime: bedTime,
      wakeTime: wakeTime,
      napMinutes: napMinutes,
    );
    if (derived != null) {
      await metrics.upsert(
        isoDate: isoDate,
        kind: MetricKinds.sleepHours,
        value: derived,
        unit: 'sa',
      );
    } else if (bedTime == null && wakeTime == null) {
      await metrics.delete(isoDate, MetricKinds.sleepHours);
    }
  }

  /// Yalnız süre girişi (eski davranış): saatler temizlenir — saatle
  /// çelişen bir süre iki yerde iki gerçek yaratırdı.
  Future<void> saveHoursOnly(String isoDate, double hours) async {
    await today.setSleepTimes(
      isoDate,
      bedTime: null,
      wakeTimeActual: null,
      napMinutes: null,
    );
    await metrics.upsert(
      isoDate: isoDate,
      kind: MetricKinds.sleepHours,
      value: hours,
      unit: 'sa',
    );
  }
}
