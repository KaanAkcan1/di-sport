import 'package:disport/app/app.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_providers.g.dart';

@riverpod
LabRepository labRepository(Ref ref) =>
    LabRepository(ref.watch(appDatabaseProvider));

/// Panel → sonuçlar (yeniden eskiye). Sağlık ekranının ana akışı.
@riverpod
Stream<Map<String, List<LabEntry>>> labsByPanel(Ref ref) =>
    ref.watch(labRepositoryProvider).watchByPanel();

/// Vadesi gelmiş tahliller — ekranın tepesindeki uyarı şeridi.
@riverpod
Future<List<DueSchedule>> dueLabs(Ref ref) async {
  // Sonuç eklenince bu liste değişebilir (vade ileri kayar); akışa
  // bağlanarak yeniden hesaplanmasını sağlıyoruz.
  await ref.watch(labsByPanelProvider.future);
  return ref.watch(labRepositoryProvider).dueSchedules(DateTime.now());
}

/// Ölçüm türü başına en güncel değer — Sağlık ekranının ölçüm bölümü.
///
/// Akış: Bugün sekmesinden girilen tartı buraya da yansımalı ve Sağlık
/// sekmesi `IndexedStack` içinde canlı kaldığı için tek seferlik okuma
/// bir daha çalışmazdı.
@riverpod
Stream<Map<String, MetricSample>> latestMetrics(Ref ref) =>
    ref.watch(bodyMetricsRepositoryProvider).watchLatestPerKind();
