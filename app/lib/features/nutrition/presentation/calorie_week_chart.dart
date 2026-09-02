import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Son yedi günün net kalorisi, hedef çizgisiyle.
///
/// **Çubuk, çizgi değil:** kalori günlük bir toplam, sürekli bir ölçüm
/// değil. Çizgi grafiği günler arasında olmayan bir süreklilik ima
/// eder; kilo grafiğinde doğru olan burada yanlış.
///
/// Hedefi aşan gün tehlike tonuna dönüyor ve **hedef çizgisi her zaman
/// çiziliyor** — renk tek başına anlam taşımasın diye çubuğun nereyi
/// geçtiği görünür olmalı.
class CalorieWeekChart extends ConsumerWidget {
  const CalorieWeekChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final todayIso = ref.watch(todayIsoProvider);
    final today = DateTime.parse(todayIso);
    final from = today.subtract(const Duration(days: 6));

    final goal = ref.watch(dailyKcalGoalProvider).value;
    final net =
        ref
            .watch(
              netKcalByDayProvider(
                PlanRepository.iso(from),
                PlanRepository.iso(today),
              ),
            )
            .value ??
        const <String, double>{};

    final days = [
      for (var back = 6; back >= 0; back--)
        today.subtract(Duration(days: back)),
    ];

    // Hiç öğün girilmemişse bölüm **hiç çizilmiyor**. Kullanmadığı bir
    // özellik için boş durum göstermek, kilo grafiğinin üstünü
    // gereksiz doldurup asıl içeriği aşağı iterdi — boş durum bir şey
    // eksik olduğunda anlamlı, hiç başlanmamışken değil.
    if (net.isEmpty) return const SizedBox.shrink();

    final values = [
      for (final day in days) net[PlanRepository.iso(day)] ?? 0.0,
    ];
    // Üst sınır hedefi de kapsıyor: hedef çizgisi grafiğin dışında
    // kalırsa kullanıcı ne kadar altında olduğunu göremez.
    final maxY =
        [...values, (goal ?? 0).toDouble()].reduce((a, b) => a > b ? a : b) *
        1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(context.l10n.progressCaloriesTitle),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY <= 0 ? 100 : maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        TurkishDate.weekdayInitial(days[index]),
                        style: AppTypography.statCaption.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: goal == null
                  ? const ExtraLinesData()
                  : ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: goal.toDouble(),
                          color: theme.colorScheme.onSurfaceVariant,
                          strokeWidth: 1,
                          dashArray: [4, 3],
                        ),
                      ],
                    ),
              barGroups: [
                for (var index = 0; index < values.length; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        width: 14,
                        borderRadius: AppRadius.smAll,
                        color: goal != null && values[index] > goal
                            ? semantic.danger
                            : theme.colorScheme.primary,
                      ),
                    ],
                  ),
              ],
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    '${rod.toY.round()} kcal',
                    theme.textTheme.labelSmall ?? const TextStyle(),
                  ),
                ),
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions) return;
                  final index = response?.spot?.touchedBarGroupIndex;
                  if (index == null) return;
                  _openBreakdown(context, ref, days[index]);
                },
              ),
            ),
          ),
        ),
        if (goal != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              '${context.l10n.progressCaloriesGoalLine}: $goal kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// Bir günün dökümü — hangi öğün ne kadardı.
  void _openBreakdown(BuildContext context, WidgetRef ref, DateTime day) {
    final isoDate = PlanRepository.iso(day);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final meals = ref.watch(dayMealsProvider(isoDate)).value ?? const [];
          final activities =
              ref.watch(dayActivitiesProvider(isoDate)).value ?? const [];

          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  context.l10n.progressDayBreakdown(
                    TurkishDate.weekdayAndDay(day),
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final entry in meals)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(mealKindIcon(entry.mealKind)),
                    title: Text(entry.foodName ?? entry.foodId),
                    subtitle: Text(mealKindLabel(context, entry.mealKind)),
                    trailing: Text('${entry.kcal.round()} kcal'),
                  ),
                for (final log in activities)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.directions_run),
                    title: Text(log.activityName ?? log.activityId),
                    subtitle: Text('${log.minutes} dk'),
                    trailing: Text('−${log.kcal.round()} kcal'),
                  ),
                if (meals.isEmpty && activities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(context.l10n.foodStartMessage),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
