# FORMALITY — Görsel Kimlik Brifi

**Tarih:** 2026-09-02 · **Durum:** Onaylandı (palet A "Gece Grafiti";
B yedekte · logo **V2a**) ·
**Bağlantı:** [Marka stratejisi](2026-09-02-formality-marka-stratejisi.md)

**Taşıyıcı karar:** Marka ekrana uymaz, ekran markaya uyar. Tek sabit
renk Vue yeşili `#42B883`; uygulamanın mevcut lacivert/fildişi paleti
markaya göre güncellenecek.

---

## 01 — Kimlik Stratejisi

Formality'nin kimliği ismin esprisinden doğar: **formalite = kâğıt,
form, damga, imza.** Görsel dünya bir "form kâğıdı" evrenidir — krem
kâğıt, koyu mürekkep, ve her şeyin üstüne basılan yeşil ONAY damgası.
Espri görünmez bir katmandır: uzaktan sakin ve resmî duran her yüzey,
yakından bakınca göz kırpar. Bağıran fitness estetiğinin tam karşısında
konumlanır.

---

## 02 — Logo

**Yön:** Sembol + yazı markası. Sembol uygulama ikonunda tek başına
yaşar.

**Konsept — "Onay damgası aslında nabız":** Yuvarlatılmış kare, koyu
zemin (`#0F1B16`); üzerinde Vue yeşili tek fırça hattı —
soldan **onay işareti (✓)** olarak başlar, sağa doğru **grafik/nabız
çizgisine** uzar. Damga estetiği: hafif dokulu baskı hissi
düşünülebilir (aşırıya kaçmadan). İki anlam tek harekette: "onaylandı"
+ "takip ediliyor".

**Yazı markası:** "Formality", Barlow Condensed SemiBold, hafif açık
harf aralığı; yalnız baş harf büyük.

**Karakter:** Kendinden emin, sakin, hafif göz kırpan.

**Kaçınılacaklar:** Halter/koşucu silueti, kalp, elma-havuç, degrade
"AI moru", altıgen/nöron ağı, gölge ve degrade.

**Referanslar:** Vue.js (iki tonlu sade geometri), Todoist (onay
işaretinin sıcak sahiplenilişi), Linear (koyu-öncelikli tek-vurgu
disiplini).

---

## 03 — Renk: Palet A "Gece Grafiti" (seçildi)

| Rol | Renk | Hex |
|---|---|---|
| Marka / damga | Vue yeşili **(sabit)** | `#42B883` |
| Zemin (koyu tema, varsayılan) | Yeşil alttonlu is-siyahı | `#0F1B16` |
| Yüzey katmanı (koyu) | Bir ton açığı | `#16241E` |
| Metin (koyu zeminde) | Kırık beyaz | `#EDF2EF` |
| Zemin (açık tema) | Soğuk kırık beyaz | `#F2F5F3` |
| Kıl çizgi / ayraç (açık) | Soğuk gri | `#D3DBD6` |
| İkincil metin (açık) | Yeşilimsi gri | `#5E6E66` |

Yeşil, kendi ailesinden bir siyahın üstünde en sert parlar —
koyu-öncelikli, stüdyo özgüveni. Damga/onay hikâyesi logoda yaşamaya
devam eder; kâğıt dokusu palete taşınmaz. Bilinen risk: yeşil+siyah
Spotify çağrışımı — ton farkı ve damga konseptiyle yönetilir.

**Sinyal renkleri:** Amber (eksik) ve kızıl (aşım) markanın değil
arayüzün renkleridir; yalnız anlam taşır, marka yüzeylerinde
kullanılmaz. Kontrast eşikleri (metin 4.5:1, arayüz 3:1) palet
uygulamaya taşınırken `contrast_test.dart` ile doğrulanacak.

### Yedek: Palet B "Form Kâğıdı" (cepte)

Krem `#F4EFE6` + mürekkep `#1C2B26` + kâğıt grisi `#D8D2C4` — "form
kâğıdı + damga" dünyası. Açık temaya sıcaklık istenirse dönülecek yön;
karşılaştırma: `docs/brand/2026-09-02-palet-karsilastirma.png`.

### Logo: V2a (seçildi)

"Nabız onayı" — EKG hattının derin vuruşu onay işaretinin kendisi;
30 birimlik kalın çizgi, vuruş ortada. Varyasyonlar:
`docs/brand/2026-09-02-v2-varyasyonlar-paletA.png`.

---

## 04 — Tipografi

- **Barlow Condensed** (SemiBold/Bold): logotip, kahraman rakamlar,
  başlıklar. Çizelge mirası.
- **Inter**: gövde, arayüz, mağaza metinleri. Türkçe glifler tam,
  tablo rakamı var.
- Hiyerarşi: başlık/rakam Barlow · gövde Inter · etiketler Inter harf
  aralıklı büyük harf. **Gövde asla Barlow Condensed yazılmaz.**
- Kaçın: el yazısı, serif, ince "premium wellness" fontları.

---

## 05 — Görsel Dili

Duotone boru hattı (kırp + iki ton + başlangıç/bitiş karesi) markanın
görsel imzası; tanıtım görselleri de aynı işlemden geçer. Duotone
renkleri yeni palete güncellenir: is-siyahı `#0F1B16` + yeşil.
Fotoğraf belgesel ve gerçekçi; kusursuz vücut, stüdyo teri, motivasyon
klişesi yok. Konular: ürün ekranları, çizelge/veri motifleri, gündelik
nesneler (tartı, defter, su şişesi).

---

## 06 — İkonografi

**Taban:** Lucide çizgi ikonları — dolgusuz, ince tek ağırlık
(1.5 px hissi), yuvarlatılmış uç, aynı ızgara.

**Espri ikonda da yaşar — ama ince.** Kural: **espri silüette değil
detayda.** İkon uzaktan işlevsel okunur; yakından bakan göz kırpışı
görür. Örnek dokular:

- Su bardağı ikonunda minik ✓ filigranı ("içildi, onaylandı")
- Tartı ikonunun ibresi bir tık gülümseyen açıda
- Rapor/tahlil ikonunda köşesi kıvrık form kâğıdı + damga izi
- Boş durum çizimlerinde damga/kaşe motifi ("bugün boş — henüz
  damgalanmadı")

Sınır: bir ekranda en fazla bir-iki göz kırpma; ikonografinin tamamı
şakaya dönüşmez. İşlev her zaman espriden önce okunur.

---

## 07 — Tasarım İlkeleri

**Gölge yok, ton var.** Derinlik ton katmanı + kıl çizgiyle; hiçbir
yüzeyde gölge/degrade yok.

**Bir kahraman, bir vurgu.** Her yüzeyde tek büyük öge; yeşil yalnız
onu işaretler.

**Espri detayda, disiplin bütünde.** Uzaktan resmî, yakından hınzır —
isim gibi. Espri hiçbir zaman okunurluğun ve işlevin önüne geçmez.

**Renk asla yalnız konuşmaz.** Her renkli sinyalin yanında ikon ya da
metin vardır.

---

## 08 — Marka Yüzeyleri

- **Uygulama ikonu:** `#0F1B16` zemin + yeşil onay-nabız damgası
  (V2a); temadan bağımsız tek ikon.
- **Açılış ekranı:** Düz is-siyahı zemin, ortada damga, altında Barlow
  "Formality"; animasyon yoksa da olur, varsa tek yumuşak belirme.
- **Mağaza vitrini:** Ekran görüntüleri + her karede tek kahraman
  rakam + tek satır espri ("Forma girmek? Formalite."); koyu stüdyo
  çerçeve dili.
- **Sosyal medya:** İs-siyahı ya da soğuk beyaz kartlar, büyük Barlow
  rakam,
  Inter alt metin; kampanya sesi: "Sağlık ciddi iş. Biz değiliz."
- **README / web:** Mürekkep zemin, tek yeşil vurgu, ekran görüntüsü
  öncelikli; başlıkta mimari dürüstlük (çevrimdışı, veri sende).

---

## Uygulamaya etkisi (ayrı iş, bu brifin kapsamı dışında)

Palet B kabul edildiği için `app_palette.dart`'taki lacivert (`ink*`)
ve fildişi (`ivory*`) rampaları yeni mürekkep/krem değerlerine göre
yeniden türetilecek; `contrast_test.dart` eşikleri korunacak. Bu bir
kilometre taşı olarak ayrıca planlanmalı.
