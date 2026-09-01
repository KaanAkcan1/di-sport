# di@sport — Proje Rehberi

Bu dosya, oturum başında otomatik yüklenir. Amacı kodu baştan taramadan
projeyi anlamandır. **Bir şey değiştiğinde burayı da güncelle** —
bayatlamış rehber, rehber olmamaktan kötüdür.

---

## Ne yapıyoruz

Kişisel sağlık ve antrenman takip uygulaması. Kâğıt üzerindeki 4 haftalık
çizelgenin (`kaan-eylul-2026-cizelge.pdf`) dijital hâli, üç eklentiyle:
egzersiz kataloğu, yapay zekâ köprüsü (uygulama bağlam üretir → kullanıcı
herhangi bir AI'a verir → dönen planı uygulama içeri alır), ölçüm ve
tahlil takibi.

**Tek kullanıcı, tek cihaz, tamamen çevrimdışı.** Hesap yok, bulut yok,
mağaza yok. Mimari bunları sonradan almaya açık (bkz. `SyncColumns`).

---

## Dokümanlar — önce bunları oku

| Dosya | İçerik |
|---|---|
| [Tasarım (spec)](docs/superpowers/specs/2026-08-28-disport-tasarim.md) | **Tek doğruluk kaynağı.** Veri modeli, ekranlar, AI sözleşmesi, alarmlar. Kod bununla çelişiyorsa kod yanlıştır. |
| [M1 planı](docs/superpowers/plans/2026-08-28-m1-iskelet.md) | İskelet — **tamamlandı** |
| [M2 planı](docs/superpowers/plans/2026-08-28-m2-katalog.md) | Egzersiz kataloğu — **tamamlandı** |
| [M3 planı](docs/superpowers/plans/2026-08-28-m3-plan-ve-gunluk.md) | Plan, günlük kayıt, Bugün + Antrenman — **tamamlandı** |
| [M4 planı](docs/superpowers/plans/2026-08-28-m4-ai-koprusu.md) | AI köprüsü — **tamamlandı** |
| [M5 planı](docs/superpowers/plans/2026-08-28-m5-saglik-ilerleme-alarm.md) | Tahlil, grafik, alarm, yedek, BYOK — **tamamlandı** (BYOK hariç) |
| [M6 planı](docs/superpowers/plans/2026-08-31-m6-ozellestirme-ve-gorsel-refactor.md) | Görsel refactor + özelleştirme — **sürüyor** |

Planlar sırayla yürütülür. Bir kilometre taşı bitince **sonraki planı
gözden geçir ve senkronize et** — öğrenilenler planı eskitir.

---

## Nerede ne var

```
di@sport/
├── CLAUDE.md                 ← bu dosya
├── docs/superpowers/         spec + planlar
├── kaan-eylul-2026-cizelge.pdf   kaynak çizelge
└── app/                      Flutter projesi (tüm yollar buna göre)
    ├── assets/fonts/         Inter (değişken) + Barlow Condensed (4 ağırlık)
    ├── lib/
    │   ├── main.dart         tek satır → bootstrap()
    │   ├── bootstrap.dart    açılış işleri (katalog tohumu, alarm penceresi)
    │   ├── app/
    │   │   ├── app.dart      DisportApp + _Shell (5 sekme) + appDatabaseProvider
    │   │   └── theme/        app_theme (birleştirici) · app_color_schemes · app_component_themes
    │   ├── core/
    │   │   ├── db/           AppDatabase (toplayıcı) · SyncColumns mixin
    │   │   ├── design/       app_palette · app_dimens · app_typography · app_semantic_colors
    │   │   ├── result/       Result<T> sealed
    │   │   └── widgets/      paylaşılan bileşenler (barrel: widgets.dart)
    │   └── features/
    │       └── <feature>/    domain/ · data/ · application/ · presentation/
    └── test/                 lib/ ağacını aynalar
```

### Feature listesi ve durumu

| Feature | Durum | Sorumluluk |
|---|---|---|
| `today` | **tamam** | Zaman omurgası, tartı/uyku girişi, **kullanıcı tanımlı kurallar**, not |
| `plan` | **tamam** | 28 günlük program, takvim görünümü, örnek plan yükleme |
| `progress` | tam | Kilo grafiği (7g hareketli ortalama), haftalık kartlar, geçiş kriteri |
| `health` | tam | Tahlil panelleri, **kullanıcı tanımlı ölçüm türleri**, vade şeridi |
| `catalog` | **tamam** | 26 hareket, arama/filtre, dört sekmeli detay, **ekipman envanteri ve filtresi** |
| `workout` | **tamam** | Antrenman akışı: set sayacı, dinlenme, geri alma |
| `ai_bridge` | **tamam** | context.md üretimi, dört kapılı doğrulama, plan.json içe alma |
| `reminders` | tam | Saf `planWindow` + platform katmanı, 7 günlük kaydırmalı pencere |
| `nutrition` | **tamam** | Besin veritabanı, porsiyonlu öğün kaydı, kalori bütçesi, serbest aktiviteler |
| `settings` | tam | Profil formu (kimlik + ölçü), **Günlük Düzen** (kalkış/uyku/mesai/yasaklı saat), bildirimler, yedekleme, **haftalık mesai/yasaklı saat pencereleri**, görünüm ve dil |
| `supplements` | **tamam** | Vitamin/ilaç tanımı, günlük alım işareti, saatli hatırlatma |

---

## Mimari kuralları — pazarlık yok

1. **Feature-first.** Her özellik kendi klasöründe, içinde
   `domain/` (saf mantık) · `data/` (Drift, repository) ·
   `application/` (Riverpod) · `presentation/` (widget).
2. **`core` hiçbir feature'ı import edemez.** Ok tek yönlü.
3. **`ai_bridge` feature'ların yalnız `domain/` katmanını import eder.**
   `data/`, `application/`, `presentation/` asla. Veri toplamak için
   kendi port arayüzlerini tanımlar (`LogSource`, `HealthSource`…),
   feature'lar bu portları uygular.
4. **Drift tabloları feature'da yaşar**, `core/db/app_database.dart`
   yalnızca `@DriftDatabase(tables: [...])` ile toplar. Tablo eklerken
   `schemaVersion`'ı artır ve `onUpgrade`'e göç bloğu ekle.
5. **Her tabloda `SyncColumns`** (`id`, `userId`, `updatedAt`,
   `deletedAt`). v1'de işlevsizler; faz-2 senkronunun kapısı.
6. **Testler `test/` altında**, `lib/` ağacını aynalar. Dilin gereği:
   `lib/` içindeki testler pakete dahil olur.
7. **Ham renk/ölçü/punto widget'a yazılmaz.** `Theme.of(context)`,
   `context.semantic`, `AppSpacing`, `AppRadius` üzerinden gelir.
8. **`core/widgets`'a yalnız ≥2 feature'da kullanılan bileşen girer.**
   Tek ekrana ait widget o feature'ın `presentation/`inde kalır.

---

## Tasarım sistemi

**Marka: Vue yeşili (#42B883), mürekkep: Vue laciverti (#35495E).**

M1'de "marka rengi anlam rengi olamaz" kuralı vardı ve marka derin
maviydi. M6'da marka yeşile taşındı; çakışma kaçınılmaz olduğu için
**başarı rengi markayla birleştirildi**. İki yakın yeşil tanımlamak
daha kötü olurdu — kullanıcıdan onları ayırt etmesi istenirdi.

Hâlâ geçerli olan: marka **amber ve kırmızıdan** uzak durmalı, ve renk
tek başına anlam taşımaz (ikon + metin her zaman eşlik eder). İkisini de
`contrast_test.dart` koruyor; ayrı bir test birleştirmeyi sabitliyor ki
sessizce geri kaymasın.

### Mürekkep dili (M12) — güncel görsel dil

M6'nın beyaz-kart dili **kullanıcı tarafından reddedildi**. Yerine gelen:

1. **Zemin Vue laciverti, koyu öncelikli.** Vue'nun iki rengi var: biri
   zemin (`ink850`), biri vurgu (`brand400`). Yeşil koyu mürekkep
   üstünde 6.4:1 ile okunuyor; açık zeminde kaybolması ana şikâyetti.
   Varsayılan tema **koyu** — Ayarlar'dan Sistem/Koyu/Açık seçilir.
2. **Kart ve gölge yok.** `shadow` iki şemada da şeffaf; ayrım **ton
   katmanı + kıl çizgi** ile. `AppElevation` kullanım dışı ve
   `ink_component_themes_test.dart` yeni kullanımı engelliyor.
   Tek istisna diyalog/alt sayfa: perde arkayı karartınca ton yetmiyor,
   onlar bir ton yukarı + belirgin kenarlık alıyor.
3. **Her ekranın bir kahraman rakamı var.** Bugün: kilo (M9'da kalan
   kalori) · İlerleme: toplam değişim · Antrenman: seans süresi.
   56pt Barlow Condensed, altında tek satır `AppMetricStrip`.
4. **Yeşilin tek anlamı ilerleme + eylem.** Aşım kızıl, eksik amber;
   renk hep sayı ya da ikonla birlikte.
5. **Açık modda saf beyaz yok** — fildişi rampa (`ivory*`). Tek beyaz
   katman "beyaz kart" görünümünü geri getirirdi; test bunu koruyor.

| Katman | Dosya | İçerik |
|---|---|---|
| Ham palet | `core/design/app_palette.dart` | Renk rampaları: marka · **mürekkep (`ink*`)** · **fildişi (`ivory*`)** · sis (`mist*`). **Widget'ta doğrudan kullanılmaz.** |
| Ölçüler | `core/design/app_dimens.dart` | `AppSpacing` (4dp ritmi) · `AppRadius` · `AppTouch` (48dp) · `AppMotion` · ~~`AppElevation`~~ (M12'de emekli) |
| Tipografi | `core/design/app_typography.dart` | Inter, M3 tip rolleri + sayısal stiller (tablo rakamı) |
| Anlam renkleri | `core/design/app_semantic_colors.dart` | `ThemeExtension` → `context.semantic.success/warning/danger/hairline/chartSeries` |
| Şemalar | `app/theme/app_color_schemes.dart` | Açık/koyu `ColorScheme` (fromSeed değil, açık tanım) |
| Bileşen stilleri | `app/theme/app_component_themes.dart` | Gruplanmış statik metotlar |
| Birleştirici | `app/theme/app_theme.dart` | Yalnız bir araya getirir. Büyüyorsa parça yanlış yerdedir. |

**Font — iki aile, ikisi de paketli (çevrimdışı):**

- **Inter** (değişken): gövde ve arayüz. Türkçe glifleri eksiksiz,
  tablo rakamı destekli.
- **Barlow Condensed** (4 ağırlık): saatler, büyük sayılar, istatistik
  etiketleri. Uygulamanın içeriği sayı ve kaynağı bir çizelge; sıkışık
  rakam hem daha çok veri sığdırır hem karakter verir.
  **Gövde metni asla bununla yazılmaz** — Türkçe sözcükler sıkışık
  harfle küçük puntoda okunurluk kaybeder.

**`TurkishText.upper()` kullan, `toUpperCase()` değil.** Dart'ınki
ASCII kuralıyla çalışır: "Kilo" → "KILO", ki Türkçede "kılo" okunur.

**Grafik renkleri:** Okabe-Ito paleti (renk körlüğünde ayırt edilebilir).
Açık modda **turuncu ve pembe** koyulaştırılmış varyantlarıyla kullanılır
(`chartOrangeOnLight`, `chartPinkOnLight`) — özgüleri fildişi zeminde
3:1 eşiğini geçmiyor. Zemin değişince eşik düşürülmedi, renkler
koyulaştırıldı; kural bu.

### Paylaşılan bileşenler (`core/widgets/widgets.dart`)

| Bileşen | Ne için |
|---|---|
| `AppAsyncView<T>` | Riverpod'un yükleniyor/hata/veri/boş durumları. **Her ekranda bunu kullan**, elle `switch` yazma. |
| `AppEmptyState` | Boş durum: ne yok, neden, ne yapılabilir. Üç ton, her tonun kendi ikonu. |
| `AppStatusChip` / `AppStatusDot` | `AppStatus` (good/caution/bad/unknown) → ikon + renk + ekran okuyucu etiketi. |
| `AppMetricValue` | Sayı + birim. Tablo rakamı, Türkçe ondalık virgülü, `null` ≠ `0`. |
| `AppSection` / `AppSectionHeader` | Başlıklı bölüm, standart dikey ritim. |
| `AppSectionLabel` | Çizelge etiketi: harf aralıklı büyük harf başlık + sağda sayı. Mürekkep dilinin bölüm ayracı. |
| `AppHeroNumber` | Ekranın kahraman rakamı (56pt) + isteğe bağlı gauge. Aşımda dolar **ve** danger tonuna döner. |
| `AppMetricStrip` / `AppMetric` | Kahramanın altındaki tek satır metrik. Delta ok işareti taşır — renk tek başına değil. |
| `AppSpotCard` | "SIRADA" kartı: sıradaki iş listeden çıkıp öne alınır, tek dokunuşla başlar. |
| `AppWeekDots` | Son yedi günün doluluğu. Her noktada gün harfi yazılı. |
| `AppTimeRail` / `AppNowMarker` | Gün omurgası ve canlı "şimdi" işareti. Geçmişle geleceği ayırır. |
| `AppScreenBody` | Kaydırılabilir gövde; alt çubuk için boşluğu otomatik bırakır. |

**`AppStatBand` M12'de silindi.** Üç sayıyı eşit ağırlıkta gösteriyordu
ve ekranın "en önemli sayısı" diye bir şey yoktu. Yerine
`AppHeroNumber` + `AppMetricStrip` ikilisi geçti.

### Erişilebilirlik — testle korunuyor

`test/core/design/contrast_test.dart` WCAG oranlarını **otomatik**
doğrular. Palet değişir de eşik altına düşerse derleme yeşil kalmaz.
Renk değiştirdiğinde bu testi çalıştır.

Kurallar: metin 4.5:1 · arayüz/grafik 3:1 · dokunma hedefi 48dp ·
renk asla tek başına anlam taşımaz (ikon veya metin eşlik eder) ·
`prefers-reduced-motion` desteklenir (`AppMotion.respectingMotion`) ·
yazı ölçeği 0.85–1.6 arasında sınırlanır.

---

## Yığın

Flutter **3.47.2** / Dart 3.13 · flutter_riverpod **3.4.2** ·
drift **2.34** + drift_flutter · uuid

riverpod_annotation + riverpod_generator (codegen) · uuid

share_plus (context.md paylaşımı ve yedek) · fl_chart (kilo grafiği) ·
flutter_local_notifications + timezone + flutter_timezone (alarmlar) ·
path_provider + path + file_picker (yedekleme)

**Android:** `isCoreLibraryDesugaringEnabled = true` şart —
flutter_local_notifications `java.time` kullanıyor.

**freezed kullanılmıyor** — `ai_bridge` için öngörülmüştü, vazgeçildi.
Ayrıştırma hataları AI'a geri yapıştırıldığı için alan yolunu bildiren
kendi `JsonReader`'ımız yazıldı; hazır üreteç yalnız "type 'Null' is not
a subtype" diyor ve AI neyi düzelteceğini bilemiyor.

`custom_lint` kurulamıyor — `analyzer ^8` istiyor, `drift_dev` ve
`riverpod_lint` `analyzer ^13` kullanıyor.

---

## Komutlar

Kabuk **Git Bash** ya da PowerShell. Flutter `C:\dev\flutter\bin`.

```bash
export PATH="$PATH:/c/dev/flutter/bin"
export JAVA_HOME="/c/Program Files/Microsoft/jdk-17.0.20.101-hotspot"
export ANDROID_HOME="/c/Users/kaan.akcan/AppData/Local/Android/Sdk"
cd app

flutter test                  # tüm testler
flutter analyze               # temiz olmalı
dart run build_runner build   # Drift/freezed kod üretimi
flutter run                   # emülatörde çalıştır
```

**Emülatör:** `disport_pixel` (Pixel 7, API 36).
`$ANDROID_HOME/emulator/emulator.exe -avd disport_pixel`

### Tuzaklar

- **`flutter pub add paket:^1.2.3` Windows'ta bozuk.** `flutter.bat`
  argümanları `cmd` üzerinden geçirdiği için `^` yutulur ve sürüm
  sabitlenmiş sayılır. Sürüm kısıtı gerekiyorsa `pubspec.yaml`'ı elle
  düzenle, sonra `flutter pub get`.
- **Üretilen dosyalar (`*.g.dart`, `*.freezed.dart`) git'te yok.** Temiz
  klonun ardından önce `dart run build_runner build` çalıştır.
- **Proje yolunda `@` var** (`di@sport`). Flutter proje *adı* geçersiz
  karakter kabul etmediği için uygulama `app/` alt dizininde.
- **`drift` ve `matcher` ikisi de `isNull` tanımlar.** Testte çakışırsa
  `import 'package:drift/drift.dart' hide isNull;`.
- **Widget testinde Drift kullanma.** Drift'in `watch()` akışı gerçek async
  I/O ile gelir, `testWidgets` ise sahte-async bölgesinde çalışır;
  `pumpAndSettle` akışı bekleyerek asılı kalır. Ekran testinde ilgili
  provider'ı `overrideWith` ile bellekteki veriyle değiştir. Sorgu davranışı
  zaten repository testinde gerçek veritabanıyla doğrulanıyor.
- **Riverpod aile argümanı olarak `List` geçme.** Riverpod argümanları `==`
  ile karşılaştırır, Dart listeleri kimlikle; her `build` yeni örnek üretir
  ve provider sonsuza dek yeniden çalışır. Argüman `String` gibi değer
  eşitliği olan bir tip olmalı (`exerciseVariantsProvider(id)`).
- **Test süreci takılırsa `sqlite3.dll` kilitli kalır.** Sonraki
  `flutter test` "failed to delete file" der. Çözüm: `dart` ve
  `flutter_tester` süreçlerini öldür, `build/native_assets` klasörünü sil.
- **`custom_lint` şu an kurulamıyor.** `analyzer ^8` istiyor; `drift_dev` ve
  `riverpod_lint` `analyzer ^13` kullanıyor. Ekosistem yetişince eklenecek;
  o zamana kadar `core → feature` import yasağı yazılı kural olarak kalıyor.
- **`Override` ve `ProviderListenable` `flutter_riverpod`'dan dışa
  verilmiyor.** Testte `List<Override>` yazamazsın; yardımcıyı niyete göre
  parametrele (`onPainFree: ...`) ya da okumayı kapanış olarak al.
- **Akış sağlayıcısında `.future` ilk değeri döner**, sonrakini beklemez.
  "Yeni veri geldi mi" testinde kullanma; koşul sağlanana kadar yokla.
- **`file_picker` 12+ şart** — 10.x/11.x `win32 ^5.9` istiyor, `share_plus`
  13 daha yenisini; ikisi birlikte çözülmüyor. API'si de statik:
  `FilePicker.pickFile()`, `FilePicker.platform` değil.
- **`flutter_timezone` 5'te `getLocalTimezone()` `TimezoneInfo` döner**,
  `String` değil; `.identifier` al.
- **`tz.local` varsayılan olarak UTC.** Ayarlanmazsa 06:30 alarmı Türkiye'de
  09:30'da çalar.
- **`flutter build` bazen "Unable to determine engine version" verip
  başarısız oluyor** (`update_engine_version.ps1` dosya kilidi). Çıktının
  son satırında `√ Built ...` yoksa yapı olmamıştır — eski APK kurulur ve
  değişiklik yokmuş gibi görünür. Komutu tekrarla.
- **`adb shell input text` Türkçe karakterde çöker** (`ı` NullPointer verir).
  Cihazda elle sınarken ASCII yaz.
- **`ReorderableListView.onReorder` kullanımdan kalktı**; `onReorderItem`
  hedef dizini kendi düzeltiyor, elle `to > from ? to - 1 : to` yapma.
- **`adb shell input tap` klavye açıkken güvenilmez** — sayfa kayar,
  dokunuş yanlış alana gider. Alanlar arası geçişte `KEYCODE_TAB` kullan.

---

## Çalışma biçimi

- **TDD DEĞİL — kullanıcı kararı (M12'den itibaren).** Döngü:
  **önce kod → sonra testler → testleri çalıştır → review.**
  "Önce başarısız test" adımı istenmiyor. Test yazmak hâlâ zorunlu,
  sırası değişti; görev testsiz bitmez. (M1-M6 planları TDD ile
  yazılmıştı; v2 planları bu yeni döngüye göre yazılır.)
- **Her görev sonunda** `flutter analyze` temiz + `flutter test` yeşil.
- **Conventional commits**, İngilizce: `feat:`, `fix:`, `chore:`, `test:`.
- **Kullanıcı dili Türkçe.** Arayüz metinleri, kod yorumları ve commit
  gövdesi dışındaki iletişim Türkçe.
- Kod yorumları *neden*i anlatır, *ne*yi değil. Bir karar tartışmalıysa
  gerekçesi yorumda durur.

## Egzersiz kataloğu

`app/assets/catalog.json` — **161 hareket**, elle yazılmıyor: bir boru
hattı üretiyor (`tools/import_free_exercise_db.py`). Kaynak
[free-exercise-db](https://github.com/yuhonas/free-exercise-db) (876
kayıt, Unlicense).

| Dosya | Ne |
|---|---|
| `tools/catalog_selection.txt` | Hangi id'ler girecek. Ölçüt **kapsama**: her hareket kalıbı × her ekipman × ev/salon temsil edilsin, varyant yığılmasın (kaynakta 24 ayrı deadlift var). |
| `tools/catalog_overrides.json` | Elle yazılan içerik ve kaynak düzeltmeleri, id bazında **kısmi** — yalnız yazdığın alan biner. |
| `tools/catalog_names_tr.json` | Türkçe adlar. Ayrı dosyada çünkü sözlük; içerikle karışmasın. |

```bash
python tools/import_free_exercise_db.py           # üret
python tools/import_free_exercise_db.py --check   # diskteki güncel mi
```

Çıktı **determinist**: aynı girdi aynı dosyayı verir. `--check` boru
hattının bozulmasının nöbetçisi — `catalog.json`'ı elle düzenlersen
uyarır. Kaynakta olmayan ve override'da da bulunmayan alan **boş
kalır**; uydurma bir "sık yapılan hata" gerçeğiyle aynı görünür ve
kullanıcı ikisini ayırt edemez.

**İki kademeli içerik çıtası** (`test/assets/catalog_seed_test.dart`):

- **her kayıtta:** `id`, `nameEn`, `category`, `location`, `equipment`,
  `primaryMuscles`, `difficulty`, `execution` (≥2 adım)
- **çekirdek listede** (testte açık `coreIds` — programda fiilen geçen
  hareketler): ayrıca `nameTr`, `summary`, `setup`, `breathing`,
  `cues` (≥2), `commonMistakes` (≥2), `safety`

**Adlar İngilizce-öncelikli** (spec §4.1). EN arayüzde `nameEn`, TR
arayüzde `nameEn (nameTr)`, `nameTr` boşsa yalnız `nameEn`. Gerekçe:
kullanıcı hareketi internette arayacak ve "Goblet Çömelme" hiçbir şey
bulmuyor. `ai_bridge`'e giden `ExerciseRef.name` de İngilizce.

**Ekipman tipli** (`EquipmentKind`, 17 değer). 13'ü kaynağın sözlüğü,
4'ü elle eklendi: `pullUpBar`, `dipBars`, `bench`, `jumpRope` —
kaynak barfiksi "body only" sayıyor, kendi amacı için doğru ama
envanter için yanlış. `needsInventory` false olanlar (`bodyOnly`,
`none`, `other`) envanterde sorulmuyor: herkeste sandalye var.

**MET değerleri** 2024 Adult Compendium'dan. Kuvvet/gövde/hareketlilik
**kategori varsayılanı** alıyor (5.0 / 3.8 / 2.3) çünkü compendium 100
squat varyantı için değil efor düzeyi için değer veriyor — kayıt başına
uydurulmuş MET olmayan bir kesinlik vaat ederdi. Kardiyoda tersi:
ip atlama 12.3, eliptik 5.0; her kayıt kendi değerini taşımak zorunda
ve eksikse boru hattı uyarıyor. `treadmill_incline_walk` ve
`stationary_bike` sabit MET kullanmıyor — `metModel` ile ACSM
denklemlerine bağlanıyorlar (hesabın kodu M9'da).

**Görseller:** 7 hareketin görseli var (`assets/exercises/*.webp`).
Ham kullanılmıyor — `tools/build_catalog_images.py` hepsini aynı
işlemden geçiriyor: kırpma (üçüncü taraf salon tabelaları kadraj
dışına), duotone (tek görsel dil), başlangıç + bitiş karesi yan yana,
numaralı. Kaynak kareleri hareketi net göstermeyen ya da arka planında
okunur marka kalan kayıtlar **bilerek görselsiz**: yanlış görsel
görselsizden kötüdür. Görsel eklemek için o dosyadaki `SOURCES`
tablosuna satır ekle.

## Besin ve kalori

`app/assets/foods.json` — **368 besin**, iki kaynaktan, `tools/build_foods.py`
üretiyor.

| Dosya | Ne |
|---|---|
| `tools/foods_curated.json` | 109 Türk ev yemeği, ev ölçüsü porsiyonlarıyla. `tools/_gen_curated.py` üretiyor (kompakt tablodan). |
| `tools/foods_usda_selection.txt` | `fdcId \| slug \| Türkçe ad` — USDA SR Legacy seçimi. `tools/_gen_usda_selection.py` çözüyor. |
| `tools/cache/usda_sr_legacy.zip` | Kaynak arşiv. **Git'te yok**, bir kez indiriliyor (komut `build_foods.py` başlığında). |
| `app/assets/activities.json` | 72 serbest aktivite + MET. `tools/_gen_activities.py`. |

**Neden iki kaynak:** etli kuru fasulyenin hiçbir açık veri tabanında
karşılığı yok ve kimse onu gramla düşünmüyor — elle, "1 kase = 250 g"
ile yazılıyor. Elma ve tavuk göğsünde tersi: USDA'da zaten var, elle
yazmak hem uzun hem daha hatalı. USDA kayıtlarının **Türkçe adı
boş kalabilir**; arayüz İngilizcesini gösteriyor (katalogun §4.1
kuralı).

**Snapshot ilkesi — taşıyıcı karar.** `meal_entries.kcalSnapshot` ve
`activity_logs.kcalSnapshot` kayıt anında donuyor. Besin tablosunu
düzeltmek dünkü toplamı oynatmaz; 10 kilo vermek eski antrenmanın
harcamasını yeniden yazmaz. İkisi de kaydedildiğinde doğruydu. İki test
bunu tutuyor (`nutrition_repository_test`, `activities_repository_test`).

**Enerji hesabı** `workout/domain/energy_estimator.dart` — saf. ACSM
yürüyüş/koşu denklemleri (eğim **kesire** çevriliyor; birim karışırsa
sonuç 25 kat şişer), bisiklette efor→MET, kuvvette seans süresi × 5.0
MET. **Seans kaydı yoksa kcal üretilmiyor** — setlerin toplam süresi
seansın süresi değil ve dinlenmeyi bilmeden tahmin uydurmak olurdu.
Her sonuç arayüzde `≈` ile gösteriliyor.

**`EnergySource` portu** (`nutrition/domain/ports.dart`): `nutrition`
arayüzü tanımlıyor, `workout` uyguluyor. Serbest aktiviteler porta
**dahil değil** — onlar `nutrition`'ın kendi tablosunda ve iki kaynak
`nutrition_providers`'ta toplanıyor. Aksi hâlde `workout`,
`nutrition`'ın verisini okurdu.

**Spec'ten sapma:** şablon tablosu (`meal_templates`) açılmadı. Yerine
`copyMeal` var ve **dünden değil, o öğünde kayıt bulunan en son
günden** kopyalıyor — dün kahvaltı girilmemiş olabilir ve boş bir kopya
işe yaramaz. Gerçek şablon özelliği istenirse sonra eklenir.

## Düzenlenebilirlik

**Bugün, gün ekranının `dateKey = bugün` hâli.** Takvimden bir güne
dokunmak `DayScreen(dateKey:)` açıyor; başlıktaki oklar ve tarih
seçici komşu günlere geçiriyor.

Tarih bir provider'da (`viewedDateProvider`) duruyor ve `DayScreen`
onu bir `ProviderScope` ile geçersiz kılıyor. Alternatif, `dateKey`i
onlarca widget yapıcısından geçirmekti — biri unutulduğunda sessizce
bugüne bakan bir bölüm kalırdı.

**Aile argümanı `String`, `DateTime` değil.** Riverpod argümanları `==`
ile karşılaştırıyor; `DateTime` saat bileşeni taşıdığı için aynı günün
iki örneği asla eşit çıkmaz ve provider sonsuza dek yeniden kurulur.

| Kural | Neden |
|---|---|
| Bugün değilse "şimdi" yok | Kart, canlı işaret ve geçmiş/gelecek ayrımı çizilmiyor. Dünün listesine bugünün saatini uygulamak olmayan bir zaman gösterir. |
| Gelecek günde kayıt alanı yok | Plan görünür kalıyor ("yarın ne var" meşru); alan bırakmak yanlış güne kayıt yapmaya davet ederdi. |
| "Bugüne dön" = pop, push değil | `dateKey = bugün` push edilseydi Bugün sekmesinin ikizi doğardı. |
| Günler arası geçiş `pushReplacement` | Bir hafta gezinen kullanıcı geri tuşuna yedi kez basmasın. |

### Plan editörü

`PlanEditorRepository` **yazma yolu**; `PlanRepository` okuma yolu.
Ayrılar çünkü okuma her ekranda, yazma yalnız editörde — birleştirmek
plan gösteren her ekrana silme yeteneği vermek olurdu.

Dört editör: plan ayarları (başlık, hedefler, kurallar), gün (tip,
başlık, akşam önerisi), slot (saat, tür, öğün, etiket, not), hareket
(katalogdan seçim, hedefler, kardiyo şiddeti). Hepsi `planChanged()`
üzerinden kaydediyor: plan tazeleniyor **ve alarmlar hemen yeniden
kuruluyor**. Bir sonraki açılışı beklemek, sabah eski saatte alarm
duymak demek.

Düzenleme girişleri **gün ekranında**: kullanıcı saati değiştirirken
zaten o güne bakıyor. Slot satırında uzun basış düzenliyor — dokunma
işaretlemeye ait ve onu düzenlemeye vermek her işaretlemede form
açardı.

`sourceRaw` planın **kökeni** olmaya devam ediyor, tanımı olmaktan
çıkıyor: AI planı düzenlendiğinde orijinal belge yerinde kalıyor ve
plan başlığının altında "AI planı · düzenlendi" yazıyor.

**Boş plan** (`createEmptyPlan`) hafta sayısı kadar `rest` günü açıyor,
slotsuz. Varsayılan slot koymak silinecek satırlar üretmek olurdu.

## Durum

**v1 tamamlandı (M1-M6). v2 tamamlandı (M7-M12).** 755 test yeşil, analiz temiz.

| | |
|---|---|
| M1 | iskelet, Drift şeması, tasarım sistemi, 5 sekmeli kabuk |
| M2 | egzersiz kataloğu (arama/filtre, dört sekmeli detay) |
| M3 | plan, günlük kayıt, Bugün ve Antrenman ekranları |
| M4 | AI köprüsü, onboarding, profil formu |
| M5 | tahlil takibi, İlerleme ve Sağlık ekranları, alarmlar, yedekleme |
| M6 | görsel refactor (Vue yeşili) + özelleştirme: kurallar, ölçümler, ekipman, haftalık düzen |
| M7 | dil altyapısı — TR/EN, ARB, `hardcoded_text_test` nöbetçisi |
| M8 | katalog 2.0 — 161 hareket, boru hattı, tipli ekipman, İngilizce-öncelikli adlar |
| M11 | takviye ve ilaç takibi |
| M12 | mürekkep tasarım dili — koyu yüzey, kartsız, ekran başına bir kahraman sayı |
| M9 | besin ve kalori — 368 besin, 72 aktivite, kalori bütçesi |
| M10 | düzenlenebilirlik — tarihli gün ekranı, plan editörü, Günlük Düzen |

**Döngü kapandı:** onboarding → "Yeni plan iste" → `context.md` paylaş →
herhangi bir AI → dönen JSON → "İçeri al" → doğrula → önizle → onayla →
plan Bugün ekranında.

### Veritabanı şeması

| Sürüm | Eklenen |
|---|---|
| v1 | `profile_entries` |
| v2 | `exercises` |
| v3 | `plans`, `plan_days`, `plan_slots`, `plan_exercises` |
| v4 | `daily_logs`, `body_metrics` |
| v5 | `exercise_logs` |
| v6 | `lab_results`, `lab_schedules` |
| v7 | `daily_rules` + `daily_logs.checkedRulesJson` |
| v8 | `metric_definitions` |
| v9 | `equipment_items` |
| v10 | `weekly_windows` |
| v11 | `supplements`, `supplement_logs` |
| v12 | `equipment_items.atHome/atGym`, tipli `equipment` |
| v13 | `foods`, `food_portions`, `meal_entries`, `activities`, `activity_logs`, `workout_sessions` + `plan_exercises`/`exercise_logs` şiddet sütunları |
| v14 | `plan_slots.mealKind` |

Tablo eklerken `schemaVersion`'ı artır ve `onUpgrade`'e **yeni bir**
`if (from < N)` bloğu ekle; eskileri değiştirme.

### AI köprüsü — nerede ne var

| Dosya | Sorumluluk |
|---|---|
| `ai_bridge/domain/ports.dart` | Feature'ların uygulayacağı arayüzler. `ai_bridge` hiçbir feature'ın `data/` katmanını import etmez. |
| `domain/json_reader.dart` | Alan yolunu izleyen okuyucu. Hata mesajı AI'a geri yapıştırılabilir olmalı. |
| `domain/plan_validator.dart` | Kapı 1-3. **İlk hatada durmaz**, hepsini tek mesajda toplar. |
| `domain/plan_importer.dart` | Depo tiplerini değil fonksiyon imzalarını alır. |
| `domain/context_md_builder.dart` | Yedi bölümlü belge. `ProfileKeys.form` onboarding formunun **ve** alarm zamanlayıcısının uyanma saati anahtarının kaynağı. |
| `presentation/import_plan_sheet.dart` | Kapı 4: önizleme ve onay. Onaysız hiçbir şey yazılmaz. |

Yeni bir adaptör eklerken: portu `ports.dart`'a yaz, uygulamasını ilgili
feature'ın `application/` klasörüne koy, `ai_bridge_providers.dart`'ta bağla.

### Alarmlar — nerede ne var

| Dosya | Sorumluluk |
|---|---|
| `reminders/domain/reminder_planner.dart` | `planWindow` — **saf**. Beş bildirim türü, 7×24 saatlik anlık pencere, determinist id. |
| `reminders/application/reminder_scheduler.dart` | Kaynakları toplar → `planWindow` → `service.replaceAll`. |
| `core/notifications/notification_service.dart` | Arayüz. Testlerde sahtelenir. |
| `core/notifications/local_notification_service.dart` | flutter_local_notifications + timezone. |
| `reminders/application/reminder_providers.dart` | `rescheduleQuietly` — arayüzden yapılan her çağrı bunu kullanmalı. |

**Kurallar:**

- **Bildirim metni planner'da değil.** `planWindow` metnin *türünü*
  üretiyor (`ReminderTextKind`), sözcükleri `reminder_texts.dart`
  kullanıcının dilinde kuruyor. Planner saf kaldı — "salı 06:30 alarmı
  kurulur mu" sorusu hâlâ emülatörsüz cevaplanıyor. Arka planda
  `BuildContext` olmadığı için dil `PlatformDispatcher`'dan çözülüyor.
- **Yasaklı pencere takviyeye uygulanmaz.** "Bu saatlerde uygun
  değilim" mesai için doğru bir kural ama ilaç saati mesaiye kurban
  edilmez. Takviye adayları süzgeçten *sonra* ekleniyor.
- `canScheduleExact()` **sorar, istemez**. İstemek (`requestExactPermission`)
  Android'de sistem ayarları sayfasını açıyor; bunu bildirim kurarken
  çağırmak kullanıcıyı sebepsiz ayarlara fırlatır. Yalnız Ayarlar
  ekranındaki satır ister.
- `USE_EXACT_ALARM` **kullanılmıyor** — Play Store onu yalnız alarm/takvim
  uygulamalarına veriyor. `SCHEDULE_EXACT_ALARM` reddedilirse
  `inexactAllowWhileIdle`'a düşülür.
- Bildirim tercihi ya da profil değişince pencere **hemen** yeniden
  kurulur; bir sonraki açılışı beklemek "çalışmadı" hissi verir.
- Pencere yalnız 7 gün ileriyi kapsar (iOS 64 sınırı). Uygulama bir hafta
  açılmazsa alarmlar tükenir — kabul edilmiş sınır.

### Ekranlar veritabanını **akışla** okur

`IndexedStack` beş sekmeyi de canlı tutuyor: sekme değiştirmek ekranı
yeniden kurmuyor. Bu yüzden bir ekran tek seferlik okuma yaparsa
kullanıcı başka sekmede veri girip döndüğünde **eski veriyi görür**.

Cihazda yakalanan gerçek bir kusurdu (İlerleme yeni tartıyı görmüyordu).
Yeni bir ekran yazarken: `Future` değil `Stream` kullan
(`watchSeries`, `watchLatestPerKind`, `watchBetween`).

Nöbetçisi: `test/features/progress/progress_reactivity_test.dart`.
**Widget testi bu kusuru yakalayamaz** — orada ekran her testte sıfırdan
kurulur, yani koşul hiç doğmaz.

### Kullanıcı tanımlı veri — ortak kalıp

Kurallar, ölçüm türleri ve ekipman aynı desende:

1. Tablo yalnız **tanımı** tutar; kayıtlar eski yerlerinde kalır
   (`daily_logs` sütunları, `body_metrics.kind`).
2. Yerleşikler `bootstrap`ta tohumlanır, **silinmiş olan geri
   getirilmez** — ölçüt satırın varlığı, `deletedAt` değil. Aksi hâlde
   kullanıcı aynı şeyi her açılışta siler.
3. Silme **yumuşak**; geçmiş kayıt bozulmaz ve onay diyaloğu bunu
   söyler. Söylemezsen kullanıcı geçmişini kaybetmekten korkup listeyi
   hiç toparlamıyor.
4. Yerleşikler de yeniden adlandırılabilir (su hedefi 3 litre olmak
   zorunda değil) ama **id sabit kalır** — geçmiş ona bağlı.

### Bilinen boşluklar

- **Uygulama ikonu ve açılış ekranı hâlâ Flutter varsayılanı.** Planlarda
  yoktu; ürüne çıkmadan eklenmeli.
- **BYOK (M5 Task 8) yapılmadı** — isteğe bağlı işaretliydi. Kopyala-yapıştır
  yolu çalışıyor; doğrudan Gemini çağrısı eklenirse mevcut doğrulama
  akışına girmeli, ayrı yol açılmamalı. Onay kapısı şart (spec 7.5).
- **`custom_lint` kurulamıyor** — `analyzer ^8` istiyor, `drift_dev` ve
  `riverpod_lint` `^13`. Ekosistem gecikmesi; `core → feature` kuralı
  şimdilik yazılı kural olarak duruyor.
- **Geri yükleme sonrası uygulama yeniden başlatılmalı** — açık Drift
  bağlantısı eski veriyi göstermeye devam ediyor. Kullanıcıya snackbar ile
  söyleniyor; otomatik yeniden başlatma yok.
- **Geçmiş günde antrenman seti düzenlenemiyor.** Gün ekranı tartıyı,
  öğünü, kuralları ve notu geçmişe yazıyor ama `exercise_logs` satırları
  yalnız antrenman ekranından ve yalnız o gün giriliyor. M10 gözden
  geçirmesinde istenmişti; kapsam dışı bırakıldı ve açık kalıyor.
- **`profile_entries.familyDinnerTime` yazılamıyor.** Alan formdan
  kalktı ama veri duruyor; `context.md` onu hâlâ basıyor. Eski
  kurulumlarda değer varsa AI görmeye devam eder, yeni kurulumda hiç
  dolmaz.
