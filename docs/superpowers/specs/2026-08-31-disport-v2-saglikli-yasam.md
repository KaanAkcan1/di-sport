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
   AI'a gitmek zorunda.
3. **Geçmişe erişim yok.** Bugün ekranı bugüne sabit; dün tartılmayı
   unutan kullanıcının kaydı sonradan girmesinin yolu yok, geçmiş bir
   günün kaydını düzeltmenin de. Takvim var ama yalnız gösteriyor.

M10 bu ikisini birden çözüyor (bkz. §6).

---

## 2. Kapsam ve sıra

Altı kilometre taşı. Yürütme sırası:

| Sıra | İş | Şema | Neden burada |
|---|---|---|---|
| 1 | **M12** Tasarım yenilemesi | — | Kullanıcının bugün gördüğü sorun; sonraki her ekran yeni dille kurulsun |
| 2 | **M7** Dil altyapısı | — | Sonraki dördü de yeni metin üretiyor |
| 3 | **M11** Takviye ve ilaç | v11 | Kullanıcı isteğiyle öne alındı; bağımsız olduğu için sıkışabildi |
| 4 | **M8** Katalog 2.0 + ekipman | v12 | M9 hareket başına MET'e dayanıyor |
| 5 | **M9** Besin ve kalori | v13 | |
| 6 | **M10** Düzenlenebilirlik | — | Öncekilerin ürettiği veriyi de düzenler |

Her taş kendi planını alır (`docs/superpowers/plans/`), kendi TDD
döngüsünü yürütür, kendi commit dizisiyle biter.

---

## 2a. M12 — Tasarım yenilemesi: mürekkep dili

Taslaklarla karara bağlandı (artifact: `disport-v2-mockups.html`,
statik HTML; kaynak scratchpad'de, karar verilmiş son hâl yayında).
M6'nın "beyaz kart + yumuşak gölge + soluk zemin" dili terk edildi —
kullanıcı bunu açıkça reddetti ("yapay zekâi"). Yeni dilin çıkışı
ürünün kendisi: bu uygulama bir çizelgenin dijitali, içeriği sayı.

### Kurallar

1. **Zemin Vue laciverti mürekkep** (`#16232f` ailesi), koyu öncelikli.
   Vue'nun iki rengi var: lacivert zemin, yeşil vurgu. Yeşil koyuda
   elektrik gibi okunur — açık zeminde kaybolması M6'nın ana
   şikâyetiydi. Açık tema ölmez: aynı hiyerarşi fildişi + mürekkep
   metinle kurulur, Ayarlar'dan seçilir.
2. **Kart ve gölge yok.** Ayrım ton katmanları ve ince çizgiyle
   (`hairline`). `AppElevation` kullanım dışı kalır.
3. **Her ekranın bir kahraman rakamı var:** Bugün'de kalan kalori,
   İlerleme'de toplam kayıp, Antrenman'da süre/seans kalorisi.
   Kahraman ~56pt Barlow Condensed; geri kalanı tek satır metrik
   şeridi. (Whoop deseni: tek skor, uzaktan okunur.)
4. **Yeşilin tek anlamı ilerleme + eylem.** Tamamlanan, aktif olan,
   basılacak olan. Aşım kızıl, eksik amber; üçü asla karışmaz ve
   renk hep sayı/metinle birlikte (v1 erişilebilirlik kuralı sürer).
5. **Tahmin `≈` ile işaretlenir** — kalori hesabının her göründüğü yerde.

### Ekran kararları

| Ekran | Karar |
|---|---|
| Bugün | Kahraman: kalan kcal + ince gauge. Tek satır metrik (kilo, protein, program, spor). Hafta şeridi: 7 nokta, kaçak gün sönük. Omurga ince çizgili liste, slot türü ikonlu (kalkış/öğün/spor/takviye/uyku). **Sıradaki iş "SIRADA" kartına büyür** — tek dokunuşla başlar. Her satır dokununca gerçekleşeni girme/düzenleme açar. Altta üç hızlı eylem: +Öğün, +Tartı, +Aktivite |
| Plan takvimi | Gün hücreleri kalori dengesiyle tonlanır: yeşilimsi = bütçe altı, kızılımsı = üstü, kesikli çerçeve = serbest gün. Hücrede fark rakamı; antrenman günü ▲. **Serbest güne değer girilirse yine hesaplanır** — çerçeve kesikli kalır, sayı gelir. Güne dokun → o gün tam yetkiyle açılır (M10). Hafta özeti satırı **istenmedi**, eklenmeyecek |
| Katalog | Yer = bağlam, filtre değil: tepede üç sekme **Evde · Salonda · Dışarıda**. Dışarıda sekmesi serbest aktiviteleri (M9 `activities`) MET ve ≈kcal/saat ile listeler. Kalan filtreler tek ⚙ düğmesinde (rozet = aktif sayısı; alt sayfa: ekipmanıma uygun anahtarı, tür, kas grubu, zorluk). Aktif filtreler ×'li etiket olarak görünür. Liste "SON YAPTIKLARIN" ile açılır — son seans özeti ve ilerleme etiketi (↗ +2,5 kg) satırda |
| Öğün kaydı | Bugün'den açılır, sekme değil. Arama **asla boş açılmaz**: "SIK YEDİKLERİN" tek dokunuş + öğün şablonları ("Kahvaltım" → n kalem birden). Tür kartları görselli (Yemek, Çorba, Kahvaltılık, Meyve, Sebze, Kuruyemiş, İçecek, Tahıl ürünleri). Aynı seçici plan editöründe de kullanılır |
| Antrenman | Set satırında iki soluk sütun: **GEÇEN + PLAN** (Hevy deseni). Set ✓'lanınca dinlenme sayacı otomatik başlar. Tepede canlı süre + ≈kcal |
| İlerleme | Üç katman (Whoop): kahraman rakam → trend grafikleri → derine iniş. Kilo grafiğine ek **haftalık kalori çubukları**: 7 gün hedef çizgisine karşı, aşan gün kızıl; çubuğa dokun → o günün öğün dökümü |

### Sıralama notu

M12 görsel dili kurar ve **mevcut** ekranları taşır. Sonraki taşların
getirdiği yeni öğeler (kalori kahramanı, takvim tonlaması, GEÇEN
sütunu…) veri gelmeden boş kalacağından, M12'de yerleri hazırlanır ama
veriye bağlanmaları kendi taşlarında yapılır — ör. kalori şeridi M9'da
dolar, o zamana dek kahraman rakam kilo/program ikilisidir.

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

### 4.2.1 Envanter yere bağlı

Bugünkü envanter düz bir "sahip olduklarım" listesi. Ama bu ürünün
ayrımı ev ile salon: evde dambıl var, salonda kablo makinesi var, ve
"bu hareketi yapabilir miyim" sorusunun cevabı **nerede antrenman
yaptığına göre değişiyor**. Tek liste bu soruyu cevaplayamıyor.

`equipment_items` iki bayrak alır (şema v12):

```
equipment_items
  id · kind(EquipmentKind) · labelTr? · labelEn?
  atHome(bool) · atGym(bool)
  + SyncColumns
```

İki ayrı satır değil iki bayrak: aynı ekipman ikisinde de olabilir ve
onu iki kayıtla temsil etmek "dambılı sildim" dediğinde hangisinin
silineceğini belirsizleştirirdi.

Ayarlar'daki envanter ekranı iki sütunlu olur:

```
                        Ev   Salon
  Vücut ağırlığı         ✓     ✓
  Dambıl                 ✓     ✓
  Direnç bandı           ✓     ─
  Kablo makinesi         ─     ✓
  Barbell                ─     ✓
  Kettlebell             ─     ─
```

Yerleşik ekipmanlar tohumlanırken **hiçbiri işaretli gelmez** — vücut
ağırlığı hariç. Kullanıcıya sahip olmadığı şeyi varsaymak, filtrenin
ilk günden yanlış çalışması demek.

`canPerform` yere bağlanır:

```dart
bool canPerform({
  required List<EquipmentKind> required,
  required EquipmentInventory inventory,
  required ExerciseLocation where,   // home | gym
})
```

Katalog filtresi de bu bağlamı taşır: ev/salon seçimi zaten var
(`ExerciseLocation`), envanter artık ona uyar.

### 4.2.2 Gereklilik rozeti

Katalog listesinde ve detayda: hareketin istediği ekipman o yerdeki
envanterde yoksa açıkça söylenir — "Dambıl gerekiyor (evinde yok)".
Filtre bunu **gizlemek yerine işaretler**; kullanıcı neyi kaçırdığını
görmeli, aksi hâlde katalog sessizce küçülür ve bunun neden olduğu
anlaşılmaz.

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

### 4.4 MET ve enerji modeli

Her harekete iki alan: `met` (temel değer) ve `metModel` (nasıl
hesaplanacağı). Kaynak [2024 Adult Compendium of Physical
Activities](https://pacompendium.com/).

**Tek MET değeri kardiyoda yetmiyor.** Koşu bandında 5 km/h düz
yürüyüş ~4 MET, 8 km/h %8 eğimde ~11 MET — aynı harekete tek sayı
vermek üç kat hata demek. Bu yüzden `metModel` var:

| `metModel` | Kim kullanıyor | Nasıl |
|---|---|---|
| `fixed` | Kuvvet ve gövde hareketleri | `met` sabit. Compendium: kuvvet antrenmanı hafif/orta 3.5, dinamik/yüksek 6.0 |
| `treadmill` | Koşu bandı, yürüyüş | ACSM denklemi, **hız + eğim** girdisiyle |
| `cycling` | Kondisyon bisikleti | Direnç kademesi → MET tablosu (aşağıda) |

**ACSM metabolik denklemleri** (`VO₂` ml/kg/dk, hız m/dk, eğim ondalık):

```
yürüyüş  (< 7 km/h):  VO₂ = 0.1×hız + 1.8×hız×eğim + 3.5
koşu     (≥ 7 km/h):  VO₂ = 0.2×hız + 0.9×hız×eğim + 3.5
MET = VO₂ / 3.5
```

**Bisiklette denklem kullanılmıyor.** ACSM'in bisiklet denklemi watt
istiyor; ev ve salon bisikletlerindeki "direnç kademesi" cihaza özel ve
watt'a güvenilir şekilde çevrilemiyor. Bunun yerine kademe → MET
tablosu, Compendium'un bisiklet satırlarına dayanarak: hafif ~5.0,
orta ~7.0, yüksek ~10.5. Kademe sayısı cihaza göre değiştiği için
kullanıcı üç kaba seviyeden seçer, kademe numarası girmez — sahte
hassasiyet üretmemek için.

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
foods                        (şema v13)
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

### 5.5 Egzersiz enerjisi — nerede hesaplanır

**Hesaplayıcı:** `workout/domain/energy_estimator.dart` — saf, girdisi
`met`/`metModel` + kilo + süre + şiddet, çıktısı kcal. Veritabanı
görmez, Riverpod görmez; testi doğrudan yazılır.

`nutrition` feature'ı bu değeri **port üzerinden** okur
(`EnergySource`), `workout` uygular. `ai_bridge`'de kurulan desenin
aynısı: besin özelliği antrenmanın `data/` katmanını import etmez.

**Şiddet nereden geliyor:** plan zaten `PlanExercise.intensity`
taşıyor ("d6", "%8") ama serbest metin — hesaba giremez. M9'da tiplenir
(v13 göçüyle; plan review'i alanın M8-M9 arasında sahipsiz kaldığını
gösterdi, sahibi M9):

```
PlanExercise
  ...
  speedKmh?      koşu bandı
  gradePct?      koşu bandı
  effort?        light | moderate | vigorous   (bisiklet, kuvvet)
```

**Planlanan ve yapılan ayrı saklanır.** Plan ne dediyse
`plan_exercises`'ta durur; kullanıcının fiilen yaptığı `exercise_logs`'a
yazılır — aynı alanlar, ayrı satır:

```
plan_exercises     planlanan:  4 × 12 · %8 eğim · 6 km/h
exercise_logs      yapılan:    4 × 10 · %10 eğim · 5.5 km/h
```

Kalori **yapılandan** hesaplanır. Bu ayrım şart: bandı %10'a çıkaran
kullanıcının harcadığı enerji plandakinden farklı, ve "planı
tutturdum mu" sorusunun cevabı ancak ikisi ayrı dururken verilebilir.
Tek alanda saklamak, kaydı girer girmez planı yok eder.

Antrenman ekranı planlanan değerlerle **önceden dolu** gelir; kullanıcı
farklı yaptıysa üzerine yazar. Sapma varsa gün görünümünde
gösterilir — "planlanan 4 × 12, yapılan 4 × 10".

**Kuvvet setlerinde süre:** antrenman ekranı zaten set sayacı ve
dinlenme sayacı tutuyor, yani seansın geçen süresi biliniyor. Kuvvet
kalorisi **seans süresi** üzerinden hesaplanır, set başına değil —
Compendium'un kuvvet antrenmanı MET'i zaten dinlenmeler dahil bir
seansı tarif ediyor. Set başına hesaplamak sayıyı üçe böler.

### 5.6 Serbest aktivite — futbol, boks, basketbol…

Katalog hareketleri set ve tekrarla ölçülüyor. Bir futbol maçının seti
yok; olan tek şey **süre**. Bunu katalog kaydı yapmak yanlış olurdu —
dört sekmeli detay ekranı, kolaylaştırma zinciri, sık hatalar; hiçbiri
karşılığı olmayan alanlar.

Ayrı ve hafif bir tablo çifti (şema v13 ile birlikte):

```
activities                   MET tablosu
  id · nameTr · nameEn · category · met · source
  + SyncColumns

activity_logs                ne kadar yapıldı
  id · date · activityId · minutes · kcalSnapshot
  + SyncColumns
```

Kayıt akışı tek adım: **aktivite seç → süre gir**. Kalori
`met × kilo × saat` ile çıkar ve Bugün ekranındaki bütçeye girer.

**Tohum:** [Compendium'un spor bölümünden](https://pacompendium.com/sports/)
~70 yaygın aktivite. Doğrulanmış örnek değerler: basketbol maçı 8.0 ·
basketbol genel 7.5 · boks ringde 12.3 · boks kum torbası 5.8 ·
badminton yarışma 7.0. Futbol, yüzme, tenis, dans, yürüyüş ve ev işi
satırları aynı kaynaktan alınır; **her kayıt Compendium kodunu
`source` alanında taşır**, böylece bir değer sorgulanırsa nereden
geldiği görülebilir.

Kullanıcı kendi aktivitesini de ekleyebilir (M6'nın kullanıcı tanımlı
veri kalıbı): ad + MET. MET bilmiyorsa üç kaba seviyeden seçer —
hafif 3.0, orta 6.0, yoğun 9.0.

**Nerede görünür:**

1. **Antrenman ekranı**, seans bitince: "≈ 320 kcal"
2. **Bugün ekranı kalori kartı**: hem antrenman hem serbest aktivite
   bütçeye geri ekler
3. Başka yerde değil. İlerleme ekranına haftalık yakılan kalori
   eklemek düşünüldü ve **atıldı** — tahmin üstüne tahmin biriktirmek,
   kilo grafiğinin verdiği gerçek sinyali gölgeler.

**Hata payı açıkça taşınır.** Her yerde `≈` işaretiyle gösterilir.
ACSM denklemleri yürüyüş ve koşu için doğrulanmış; kuvvet antrenmanı
MET'i kaba bir ortalama ve kişiden kişiye belirgin değişiyor. Kesin
sayı göstermek, olmayan bir hassasiyet iddia etmek olur.

### 5.7 Ekran

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

Geçmiş bir gün **tam yetkiyle** açılır: kilo, uyku, kurallar, not, öğün
ve antrenman kaydı hem düzenlenebilir hem sonradan **eklenebilir**.
Salt-okunur bir geçmiş görünümü değil — dün tartılmayı unutan kullanıcı
bugün girebilmeli.

Gezinme iki yoldan:

- **Takvimden:** Plan takviminde bir güne dokunmak o günü açar. Takvim
  bugün yalnız gösteriyor; asıl giriş kapısı bu olur. Kayıt girilmiş
  günler takvimde işaretlenir, böylece boşluklar görülür.
- **Bugün ekranından:** başlık tarih seçici olur; sol/sağ oklarla gün
  gün gezinir.

**Tek kural:** ölçüm kaydı (kilo, uyku, öğün) yalnız bugüne ve geçmişe
girilebilir — gelecekte "ne yedim" sorusunun cevabı yok. Plan düzenleme
her tarihte serbest.

Bugün olmayan bir tarihte başlık görsel olarak ayrışır ve "bugüne dön"
kısayolu çıkar; kullanıcı hangi günde yazdığını her an bilmeli.

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
supplements                  (şema v11)
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
| Şema v10 → v14 göçleri | Her sürüm kendi `if (from < N)` bloğunu alır; eskiler değiştirilmez (v1 kuralı). M11 → v11 (takviye), M8 → v12 (ekipman enum + yer bayrakları), M9 → v13 (besin + aktivite + plan/log şiddet alanları), M10 → v14 (`plan_slots.mealKind`) |

## Uygulama sırasında alınan kararlar

### M9 — şablon yerine "son öğünü kopyala"

Spec §5.3'te öğün şablonu (`meal_templates`) öngörülmüştü. Uygulamada
açılmadı: kullanıcının kahvaltısı zaten tekrar ediyor ve `copyMeal`
aynı işi tablo açmadan yapıyor. **Kaynak gün "dün" değil, o öğünde
kayıt bulunan en son gün** — dün kahvaltı girilmemiş olabilir ve boş
bir kopya hiçbir işe yaramaz.

Gerçek şablon özelliği (adlandırılmış, elle düzenlenebilir öğün
kümeleri) kullanıcı isterse sonra eklenir; bu sadeleştirme açık bir
karar olarak işaretli.

### M9 — `FoodCategory` on iki değer, ekranda sekiz

Enum veri kararı, kart listesi arayüz kararı. USDA kayıtları
`etBalik`/`sutUrunu` olmadan bir yere sığmıyor ama on iki çip tek
satıra sığmıyor ve seçim yapmayı zorlaştırıyor. Kalan dört tür
aramadan geliyor.
