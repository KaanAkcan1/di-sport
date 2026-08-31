# di@sport v2 — Sağlıklı yaşam programı

**Tarih:** 2026-08-31
**Durum:** onaylandı, uygulanmayı bekliyor
**Önceki spec:** [2026-08-28-disport-tasarim.md](2026-08-28-disport-tasarim.md) — v1'in tek doğruluk kaynağı;
bu belge onu değiştirmez, üstüne ekler. Çeliştikleri yerde **bu belge** geçerlidir.

---

## 1. Neden

v1 bir **antrenman takipçisi**: plan, günlük kayıt, tahlil, alarm. Çalışıyor.
Eksik olan, günün geri kalanı — ne yendiği, ne kadar enerji girip çıktığı,
hangi takviyenin alındığı. Bu üçü eklenince ürün "antrenman takibi"nden
**sağlıklı yaşam programına** dönüşür.

Buna paralel iki yapısal borç ödenmeli:

1. **Uygulama tek dilli.** Arayüz metinleri koda gömülü Türkçe. İngilizce
   çıkacaksa bu borç, yeni metin yazılmadan **önce** ödenmeli — yoksa
   ~120 hareket ve ~400 besin iki kez yazılır.
2. **Veri yalnız AI'dan giriyor.** Plan `plan.json` ile geliyor ve
   uygulama içinden değiştirilemiyor. Kullanıcı bir saati kaydırmak için
   AI'a gitmek zorunda. Aynı şekilde geçmiş bir günün kaydı da
   düzeltilemiyor — dün tartılmayı unutan kullanıcının yapabileceği bir
   şey yok.

---

## 2. Kapsam ve sıra

Beş kilometre taşı. Sıra tercih değil, bağımlılık:

| | İş | Neden burada |
|---|---|---|
| **M7** | Dil altyapısı | Sonraki dördü de yeni metin üretiyor |
| **M8** | Katalog 2.0 | M9 hareket başına MET'e dayanıyor |
| **M9** | Besin ve kalori | |
| **M10** | Düzenlenebilirlik | Öncekilerin ürettiği veriyi de düzenler |
| **M11** | Takviye ve ilaç | Bağımsız; en sona alındı |

Her taş kendi planını alır (`docs/superpowers/plans/`), kendi TDD
döngüsünü yürütür, kendi commit dizisiyle biter.

---

## 3. M7 — Dil altyapısı

### 3.1 Karar

Arayüz, katalog ve besin verisi iki dilli. **AI köprüsü kapsam dışı** —
`context.md` ve doğrulayıcı hata mesajları Türkçe kalır. Gerekçe: bu
metinler kullanıcıya değil AI'a gidiyor ve doğrulayıcının hata mesajları
AI'a geri yapıştırılmak üzere tasarlandı; iki dilli hâle getirmek
doğrulama testlerinin tamamını ikizler. Ayrı bir taş olarak ertelendi.

Kullanıcının girdiği metin (not, özel kural adı, özel ölçüm etiketi)
**çevrilmez** — o kullanıcının kendi metni, uygulamanın değil.

### 3.2 Altyapı

`flutter_localizations` + `gen_l10n`. Şablon dosya `app_tr.arb`, çeviri
`app_en.arb`. Şablonun Türkçe olması bilinçli: metinler önce Türkçe
yazıldı, anahtar adları ve çoğul kuralları oradan çıkıyor.

### 3.3 Dile bağlanması gereken üç yardımcı

`core/utils` altındaki üç sınıf şu an Türkçeyi varsayıyor:

| Bugün | Sonra | Değişen |
|---|---|---|
| `TurkishText.upper(s)` | `LocaleText.upper(locale, s)` | TR'de `i→İ`, `ı→I`; EN'de standart `toUpperCase()` |
| `TurkishText.fold(s)` | `LocaleText.fold(locale, s)` | Arama katlaması. **Katalog aramasında her iki dilin katlaması da denenir** — TR arayüzde "pushup" yazan kullanıcı sonuç görmeli |
| `TurkishDate`, `TurkishNumber` | `intl` `DateFormat`/`NumberFormat` | Ondalık ayracı, gün ve ay adları locale'den |

`LocaleText.upper` yalnız bir sadeleştirme değil: Dart'ın ASCII
`toUpperCase()`'i Türkçede "Kilo" → "KILO" veriyor ve bu "kılo" okunur.
Kural v1'de yazıldı, burada dile bağlanıyor.

### 3.4 Dil seçimi

Ayarlar'da üç seçenek: **Sistem · Türkçe · English**. Profil tablosunda
saklanır (`ProfileKeys.locale`), `DisportApp` bunu `MaterialApp.locale`e
verir. Varsayılan "Sistem".

### 3.5 Testler

- **Eksik çeviri testi:** `app_tr.arb`'deki her anahtar `app_en.arb`'de de
  var mı. Tek yönlü değil çift yönlü — fazlalık anahtar da hatadır.
- **Gömülü metin taraması:** `lib/` içindeki widget dosyalarında Türkçe
  karaktere sahip string sabiti kalmış mı. Kaba ama etkili; taşınmayı
  unutulan metni yakalar.
- Mevcut `contrast_test.dart` ve ekran testleri bozulmadan geçmeli.

---

## 4. M8 — Katalog 2.0

### 4.1 Ad gösterimi

Hareket adı özel addır; çevrilmesi kullanıcının internette aratmasını
zorlaştırıyor. Karar:

- **EN arayüzde:** yalnız İngilizce ad — `Goblet Squat`
- **TR arayüzde:** İngilizce ana, Türkçe parantez içinde —
  `Goblet Squat (Goblet Çömelme)`
- **Arama** her iki adda da tutar, her iki dilin katlamasıyla

### 4.2 Ekipman — serbest metinden tipli listeye

Bugün ekipman serbest metin Türkçe (`'vücut ağırlığı'`, `'dambıl'`).
Tipli olmadığı için "bu hareket ne gerektiriyor" rozeti üretilemiyor ve
M6'da eklenen envanter filtresi katlanmış dizgi karşılaştırmasına
dayanıyor — kırılgan.

free-exercise-db'nin 13 değerlik sabit listesi doğrudan alınıyor:

```
bodyOnly · barbell · dumbbell · kettlebell · cable · machine
bands · medicineBall · exerciseBall · foamRoll · ezCurlBar
other · none
```

`EquipmentKind` enum'ı olur; görünen adı iki dilde ARB'den gelir.
Envanter (`equipment_items`, v9) bu enuma bağlanır. Göç: mevcut Türkçe
dizgiler eşleme tablosuyla enuma çevrilir.

Katalog listesinde ve detayda **gereklilik rozeti**: hareketin istediği
ekipman envanterde yoksa açıkça söylenir — "Dambıl gerekiyor
(envanterinde yok)". Filtre bunu gizlemek yerine işaretler; kullanıcı
neyi kaçırdığını görmeli.

### 4.3 İçerik — ~120 hareket, hepsi tam kayıt

Kaynak [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
(Unlicense, kamu malı): 876 hareket, 873'ünde 2'şer kare
(başlangıç + bitiş) — mevcut `tools/build_catalog_images.py` boru hattı
tam bu formatı bekliyor.

Otomatik gelen alanlar: `nameEn`, `category`, `equipment`,
`primaryMuscles`, `secondaryMuscles`, `execution`, `images`.
Türetilenler: `id`, `location` (ekipmandan), `difficulty` (`level`'dan),
`videoQuery`.

**Gelmeyen alanlar araştırılıp yazılır:** `nameTr`, `summary`, `setup`,
`breathing`, `tempo`, `cues`, `commonMistakes`, `safety`,
`regressions`/`progressions`, `met`.

**Eksik alan kaydı dışlamaz — araştırılır, olmazsa boş kalır.**
Boş bırakmak son çare, ilk hamle değil. Bir alanın karşılığı
free-exercise-db'de yoksa sırayla şuralara bakılır:

1. Hareketin adıyla web araması — antrenman kaynakları, hareket
   kılavuzları, kolaylaştırma/zorlaştırma zincirleri
2. [2024 Adult Compendium](https://pacompendium.com/) — `met` için
3. Aynı kalıptaki komşu hareket — `regressions`/`progressions`
   zincirini kurmanın tek yolu genelde bu
4. Kas ve mekanik bilgisinden çıkarım — `breathing` ve `tempo` çoğu
   hareket için kalıptan türetilebilir (eksantrik fazda nefes al)

Bu dördü de sonuç vermezse alan boş bırakılır ve hareket yine de
kataloğa girer. Uydurmak, boş bırakmaktan kötüdür:
"sık yapılan hata" diye yazılmış tahmini bir cümle, gerçek bir hata
kaydıyla aynı görünür ve kullanıcı ikisini ayırt edemez.

Boş alan **ekranda gösterilmez** — sekme ya da bölüm hiç çizilmez.
Rozet, uyarı, "eksik" etiketi de yok: bu kullanıcının çözebileceği bir
sorun değil, gürültü olur.

Bunun tohum testine yansıması iki kademeli:

- **Her kayıtta zorunlu:** `id`, `nameEn`, `category`, `location`,
  `equipment`, `primaryMuscles`, `difficulty`, `execution` (≥2 adım).
  Bunlar olmadan kayıt işlevsizdir — plana konamaz, filtrelenemez.
- **Çekirdek listede ayrıca zorunlu:** `nameTr`, `summary`, `setup`,
  `breathing`, `cues` (≥2), `commonMistakes` (≥2), `safety`.
  Çekirdek = örnek planda ve programda geçen hareketler. Bunlar
  kullanıcının fiilen yapacağı hareketler; onlarda eksik alan kabul
  edilmez.

Çekirdek listesi testte açıkça yazılır. Bir hareket programa girerse
listeye eklenir ve test onu doldurmaya zorlar.

876'nın çoğu bu ürüne gürültü: 24 ayrı deadlift varyantı, strongman ve
olympic weightlifting kategorileri. Süzme ölçütü **kapsama**: her hareket
kalıbı (itme/çekme yatay ve dikey, kalça menteşesi, çömelme, taşıma,
gövde) × her ekipman × ev/salon kombinasyonu temsil edilsin, varyant
yığılmasın.

**İçeriğin niteliği:** bu alanlar araştırma ve genel antrenman
bilgisinden yazılıyor, hakemli kaynaktan değil. Bu yüzden `safety`
alanı temkinli tutulur ("ağrı varsa dur ve yüksekliği artır" gibi), ve
`catalog_seed_test.dart` **yapıyı** denetler — doğruluğu değil. Bu
sınır bilinerek kabul edildi.

### 4.4 MET

Her harekete `met` alanı ([2024 Adult Compendium of Physical
Activities](https://pacompendium.com/) referansıyla). M9'un egzersiz
kalorisi buna dayanıyor. Örnek: dinamik ağırlık antrenmanı ~5.0,
yürüyüş bandı %8 eğim ~6.0, plank ~3.0.

### 4.5 Dönüştürücü

`tools/import_free_exercise_db.py` — iskeleti üretir, elle yazılan
alanları ayrı bir dosyadan (`tools/catalog_overrides.json`) birleştirir.
Katalog üretimi tekrarlanabilir kalır; kaynak güncellenirse elle yazılan
içerik kaybolmaz.

---

## 5. M9 — Besin ve kalori

### 5.1 Veri kaynağı

Araştırma sonucu: **hazır ve güvenilir bir Türk yemeği veri seti yok.**

| Kaynak | Neden yetmiyor |
|---|---|
| TürKomp (Tarım Bakanlığı) | ~500 besin, TR+EN, ama toplu indirme/API yok ve **ham besin** — "kuru fasulye tanesi" var, "etli kuru fasulye" yok |
| [USDA SR Legacy](https://fdc.nal.usda.gov/) | 7.793 kayıt, kamu malı, CSV. İngilizce ve ham besin ağırlıklı; "raw, with salt" gibi onlarca varyant arama deneyimini bozar |
| Open Food Facts | 500k+ barkodlu market ürünü. Ev yemeği yok, APK'ya sığmaz, çevrimiçi ister — çevrimdışı mimariyi bozar |

Ev yemeği kalorileri yalnız yemek sitelerinde ve birbirini tutmuyor:
"etli kuru fasulye" için 244–360 kcal aralığı görüldü.

**Karar:** küratörlü liste birinci sınıf. Önce elle yazılan liste
(Türk ev yemekleri, yaygın ürünler, meyve/kuruyemiş/içecek), eksik
kalanlar **USDA SR Legacy'den aynı formata dönüştürülerek** eklenir.
Türkçe karşılığı olmayan kayıt İngilizce adıyla kalır. Her kayıt
kaynağını taşır (`source`, `sourceRef`) — bir değer sorgulanırsa
nereden geldiği görülebilmeli.

Hedef: ~400 kayıt.

### 5.2 Veri modeli — üç tablo

Üç ayrı şey var: *besin nedir*, *nasıl ölçülür*, *ne yendi*.

```
foods                        (şema v11)
  id · nameTr · nameEn · category
  kcal100 · protein100 · carb100 · fat100
  source(curated|usda|user) · sourceRef
  + SyncColumns

food_portions                ev ölçüleri
  id · foodId · labelTr · labelEn · grams · isDefault
  + SyncColumns

meal_entries                 ne yendi
  id · date · mealKind · slotId?
  foodId · quantity(double) · portionId? · grams
  kcalSnapshot · proteinSnapshot
  + SyncColumns
```

**Kategoriler:** yemek · çorba · meyve · sebze · kuruyemiş · içecek ·
süt ürünü · ekmek/tahıl · et/balık · atıştırmalık · diğer.
Arama kutusu türden bağımsız, hepsinde gezer.

**`mealKind`:** kahvaltı · ara öğün · öğle · ikindi · akşam · gece.
Plan slotu varsa `slotId` ile bağlanır; yoksa serbest kayıt olur —
plansız da yemek kaydedilebilmeli.

**Kalori ve protein neden kayıtta donduruluyor:** kullanıcı bir besinin
değerini sonradan düzeltirse geçmiş günlerin toplamı değişmemeli. Dün
ne yendiği bir *gerçek*; bugün tahmini iyileştirmek onu geçmişe dönük
bozmamalı. Katalogda bu sorun yok — hareket anlatımı sayı üretmiyor.

### 5.3 Porsiyon seçimi

Besin seçilince varsayılan ev ölçüsü gelir, yanında miktar çarpanı.
"3 porsiyon yedim" → `quantity = 3`, `grams = 3 × 250`. Gram girmek de
mümkün ama öne çıkan yol ev ölçüsü — kimse tabağını tartmıyor.

```
┌──────────────────────────────────┐
│ Etli Kuru Fasulye                │
│ Beef & Bean Stew                 │
│                                  │
│  1 kase (250 g)            ▾     │
│  ─  [ 3 ]  ＋                    │
│                                  │
│  750 g · 810 kcal · 42 g protein │
│             [ Öğüne ekle ]       │
└──────────────────────────────────┘
```

### 5.4 Bütçe ve denge

Planın `goals.dailyKcal` değeri bütçe. Yenenler düşer, egzersiz geri
ekler:

```
kalan = hedef − yenen + egzersizKalorisi
egzersizKalorisi = Σ (met × kiloKg × süreSaat)
```

Bugün ekranında bir **kalori kartı** — mevcut `AppStatBand`'e üçüncü
sütun eklenmez; band iki sütuna bilerek indirilmişti (v1'de üçüncü sütun
alttaki kartın başlığını tekrarlıyordu).

Protein de sayılır — planda zaten `goals.proteinG` var.

**Egzersiz kalorisi tahmindir ve öyle gösterilir:** "≈ 240 kcal".
Kesin sayı göstermek, olmayan bir hassasiyet iddia eder.

Plan yoksa bütçe yok — yalnız toplam gösterilir. Uydurma bir hedef
üretmek yanlış sinyal olur.

### 5.5 Ekran

Besin arama ve öğün kaydı **Bugün** ekranından açılan bir sayfa.
Ayrı sekme açılmıyor: beş sekme sınırı doldu ve öğün kaydı günün
kaydının parçası, ayrı bir alan değil.

---

## 6. M10 — Düzenlenebilirlik

### 6.1 İki istek, tek altyapı

1. Geçmiş günlerde düzenleme yapılabilmeli
2. AI'dan JSON ile gelen her veri uygulama içinden düzenlenebilmeli

İkisi de aynı boşluktan doğuyor: veri tek yönlü akıyor.

### 6.2 Tarihe bağlı gün ekranı

`todayProviders` bugüne sabit. `dayProviders(date)` hâline gelir; Bugün
ekranı `date = bugün` ile çağrılan özel hâli olur.

Gezinme iki yoldan:
- Bugün ekranının başlığı tarih seçici; sol/sağ oklarla gün gün gezinir
- Plan takviminde bir güne dokunmak aynı ekranı o tarihle açar

**Kural:** ölçüm kaydı (kilo, uyku, öğün) yalnız bugüne ve geçmişe
girilebilir — gelecekte "ne yedim" sorusunun cevabı yok. Plan düzenleme
her tarihte serbest.

Başlık bugün olmayan bir tarihteyse görsel olarak ayrışır; kullanıcı
yanlışlıkla geçmişe kayıt girdiğini fark etmeli.

### 6.3 Plan editörü

`plans`, `plan_days`, `plan_slots`, `plan_exercises` yazılabilir olur.

| Ekran | Düzenlenen |
|---|---|
| Plan ayarları | Başlık, hedefler (kcal, protein, su, haftalık salon/ev), beslenme kuralları (yasak/serbest listeleri) |
| Gün düzenleme | Tip (salon/ev/dinlenme), günün başlığı, akşam önerisi |
| Slot düzenleme | Saat, tür, etiket, not; ekle/sil/sırala. **Öğün türü burada seçilir** (`mealKind`) |
| Hareket düzenleme | Katalogdan seç; set, tekrar, süre, dinlenme, şiddet |

Ayrıca **boş plan oluşturma**: AI'a gitmeden sıfırdan plan kurulabilmeli.
Bugün plan yalnız `plan.json` ile ya da örnek planla geliyor.

`FullPlan.sourceRaw` (AI'ın verdiği ham JSON) korunur ama artık planın
*tanımı* değil *kökeni* olur — düzenlemeden sonra ikisi ayrışır ve bu
normaldir. Plan detayında "AI'dan geldi, sonra düzenlendi" bilgisi
gösterilir.

### 6.4 M6'dan devreden

- Uyanma/uyku saatleri Ayarlar profil formundan **kaldırılır**, M6'da
  eklenen haftalık pencere ekranına taşınır. Ekranın adı **Günlük
  Düzen** olur; kalkış, uyku, mesai ve uygun olmayan saatler tek yerde.
- Ayarlar'daki serbest metin "aile yemeği saati" alanı kaldırılır;
  karşılığı plan slotudur.

---

## 7. M11 — Takviye ve ilaç

Vitamin ve ilaç takibi. Plan slotu **değil** ayrı tablo: her gün tekrar
eder, plandan bağımsız yaşar ve plan değişince kaybolmamalı.

```
supplements                  (şema v12)
  id · nameTr · nameEn · dose · unit
  times(HH:mm listesi) · weekdays · note
  + SyncColumns

supplement_logs
  id · date · supplementId · time · takenAt?
  + SyncColumns
```

Alarmlar mevcut `planWindow` üzerinden kurulur — altıncı bildirim türü.
Bugün ekranında günün kuralları kartının yanında bir takviye kartı.

M6'nın "kullanıcı tanımlı veri" kalıbı aynen uygulanır: yerleşik
tohumlanmaz (kimsenin varsayılan vitamini yok), silme yumuşak, geçmiş
kayıt bozulmaz.

---

## 8. Kapsam dışı

Bilerek yapılmayanlar:

- **Barkod okuma.** Çevrimiçi gerektirir; çevrimdışı mimariyi bozar.
- **Fotoğraftan kalori tahmini.** Güvenilmez; yanlış sayı hiç sayı
  olmamasından kötü.
- **AI köprüsünün iki dilli olması.** Doğrulayıcı hata mesajları AI'a
  geri yapıştırılmak üzere yazıldı; iki dilli hâle getirmek doğrulama
  testlerinin tamamını ikizler. Ayrı bir taşa bırakıldı.
- **Karbonhidrat ve yağ hedefi.** Değerler saklanır ama hedef ve uyarı
  üretilmez — kcal ve protein yeterli sinyal veriyor, üç hedef daha
  eklemek ekranı gürültüye boğar.
- **Tarif ve malzeme kırılımı.** Besin kaydı porsiyon düzeyinde kalır.

---

## 9. Riskler

| Risk | Karşılık |
|---|---|
| ~120 hareketin elle yazılan alanları tutarsız kalır | Tohum testi çıtayı yapısal olarak zorlar; içerik toplu değil kalıp kalıp yazılır |
| ~400 besinin kalori değerleri yanlış olabilir | Her kayıt kaynağını taşır; kullanıcı düzeltebilir; geçmiş kayıt dondurulduğu için düzeltme geriye yayılmaz |
| Dil taşıması sırasında metin kaybı | Gömülü Türkçe metin taraması + eksik çeviri testi |
| Plan editörü AI akışını bozar | `sourceRaw` korunur; içeri alma yolu değişmez, editör onun üstüne biner |
| Şema v10 → v12 göçleri | Her sürüm kendi `if (from < N)` bloğunu alır; eskiler değiştirilmez (v1 kuralı) |
