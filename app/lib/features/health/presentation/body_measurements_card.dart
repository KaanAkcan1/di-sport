import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/health/data/metric_definitions_repository.dart';
import 'package:flutter/material.dart';

/// Dönemsel ölçümlerin son değerleri.
///
/// Kilo ve uyku burada yok: onlar her gün Bugün ekranından giriliyor
/// (`MetricDefinition.isDaily`). Buradakiler seyrek ölçülenler — bel,
/// göbek, şınav maksimumu, plank ve kullanıcının kendi eklediği türler.
/// İkisini aynı yere koymak günlük girişi seyrek ekranın arkasına
/// gömerdi.
class BodyMeasurementsCard extends StatelessWidget {
  const BodyMeasurementsCard({
    super.key,
    required this.definitions,
    required this.latest,
    required this.onEdit,
    required this.onManage,
  });

  final List<MetricDefinition> definitions;
  final Map<String, MetricSample> latest;
  final void Function(MetricDefinition definition) onEdit;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppSection(
      title: l10n.healthMeasurementsTitle,
      description: l10n.healthMeasurementsDescription,
      action: IconButton(
        key: const Key('manage-metrics-button'),
        icon: const Icon(Icons.tune),
        tooltip: l10n.healthManageMetricsTooltip,
        onPressed: onManage,
      ),
      child: definitions.isEmpty
          ? Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: AppEmptyState(
                  icon: Icons.straighten,
                  title: l10n.healthNoMetricsTitle,
                  description: l10n.healthNoMetricsDescription,
                ),
              ),
            )
          : Card(
              child: Column(
                children: [
                  for (final (index, definition) in definitions.indexed) ...[
                    if (index > 0)
                      const Divider(height: 1, indent: AppSpacing.lg),
                    ListTile(
                      key: Key('metric-${definition.kind}'),
                      title: Text(definition.label),
                      subtitle: Text(
                        latest[definition.kind] == null
                            ? l10n.healthMetricNeverMeasured
                            : TurkishDate.isoToDayMonthYear(
                                latest[definition.kind]!.date,
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: AppMetricValue(
                        value: latest[definition.kind]?.value,
                        unit: definition.unit,
                        fractionDigits: definition.decimals,
                      ),
                      onTap: () => onEdit(definition),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
