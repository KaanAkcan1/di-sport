import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/progress/domain/transition_criteria.dart';
import 'package:disport/features/progress/domain/weekly_summary.dart';
import 'package:disport/features/progress/domain/weight_trend.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_providers.g.dart';

/// Profilde "koşu sonrası ağrı yok" onayının anahtarı.
///
/// Bu ölçüt ölçülemez; yalnız kullanıcı bilebilir (spec 5.5). Profilde
/// duruyor çünkü tarihli bir ölçüm değil, kalıcı bir beyan.
const painFreeProfileKey = 'painFreeConfirmed';

/// İlerleme ekranının ihtiyaç duyduğu her şey — tek nesne.
///
/// Ekran hesap yapmaz: hareketli ortalama, haftalık dilimleme ve geçiş
/// ölçütü `domain/`'de saf fonksiyonlarla çözülüyor, burada yalnız
/// veriyle buluşturuluyor. Widget içinde hesaplamak, aynı mantığı
/// grafik ve kart için iki kez yazma riskini doğururdu.
class ProgressViewData {
  const ProgressViewData({
    required this.weights,
    required this.trend,
    required this.weeks,
    required this.latestMetrics,
    required this.criteria,
    required this.hasPlan,
  });

  final List<WeightPoint> weights;
  final List<TrendPoint> trend;
  final List<WeekSummary> weeks;
  final Map<String, MetricSample> latestMetrics;
  final TransitionCriteria criteria;

  /// Plan yoksa haftalık kartlar üretilemez — gün tiplerini plan verir.
  final bool hasPlan;

  bool get isEmpty => weights.isEmpty && weeks.isEmpty;
}

/// Kilo serisi — akış.
///
/// Future değil akış olması şart: İlerleme sekmesi `IndexedStack`
/// içinde canlı kalıyor, tek seferlik okuma kullanıcı Bugün'de
/// tartıldıktan sonra bir daha çalışmazdı.
@riverpod
Stream<List<WeightPoint>> weightSeries(Ref ref) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchSeries(MetricKinds.weight);

@riverpod
Stream<Map<String, MetricSample>> latestMetricSamples(Ref ref) =>
    ref.watch(bodyMetricsRepositoryProvider).watchLatestPerKind();

@riverpod
Future<ProgressViewData> progressView(Ref ref) async {
  final plan = await ref.watch(activePlanProvider.future);

  final weights = await ref.watch(weightSeriesProvider.future);
  final latest = await ref.watch(latestMetricSamplesProvider.future);

  final profile = await ref.watch(profileEntriesProvider.future);

  final criteria = evaluateTransition(
    latestWeight: latest[MetricKinds.weight]?.value,
    latestPushupMax: latest[MetricKinds.pushupMax]?.value,
    painFreeConfirmed: profile[painFreeProfileKey] == 'true',
  );

  if (plan == null) {
    return ProgressViewData(
      weights: weights,
      trend: movingAverage(weights),
      weeks: const [],
      latestMetrics: latest,
      criteria: criteria,
      hasPlan: false,
    );
  }

  // Plan günleri ile günlük kayıtlar burada eşleniyor; `summarizeWeeks`
  // saf kalsın diye birleştirme bu katmanda yapılıyor.
  final days = plan.days.map((day) => PlanRepository.iso(day.date)).toList();
  final logs = await ref
      .watch(todayRepositoryProvider)
      .watchBetween(days.first, days.last)
      .first;

  final facts = <DayFact>[
    for (final day in plan.days)
      (
        date: PlanRepository.iso(day.date),
        dayType: day.type.name,
        workoutDone: logs[PlanRepository.iso(day.date)]?.workoutDone ?? false,
        // Kayıt girilmemiş gün "kaçak" sayılmaz: kullanıcı o gün
        // uygulamayı hiç açmamış olabilir, kural çiğnediğini
        // varsaymak haksızlık olur.
        noAlcoholSugar:
            logs[PlanRepository.iso(day.date)]?.noAlcoholSugar ?? true,
      ),
  ];

  return ProgressViewData(
    weights: weights,
    trend: movingAverage(weights),
    weeks: summarizeWeeks(
      days: facts,
      weights: weights,
      gymTarget: plan.goals.weeklyGym,
      homeTarget: plan.goals.weeklyHome,
    ),
    latestMetrics: latest,
    criteria: criteria,
    hasPlan: true,
  );
}

/// Ağrı onayını değiştirir ve görünümü tazeler.
@riverpod
Future<void> Function(bool) setPainFreeConfirmed(Ref ref) => (value) async {
  await ref
      .read(profileRepositoryProvider)
      .set(painFreeProfileKey, value.toString());
  ref.invalidate(progressViewProvider);
};
