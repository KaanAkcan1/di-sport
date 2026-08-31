import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:flutter/material.dart';

/// Metrik şeridindeki tek değer.
class AppMetric {
  const AppMetric({
    required this.caption,
    this.value,
    this.unit,
    this.delta,
    this.deltaPositive = true,
    this.accent = false,
  });

  /// Değerin üstündeki küçük büyük harf etiket — "KİLO", "PROTEİN".
  final String caption;

  /// Biçimlenmiş değer; `null` ise `—` çizilir.
  final String? value;

  /// Değerin hemen ardındaki küçük birim — "/140 g", "kcal".
  final String? unit;

  /// Değişim miktarı — "0,4". Yön işareti [deltaPositive]'ten gelir.
  final String? delta;

  /// Değişim iyi yönde mi. Kilo takibinde **azalma** iyidir; bu yüzden
  /// karar burada değil çağrı yerinde verilir — widget "aşağı ok = iyi"
  /// diye bir kural bilmez.
  final bool deltaPositive;

  /// Değer marka renginde vurgulansın mı.
  final bool accent;
}

/// Kahraman rakamın altındaki tek satır metrik şeridi.
///
/// [AppStatBand]'in ikinci yarısı. Şerit koyu bir kutuydu ve üç sayıyı
/// eşit ağırlıkta gösteriyordu; mürekkep dilinde ekranın kendisi koyu
/// olduğu için kutuya gerek kalmadı — sayılar doğrudan yüzeyde duruyor.
class AppMetricStrip extends StatelessWidget {
  const AppMetricStrip(this.metrics, {super.key});

  final List<AppMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, metric) in metrics.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xl),
          Flexible(child: _MetricColumn(metric: metric)),
        ],
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.metric});

  final AppMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final empty = metric.value == null;

    // Etiket rengi `onSurfaceVariant`: ham palet sabiti yazmak yasak
    // (CLAUDE.md kural 7) ve daha sönük bir ton kontrast eşiğinin
    // altına düşüyordu.
    final captionColor = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label: empty
          ? '${metric.caption}: girilmedi'
          : '${metric.caption}: ${metric.value}'
                '${metric.unit == null ? '' : ' ${metric.unit}'}'
                '${metric.delta == null ? '' : ', değişim ${metric.delta}'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TurkishText.upper(metric.caption),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.statCaption.copyWith(
              color: captionColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.value ?? '—',
                  maxLines: 1,
                  style: AppTypography.metricSmall.copyWith(
                    fontSize: 20,
                    color: empty
                        ? captionColor
                        : metric.accent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (metric.unit case final u? when !empty)
                  Text(
                    u,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: captionColor,
                    ),
                  ),
                if (metric.delta case final d? when !empty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    // Renk tek başına anlam taşımaz: ok işareti yönü
                    // renkten bağımsız söylüyor (spec §2a.4).
                    '${metric.deltaPositive ? '▾' : '▴'}$d',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: metric.deltaPositive
                          ? semantic.success
                          : semantic.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
