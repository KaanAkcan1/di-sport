# di@sport M6 — Özelleştirme ve Görsel Refactor

**Goal:** Kullanıcı kendi kurallarını, ölçümlerini, ekipmanını, mesaisini
ve yasaklı saatlerini tanımlayabilir; katalog genişler; ve tüm arayüz
enterprise seviyede yeniden tasarlanır.

**Spec:** `docs/superpowers/specs/2026-08-28-disport-tasarim.md`
**Önkoşul:** M5 tamamlanmış (v1 çalışıyor).

---

## Neden bu tur

Kullanıcının iki tür geri bildirimi var:

**1. Sabit olan şeyler sabit olmamalı.** v1'de günün kuralları üç sabit
kutucuk, ölçüm türleri yedi sabit satır, katalog 17 sabit hareket.
Hepsi PDF'ten çıkarıldı ve kullanıcının hayatı PDF'te yazandan geniş.

**2. Arayüz "hiç beğenilmedi".** Bu haklı bir eleştiri ve nedeni
somut — aşağıda.

---

## Görsel tanı: neden soluk görünüyor

Mevcut kodun kendi ölçtüğü sorunlar:

| Sorun | Kanıt | Sonuç |
|---|---|---|
| Kartın yüksekliği yok | `AppElevation.card = 0.0` | Kart zeminden ayrışmıyor |
| Zemin ile kart neredeyse aynı | zemin `neutral50` (#F8FAFC), kart `neutral0` (#FFFFFF) | 1.02:1 — göz sınırı seçemiyor |
| Kenarlık görünmüyor | `neutral200` (#E2E8F0) beyaz üstünde | Kart "var mı yok mu" |
| Marka rengi hiç görünmüyor | Yalnız FAB ve seçili sekmede | Uygulamanın kimliği yok |
| Sayılar küçük | `metricMedium` 20px, satır sonunda | Veri uygulaması ama veri vurgusuz |
| Hiyerarşi tek düzlemde | Her kart aynı ağırlıkta | Göz nereye bakacağını bilmiyor |

**Kök neden:** tasarım sistemi *doğru kurallara* sahip (marka ≠ anlam,
kontrast testli, 4dp ritmi) ama *karaktersiz*. Kurallar korunmalı,
karakter eklenmeli.

---

## Tasarım yönü

### Konu neyse dil o

Bu uygulama bir **çizelgenin** dijital hâli. Kaynak PDF bir tablo:
satırlar saat, sütunlar gün. Uygulamadaki her ekran zamana göre
düzenli — slotlar saate, günler haftaya, kilo günlere, tahlil aylara.

**Bu yüzden omurga zaman olacak.**

### İmza öğe: gün omurgası

Bugün ekranında sürekli bir dikey zaman rayı. Slotlar bu raya asılı,
saatler sıkışık rakamla, ve **şu anki konum canlı işaretli**.

Gerekçe dekorasyon değil: sabah 05:45'te uygulamayı açan kullanıcının
tek sorusu "sırada ne var". v1'de slotlar düz bir liste — geçmişle
gelecek arasında hiçbir görsel fark yok, bu bilgi atılıyor.

**Göze alınan risk:** ray düzeni karmaşık ve canlı işaret için tiker
gerekiyor. Karşılığında ekranın tek sorusu cevaplanıyor.

### Tipografi: iki aile

| Rol | Aile | Neden |
|---|---|---|
| Gövde, arayüz | **Inter** | Türkçe glifler tam, tablo rakamı var. Değişmiyor. |
| Saat, büyük sayı, istatistik etiketi | **Barlow Condensed** | Skor tabelası ve tur zamanı dili. Uygulamanın içeriği sayı; sıkışık rakam hem daha çok veri sığdırır hem karakter verir. |

İki aile de değişken font, ikisi de uygulamayla paketli (çevrimdışı).

### Renk: aynı kurallar, gerçek derinlik

Marka ≠ anlam kuralı **korunuyor** — üç durum ekseni var, marka onlara
karışamaz. Değişen, kontrastın kendisi:

- Zemin `neutral100`'e koyulaşıyor, kart beyaz kalıyor → kart görünür
- Kartlar gerçek (yumuşak) gölge alıyor → `AppElevation.card` artık 0 değil
- Marka `brand700`'e derinleşiyor, ve yalnız FAB'da değil **"şimdi"**
  göstergesinde, aktif rayda, seçili günde kullanılıyor
- `ink` (neutral900) başlık şeritlerinde yüzey olarak kullanılıyor →
  ekranın bir ağırlık merkezi oluyor

---

## Fazlar

Sıra bilinçli: tasarım temeli önce, çünkü yeni ekranlar yeni dille
yazılmalı — önce yazıp sonra refactor etmek iki kat iş.

### Faz A — tasarım temeli

- A1: Barlow Condensed paketleme + `AppTypography` iki aileye çıkıyor
- A2: `AppPalette`/`app_color_schemes` derinlik düzeltmesi, `AppElevation`
- A3: Yeni paylaşılan bileşenler: `AppCard`, `AppStatCard`, `AppTimeRail`,
      `AppSegmented`, `AppListTile`
- A4: Kontrast testleri güncelleniyor (eşikler değişmiyor, değerler değişti)

### Faz B — ekranların yeniden yazımı

- B1: Bugün — gün omurgası, canlı "şimdi" işareti
- B2: Plan — hafta şeridi, gün düzenleme
- B3: İlerleme — istatistik başlığı, grafik yeniden
- B4: Sağlık — panel yoğunluğu
- B5: Katalog + Antrenman — kart ızgarası

### Faz C — özelleştirme

- C1: `daily_rules` tablosu — günün kuralları eklenebilir/sıralanabilir
- C2: `custom_metrics` — ölçüm türleri eklenebilir
- C3: Ekipman envanteri + katalog filtresi
- C4: Haftalık mesai saatleri
- C5: Yasaklı gün/saat pencereleri
- C6: Plan gününde "serbest/tatil" işareti

### Faz D — katalog

- D1: Araştırmayla hareket ekleme
- D2: Görsellerin açıklayıcılığı

---

## Değişmeyecek kurallar

Bunlar M1-M5'te bedeli ödenerek öğrenildi; refactor bunları bozamaz:

1. **Marka rengi anlam rengi olamaz.** Üç durum ekseni var.
2. **Kontrast testleri geçmeli.** `contrast_test.dart` eşikleri düşmez.
3. **Renk tek başına anlam taşımaz.** İkon ya da metin eşlik eder.
4. **Ekranlar akışla okur**, tek seferlik değil (`IndexedStack` canlı).
5. **Dokunma hedefi 48dp**, yazı ölçeği 0.85–1.6 arasında bozulmaz.
6. **Ham renk/ölçü widget'a yazılmaz.**
