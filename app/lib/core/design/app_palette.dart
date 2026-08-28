import 'package:flutter/material.dart';

/// Ham renk rampaları — tasarım sisteminin en alt katmanı.
///
/// Bu sınıftaki değerler doğrudan widget'larda KULLANILMAZ. Widget'lar
/// `Theme.of(context).colorScheme` ve `AppSemanticColors` üzerinden
/// anlamsal isimlere erişir (spec 4.1; ui-ux §6 `color-semantic`).
/// Buradaki tek iş, o anlamsal isimlerin beslendiği paleti tanımlamak.
abstract final class AppPalette {
  // ---------------------------------------------------------------------
  // Marka — derin mavi.
  //
  // Bilinçli tercih: marka rengi anlam rengi OLAMAZ. Uygulamada üç ayrı
  // durum ekseni var (gün yapıldı/kaçırıldı, tahlil düşük/normal/yüksek,
  // kilo yönü). Marka yeşil ya da turuncu olsaydı "iyi/kötü" sinyaliyle
  // çakışır, kullanıcı rengin ne anlattığını her seferinde çözmek
  // zorunda kalırdı. Mavi bu üç eksenin hiçbirinde anlam taşımaz.
  // ---------------------------------------------------------------------
  static const brand50 = Color(0xFFEFF6FF);
  static const brand100 = Color(0xFFDBEAFE);
  static const brand200 = Color(0xFFBFDBFE);
  static const brand300 = Color(0xFF93C5FD);
  static const brand400 = Color(0xFF60A5FA);
  static const brand500 = Color(0xFF3B82F6);
  static const brand600 = Color(0xFF2563EB);
  static const brand700 = Color(0xFF1D4ED8);
  static const brand800 = Color(0xFF1E40AF);
  static const brand900 = Color(0xFF1E3A8A);

  /// Koyu modun marka kapsayıcısı — doygunluğu düşürülmüş lacivert.
  ///
  /// Rampadan `brand800` alınsaydı seçili sekme göstergesi koyu modda
  /// açık moddakinden çok daha ağır görünürdü: açık modda gösterge
  /// soluk bir zemin, koyu modda parlak bir hap olurdu. İki mod aynı
  /// karakterde olmalı (ui-ux §4 `dark-mode-pairing`), bu yüzden
  /// aynı tonda ama kroması düşük ayrı bir değer.
  static const brandContainerDark = Color(0xFF2A3E63);

  // ---------------------------------------------------------------------
  // Nötrler — slate. Yüzeyler, metin, kenarlıklar.
  // ---------------------------------------------------------------------
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF8FAFC);
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral500 = Color(0xFF64748B);
  static const neutral600 = Color(0xFF475569);
  static const neutral700 = Color(0xFF334155);
  static const neutral800 = Color(0xFF1E293B);
  static const neutral900 = Color(0xFF0F172A);
  static const neutral950 = Color(0xFF020617);

  // ---------------------------------------------------------------------
  // Anlam renkleri. Yalnızca durum bildirir; dekorasyon için kullanılmaz.
  // Açık ve koyu mod için ayrı tonlar: koyu modda ters çevirme değil,
  // aydınlatılmış/doygunluğu azaltılmış varyant (ui-ux §6
  // `color-dark-mode`).
  // ---------------------------------------------------------------------
  static const successLight = Color(0xFF15803D); // green-700
  static const successDark = Color(0xFF4ADE80); // green-400
  static const successSurfaceLight = Color(0xFFDCFCE7);
  static const successSurfaceDark = Color(0xFF14532D);

  static const warningLight = Color(0xFFB45309); // amber-700
  static const warningDark = Color(0xFFFBBF24); // amber-400
  static const warningSurfaceLight = Color(0xFFFEF3C7);
  static const warningSurfaceDark = Color(0xFF78350F);

  static const dangerLight = Color(0xFFB91C1C); // red-700
  static const dangerDark = Color(0xFFF87171); // red-400
  static const dangerSurfaceLight = Color(0xFFFEE2E2);
  static const dangerSurfaceDark = Color(0xFF7F1D1D);

  static const infoLight = Color(0xFF0369A1); // sky-700
  static const infoDark = Color(0xFF7DD3FC); // sky-300

  // ---------------------------------------------------------------------
  // Grafik serileri — Okabe-Ito paleti.
  //
  // Renk körlüğünün üç yaygın türünde (protanopi, deuteranopi,
  // tritanopi) ayırt edilebilir olacak şekilde tasarlanmış, veri
  // görselleştirmenin fiili standardı. Yine de renk tek başına anlam
  // taşımaz: çizgi deseni ve doğrudan etiketleme ile desteklenir
  // (ui-ux §10 `pattern-texture`, `color-guidance`).
  // ---------------------------------------------------------------------
  static const chartBlue = Color(0xFF0072B2);
  static const chartGreen = Color(0xFF009E73);
  static const chartPink = Color(0xFFCC79A7);
  static const chartSky = Color(0xFF56B4E9);
  static const chartVermillion = Color(0xFFD55E00);
  static const chartYellow = Color(0xFFF0E442);

  /// Okabe-Ito turuncusu, koyu zeminler için özgün hâliyle.
  static const chartOrange = Color(0xFFE69F00);

  /// Aynı turuncunun açık mod karşılığı.
  ///
  /// Özgün #E69F00 beyaz zeminde 2.25:1 kalıyor — arayüz bileşeni için
  /// gereken 3:1 eşiğinin altında. Okabe-Ito paleti serileri birbirinden
  /// ayırmak için tasarlandı, zemine karşı kontrast için değil; ton
  /// korunarak koyulaştırıldı (3.09:1).
  static const chartOrangeOnLight = Color(0xFFC38700);
}
