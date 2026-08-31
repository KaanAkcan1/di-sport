import 'package:disport/core/design/app_palette.dart';
import 'package:flutter/material.dart';

/// Açık ve koyu renk şemaları.
///
/// `ColorScheme.fromSeed` yerine açık tanım: tohumdan üretim hızlı bir
/// başlangıç sağlar ama üretilen tonlar üstünde denetim bırakmaz. Bu
/// uygulamada renk anlam taşıdığı için (tahlil referans aralığı, kaçak
/// gün) her tonun bilinçli seçilmesi gerekiyor.
abstract final class AppColorSchemes {
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.brand700,
    onPrimary: AppPalette.neutral0,
    primaryContainer: AppPalette.brand100,
    onPrimaryContainer: AppPalette.brand900,
    secondary: AppPalette.neutral600,
    onSecondary: AppPalette.neutral0,
    secondaryContainer: AppPalette.neutral100,
    onSecondaryContainer: AppPalette.neutral800,
    tertiary: AppPalette.brand400,
    onTertiary: AppPalette.neutral0,
    error: AppPalette.dangerLight,
    onError: AppPalette.neutral0,
    errorContainer: AppPalette.dangerSurfaceLight,
    onErrorContainer: Color(0xFF7F1D1D),
    // Kart beyaz, zemin bir ton koyu. v1'de ikisi de neredeyse beyazdı
    // (1.02:1) ve kartlar kaybolurdu; asıl "soluk görünüyor" şikâyeti
    // buradan geliyordu.
    surface: AppPalette.neutral0,
    onSurface: AppPalette.inkStrong,
    onSurfaceVariant: AppPalette.neutral600,
    surfaceContainerLowest: AppPalette.neutral0,
    surfaceContainerLow: AppPalette.neutral0,
    surfaceContainer: AppPalette.neutral100,
    surfaceContainerHigh: AppPalette.neutral200,
    surfaceContainerHighest: AppPalette.neutral300,
    outline: AppPalette.neutral300,
    outlineVariant: AppPalette.neutral200,
    // Mürekkep yüzeyi: başlık şeritleri ve istatistik blokları.
    inverseSurface: AppPalette.ink,
    onInverseSurface: AppPalette.neutral0,
    inversePrimary: AppPalette.brand300,
    scrim: Color(0x99000000), // %60 — ön planı yalıtacak güçte
    // Gölge lacivert tonlu: nötr siyah gölge yeşil/lacivert bir arayüzde
    // kirli görünüyor.
    shadow: Color(0x1F213547),
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    // Koyu modda marka rengi ters çevrilmiyor, açık tonu alınıyor:
    // koyu zeminde doygun mavi hem okunmaz hem gözü yorar
    // (ui-ux §6 `color-dark-mode`).
    primary: AppPalette.brand300,
    onPrimary: AppPalette.neutral950,
    primaryContainer: AppPalette.brandContainerDark,
    onPrimaryContainer: AppPalette.brand100,
    secondary: AppPalette.neutral400,
    onSecondary: AppPalette.neutral950,
    secondaryContainer: AppPalette.neutral800,
    onSecondaryContainer: AppPalette.neutral100,
    tertiary: AppPalette.brand300,
    onTertiary: AppPalette.neutral950,
    error: AppPalette.dangerDark,
    onError: AppPalette.neutral950,
    errorContainer: AppPalette.dangerSurfaceDark,
    onErrorContainer: Color(0xFFFEE2E2),
    surface: AppPalette.neutral900,
    onSurface: AppPalette.neutral50,
    onSurfaceVariant: AppPalette.neutral300,
    surfaceContainerLowest: AppPalette.neutral950,
    surfaceContainerLow: AppPalette.neutral900,
    surfaceContainer: AppPalette.neutral800,
    surfaceContainerHigh: Color(0xFF273449),
    surfaceContainerHighest: AppPalette.neutral700,
    outline: AppPalette.neutral600,
    outlineVariant: AppPalette.neutral700,
    inverseSurface: AppPalette.neutral50,
    onInverseSurface: AppPalette.neutral900,
    inversePrimary: AppPalette.brand700,
    scrim: Color(0xB3000000),
    shadow: Color(0x66000000),
  );
}
