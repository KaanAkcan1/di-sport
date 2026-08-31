import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';

/// `health` feature'ının `ai_bridge`'e verdiği ölçüm kaynağı.
class HealthSourceAdapter implements HealthSource {
  const HealthSourceAdapter(this._metrics);

  final BodyMetricsRepository _metrics;

  @override
  Future<List<MetricPoint>> bodyMetrics({required int lastDays}) async {
    final points = <MetricPoint>[];

    for (final kind in MetricKinds.labels.keys) {
      final series = await _metrics.series(kind, limit: lastDays);
      for (final point in series) {
        points.add(
          MetricPoint(
            date: point.date,
            kind: kind,
            value: point.value,
            unit: MetricKinds.unitOf(kind),
          ),
        );
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// M5'te `lab_results` tablosu gelene kadar boş.
  ///
  /// `context.md` bunu "tahlil kaydı yok" diye yazıyor; eksik bölüm
  /// bırakmaktansa durumu açıkça söylemek daha iyi.
  @override
  Future<List<LabValueDump>> recentLabs() async => const [];
}
