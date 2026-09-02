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
  // Mürekkep rampası (M12) — koyu modun zemini.
  //
  // M6'da zemin beyaz kart + soluk arka plandı ve kullanıcı reddetti:
  // yeşil beyaz üstünde görünmüyordu. Vue'nun iki rengi var; biri zemin
  // biri vurgu oldu. Yeşil koyu mürekkep üstünde elektrik gibi okunur,
  // ve uygulama karanlık bir salonda da kullanılıyor.
  //
  // Ayrım gölgeyle değil **ton katmanı + kıl çizgiyle** kuruluyor;
  // `AppElevation` bu yüzden kullanım dışı.
  // ---------------------------------------------------------------------
  static const ink950 = Color(0xFF0E1621); // en derin zemin, onPrimary
  static const ink900 = Color(0xFF121D28); // gezinme çubuğu
  static const ink850 = Color(0xFF16232F); // ekran yüzeyi
  static const ink800 = Color(0xFF1A2938); // panel, yükseltilmiş ton
  static const ink750 = Color(0xFF1D2F41); // kıl çizgi (hairline)
  static const ink700 = Color(0xFF24384D); // ayraç
  static const ink600 = Color(0xFF2C4157); // belirgin kenarlık
  static const ink500 = Color(0xFF3D5164); // sönük ikon

  // Koyu zeminin metin rampası — "sis".
  static const mist100 = Color(0xFFF2F6F9); // güçlü metin
  static const mist200 = Color(0xFFDFE8EF); // gövde metni
  static const mist400 = Color(0xFF8DA2B5); // ikincil metin (onSurfaceVariant)
  static const mist500 = Color(0xFF68809A); // sönük etiket
  static const mist600 = Color(0xFF5F7387); // en sönük

  // ---------------------------------------------------------------------
  // Fildişi — açık modun zemini.
  //
  // Saf beyaz değil: M6'da zemin ve kart 1.02:1'di ve kartlar
  // kayboluyordu. Mürekkep dilinde ayrım tonla kurulduğu için açık
  // modda da rampa gerekiyor — beyaz üstüne beyaz katman olmaz.
  // ---------------------------------------------------------------------
  static const ivory0 = Color(0xFFFDFCF9); // en açık yüzey
  static const ivory50 = Color(0xFFF7F6F2); // ekran zemini
  static const ivory100 = Color(0xFFEFEDE7); // panel
  static const ivory200 = Color(0xFFE7E4DC); // yükseltilmiş ton
  static const ivory300 = Color(0xFFDBD7CC); // kenarlık
  static const ivoryHairline = Color(0xFFE3E0D8); // kıl çizgi

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

  /// M12: koyu modda başarı da markanın işaret yeşili.
  ///
  /// Eskiden `brand300`'dü; mürekkep zeminde `primary` de `brand400`
  /// olunca iki yakın yeşil doğuyordu. Birleştirme kararı (marka =
  /// başarı) koyu modda da geçerli — `ink_scheme_test` bunu sabitliyor.
  static const successDark = brand400;

  static const successSurfaceLight = brand50;

  /// Mürekkep zeminde "bütçe altı / yapıldı" dolgusu. Yeşile çalan
  /// lacivert: takvim hücresi bir bakışta okunmalı ama rakamı
  /// bastırmamalı.
  static const successSurfaceDark = Color(0xFF183626);

  static const warningLight = Color(0xFFB45309); // amber-700

  /// Mürekkep zeminde uyarı. `amber-400` (#FBBF24) lacivert üstünde
  /// fazla parlak kalıyordu; bir tık koyulaştırıldı.
  static const warningDark = Color(0xFFE8A33D);

  static const warningSurfaceLight = Color(0xFFFEF3C7);
  static const warningSurfaceDark = Color(0xFF3A2C14);

  static const dangerLight = Color(0xFFB91C1C); // red-700

  /// Mürekkep zeminde aşım/hata. `red-400` mürekkeple çakışmıyordu ama
  /// fazla pembeye kaçıyordu; toprak tonuna çekildi.
  static const dangerDark = Color(0xFFE06C5F);

  static const dangerSurfaceLight = Color(0xFFFEE2E2);

  /// "Bütçe üstü" dolgusu — kızıla çalan lacivert.
  static const dangerSurfaceDark = Color(0xFF3A2622);

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
  /// korunarak (41°) koyulaştırıldı.
  ///
  /// M12'de bir tık daha koyulaştı: zemin saf beyazdan fildişine
  /// (`ivory50`) taşınınca eski değer 3:1'in hemen altına düştü.
  /// Testin eşiği düşürülmedi, renk düzeltildi — 3.20:1.
  static const chartOrangeOnLight = Color(0xFFB87F00);

  /// Okabe-Ito pembesinin açık mod karşılığı — turuncuyla aynı gerekçe.
  ///
  /// Özgün #CC79A7 beyaz zeminde 3.06:1 ile eşiğin hemen üstündeydi;
  /// fildişi zeminde 2.83'e düştü. Ton (326°) korunarak koyulaştırıldı,
  /// 3.32:1. Koyu modda özgün pembe kullanılmaya devam ediyor.
  static const chartPinkOnLight = Color(0xFFC06C9B);

  // ---------------------------------------------------------------------
  // Alan renkleri (v3) — beş sekmenin kimliği.
  //
  // Okabe-Ito ailesinden seçildi ki grafiklerle aynı dili konuşsunlar.
  // Renk hiçbir yerde tek başına anlam taşımaz; ikon + etiket her zaman
  // eşlik eder. Diyet marka yeşilini kullanır (ayrı sabit yok).
  //
  // `*OnLight` varyantları grafiklerdeki kuralın aynısı: özgün renkler
  // fildişi zeminde 3:1 eşiğinin altında kalıyor (sport 2.13, health
  // 2.83, med 2.22); eşik düşürülmez, ton korunarak koyulaştırılır.
  // Ölçülen oranlar: sportOnLight 4.19, healthOnLight 4.31,
  // medOnLight 4.75 (fildişi üstünde).
  // ---------------------------------------------------------------------
  static const areaSport = chartSky; // #56B4E9 — ink850'de 6.92:1
  static const areaSportOnLight = Color(0xFF2E7DAB);
  static const areaHealth = chartPink; // #CC79A7 — ink850'de 5.21:1
  static const areaHealthOnLight = Color(0xFFA85B86);
  static const areaMed = Color(0xFFB39DDB); // ink850'de 6.66:1
  static const areaMedOnLight = Color(0xFF7E5FA8);
  static const areaEnergy = chartOrange;

  /// `chartOrangeOnLight` (3.20 fildişi) alan yüzeyi `F7EDD8` üstünde
  /// 2.97'ye düşüyor — ikon kutusu kendi yüzeyinde de 3:1 ister. Ton
  /// korunarak bir kademe daha koyu: yüzeyde 3.50, fildişide 3.76.
  static const areaEnergyOnLight = Color(0xFFA87400);

  /// Alan renklerinin koyu moddaki zemin yüzeyleri — `tile` kutuları.
  static const areaSportSurfaceDark = Color(0xFF16303F);
  static const areaHealthSurfaceDark = Color(0xFF33222E);
  static const areaMedSurfaceDark = Color(0xFF2A2438);
  static const areaEnergySurfaceDark = Color(0xFF382E18);

  /// Açık moddaki yüzeyler — fildişiyle uyumlu soluk tonlar.
  static const areaSportSurfaceLight = Color(0xFFE2EFF7);
  static const areaHealthSurfaceLight = Color(0xFFF4E6EE);
  static const areaMedSurfaceLight = Color(0xFFEDE7F6);
  static const areaEnergySurfaceLight = Color(0xFFF7EDD8);
}
