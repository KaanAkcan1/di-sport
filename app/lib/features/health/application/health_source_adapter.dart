import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/health/data/lab_repository.dart';

/// `health` feature'ının `ai_bridge`'e verdiği ölçüm ve tahlil kaynağı.
class HealthSourceAdapter implements HealthSource {
  const HealthSourceAdapter({required this.metrics, required this.labs});

  final BodyMetricsRepository metrics;
  final LabRepository labs;

  @override
  Future<List<MetricPoint>> bodyMetrics({required int lastDays}) async {
    final points = <MetricPoint>[];

    for (final kind in MetricKinds.labels.keys) {
      final series = await metrics.series(kind, limit: lastDays);
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

  /// Marker başına yalnız **son** sonuç.
  ///
  /// Tüm tahlil geçmişi `context.md`'yi şişirir ve AI'ı eski değerlere
  /// bakıp güncel durumu kaçırmaya yöneltir. Eğilim gerekiyorsa
  /// kullanıcı özellikle sorar.
  @override
  Future<List<LabValueDump>> recentLabs() async {
    final latest = await labs.latestPerMarker();
    latest.sort((a, b) => a.marker.compareTo(b.marker));

    return [
      for (final entry in latest)
        LabValueDump(
          date: entry.date,
          marker: entry.marker,
          value: entry.value,
          unit: entry.unit,
          refLow: entry.refLow,
          refHigh: entry.refHigh,
        ),
    ];
  }
}
