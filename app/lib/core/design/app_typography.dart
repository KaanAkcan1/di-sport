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

  /// Sıkışık aile — saatler, büyük sayılar, istatistik etiketleri.
  ///
  /// Barlow Condensed bilinçli bir eşleştirme: bu uygulamanın kaynağı
  /// bir çizelge ve içeriği sayı. Sıkışık rakam hem dar sütuna daha
  /// çok veri sığdırır hem de skor tabelası/tur zamanı dilini getirir —
  /// arayüze Inter'in tek başına veremediği karakteri veren şey bu.
  ///
  /// Gövde metni **asla** bununla yazılmaz: Türkçe sözcükler sıkışık
  /// harfle küçük puntoda okunurluk kaybeder. Yalnız sayı, saat ve
  /// kısa büyük harf etiket.
  ///
  /// Türkçe glifleri (ı İ ğ ş ç ö ü) eksiksiz — testte doğrulanıyor.
  static const condensedFamily = 'BarlowCondensed';

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

  /// Ekranın **kahraman** rakamı — M12'nin merkezi öğesi.
  ///
  /// Her ekranın tek bir büyük sayısı var: Bugün'de kalan kalori,
  /// İlerleme'de toplam değişim, Antrenman'da seans süresi. Kol
  /// mesafesinden okunmalı — Whoop'un 72pt skoruyla aynı fikir, ama
  /// bizde sayı 5 haneye kadar çıkabildiği için sıkışık aileyle 56'da
  /// dengeleniyor.
  static const metricHero = TextStyle(
    fontFamily: condensedFamily,
    fontSize: 56,
    height: 58 / 56,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    fontFeatures: tabularFigures,
  );

  /// Ekranın ana rakamı — bugünkü kilo, haftalık ortalama.
  ///
  /// Sıkışık aile: 48 punto Inter ile yazılan "109,4 kg" satırı tek
  /// başına kaplar; sıkışık hâli aynı yerde hem daha büyük hem daha
  /// okunur duruyor.
  static const metricLarge = TextStyle(
    fontFamily: condensedFamily,
    fontSize: 48,
    height: 52 / 48,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    fontFeatures: tabularFigures,
  );

  /// Kart içi rakam — set sayacı, tahlil değeri.
  static const metricMedium = TextStyle(
    fontFamily: condensedFamily,
    fontSize: 26,
    height: 30 / 26,
    fontWeight: FontWeight.w600,
    fontFeatures: tabularFigures,
  );

  /// Tablo hücresi, liste içi rakam.
  static const metricSmall = TextStyle(
    fontFamily: condensedFamily,
    fontSize: 18,
    height: 22 / 18,
    fontWeight: FontWeight.w500,
    fontFeatures: tabularFigures,
  );

  /// Rakamın yanındaki birim — "kg", "sn", "ng/mL".
  ///
  /// Inter kalıyor: birim bir sözcük, rakam değil.
  static const unit = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );

  /// Zaman rayındaki saat — "06:30".
  ///
  /// Tablo rakamı şart: raydaki saatler alt alta ve sola hizalı; oranlı
  /// rakamla "11:00" ile "06:30" farklı genişlikte olur, ray eğrilir.
  static const timeRail = TextStyle(
    fontFamily: condensedFamily,
    fontSize: 20,
    height: 22 / 20,
    fontWeight: FontWeight.w600,
    fontFeatures: tabularFigures,
    letterSpacing: 0.2,
  );

  /// İstatistik bloğunun altındaki küçük büyük harf etiket —
  /// "HAFTALIK ORTALAMA", "SON TAHLİL".
  ///
  /// Harf aralığı açık: sıkışık aile büyük harfte sıkışıklığını
  /// abartır, aralık onu geri dengeler.
  static const statCaption = TextStyle(
    fontFamily: condensedFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}
