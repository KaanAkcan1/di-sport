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
    // M12 — fildişi rampa, saf beyaz yok.
    //
    // v1'de zemin ve kart 1.02:1'di, kartlar kaybolurdu. M6 bunu kart
    // gölgesiyle çözdü; M12 gölgeyi tamamen kaldırdığı için ayrım artık
    // yalnız tondan geliyor ve rampanın **tamamı** fildişi olmak
    // zorunda — tek bir saf beyaz katman bırakmak "beyaz kart"
    // görünümünü geri getirirdi.
    surface: AppPalette.ivory50,
    onSurface: AppPalette.inkStrong,
    onSurfaceVariant: AppPalette.neutral600,
    surfaceContainerLowest: AppPalette.ivory0,
    surfaceContainerLow: AppPalette.ivory0,
    surfaceContainer: AppPalette.ivory100,
    surfaceContainerHigh: AppPalette.ivory0,
    surfaceContainerHighest: AppPalette.ivory200,
    outline: AppPalette.ivory300,
    outlineVariant: AppPalette.ivoryHairline,
    // Mürekkep yüzeyi: başlık şeritleri ve istatistik blokları.
    inverseSurface: AppPalette.ink,
    onInverseSurface: AppPalette.neutral0,
    inversePrimary: AppPalette.brand300,
    scrim: Color(0x99000000), // %60 — ön planı yalıtacak güçte
    // Gölge yok: mürekkep dilinde ayrım ton ve çizgiyle kuruluyor.
    shadow: Color(0x00000000),
  );

  /// M12 mürekkep dili — koyu mod artık **birincil** moddur.
  ///
  /// Zemin Vue laciverti, vurgu Vue yeşili. `primary` `brand300` değil
  /// `brand400`: mürekkep üstünde işaret yeşilinin kendisi okunuyor
  /// (6.4:1) ve açık moddaki "yeşil kayboluyor" şikâyeti burada
  /// tamamen ortadan kalkıyor.
  ///
  /// `shadow` şeffaf: ayrım gölgeyle değil ton katmanı ve kıl çizgiyle.
  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.brand400,
    onPrimary: AppPalette.ink950,
    primaryContainer: AppPalette.brandContainerDark,
    onPrimaryContainer: AppPalette.brand100,
    secondary: AppPalette.mist400,
    onSecondary: AppPalette.ink950,
    secondaryContainer: AppPalette.ink800,
    onSecondaryContainer: AppPalette.mist200,
    // Nane: ikincil yeşil vurgu — seçili sekme etiketi, canlı sayaç.
    tertiary: AppPalette.brand200,
    onTertiary: AppPalette.ink950,
    error: AppPalette.dangerDark,
    onError: AppPalette.ink950,
    errorContainer: AppPalette.dangerSurfaceDark,
    onErrorContainer: Color(0xFFF3DDD9),
    surface: AppPalette.ink850,
    onSurface: AppPalette.mist100,
    onSurfaceVariant: AppPalette.mist400,
    surfaceContainerLowest: AppPalette.ink950,
    surfaceContainerLow: AppPalette.ink900,
    surfaceContainer: AppPalette.ink850,
    surfaceContainerHigh: AppPalette.ink800,
    surfaceContainerHighest: AppPalette.ink700,
    outline: AppPalette.ink600,
    outlineVariant: AppPalette.ink700,
    inverseSurface: AppPalette.mist100,
    onInverseSurface: AppPalette.ink900,
    inversePrimary: AppPalette.brand700,
    scrim: Color(0xCC000000),
    shadow: Color(0x00000000),
  );
}
