import 'package:flutter/material.dart';

/// Boşluk ölçeği — 4dp ritmi (ui-ux §5 `spacing-scale`).
///
/// Rastgele değer yazmak yerine buradan seçmek, ekranlar arası dikey
/// ritmin tutarlı kalmasını sağlar. Yeni bir değere ihtiyaç duyulursa
/// önce "gerçekten gerekli mi" diye sorulur; gerekliyse buraya eklenir,
/// widget içine gömülmez.
abstract final class AppSpacing {
  /// 4 — ikon ile metin arası gibi en dar aralık.
  static const xs = 4.0;

  /// 8 — dokunma hedefleri arası asgari boşluk.
  static const sm = 8.0;

  /// 12 — kart içi sıkı gruplama.
  static const md = 12.0;

  /// 16 — varsayılan kenar boşluğu ve kart iç dolgusu.
  static const lg = 16.0;

  /// 20 — ilişkili öğe grupları arası.
  static const xl = 20.0;

  /// 24 — bölüm içi ayrım.
  static const xl2 = 24.0;

  /// 32 — bölümler arası ayrım.
  static const xl3 = 32.0;

  /// 48 — büyük bölüm ayrımı, boş durum ekranları.
  static const xl4 = 48.0;

  /// Ekran kenarlarının varsayılan yatay dolgusu.
  static const screenH = lg;

  /// Alt gezinme çubuğunun altında kalan içerik için ek dolgu —
  /// listelerin son öğesi çubuğun arkasında kalmasın
  /// (ui-ux §5 `fixed-element-offset`).
  static const bottomBarClearance = 88.0;
}

/// Köşe yarıçapı ölçeği. Tek bir ölçekten seçmek, "her kart biraz farklı
/// yuvarlak" hissini engeller (ui-ux §4 `effects-match-style`).
abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 999.0;

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const mdAll = BorderRadius.all(Radius.circular(md));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const xlAll = BorderRadius.all(Radius.circular(xl));
  static const fullAll = BorderRadius.all(Radius.circular(full));
}

/// Dokunma hedefi asgarileri (ui-ux §2 `touch-target-size`).
///
/// Apple 44pt, Material 48dp ister. İkisini de karşılamak için 48
/// tabanı alınır; görsel öğe daha küçükse dokunma alanı bu boyuta
/// genişletilir.
abstract final class AppTouch {
  static const minSize = 48.0;
  static const minGap = AppSpacing.sm;
}

/// Hareket süreleri ve eğrileri (ui-ux §7).
///
/// Tek yerden yönetilmesi, tüm uygulamanın aynı ritimde hareket etmesini
/// sağlar — farklı ekranlarda farklı hızlar "derme çatma" hissi verir.
abstract final class AppMotion {
  /// 120ms — basma geri bildirimi, renk geçişi.
  static const fast = Duration(milliseconds: 120);

  /// 200ms — varsayılan mikro etkileşim.
  static const base = Duration(milliseconds: 200);

  /// 280ms — panel/sayfa geçişi.
  static const slow = Duration(milliseconds: 280);

  /// Çıkış girişten kısa olur; arayüz daha çevik hissettirir
  /// (ui-ux §7 `exit-faster-than-enter`).
  static const exit = Duration(milliseconds: 160);

  /// Giren öğeler için: hızlı başlar, yumuşak durur.
  static const enterCurve = Curves.easeOutCubic;

  /// Çıkan öğeler için.
  static const exitCurve = Curves.easeInCubic;

  /// Vurgulu geçişler (sayfa, sayfa içi büyük yer değişimi).
  static const emphasized = Curves.easeInOutCubicEmphasized;

  /// Sistemde "hareketi azalt" açıksa süreyi sıfırlar
  /// (ui-ux §1 `reduced-motion`).
  static Duration respectingMotion(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}

/// Yükseklik (gölge) ölçeği — **M12'den itibaren kullanım dışı.**
///
/// Mürekkep dilinde gölge yok: ayrım ton katmanı (`surface` →
/// `surfaceContainerHigh`) ve kıl çizgiyle kuruluyor (spec §2a.2).
/// M6'da gölge gerekiyordu çünkü zemin ve kart ikisi de beyaza yakındı;
/// zemin mürekkebe taşınınca o dayanak kalktı.
///
/// Sınıf silinmedi ki "gölge neden yok" sorusunun cevabı burada dursun.
/// **Yeni kullanım eklenmez** — `elevation_free_test.dart` bunu
/// denetliyor. Bir yüzeyin öne çıkması gerekiyorsa bir ton yukarı
/// çıkar ve kenarlık alır; ön plan katmanları (diyalog, alt sayfa)
/// için kalıp `app_component_themes.dart` içinde.
@Deprecated('M12: mürekkep dilinde gölge yok, ton katmanı kullan')
abstract final class AppElevation {
  static const none = 0.0;
  static const card = 1.0;
  static const cardRaised = 3.0;
  static const raised = 3.0;
  static const overlay = 6.0;
}

/// Kenarlık kalınlıkları.
///
/// Vurgulu kenarlık (seçili gün, etkin ray) 2dp; sıradan ayrım 1dp.
/// Arada değer yok — "biraz daha kalın" istendiğinde ölçek bozulur.
abstract final class AppBorder {
  static const hairline = 1.0;
  static const emphasis = 2.0;

  /// Zaman rayının kalınlığı. Kalın değil ama görünür olmalı;
  /// ray ekranın omurgası.
  static const rail = 2.0;
}
