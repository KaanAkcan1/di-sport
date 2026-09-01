import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Sayı gösteriminin boyutu.
enum AppMetricSize { large, medium, small }

/// Sayı + birim gösterimi.
///
/// Uygulamanın esas içeriği sayı: kilo, set × tekrar, tahlil değeri,
/// plank süresi. Bunları her ekranda elle `Text('$v kg')` diye yazmak
/// üç sorun doğurur: rakamlar tablo rakamı olmaz ve alt alta kayar,
/// birim bazen kalın bazen ince olur, ondalık ayracı bazen nokta bazen
/// virgül gelir. Burada üçü de tek yerde çözülür.
///
/// Türkçe biçimlendirme: ondalık ayracı virgül.
class AppMetricValue extends StatelessWidget {
  const AppMetricValue({
    super.key,
    required this.value,
    this.unit,
    this.size = AppMetricSize.medium,
    this.fractionDigits = 1,
    this.color,
    this.placeholder = '—',
  });

  /// Gösterilecek sayı. `null` ise [placeholder] çizilir — "veri yok"
  /// ile "sıfır" görsel olarak asla karışmamalı.
  final num? value;

  final String? unit;
  final AppMetricSize size;

  /// Ondalık basamak sayısı. Tam sayı metrikler (şınav tekrarı, set)
  /// için 0 verilir.
  final int fractionDigits;

  final Color? color;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective = color ?? theme.colorScheme.onSurface;

    final numberStyle = switch (size) {
      AppMetricSize.large => AppTypography.metricLarge,
      AppMetricSize.medium => AppTypography.metricMedium,
      AppMetricSize.small => AppTypography.metricSmall,
    }.copyWith(color: effective, fontFamily: AppTypography.fontFamily);

    final unitStyle = AppTypography.unit.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFamily: AppTypography.fontFamily,
    );

    final text = value == null ? placeholder : _format(value!);

    return Semantics(
      label: value == null
          ? context.l10n.commonValueMissing
          : '$text${unit == null ? '' : ' $unit'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(text, style: numberStyle),
          if (unit case final u?) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(u, style: unitStyle),
          ],
        ],
      ),
    );
  }

  String _format(num v) {
    final fixed = v.toStringAsFixed(fractionDigits);
    // Türkçede ondalık ayracı virgüldür. `intl` paketi eklemek yerine
    // tek karakter değişimi yeterli: bu uygulamada yalnız tek dil var
    // ve binlik ayracı gerektiren büyüklükte sayı yok.
    return fixed.replaceAll('.', ',');
  }
}
