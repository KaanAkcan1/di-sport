import 'package:flutter/material.dart';

/// Ham renk rampaları — tasarım sisteminin en alt katmanı.
///
/// Bu sınıftaki değerler doğrudan widget'larda KULLANILMAZ. Widget'lar
/// `Theme.of(context).colorScheme` ve `AppSemanticColors` üzerinden
/// anlamsal isimlere erişir (spec 4.1; ui-ux §6 `color-semantic`).
/// Buradaki tek iş, o anlamsal isimlerin beslendiği paleti tanımlamak.
abstract final class AppPalette {
  // ---------------------------------------------------------------------
  // Marka — Vue yeşili (#42B883) çevresinde kurulmuş rampa.
  //
  // ÖNEMLİ — bir kural burada bilerek değiştirildi:
  //
  // M1'de "marka rengi anlam rengi OLAMAZ" kuralı kondu, gerekçesi
  // uygulamada üç durum ekseni bulunması (gün yapıldı/kaçırıldı, tahlil
  // düşük/normal/yüksek, kilo yönü) ve yeşil bir markanın "iyi"
  // sinyaliyle çakışacak olmasıydı.
  //
  // Marka yeşile taşınınca bu çakışma kaçınılmaz. İki yeşil tanımlayıp
  // birini markaya birini başarıya vermek daha kötü olurdu: kullanıcı
  // iki yakın yeşili ayırt etmeye çalışırdı. Bunun yerine **ikisi
  // birleştirildi** — `successLight/Dark` bu rampadan besleniyor.
  //
  // Neden savunulabilir: alışkanlık takibinde "marka" ile "yapıldı"
  // aynı yeşil olması tutarlı bir eşleme. Ayrıca kural zaten renk tek
  // başına anlam taşımasın diyordu (ikon + metin her zaman eşlik eder);
  // o kural yürürlükte.
  //
  // Ayrışması **şart** olanlar marka↔uyarı (amber) ve marka↔hata
  // (kırmızı); ton mesafesi testi artık bunları koruyor.
  // ---------------------------------------------------------------------
  static const brand50 = Color(0xFFECFAF3);
  static const brand100 = Color(0xFFD1F3E2);
  static const brand200 = Color(0xFFA5E6C6);
  static const brand300 = Color(0xFF73D6A6);

  /// Vue'nun işaret yeşili. Marka rengi budur; büyük dolgularda ve
  /// koyu modda kullanılır.
  static const brand400 = Color(0xFF42B883);

  static const brand500 = Color(0xFF35A170);
  static const brand600 = Color(0xFF2A855C);

  /// Açık modun `primary`'si. `brand400` beyaz metinle 2.2:1'de kalıyor —
  /// dolgulu düğmede okunmaz. Ton korunarak koyulaştırıldı.
  static const brand700 = Color(0xFF1F6B4A);

  static const brand800 = Color(0xFF17513A);
  static const brand900 = Color(0xFF0F3527);

  /// Koyu modun marka kapsayıcısı — doygunluğu düşürülmüş yeşil.
  ///
  /// Rampadan `brand800` alınsaydı seçili sekme göstergesi koyu modda
  /// açık moddakinden çok daha ağır görünürdü. İki mod aynı karakterde
  /// olmalı (ui-ux §4 `dark-mode-pairing`).
  static const brandContainerDark = Color(0xFF1D4536);

  // ---------------------------------------------------------------------
  // Mürekkep — Vue'nun laciverti.
  //
  // Nötr rampadan ayrı duruyor çünkü işi farklı: bu bir *yüzey* rengi.
  // Başlık şeritleri ve istatistik blokları bununla dolduruluyor ki
  // ekranın bir ağırlık merkezi olsun. v1'de böyle bir merkez yoktu,
  // her şey aynı düzlemde duruyordu ve göz nereye bakacağını bilmiyordu.
  // ---------------------------------------------------------------------

  /// Vue'nun gövde metni rengi. En koyu mürekkep.
  static const inkStrong = Color(0xFF213547);

  /// Vue'nun ikincil laciverti. Dolu yüzeyler için.
  static const ink = Color(0xFF35495E);

  /// Mürekkebin açık varyantı — lacivert yüzey üstünde ikincil metin.
  static const inkMuted = Color(0xFF7E93A8);

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
  // Başarı = marka. Bilinçli birleştirme; gerekçesi marka bloğunda.
  static const successLight = brand700;
  static const successDark = brand300;
  static const successSurfaceLight = brand50;
  static const successSurfaceDark = brandContainerDark;

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
