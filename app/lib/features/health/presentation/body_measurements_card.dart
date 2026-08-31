import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:flutter/material.dart';

/// Ay sonu ölçümlerinin son değerleri.
///
/// Kilo ve uyku burada yok: onlar her gün Bugün ekranından giriliyor.
/// Buradakiler seyrek ölçülenler — bel, göbek, şınav maksimumu, plank.
/// İkisini aynı yere koymak, günlük girişi seyrek ekranın arkasına
/// gömerdi.
class BodyMeasurementsCard extends StatelessWidget {
  const BodyMeasurementsCard({
    super.key,
    required this.latest,
    required this.onEdit,
  });

  final Map<String, MetricSample> latest;
  final void Function(String kind) onEdit;

  /// Bu kartta gösterilen türler ve sırası.
  static const kinds = [
    MetricKinds.waist,
    MetricKinds.belly,
    MetricKinds.pushupMax,
    MetricKinds.plankSec,
  ];

  /// Tam sayı gösterilecek türler — "6,0 tekrar" diye bir şey yok.
  static const _wholeNumberKinds = {
    MetricKinds.pushupMax,
    MetricKinds.plankSec,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppSection(
      title: 'Ölçümler',
      description: 'Ayda bir ölç; geçiş kriteri şınav sayısına bakıyor.',
      child: Card(
        child: Column(
          children: [
            for (final (index, kind) in kinds.indexed) ...[
              if (index > 0) const Divider(height: 1, indent: AppSpacing.lg),
              ListTile(
                key: Key('metric-$kind'),
                title: Text(MetricKinds.labelOf(kind)),
                subtitle: Text(
                  latest[kind] == null
                      ? 'henüz ölçülmedi'
                      : TurkishDate.isoToDayMonthYear(latest[kind]!.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: AppMetricValue(
                  value: latest[kind]?.value,
                  unit: MetricKinds.unitOf(kind),
                  fractionDigits: _wholeNumberKinds.contains(kind) ? 0 : 1,
                ),
                onTap: () => onEdit(kind),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
