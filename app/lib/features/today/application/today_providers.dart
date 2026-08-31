import 'package:disport/app/app.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_providers.g.dart';

@riverpod
TodayRepository todayRepository(Ref ref) =>
    TodayRepository(ref.watch(appDatabaseProvider));

@riverpod
BodyMetricsRepository bodyMetricsRepository(Ref ref) =>
    BodyMetricsRepository(ref.watch(appDatabaseProvider));

/// Bugünün tarihi, `yyyy-MM-dd`.
///
/// Ayrı provider olması testlerde sabit bir güne kilitlemeyi sağlıyor;
/// `DateTime.now()` ekranın içine gömülseydi test yarın kırılırdı.
@riverpod
String todayIso(Ref ref) => PlanRepository.iso(DateTime.now());

/// Bugünün plan günü — plan yoksa ya da bugünü kapsamıyorsa null.
@riverpod
Stream<FullPlanDay?> todayPlanDay(Ref ref) =>
    ref.watch(planRepositoryProvider).watchDay(ref.watch(todayIsoProvider));

/// Bugünün işaret ve not durumu.
@riverpod
Stream<DailyLogView> todayLog(Ref ref) =>
    ref.watch(todayRepositoryProvider).watchDay(ref.watch(todayIsoProvider));

/// Bugünün tartısı.
@riverpod
Stream<double?> todayWeight(Ref ref) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchValue(ref.watch(todayIsoProvider), MetricKinds.weight);

/// Bugünün uyku süresi.
@riverpod
Stream<double?> todaySleep(Ref ref) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchValue(ref.watch(todayIsoProvider), MetricKinds.sleepHours);

/// Antrenman kaçırılan ardışık gün sayısı.
///
/// PDF'in "iki gün üst üste kaçırma — kural bu" satırının karşılığı;
/// 2 ve üstünde Bugün ekranı uyarı gösterir.
@riverpod
Future<int> missedStreak(Ref ref) async {
  final plan = await ref.watch(activePlanProvider.future);
  if (plan == null) return 0;

  return ref
      .watch(todayRepositoryProvider)
      .missedStreak(
        todayIso: ref.watch(todayIsoProvider),
        planDayTypes: {
          for (final day in plan.days)
            PlanRepository.iso(day.date): day.type.name,
        },
      );
}
