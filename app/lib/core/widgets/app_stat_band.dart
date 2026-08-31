import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:flutter/material.dart';

/// İstatistik şeridindeki tek sayı.
class AppStat {
  const AppStat({
    required this.caption,
    this.value,
    this.unit,
    this.text,
    this.fractionDigits = 1,
    this.tone,
  });

  /// Sayının altındaki küçük büyük harf etiket — "KİLO", "SERİ".
  final String caption;

  /// Sayısal değer.
  ///
  /// `null` meşru bir durum: "henüz tartılmadı". Yer tutucu (`—`)
  /// çizilir — `0` ile "veri yok" görsel olarak asla karışmamalı.
  final num? value;
  final String? unit;

  /// Sayı yerine kısa metin — "3 / 5" gibi zaten biçimlenmiş değerler.
  /// Verilirse [value]'nun önüne geçer.
  final String? text;

  final int fractionDigits;

  /// Vurgu rengi; verilmezse şeridin varsayılan metin rengi.
  final Color? tone;
}

/// Ekranın tepesindeki koyu istatistik şeridi.
///
/// **Neden var:** v1'de her ekran aynı düzlemde başlıyordu — bir sıra
/// beyaz kart, hiçbiri diğerinden ağır değil. Göz nereye bakacağını
/// bilmiyordu ve ekran "karaktersiz" görünüyordu. Şerit ekrana bir
/// ağırlık merkezi veriyor: kullanıcı açtığında önce buraya bakıyor,
/// günün özetini bir bakışta alıyor.
///
/// **Neden koyu:** lacivert yüzey beyaz kartlardan kesin olarak
/// ayrışıyor ve altındaki içeriği "ikincil" konuma yerleştiriyor.
/// Aynı işi açık renkli bir kart yapamazdı — beyaz üstünde beyaz.
///
/// Sayılar sıkışık aileyle: üç sayı yan yana ancak böyle sığıyor ve
/// tablo rakamı sayesinde değer değişince genişlik kaymıyor.
class AppStatBand extends StatelessWidget {
  const AppStatBand({
    super.key,
    required this.title,
    required this.stats,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final List<AppStat> stats;

  /// Sağ üstte ikincil eylem.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBand = theme.colorScheme.onInverseSurface;
    final mutedOnBand = onBand.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: AppRadius.xlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onBand,
                        ),
                      ),
                    ),
                    if (subtitle case final text?) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedOnBand,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?action,
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (index, stat) in stats.indexed) ...[
                  if (index > 0)
                    // Ayraç sayıları gruplamak yerine ayırıyor; boşluk
                    // tek başına üç sayıyı "tek bir uzun sayı" gibi
                    // okutabiliyordu.
                    Container(
                      width: AppBorder.hairline,
                      height: 32,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      color: onBand.withValues(alpha: 0.18),
                    ),
                  Flexible(
                    child: _StatColumn(
                      stat: stat,
                      valueColor: stat.tone ?? onBand,
                      captionColor: mutedOnBand,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.stat,
    required this.valueColor,
    required this.captionColor,
  });

  final AppStat stat;
  final Color valueColor;
  final Color captionColor;

  @override
  Widget build(BuildContext context) {
    final empty = stat.text == null && stat.value == null;
    final shown =
        stat.text ??
        (stat.value == null
            ? '—'
            : TurkishNumber.format(
                stat.value!.toDouble(),
                fractionDigits: stat.fractionDigits,
              ));

    return Semantics(
      label: empty
          ? '${stat.caption}: girilmedi'
          : '${stat.caption}: $shown${stat.unit == null ? '' : ' ${stat.unit}'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kısaltma değil küçültme: "109,4" kesilip "1..." olursa
              // sayı bilgi taşımaz hâle gelir. Dar sütunda punto
              // düşüyor, rakam tam kalıyor.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    shown,
                    maxLines: 1,
                    // Değer yokken yer tutucu küçülüp soluyor: 48
                    // puntoluk bir tire "kg" ile yan yana durunca kırık
                    // bir değer gibi okunuyordu.
                    style: empty
                        ? AppTypography.metricMedium.copyWith(
                            color: captionColor,
                          )
                        : AppTypography.metricLarge.copyWith(
                            color: valueColor,
                          ),
                  ),
                ),
              ),
              // Birim yalnız değer varken: "— kg" bir ölçüm değil.
              if (stat.unit case final u? when !empty) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  u,
                  style: AppTypography.unit.copyWith(color: captionColor),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            // Dart'ın `toUpperCase()`'i değil: "Kilo" → "KILO" verirdi
            // ve bu Türkçede "kılo" okunur.
            TurkishText.upper(stat.caption),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.statCaption.copyWith(color: captionColor),
          ),
        ],
      ),
    );
  }
}
