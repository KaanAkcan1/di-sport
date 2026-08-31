import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/features/progress/domain/weight_trend.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Kilo grafiği: soluk günlük noktalar + kalın hareketli ortalama.
///
/// İki seri olmasının nedeni spec 6'daki kural: kullanıcı günlük rakama
/// tepki vermemeli. Ham veri gizlenmiyor (kullanıcı kendi kaydını
/// görmeli) ama görsel ağırlık eğilimde — göz önce kalın çizgiyi
/// okuyor.
class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.points,
    required this.trend,
  });

  final List<WeightPoint> points;
  final List<TrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final values = [
      for (final point in points) point.value,
      for (final point in trend) point.avg,
    ];
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    // Eksen verinin tam sınırına oturursa uç noktalar kenara yapışır.
    // Aralık çok darsa (tek gün, ya da sabit kilo) yapay bir açıklık
    // veriliyor; yoksa fl_chart sıfır yükseklikli eksen çizer.
    final span = (maxValue - minValue).abs();
    final pad = span < 1 ? 1.0 : span * 0.15;

    return Semantics(
      label:
          'Kilo grafiği. ${points.length} ölçüm. '
          'İlk ${TurkishNumber.format(points.first.value)} kilogram, '
          'son ${TurkishNumber.format(points.last.value)} kilogram.',
      excludeSemantics: true,
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: minValue - pad,
            maxY: maxValue + pad,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: semantic.chartGrid, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) => Text(
                    TurkishNumber.format(value, fractionDigits: 0),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  // Her noktaya etiket koymak okunmaz bir şerit yapar;
                  // beş etiket eksende yön vermeye yetiyor.
                  interval: (points.length / 5).ceilToDouble().clamp(1, 999),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    final date = DateTime.tryParse(points[index].date);
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        date == null
                            ? ''
                            : '${date.day} '
                                  '${TurkishDate.monthsShort[date.month - 1]}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${TurkishNumber.format(spot.y)} kg',
                      theme.textTheme.labelMedium ?? const TextStyle(),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              // Ham veri önce çiziliyor: eğilim çizgisi üstte kalsın.
              LineChartBarData(
                spots: [
                  for (final (index, point) in points.indexed)
                    FlSpot(index.toDouble(), point.value),
                ],
                color: semantic.chartMuted,
                barWidth: 1,
                dotData: FlDotData(
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 2,
                    color: semantic.chartMuted,
                    strokeWidth: 0,
                  ),
                ),
              ),
              LineChartBarData(
                spots: [
                  for (final (index, point) in trend.indexed)
                    FlSpot(index.toDouble(), point.avg),
                ],
                color: semantic.chartSeries.first,
                barWidth: 3,
                isCurved: true,
                // Eğri yumuşatma abartılırsa veri olmayan yerde tepe
                // uydurur; 0.2 yalnız köşeleri yuvarlıyor.
                curveSmoothness: 0.2,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
