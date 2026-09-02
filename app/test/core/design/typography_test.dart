import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tipografi', () {
    test('tüm Material 3 tip rolleri doldurulmuş', () {
      // Eksik bırakılan rol Flutter varsayılanına düşer ve font ailesi
      // sessizce tutarsızlaşır.
      final t = AppTypography.textTheme;
      final roles = <String, TextStyle?>{
        'displayLarge': t.displayLarge,
        'displayMedium': t.displayMedium,
        'displaySmall': t.displaySmall,
        'headlineLarge': t.headlineLarge,
        'headlineMedium': t.headlineMedium,
        'headlineSmall': t.headlineSmall,
        'titleLarge': t.titleLarge,
        'titleMedium': t.titleMedium,
        'titleSmall': t.titleSmall,
        'bodyLarge': t.bodyLarge,
        'bodyMedium': t.bodyMedium,
        'bodySmall': t.bodySmall,
        'labelLarge': t.labelLarge,
        'labelMedium': t.labelMedium,
        'labelSmall': t.labelSmall,
      };
      for (final entry in roles.entries) {
        expect(entry.value, isNotNull, reason: '${entry.key} tanımsız');
      }
    });

    test('gövde metni mobilde 16px, satır yüksekliği 1.5', () {
      // 16px altı gövde metni iOS'ta otomatik yakınlaştırmayı tetikler
      // ve okunabilirliği düşürür (ui-ux §5 `readable-font-size`).
      final body = AppTypography.textTheme.bodyLarge!;
      expect(body.fontSize, 16);
      expect(body.height, closeTo(1.5, 0.01));
    });

    test('hiçbir metin 11px altında değil', () {
      for (final s in [
        AppTypography.textTheme.bodySmall,
        AppTypography.textTheme.labelSmall,
      ]) {
        expect(s!.fontSize, greaterThanOrEqualTo(11));
      }
    });

    test('sayısal stiller tablo rakamları kullanır', () {
      // Alt alta dizilen kilo/tahlil değerlerinin kaymaması için
      // (ui-ux §6 `number-tabular`).
      for (final s in [
        AppTypography.metricLarge,
        AppTypography.metricMedium,
        AppTypography.metricSmall,
      ]) {
        expect(
          s.fontFeatures?.any((f) => f.feature == 'tnum'),
          isTrue,
          reason: 'tabular figures eksik',
        );
      }
    });

    test('ağırlık hiyerarşisi: başlıklar gövdeden kalın', () {
      expect(
        AppTypography.textTheme.titleMedium!.fontWeight!.value,
        greaterThan(AppTypography.textTheme.bodyMedium!.fontWeight!.value),
      );
    });

    test('tema Inter ailesini her iki modda uygular', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.textTheme.bodyLarge?.fontFamily, 'Inter');
        expect(theme.textTheme.titleLarge?.fontFamily, 'Inter');
      }
    });
  });

  group('Ölçüler', () {
    test('boşluk ölçeği 4dp ritminde', () {
      for (final v in [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl2,
        AppSpacing.xl3,
        AppSpacing.xl4,
      ]) {
        expect(v % 4, 0, reason: '$v 4dp ritmine uymuyor');
      }
    });

    test('dokunma hedefi hem Apple hem Material asgarisini karşılar', () {
      // Apple 44pt, Material 48dp — büyük olan alınır.
      expect(AppTouch.minSize, greaterThanOrEqualTo(48));
    });

    test('çıkış animasyonu girişten kısa', () {
      // ui-ux §7 `exit-faster-than-enter`
      expect(AppMotion.exit, lessThan(AppMotion.base));
    });

    test('mikro etkileşimler 150-300ms bandında', () {
      expect(AppMotion.base.inMilliseconds, inInclusiveRange(150, 300));
      expect(AppMotion.slow.inMilliseconds, lessThanOrEqualTo(400));
    });
  });

  group('Bileşen temaları', () {
    test('düğmeler asgari dokunma yüksekliğini zorlar', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final size = theme.filledButtonTheme.style?.minimumSize
            ?.resolve({});
        expect(size?.height, greaterThanOrEqualTo(AppTouch.minSize));
      }
    });

    test('gezinme etiketleri her zaman görünür', () {
      // Yalnız ikonlu gezinme keşfedilebilirliği düşürür
      // (ui-ux §9 `nav-label-icon`).
      expect(
        AppTheme.light.navigationBarTheme.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
      );
    });

    test('modal perdesi ön planı yalıtacak güçte (>= %40 siyah)', () {
      // ui-ux: scrim 40-60% black
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.colorScheme.scrim.a, greaterThanOrEqualTo(0.4));
      }
    });

    test('kartların kenarlığı her iki modda tanımlı', () {
      // Tema-özgü kenarlık tek modda kaybolursa hiyerarşi çöker.
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final shape = theme.cardTheme.shape as RoundedRectangleBorder?;
        expect(shape?.side.style, BorderStyle.solid);
      }
    });
  });
}
