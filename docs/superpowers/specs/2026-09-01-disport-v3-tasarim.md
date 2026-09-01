# di@sport v3 — Tasarım Belgesi

**Tarih:** 1 Eylül 2026
**Durum:** Onaylı mockup'tan türetildi — `docs/mockups/2026-09-01-v3-ekranlar.html` (r2.1)
**Önceli:** v2 spec (`2026-08-31-disport-v2-saglikli-yasam.md`) — orada değişmeyen her şey geçerli kalır; bu belge yalnız v3'te değişen ve ekleneni tanımlar. Çelişkide **bu belge kazanır**.

---

## 0. Sorun ve hedef

v2 işlevsel olarak tamam ama kullanılamıyor:

1. Onboarding tek form; karşılama, ekipman, medikal bilgi yok.
2. Ayarlar god ekran — kimlik, envanter, takviye, tema, dil, bildirim, yedek tek listede.
3. 368 besinlik veritabanı gezilemiyor; yalnız arama kutusundan erişiliyor.
4. `context.md` tahlil, ilaç, ekipman, katalog, günlük düzen, besin listesi ve yasaklıları **göndermiyor** — AI eldeki veriyle uyumsuz plan döndürüyor.
5. Plan yalnız baştan istenebiliyor; "şu tarihten sonrası" yok.
6. Yasaklı liste veritabanında var, hiçbir yerde kullanılmıyor.
7. Tahlil girişi yalnız elle; PDF'ten aktarma yok.
8. Ana Sayfa dokuz bölümlük bir kaydırma duvarı.

v3 bunların hepsini **tek bir bilgi mimarisi değişikliğiyle** çözer: dört alan
(diyet · spor · sağlık · ilaç) birinci sınıf olur, ilaç sağlığın altına girer,
gezinme beş sekmeye oturur.

Kullanıcının çerçevesi: *"İlaç takviye takibini, diyet takibini, spor takibini,
sağlıksal değerler takibini hep buradan yapacağız."*

---

## 1. Bilgi mimarisi

### 1.1 Alt menü

| Sekme | Renk | İçerik |
|---|---|---|
| **Ana Sayfa** | marka `#42B883` | Günün özeti + akışı. Tarihli gün ekranının `bugün` hâli. |
| **Diyet** | `#42B883` (c-diet) | Alt sekmeler: GÜNLÜK · BESİNLER · GEÇMİŞ |
| **Spor** | `#56B4E9` (c-sport) | Alt sekmeler: PLAN · ANTRENMAN · KATALOG |
| **Sağlık** | `#CC79A7` (c-health) | Alt sekmeler: TAHLİL · ÖLÇÜM · İLAÇ |
| **Daha** | nötr | Gruplanmış dizin (bkz. §7) |

Alan renkleri Okabe-Ito ailesinden (grafiklerle aynı). İlaç için `#B39DDB`
(c-med) yalnız ikon kutularında; sekme rengi değil. Renk hiçbir yerde tek
başına anlam taşımaz — ikon + etiket her zaman eşlik eder (v1 kuralı sürer).

**Kaldırılan:** İlerleme sekmesi. Kilo grafiği + haftalık özet + geçiş kriteri
→ Sağlık → ÖLÇÜM. Kalori grafiği → Diyet → GEÇMİŞ. Katalog sekmesi → Spor →
KATALOG. Bugün sekmesi → Ana Sayfa.

### 1.2 Ekran taşıma haritası (v2 → v3)

| v2 konumu | v3 konumu |
|---|---|
| Bugün sekmesi | Ana Sayfa |
| Plan sekmesi | Spor → PLAN |
| İlerleme sekmesi | Sağlık → ÖLÇÜM (kilo, haftalık özet, geçiş) + Diyet → GEÇMİŞ (kalori) |
| Sağlık sekmesi | Sağlık → TAHLİL |
| Katalog sekmesi | Spor → KATALOG |
| Ayarlar → takviye | Sağlık → İLAÇ |
| Ayarlar → ekipman | Daha → Ekipman ve sporların |
| Ayarlar → profil formu | Daha → Profil (yalnız kimlik + ölçü) |
| Ayarlar → Günlük Düzen | Daha → Günlük düzen (genişledi, bkz. §3.4) |
| Bugün → öğün bölümü | Diyet → GÜNLÜK (Ana Sayfa akışta gösterir, listelemez) |

Bildirim payload'ındaki `tabIndex` eşlemesi yeni sıraya göre güncellenir.

### 1.3 Gezinme kuralları

- Alt sekmeler **segment kontrol** (M3 `TabBar` alt çizgisi değil) — ekran
  içi ikinci bir sekme sırasıyla karışmasın.
- Ekran başlığı sekme adını **tekrarlamaz**. Ana Sayfa'da başlık günün adı
  ("Pazartesi"), üstünde eyebrow tarih; sağda ‹ · takvim · › gezinme.
- `IndexedStack` beş sekmeyi canlı tutmaya devam eder; akış (Stream) kuralı,
  `viewedDateProvider` kalıbı ve tarihli gün ekranı (M10) aynen sürer.

---

## 2. Görsel dil (mürekkep dili r2)

M12 mürekkep dili **sürer**: koyu Vue laciverti zemin, kart/gölge yok,
ton + kıl çizgi, Barlow Condensed sayılar, ekran başına bir kahraman.
r2'nin eklediği:

1. **Duotone ikon sistemi.** `phosphor_flutter` paketi (duotone ağırlık).
   İkonlar renkli ikon kutularında (`tile`): 40dp yuvarlatılmış kare,
   alan renginin yüzeyi + alan renginin kendisi. Material Icons yalnız
   sistem düzeyinde (geri oku vb.) kalır.
2. **Panel bileşeni** (`AppPanel`): `ink800` zemin + `ink750` kıl çizgi +
   16dp radius. M12'nin "diyalog istisnası" genelleşmiyor — panel gölgesiz,
   ton farkıyla ayrışır. `accent` varyantı marka yüzeyinden zemine geçişli.
3. **Segment kontrol** (`AppSegmented`): alt sekmelerin bileşeni.
4. **Vurgu çizgisi:** listede "sıradaki" satır sol kenarında 2dp alan rengi
   çizgisi taşır (Ana Sayfa akışı, ilaç listesi — aynı dil).
5. **Ferahlık:** bölüm arası boşluk `xl2`; satır yüksekliği ≥48dp;
   Ana Sayfa en fazla üç bölüm.

Kontrast kuralları ve `contrast_test.dart` aynen geçerli; yeni alan renkleri
teste eklenir (koyu zeminde ≥3:1 arayüz eşiği).

---

## 3. Kurulum (onboarding)

### 3.1 Akış

```
Hoş geldin (1 ekran, dört alan tanıtımı)
→ Adım 1/3: Kimlik (ad, soyad, doğum tarihi GG/AA/YYYY, cinsiyet)
→ Adım 2/3: Ölçüler (boy, kilo → ilk body_metrics kaydı, hedef kilo)
→ Adım 3/3: bitti → Ana Sayfa
```

- İlerleme çubuğu görünür (3 nokta).
- Cinsiyet: erkek / kadın / belirtmek istemiyorum — kalori hesabı gerekçesi
  ekranda yazar. Belirtilmezse ortalama katsayı.
- Doğum tarihi tam tarih; yaş türetilir. Doğum gününde Ana Sayfa başlığında
  kısa kutlama satırı görünür; **başka davranış değişmez**.
- VKİ değerlendirmesi onboarding'de **gösterilmez** (yeni kullanıcıya "obez"
  damgası kötü karşılama) — Sağlık → ÖLÇÜM'de yaşar.
- "Atla" yok: arkada boş uygulama var.

### 3.2 Kurulum kartları (Ana Sayfa)

İlk açılışta Ana Sayfa kahraman kalori **göstermez** (kayıt yokken anlamsız).
Yerine kurulum paneli: `1/4 tamam` ilerleme + üç kart:

| Kart | Süre | Açtığı ekran |
|---|---|---|
| Ekipmanlarını seç | 2 dk | §3.3 |
| Medikal bilgilerin | 3 dk | §4 |
| Günlük düzenin | 1 dk | §3.4 |

Her kartın **GEÇ** eylemi var; geçilen kart listeden düşer, ekran her zaman
Daha'dan erişilebilir. 4/4'te panel kendini kaldırır ve kahraman kalori
(plan varsa bütçe, yoksa toplam) devreye girer. Panel altında "İlk planını
iste" tonlu düğmesi.

### 3.3 Ekipman ve sporlar

Üç segment: **EVDE · SALONDA · SEVDİĞİN SPORLAR**.

- EVDE: mevcut `EquipmentKind` çipleri. **Ev eşyası artık sorulur:**
  sandalye ve basamak seçilebilir (varsayılan işaretsiz), duvar sorulmaz
  (her evde var). Bu iki eşya `EquipmentKind.other`dan ayrışır:
  `chair`, `step` enum değerleri eklenir ve `needsInventory=true` olur.
  Katalogdaki `other` ekipmanlı hareketlerden sandalye/basamak gerektirenler
  override ile yeni değerlere taşınır. Göç: mevcut kurulumlarda `chair` ve
  `step` **işaretli açılır** (v2 "herkeste var" varsayımını koruyarak) —
  yeni kurulumda işaretsiz.
- SALONDA: "Salona gidiyor musun?" anahtarı; açıksa salon çipleri.
- SEVDİĞİN SPORLAR: `activities` tablosundan çok seçim + isteğe bağlı sıklık
  notu. Yeni tablo `favorite_sports(activityId, note)` (SyncColumns).
  AI belgesine "sevdiği sporlar" bölümü olarak gider; Dışarıda listesinde
  üstte görünür.
- Her iki ekipman sekmesinde "Etkisi" paneli: işaretlere göre
  evde/salonda yapılabilen hareket sayısı; satırlarda "N hareket açar".

### 3.4 Günlük Düzen (genişler)

Mevcut: kalkış, uyku, mesai, uygun-değil pencereleri + 24 saat şeridi.
Eklenen: **öğün saatleri ve davranışı**.

Yeni tablo `meal_behaviors` (SyncColumns):

```
mealKind TEXT      -- MealKind enum adı
time     TEXT?     -- HH:mm, boşsa saat esnek
behavior TEXT      -- planned | fixed | external
fixedNote TEXT?    -- behavior=fixed ise ne yediği ("menemen + çay")
```

| behavior | Anlamı | AI'a etkisi | Diyet → GÜNLÜK'e etkisi |
|---|---|---|---|
| `planned` | Plan bu öğünü doldurur | Normal öğün önerilir | Plan satırları görünür |
| `fixed` | Hep aynı şey yenir | "Bu öğün sabit: X — kalorisini hesaba kat, değiştirme" | Tek dokunuş "her zamanki" |
| `external` | Yemekhane/dışarıda — kontrol dışı | "Bu öğünü planlama; kalan öğünleri denge için ayarla" | Serbest kayıt alanı, plan yok |

Alarm penceresi öğün hatırlatmalarını `time` değerinden okur; plan
slotlarındaki öğün saatleri **davranışı `planned` olanlarda** bu saatlerle
tohumlanır.

---

## 4. Medikal bilgiler (yeni feature: `medical`)

Yeni tablo `medical_facts` (SyncColumns):

```
kind  TEXT   -- condition | restriction | allergy | bloodType
label TEXT   -- "İnsülin direnci", "Diz hassasiyeti", "Laktoz", "A Rh+"
note  TEXT?  -- serbest ek ("derin çömelme yok")
```

- Ekran: çip tabanlı çok seçim + serbest ekleme; yaygın değerler öneri
  çipi olarak sunulur (kod sabitinden, çeviri ARB'den).
- İlaç listesi bu ekranın **içinde görünür** (Sağlık → İLAÇ verisinin aynası);
  ekleme aynı ilaç giriş sayfasını açar. Tek veri, iki kapı.
- Gizlilik notu ekranın başında: "telefondan çıkmaz; yalnız sen paylaş
  dediğinde AI'a gider."
- `restriction` kayıtları iki yerde tüketilir: AI belgesi (§9) ve hareket
  detayındaki güvenlik satırı eşleşince vurgulanır; plan içe almada kısıt
  kontrolü (§9.4).

İlaç modeli genişler: `supplements` tablosuna `kind TEXT` sütunu
(`prescription | supplement`, varsayılan `supplement`). Giriş sayfasında tür
seçimi; AI belgesinde iki ayrı bölüm.

---

## 5. Diyet

### 5.1 GÜNLÜK — plan ve gerçekleşen

Öğün grupları `MealKind` sırasında. Her grupta:

- **Gerçekleşen** kalemler dolu satır (`meal_entries`).
- **Plan** kalemleri soluk + italik + `PLAN` rozeti — plan slotu
  `mealKind` eşleşen ve o gün kayda dönmemiş öneriler.
- Grup başlığı durum rozeti taşır: girilen öğünde plandan ±%15 içindeyse
  `PLANA UYGUN`.
- **"Plandaki gibi yedim"** düğmesi: plan satırlarını tek dokunuşta
  `meal_entries` kaydına çevirir (porsiyonlar plandaki gibi; snapshot o anki
  besin değerinden hesaplanır). `behavior=fixed` öğünde düğme "Her zamanki"
  olur ve `fixedNote` kalemlerini yazar.
- `behavior=external` öğünde plan satırı beklenmez; yalnız serbest giriş.

Su: kutucuk değil **miktar**. `daily_logs.waterMl INTEGER` sütunu eklenir
(mevcut `waterTargetMet` türetilir hâle gelir: `waterMl >= hedef`; sütun
kalır, göçte bozulmaz). Bardak dokunuşu +250 ml; hedef plan hedefinden
(litre). Ana Sayfa metrik şeridi ve Diyet GÜNLÜK aynı veriyi okur.

### 5.2 BESİNLER

368 kayıt ilk kez gezilebilir liste:

- Arama (mevcut çift dilli katlama) + tür çipleri (8 öne çıkan).
- **Sıralama:** A–Z (varsayılan) · kalori ↑ · kalori ↓ · protein ↓ ·
  sık yenen. Bellekte sıralanır.
- Satır: ad, varsayılan porsiyon + porsiyon kalorisi, 100 g değeri.
  Porsiyon kalorisi ile 100 g değeri **birlikte** gösterilir.
- Yasaklı eşleşen besin `YASAKLI` rozeti taşır (bkz. §5.4).
- Dokunuş porsiyon sayfasını açar (mevcut); öğün bağlamı yoksa öğün önce
  sorulur.

### 5.3 GEÇMİŞ

Mevcut kalori çubukları + gün dökümü buraya taşınır. Kayıt olmayan gün
`—` (sıfır çizilmez). Gün satırı o günün Ana Sayfa'sını açar.

### 5.4 Yasaklı yiyecekler (bağlanır)

`PlanRules.forbidden` üç tüketici kazanır:

1. **Besin listesinde rozet.** Eşleşme: yasaklı satır metni besinin
   `searchText`'inde çift dilli katlamayla aranır ("hamur işi" → lahmacun
   eşleşmez; bu kabul — eşleşme ancak ad düzeyinde). Ek olarak yasaklı
   satırına **besin id listesi** iliştirilebilir: yasaklı editöründe
   "besinlere bağla" seçimi (`forbidden` yapısı `{label, foodIds[]}`
   olarak genişler; JSON gerekçesiyle şema değişmez, `rulesJson` içinde).
2. **AI belgesi** — §9.
3. **Plan içe alma kontrolü** — §9.4.

Kayıt **engellenmez**; rozet yalnız hatırlatır (kullanıcı kararı).

Yasaklı editörü Diyet'ten ve Daha'dan erişilir (aynı ekran).

---

## 6. Spor

### 6.1 PLAN

- Takvim hücreleri yalnız **antrenman bilgisini** taşır: gün tipi etiketi
  (SALON/EV/DİNLEN) + ✓/✗. Kalori tonu ve farkı **kaldırılır** (Diyet'in
  işi).
- Üst şerit: hafta, salon/ev hedefi, **uyum %** = tamamlanan antrenman
  günü / geçen planlı antrenman günü.
- Hücre dokunuşu **Planlanan/Yapılan** ekranını açar (§6.2).
- "Bu tarihten sonrası için yeni plan iste" düğmesi → §9.1 kapsam seçimiyle.
- Plan başlığı altında köken satırı sürer.

### 6.2 Planlanan / Yapılan (yeni ekran)

Bir günün antrenmanı iki sütunlu tablo: hareket · PLAN · YAPILAN.

- YAPILAN sütunu `exercise_logs`'tan; hedefi karşılayan satır yeşil ✓,
  altında kalan amber, hiç yapılmamış `— EKLE`.
- **Geçmiş güne set yazılabilir/düzeltilebilir:** satır dokunuşu set
  düzenleme alt sayfası açar (tekrar/kilo/süre düzelt, set ekle/sil).
  v2'nin bilinen boşluğu kapanır. Canlı sayaç yalnız bugünde.
- Seans satırı: süre + saat aralığı + ≈kcal; seans da düzenlenebilir
  (başlangıç/bitiş saati — geçmiş gün için elle seans girişi).
- Giriş noktaları: Spor → PLAN hücresi, Ana Sayfa akışındaki antrenman
  satırı, ANTRENMAN alt sekmesindeki geçmiş listesi.

### 6.3 ANTRENMAN

Aktif seans ekranı (mevcut) + geçmiş seans listesi. Aktif seansta değişiklik
yok; kahraman seans süresi.

### 6.4 KATALOG

- Yer seçimi **çip** (Evde/Salonda/Dışarıda) — segment üstte alt sekme
  olarak durduğu için ikinci segment sırası kullanılmaz.
- Satırda ekipman rozeti: `EVDE VAR` / `X GEREKİR`.
- Dışarıda: aktiviteler; sevilen sporlar üstte.

### 6.5 Hareket detayı — tam içerik + iki dilli veri

- Yapı: görsel şeridi → çipler → segment (NASIL · İPUCU · HATA · VARYANT).
- NASIL sekmesi: hazırlık paragrafı + numaralı adımlar + **nefes, tempo,
  güvenlik** satırları (ikon kutulu). Boş alan çizilmez; sekme tamamen
  boşsa gizlenir (v2 kuralı sürer).
- Güvenlik satırı, kullanıcının `medical_facts.restriction` kaydıyla
  eşleşiyorsa (anahtar kelime: kayıtta ilişkilendirilen vücut bölgesi)
  amber vurgulanır.
- **İçerik iki dilli veri olur.** Katalog şemasında metin alanları
  `xxxTr/xxxEn` çiftine ayrılır: `summary`, `setup`, `execution`, `cues`,
  `commonMistakes`, `breathing`, `tempo`, `safety`. Arayüz dili hangisiyse
  o gösterilir; boşsa öteki dile düşer. Bu **ARB işi değil** — içerik veri.
  Boru hattı: kaynak İngilizce alanları `En`e; `catalog_overrides.json`daki
  mevcut Türkçe içerik `Tr`ye; eksik çeviriler boş kalır ve `--check`
  raporlar. Çekirdek listede iki dil de zorunlu (seed test).

---

## 7. Sağlık

### 7.1 TAHLİL

- Üstte VKİ satırı (kilo + boydan türetilir; rozet: normal/fazla kilolu/
  obez eşikleri) — onboarding'den taşınan değerlendirme burada.
- Panel özeti: N normal · N sınırda · N yüksek çipleri.
- **Değer satırı aralık çubuğu taşır:** yeşil→amber→kızıl gradyan üstünde
  değerin konumu işaretli; hedef aralık metni satırda. Nokta-rengi tek
  başına dili terk edilir.
- Türetilen değerler (HOMA-IR) hesaplanır, sorulmaz (mevcut).
- Başlıkta paylaş: tahlil özeti metin olarak dışa (doktora).
- **+ Ekle** iki yol sunar: elle gir (mevcut form) / **yapay zekâ ile
  PDF'ten** (§9.5).

### 7.2 Check-up rehberi

Yeni saf domain: `checkup_rules.dart`. Kural = {tahlil kümesi, taban aralık,
koşullar}. Kaynaklar spec'e gömülür (kod yorumunda URL):

| Kural | Aralık | Koşul |
|---|---|---|
| Tam panel (CBC, CMP, lipit, HbA1c, TSH) | 2–3 yıl | <40 yaş, kronik yok |
| Tam panel | yıllık | ≥40 yaş |
| HbA1c | 6 ay | kronik: insülin direnci/diyabet/obezite (VKİ≥30) |
| Lipit | yıllık | son sonuçta sınırda/yüksek değer |
| Lipit | 4–6 yıl | sağlıklı |
| D vitamini + B12 | yıllık | herkese; ≥50 yaşta vurgulu |

Motor: kullanıcının yaşı + `medical_facts` + son `lab_results` tarihleri →
öneri listesi {tahlil, durum: vakti-geldi/‹N› ay sonra}. TAHLİL sekmesinde
"CHECK-UP REHBERİ" bölümü; "vakti geldi" satırı mevcut vade şeridinin
(`lab_schedules`) yerine geçmez — kullanıcının kendi vadeleri öncelikli,
rehber yalnız öneridir ve bir dokunuşla `lab_schedules`'a vade olarak
eklenebilir. Uygulama tıbbi tavsiye vermez; her öneri satırında "doktoruna
danış" imzası değil, bölüm başında tek bir açıklama satırı bulunur.

### 7.3 ÖLÇÜM

İlerleme sekmesinin taşındığı yer: toplam değişim kahramanı, kilo grafiği
(7 g ortalama), ölçüm listesi (+ ekle), haftalık özet kartları, geçiş
kriteri kartı. VKİ burada güncel kilo ile canlı.

### 7.4 İLAÇ

- Günün doz listesi (mevcut) + **sıradaki doz** sol vurgu çizgisiyle.
- **Son 7 gün uyum şeridi:** gün başına alınan/planlanan; tam gün yeşil
  yüzey, eksik amber, kayıtsız nötr.
- Tanımlı listesi: reçeteli ilaçlar `t-danger`, takviyeler `t-med` ikon
  kutusuyla ayrışır.
- + düğmesi ilaç giriş sayfası: ad, doz, birim, **tür (reçeteli/takviye)**,
  saat çipleri, gün çipleri. Kaydet düğmesi sonucu söyler: "Ekle —
  hatırlatma kurulur".

---

## 8. Daha

İki grup + profil başlığı:

1. **PLANINI ETKİLEYENLER** (alt yazı: "AI'a gider"): Medikal bilgiler ·
   Ekipman ve sporların · Günlük düzen · Yasaklı yiyecekler · Günlük
   kurallar. Her satırda özet sayı.
2. **UYGULAMA:** Bildirimler · Görünüm ve dil · Yedekleme (son yedek
   4+ gün eskiyse satırda amber uyarı).

Profil: yalnız kimlik (ad, soyad, doğum tarihi, cinsiyet) + ölçü (boy,
hedef kilo). Güncel kilo burada değil (ölçüm). Ad/soyad `profile_entries`e
yeni anahtarlarla girer; Ana Sayfa selamlama adı buradan okur.

Dizinde hiçbir şey düzenlenmez; her satır kendi ekranını açar.

---

## 9. AI köprüsü v2

### 9.1 Plan isteği — kapsam

İki seçenek: **şu tarihten sonrası** (varsayılan; tarih seçici, en erken
yarın) / **baştan yeni plan**.

"Şu tarihten sonrası" mekanizması: `context.md`'ye kapsam bölümü girer
("planı yalnız ‹tarih›–‹bitiş› için üret; önceki günler korunacak").
Dönen plan importer'da **mevcut aktif planın üstüne aşılanır**: seçilen
tarihten önceki `plan_days` satırları aynen kalır, o tarihten sonrakiler
silinip (yumuşak) yenileriyle değiştirilir; plan başlığı/hedefleri dönen
belgeden güncellenir, `sourceRaw`'a yeni belge eklenir. Kayıtlar
(`meal_entries`, `exercise_logs`…) tarihli olduğundan hiç dokunulmaz.

### 9.2 Gönderilecekler ekranı

Paylaşmadan önce bölüm listesi; her satır kapatılabilir (kapatılan bölüm
belgeye girmez). Varsayılan hepsi açık. "Önce belgeyi gör" önizleme.

### 9.3 context.md v2 — bölümler

1. Kim olduğun + hedef (mevcut, ad dahil değil — kimlik AI'a gitmez;
   yaş/boy/kilo gider)
2. **Medikal:** kronik durumlar, kısıtlar, alerjiler + tahlil özeti
   (son sonuçlar, hedef aralıklarıyla) + **ilaçlar** (reçeteli ayrı,
   takviye ayrı) + sınır satırı: *"İlaç etkileşimi, doz değişikliği ya da
   ilaç önerisi verme; ilaçları yalnız zamanlama ve beslenme bağlamı
   olarak kullan."*
3. **Ortam:** ekipman (ev/salon ayrı, enum adlarıyla) + sevdiği sporlar
   (sıklık notuyla)
4. **Günlük düzen:** kalkış/uyku/mesai/uygun-değil + **öğün davranışı
   tablosu** (planned/fixed+not/external)
5. **Yasaklılar:** liste + *"bunları asla önerme"*
6. **Son 14 gün:** öğün toplamları, su (ml), ilaç uyumu (gün başına
   alınan/planlanan), antrenman (yapılan/planlanan), kilo serisi
7. **Kurallar + hedefler** (mevcut plan varsa devamlılık bağlamı)
8. **Katalog:** 161 hareket tam liste (id·nameEn·yer·ekipman·kas)
9. **Besinler:** 368 besin tam liste (id·ad·kcal100·varsayılan porsiyon)
10. **JSON şeması + kapsam talimatı**

Tahmini boyut ~12k token; tek belge, tek yapıştırma.

### 9.4 İçe alma kontrolleri

Mevcut dört kapıya eklenen kontroller (kapı 3'ün parçası):

- **Yasaklı:** plandaki besin id'leri yasaklı bağlarıyla kesişiyorsa uyarı.
- **Ekipman:** plan hareketleri kullanıcının envanteriyle `canPerform`
  değilse uyarı.
- **Öğün davranışı:** `external` öğüne plan yazılmışsa uyarı; `fixed`
  öğün planda farklıysa uyarı.
- **Medikal kısıt:** hareketin güvenlik metni / kas grubu kullanıcının
  kısıtıyla eşleşiyorsa uyarı.

Uyarılar **reddettirmez** — önizlemede amber satır; "uyarılı hareketleri
değiştirerek uygula" ikinci yol sunar (uyarılı hareket, aynı kas grubundan
kısıtsız muadille değiştirilir; muadil yoksa satır atlanır ve söylenir).

### 9.5 Tahlil aktarımı (yeni akış)

Plan köprüsünün ikizi:

1. **`tahlil-aktar.md`** üretilir (builder: `lab_import_doc_builder.dart`):
   bizim tahlil id sözlüğümüz (MetricKinds + lab değer anahtarları),
   beklenen JSON şeması, birim kuralları, tarih zorunluluğu, "yalnız
   belgede gördüğün değerleri yaz, uydurma" talimatı.
2. Kullanıcı belgeyi kopyalar, PDF ile birlikte herhangi bir AI sohbetine
   atar. **PDF uygulamaya girmez.**
3. Dönen JSON yapıştırılır → ayrıştırma (`JsonReader` — yapıştırılabilir
   hata ilkesi) → **önizleme:** değer listesi, güvenilir satır ✓,
   şüpheli satır amber (birim tanınmadı / aralık dışı / id eşleşmedi) ve
   dokununca düzeltilir.
4. Onay: "N değeri kaydet · M'i atla". Onaysız hiçbir şey yazılmaz.

Şüpheli tanımı: id sözlükte yok · birim beklenen değil · değer fizyolojik
aralığın 10 katı dışında.

---

## 10. Şema değişiklikleri (v15)

Tek göç bloğu `if (from < 15)`:

| Değişiklik | Tablo |
|---|---|
| yeni | `medical_facts (kind, label, note)` |
| yeni | `meal_behaviors (mealKind, time, behavior, fixedNote)` |
| yeni | `favorite_sports (activityId, note)` |
| sütun | `supplements.kind TEXT DEFAULT 'supplement'` |
| sütun | `daily_logs.waterMl INTEGER?` |
| sütun | `equipment_items` — göçte `chair`,`step` satırları işaretli eklenir |
| veri | `exercises` içerik sütunları `xxxTr/xxxEn` çifti (yeni sütunlar `En`; mevcutlar `Tr`ye rename edilmez — mevcut sütun Tr sayılır, yeni `En` sütunları eklenir; boru hattı v3 tohumu üretir, sürüm damgası artar) |
| anahtar | `profile_entries`: `firstName`, `lastName`, `birthDate` (yyyy-MM-dd); eski `age` okunmaya devam eder, `birthDate` varsa türetilen yaş kazanır |

Not: katalog içerik alanları Drift'te ayrı sütun değil JSON blob'daysa
(mevcut durum: `searchText` dışında model JSON'dan) — bu durumda şema
değişikliği yalnız tohum sürümüyle gelir; göç maddesi uygulanmaz. Plan
aşamasında mevcut tablo yapısına göre netleşir.

---

## 11. Yapılmayacaklar (bilinçli)

- Barkod / fotoğrafla besin kaydı — kullanıcı isterse ayrıca söyleyecek.
- Yasaklı besinin kaydını engelleme — yalnız rozet.
- İlaç etkileşim kontrolü — uygulama tıbbi tavsiye vermez; AI'a da sınır
  satırıyla yasaklanır.
- Bulut, hesap, senkron — v1 kararı sürer.

## 12. Açık kalanlar (v3 sonrası)

- Uygulama ikonu + açılış ekranı (ürüne çıkmadan şart, bu spec kapsamı dışı).
- BYOK doğrudan API çağrısı.
- Beşinci sekme adı ("Daha" / "Daha fazlası") emülatörde genişliğe göre.
