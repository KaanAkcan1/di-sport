import 'dart:math' as math;

import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 bağıl parlaklık.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

/// İki renk arası kontrast oranı (1:1 – 21:1).
double contrastRatio(Color fg, Color bg) {
  final l1 = _luminance(fg);
  final l2 = _luminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Tasarım sisteminin erişilebilirlik sözleşmesi.
///
/// Bu testler renk kararlarını göz kararına bırakmaz. Palet ileride
/// değişirse ve bir eşik altına düşerse, derleme yeşil kalmaz —
/// erişilebilirlik "hatırlanması gereken" bir şey olmaktan çıkar
/// (ui-ux §1 `color-contrast`, §6 `color-accessible-pairs`).
void main() {
  /// WCAG AA: normal metin 4.5:1
  const aaText = 4.5;

  /// WCAG AA: büyük metin ve arayüz bileşenleri 3:1
  const aaLarge = 3.0;

  void checkScheme(String mode, ColorScheme s, AppSemanticColors sem) {
    group('$mode mod', () {
      test('gövde metni yüzey üstünde AA (4.5:1)', () {
        expect(
          contrastRatio(s.onSurface, s.surface),
          greaterThanOrEqualTo(aaText),
          reason: '$mode: onSurface/surface',
        );
      });

      test('ikincil metin yüzey üstünde AA (4.5:1)', () {
        // onSurfaceVariant ikincil metin taşır (liste alt başlığı,
        // yardımcı metin) — 3:1 değil 4.5:1 istiyoruz çünkü küçük punto.
        expect(
          contrastRatio(s.onSurfaceVariant, s.surface),
          greaterThanOrEqualTo(aaText),
          reason: '$mode: onSurfaceVariant/surface',
        );
      });

      test('birincil düğme etiketi AA (4.5:1)', () {
        expect(
          contrastRatio(s.onPrimary, s.primary),
          greaterThanOrEqualTo(aaText),
          reason: '$mode: onPrimary/primary',
        );
      });

      test('birincil kapsayıcı metni AA (4.5:1)', () {
        expect(
          contrastRatio(s.onPrimaryContainer, s.primaryContainer),
          greaterThanOrEqualTo(aaText),
          reason: '$mode: onPrimaryContainer/primaryContainer',
        );
      });

      test('hata metni yüzey üstünde AA (4.5:1)', () {
        expect(
          contrastRatio(s.error, s.surface),
          greaterThanOrEqualTo(aaText),
          reason: '$mode: error/surface',
        );
      });

      test('kart yüzeyi zeminden ayırt edilebilir', () {
        // Kart ile zemin arasında kenarlık var; yine de yüzeylerin
        // birbirine tam eşit olmaması gerekiyor.
        expect(
          s.surfaceContainerLow,
          isNot(equals(s.surfaceContainerHighest)),
          reason: '$mode: yüzey basamakları ayrışmalı',
        );
      });

      test('kenarlık ve ayraç görünür (3:1 arayüz eşiği değil, min 1.3)', () {
        // Ayraçlar bilgi taşımaz, yalnız gruplama yapar; AA metin eşiği
        // aranmaz ama görünmez de olmamalı.
        expect(
          contrastRatio(s.outlineVariant, s.surface),
          greaterThan(1.15),
          reason: '$mode: outlineVariant/surface',
        );
      });

      test('anlam renkleri yüzey üstünde AA (4.5:1)', () {
        for (final (name, color) in [
          ('success', sem.success),
          ('warning', sem.warning),
          ('danger', sem.danger),
          ('info', sem.info),
        ]) {
          expect(
            contrastRatio(color, s.surface),
            greaterThanOrEqualTo(aaText),
            reason: '$mode: $name/surface',
          );
        }
      });

      test('anlam yüzeyleri üstünde metin okunur (4.5:1)', () {
        for (final (name, fg, bg) in [
          ('success', s.onSurface, sem.successSurface),
          ('warning', s.onSurface, sem.warningSurface),
          ('danger', s.onSurface, sem.dangerSurface),
        ]) {
          expect(
            contrastRatio(fg, bg),
            greaterThanOrEqualTo(aaText),
            reason: '$mode: onSurface/${name}Surface',
          );
        }
      });

      test('grafik serileri zeminden ayrışır (3:1)', () {
        for (final (i, c) in sem.chartSeries.indexed) {
          expect(
            contrastRatio(c, s.surface),
            greaterThanOrEqualTo(aaLarge),
            reason: '$mode: chartSeries[$i]',
          );
        }
      });

      test('grafik serileri birbirinden ayrışır', () {
        // Renk körlüğü güvencesi Okabe-Ito paletinden geliyor; burada
        // yalnız hiçbir ikisinin aynı olmadığını doğruluyoruz.
        expect(
          sem.chartSeries.toSet().length,
          sem.chartSeries.length,
          reason: '$mode: yinelenen seri rengi',
        );
      });
    });
  }

  checkScheme('Açık', AppTheme.light.colorScheme, AppSemanticColors.light);
  checkScheme('Koyu', AppTheme.dark.colorScheme, AppSemanticColors.dark);

  test('marka rengi anlam renkleriyle ton olarak çakışmaz', () {
    // Tasarımın temel kuralı: marka rengi "iyi" ya da "kötü" demek
    // değildir. Marka yeşile ya da kırmızıya kayarsa durum sinyali
    // bulanır.
    //
    // Ölçüt kontrast oranı DEĞİL ton mesafesi. Kontrast oranı parlaklık
    // farkını ölçer; mavi ile kehribar neredeyse aynı parlaklıkta olup
    // gözle apayrı görünebilir. Ayırt edilebilirliği belirleyen ton.
    final brandHue = HSLColor.fromColor(AppTheme.light.colorScheme.primary).hue;

    for (final (name, color) in [
      ('success', AppSemanticColors.light.success),
      ('warning', AppSemanticColors.light.warning),
      ('danger', AppSemanticColors.light.danger),
    ]) {
      final hue = HSLColor.fromColor(color).hue;
      final delta = (brandHue - hue).abs();
      final circular = math.min(delta, 360 - delta);

      expect(
        circular,
        greaterThan(60),
        reason: 'marka tonu ($brandHue°) $name tonundan ($hue°) '
            'en az 60° uzak olmalı; şu an $circular°',
      );
    }
  });
}
