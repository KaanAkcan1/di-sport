import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Ekranın kahraman rakamı — M12'nin merkezi öğesi.
///
/// M6'nın `AppStatBand`'inin halefi (o sınıf M12'de silindi). Şerit üç
/// sayıyı eşit ağırlıkta gösteriyordu
/// ve ekranın "en önemli sayısı" diye bir şey yoktu; göz üçü tarayıp
/// hangisine bakacağına karar vermek zorunda kalıyordu. Burada tek bir
/// sayı var, geri kalanı [AppMetricStrip]'e iniyor.
///
/// [gaugeFraction] verilirse altında ince bir ilerleme çubuğu çizilir.
/// 1'i aşan değer kırpılmaz — çubuk dolar **ve** danger tonuna döner:
/// bütçe aşımı susturulacak değil söylenecek bir şey.
class AppHeroNumber extends StatelessWidget {
  const AppHeroNumber({
    super.key,
    required this.caption,
    this.value,
    this.unit,
    this.gaugeFraction,
    this.accent = true,
  });

  /// Sayının altındaki tek satır açıklama — "kcal kaldı · 2 100 bütçe".
  final String caption;

  /// Biçimlenmiş değer. `null` meşru bir durum: "henüz tartılmadı".
  /// Yer tutucu (`—`) çizilir ve küçülür; `0` ile asla karışmaz.
  final String? value;

  final String? unit;

  /// 0..1 aralığında ilerleme. `null` ise çubuk hiç çizilmez —
  /// hedefi olmayan bir sayının doluluk oranı da yoktur.
  final double? gaugeFraction;

  /// Sayı marka renginde mi, yoksa nötr metin renginde mi. Kalan kalori
  /// gibi "iyi gidiyor" sinyali taşıyanlar markalı; nötr ölçümler değil.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final empty = value == null;
    final over = (gaugeFraction ?? 0) > 1;

    final numberColor = switch (null) {
      _ when empty => theme.colorScheme.onSurfaceVariant,
      _ when over => semantic.danger,
      _ when accent => theme.colorScheme.primary,
      _ => theme.colorScheme.onSurface,
    };

    return Semantics(
      label: empty
          ? context.l10n.commonMetricEmptySemantics(caption)
          : context.l10n.commonHeroValueSemantics(
              '$value${unit == null ? '' : ' $unit'}',
              caption,
            ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Kısaltma değil küçültme: "2 410" kesilip "2..." olursa
              // sayı bilgi taşımaz hâle gelir.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value ?? '—',
                    maxLines: 1,
                    style: empty
                        // Yer tutucu küçülüp soluyor: 56 puntoluk bir
                        // tire "kcal" ile yan yana kırık değer gibi
                        // okunuyordu.
                        ? AppTypography.metricLarge.copyWith(
                            color: numberColor,
                          )
                        : AppTypography.metricHero.copyWith(
                            color: numberColor,
                          ),
                  ),
                ),
              ),
              // Birim yalnız değer varken: "— kcal" bir ölçüm değil.
              if (unit case final u? when !empty) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  u,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (gaugeFraction case final f?) ...[
            const SizedBox(height: AppSpacing.md),
            _Gauge(fraction: f, over: over),
          ],
        ],
      ),
    );
  }
}

/// İnce ilerleme çubuğu — kahramanın altındaki tek çizgi.
///
/// `LinearProgressIndicator` yerine elle çiziliyor çünkü aşım
/// durumunda hem dolması hem renk değiştirmesi gerekiyor ve
/// Material'ınki değeri 1'de kırpıyor.
class _Gauge extends StatelessWidget {
  const _Gauge({required this.fraction, required this.over});

  final double fraction;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: [
            ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const SizedBox.expand(),
            ),
            FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0),
              child: ColoredBox(
                color: over ? semantic.danger : theme.colorScheme.primary,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
