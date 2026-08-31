import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/progress/domain/weekly_summary.dart';
import 'package:flutter/material.dart';

/// Bir haftanın özet kartı.
class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({super.key, required this.week});

  final WeekSummary week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('week-${week.weekIndex}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hafta ${week.weekIndex}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (week.isPartial)
                  Text(
                    'sürüyor · ${week.dayCount} gün',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppMetricValue(
                  value: week.avgWeight,
                  unit: 'kg',
                  size: AppMetricSize.large,
                ),
                const SizedBox(width: AppSpacing.md),
                if (week.deltaFromPrevWeek case final delta?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _DeltaChip(delta: delta),
                  ),
              ],
            ),
            Text(
              'haftalık ortalama',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (week.gymTarget > 0)
                  _CountChip(
                    label: 'Salon',
                    done: week.gymDone,
                    target: week.gymTarget,
                    partial: week.isPartial,
                  ),
                if (week.homeTarget > 0)
                  _CountChip(
                    label: 'Ev',
                    done: week.homeDone,
                    target: week.homeTarget,
                    partial: week.isPartial,
                  ),
                AppStatusChip(
                  status: week.slipDays == 0
                      ? AppStatus.good
                      : week.slipDays > 2
                      ? AppStatus.bad
                      : AppStatus.caution,
                  label: week.slipDays == 0
                      ? 'Kaçak yok'
                      : '${week.slipDays} kaçak gün',
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    // Kilo verme hedefi olduğu için **azalma** iyidir. Bu, uygulamadaki
    // tek ters yönlü eksen; başka yerde "aşağı = iyi" varsayılmıyor.
    final status = delta < -0.05
        ? AppStatus.good
        : delta > 0.05
        ? AppStatus.caution
        : AppStatus.unknown;

    return AppStatusChip(
      status: status,
      label: '${TurkishNumber.formatDelta(delta)} kg',
      compact: true,
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.done,
    required this.target,
    required this.partial,
  });

  final String label;
  final int done;
  final int target;
  final bool partial;

  @override
  Widget build(BuildContext context) {
    // Süren hafta hedefin altındaysa bu bir başarısızlık değil; henüz
    // bitmemiş. O yüzden yarım haftada "kötü" gösterilmiyor.
    final status = done >= target
        ? AppStatus.good
        : partial
        ? AppStatus.unknown
        : done >= target - 1
        ? AppStatus.caution
        : AppStatus.bad;

    return AppStatusChip(
      status: status,
      label: '$label $done / $target',
      compact: true,
    );
  }
}
