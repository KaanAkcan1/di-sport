import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/progress/application/progress_providers.dart';
import 'package:disport/features/progress/presentation/transition_card.dart';
import 'package:disport/features/progress/presentation/week_summary_card.dart';
import 'package:disport/features/progress/presentation/weight_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// İlerleme sekmesi: kilo eğilimi, haftalık özet, geçiş ölçütleri.
///
/// Yukarıdan aşağı sıralama "ne kadar yol aldım" sorusunun cevabından
/// "sırada ne var"a doğru gidiyor.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(progressViewProvider);

    return AppAsyncView<ProgressViewData>(
      value: view,
      onRetry: () => ref.invalidate(progressViewProvider),
      emptyWhen: (data) => data.isEmpty,
      empty: const AppEmptyState(
        icon: Icons.show_chart,
        title: 'Henüz gösterecek bir şey yok',
        description: 'Bugün sekmesinden tartını gir; birkaç gün sonra '
            'eğilim çizgisi anlamlı olmaya başlar.',
      ),
      data: (data) => AppScreenBody(
        children: [
          if (data.weights.isNotEmpty)
            AppSection(
              title: 'Kilo',
              description: 'Kalın çizgi 7 günlük ortalama — günlük '
                  'oynamalar su ve tuzdur, eğilime bak.',
              child: WeightChart(points: data.weights, trend: data.trend),
            ),

          if (data.weeks.isNotEmpty)
            AppSection(
              title: 'Haftalar',
              child: Column(
                children: [
                  for (final week in data.weeks) WeekSummaryCard(week: week),
                ],
              ),
            )
          else if (!data.hasPlan)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl2),
              child: AppEmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'Haftalık özet için plan gerekli',
                description: 'Hangi günün salon, hangisinin ev olduğunu '
                    'plandan okuyorum. Plan sekmesinden bir program yükle.',
              ),
            ),

          TransitionCard(
            criteria: data.criteria,
            latestWeight: data.latestMetrics[MetricKinds.weight]?.value,
            latestPushupMax:
                data.latestMetrics[MetricKinds.pushupMax]?.value,
            onPainFreeChanged: (value) =>
                ref.read(setPainFreeConfirmedProvider)(value),
          ),
        ],
      ),
    );
  }
}
