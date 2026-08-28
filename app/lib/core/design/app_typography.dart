import 'package:flutter/material.dart';

/// Tipografi ölçeği — Inter, Material 3 tip rolleriyle.
///
/// Inter iki nedenle seçildi. Birincisi Türkçe: noktasız ı, İ, ğ, ş
/// glifleri eksiksiz (doğrulaması testte). İkincisi bu uygulamanın
/// esas içeriği sayı — kilo, set × tekrar, tahlil değerleri — ve Inter
/// tablo rakamlarını (tabular figures) destekliyor: her rakam aynı
/// genişlikte olduğu için alt alta dizilen sayılar kaymaz
/// (ui-ux §6 `number-tabular`).
///
/// Font uygulamayla birlikte paketlenir, çalışma anında indirilmez —
/// uygulama tamamen çevrimdışıdır (spec Bölüm 2).
abstract final class AppTypography {
  static const fontFamily = 'Inter';

  /// Sayısal alanlar için: tüm rakamlar eşit genişlikte.
  static const tabularFigures = [FontFeature.tabularFigures()];

  static const _tightNegative = -0.2;

  /// Material 3'ün beş tip rolü (display, headline, title, body, label)
  /// eksiksiz doldurulur — eksik bırakılan rol Flutter'ın varsayılanına
  /// düşer ve font ailesi tutarsızlaşır.
  static const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      height: 48 / 40,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 36,
      height: 44 / 36,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    displaySmall: TextStyle(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w600,
      letterSpacing: _tightNegative,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w600,
      letterSpacing: _tightNegative,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    ),
    // Gövde satır yüksekliği 1.5 — okunabilirlik asgarisi
    // (ui-ux §6 `line-height`).
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 21 / 14,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 18 / 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w500,
    ),
  );

  // -------------------------------------------------------------------
  // Sayısal stiller. Material'ın tip rollerinde karşılığı yok çünkü bu
  // uygulamaya özgü: büyük tek sayı gösterimleri (kilo, hafta ortalaması)
  // ve tablo hücreleri.
  // -------------------------------------------------------------------

  /// Ekranın ana rakamı — bugünkü kilo, haftalık ortalama.
  static const metricLarge = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    fontFeatures: tabularFigures,
  );

  /// Kart içi rakam — set sayacı, tahlil değeri.
  static const metricMedium = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    fontFeatures: tabularFigures,
  );

  /// Tablo hücresi, liste içi rakam.
  static const metricSmall = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    fontFeatures: tabularFigures,
  );

  /// Rakamın yanındaki birim — "kg", "sn", "ng/mL".
  static const unit = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );
}
