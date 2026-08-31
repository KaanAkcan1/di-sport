import 'package:disport/app/theme/app_color_schemes.dart';
import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/design/app_palette.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contrast_test.dart' show contrastRatio;

/// M12 mürekkep dilinin sözleşmesi.
///
/// Bu testler estetik tercihi değil, **kararı** koruyor: kullanıcı beyaz
/// kart dilini açıkça reddetti ("yapay zekâi"), zemin Vue laciverti
/// oldu ve ayrım gölgeden ton + kıl çizgiye taşındı. Biri ileride
/// gölgeyi geri getirir ya da zemini beyaza çekerse burası düşer.
void main() {
  group('mürekkep şeması', () {
    const dark = AppColorSchemes.dark;

    test('zemin mürekkep laciverti', () {
      expect(dark.surface, AppPalette.ink850);
      expect(dark.surfaceContainerLow, AppPalette.ink900);
      expect(dark.surfaceContainerHigh, AppPalette.ink800);
    });

    test('vurgu Vue işaret yeşilinin kendisi', () {
      // brand300 değil brand400: mürekkep üstünde işaret yeşili okunuyor
      // (6.4:1) ve "yeşili göremiyorum" şikâyeti burada kapanıyor.
      expect(dark.primary, AppPalette.brand400);
    });

    test('gölge yok — ayrım ton ve çizgiyle', () {
      // Mürekkep dilinin tanımlayıcı kuralı (spec §2a.2).
      expect(dark.shadow.a, 0);
      expect(AppColorSchemes.light.shadow.a, 0);
    });

    test('açık şemada saf beyaz katman kalmadı', () {
      // Tek bir #FFFFFF yüzey "beyaz kart" görünümünü geri getirirdi.
      const white = Color(0xFFFFFFFF);
      for (final (name, c) in [
        ('surface', AppColorSchemes.light.surface),
        ('surfaceContainerLowest', AppColorSchemes.light.surfaceContainerLowest),
        ('surfaceContainerLow', AppColorSchemes.light.surfaceContainerLow),
        ('surfaceContainer', AppColorSchemes.light.surfaceContainer),
        ('surfaceContainerHigh', AppColorSchemes.light.surfaceContainerHigh),
      ]) {
        expect(c, isNot(white), reason: 'açık şema $name saf beyaz');
      }
    });
  });

  group('birleştirme kararı iki modda da geçerli', () {
    test('açık modda başarı = marka', () {
      expect(
        AppSemanticColors.light.success,
        AppTheme.light.colorScheme.primary,
      );
    });

    test('koyu modda başarı = marka', () {
      // M6'da yalnız açık mod için sabitlenmişti; mürekkep dilinde
      // primary brand400'e taşınınca koyu modda iki yakın yeşil
      // doğuyordu (brand300 vs brand400). Birleştirme burada da geçerli.
      expect(
        AppSemanticColors.dark.success,
        AppTheme.dark.colorScheme.primary,
      );
    });
  });

  group('takvim ton dolguları', () {
    // Takvim hücresi renkle hızlandırır ama anlamı **rakam** taşır
    // (spec §2a: renk tek başına anlam taşımaz). Dolayısıyla dolgunun
    // üstündeki rakam okunabilir olmak zorunda.
    const sem = AppSemanticColors.dark;

    test('bütçe altı dolgusunda yeşil rakam okunur (3:1)', () {
      expect(
        contrastRatio(sem.success, sem.successSurface),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('bütçe üstü dolgusunda kızıl rakam okunur (3:1)', () {
      expect(
        contrastRatio(sem.danger, sem.dangerSurface),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('iki dolgu birbirinden ayrışır', () {
      expect(sem.successSurface, isNot(sem.dangerSurface));
    });
  });

  group('kıl çizgi', () {
    test('ayraç kenarlıktan ayrı bir renk', () {
      // Aynı olsalardı liste ızgaraya dönerdi: satır ayracı ile kart
      // kenarlığı farklı ağırlıkta olmalı.
      expect(
        AppSemanticColors.dark.hairline,
        isNot(AppColorSchemes.dark.outline),
      );
    });

    test('görünür ama veriyle yarışmaz', () {
      final ratio = contrastRatio(
        AppSemanticColors.dark.hairline,
        AppColorSchemes.dark.surface,
      );
      expect(ratio, greaterThan(1.1), reason: 'çizgi görünmüyor');
      expect(ratio, lessThan(2.0), reason: 'çizgi fazla baskın');
    });
  });
}
