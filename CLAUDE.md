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
| [M5 planı](docs/superpowers/plans/2026-08-28-m5-saglik-ilerleme-alarm.md) | Tahlil, grafik, alarm, yedek, BYOK — **sıradaki** |

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
    ├── assets/fonts/         Inter değişken font
    ├── lib/
    │   ├── main.dart         tek satır → bootstrap()
    │   ├── bootstrap.dart    açılış işleri (katalog tohumu; alarm M5'te buraya)
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
| `today` | **tamam** | Günlük ekran: slot işaretleri, tartı/uyku girişi, kurallar, not |
| `plan` | **tamam** | 28 günlük program, takvim görünümü, örnek plan yükleme |
| `progress` | yer tutucu | Kilo trendi, haftalık özet, geçiş kriteri |
| `health` | kısmi | `body_metrics` tablosu ve deposu hazır; tahlil ve ekran M5'te |
| `catalog` | **tamam** | Egzersiz kütüphanesi: tablo, repository, arama/filtreli liste, dört sekmeli detay. |
| `workout` | **tamam** | Antrenman akışı: set sayacı, dinlenme, geri alma |
| `ai_bridge` | **tamam** | context.md üretimi, dört kapılı doğrulama, plan.json içe alma |
| `reminders` | yok | Alarmlar (M5) |
| `settings` | **tamam** | Profil ve yaşam tarzı formu; onboarding ve Ayarlar aynı formu paylaşır |

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

**Temel kural: marka rengi anlam rengi değildir.** Uygulamada üç bağımsız
durum ekseni var (gün yapıldı/kaçırıldı, tahlil düşük/normal/yüksek,
kilo yönü). Marka yeşil ya da turuncu olsaydı "iyi/kötü" sinyaliyle
çakışırdı. Marka **derin mavi**; yeşil/amber/kırmızı yalnız duruma ayrılmış.

| Katman | Dosya | İçerik |
|---|---|---|
| Ham palet | `core/design/app_palette.dart` | Renk rampaları. **Widget'ta doğrudan kullanılmaz.** |
| Ölçüler | `core/design/app_dimens.dart` | `AppSpacing` (4dp ritmi) · `AppRadius` · `AppTouch` (48dp) · `AppMotion` · `AppElevation` |
| Tipografi | `core/design/app_typography.dart` | Inter, M3 tip rolleri + sayısal stiller (tablo rakamı) |
| Anlam renkleri | `core/design/app_semantic_colors.dart` | `ThemeExtension` → `context.semantic.success/warning/danger/chartSeries` |
| Şemalar | `app/theme/app_color_schemes.dart` | Açık/koyu `ColorScheme` (fromSeed değil, açık tanım) |
| Bileşen stilleri | `app/theme/app_component_themes.dart` | Gruplanmış statik metotlar |
| Birleştirici | `app/theme/app_theme.dart` | Yalnız bir araya getirir. Büyüyorsa parça yanlış yerdedir. |

**Font:** Inter değişken (`assets/fonts/Inter-Variable.ttf`), uygulamayla
paketli — çalışma anında indirilmez, uygulama çevrimdışıdır. Türkçe
glifleri eksiksiz, tablo rakamı destekli.

**Grafik renkleri:** Okabe-Ito paleti (renk körlüğünde ayırt edilebilir).
Açık modda turuncu koyulaştırılmış varyantı kullanılır — özgüsü beyaz
zeminde 3:1 eşiğini geçmiyor.

### Paylaşılan bileşenler (`core/widgets/widgets.dart`)

| Bileşen | Ne için |
|---|---|
| `AppAsyncView<T>` | Riverpod'un yükleniyor/hata/veri/boş durumları. **Her ekranda bunu kullan**, elle `switch` yazma. |
| `AppEmptyState` | Boş durum: ne yok, neden, ne yapılabilir. Üç ton, her tonun kendi ikonu. |
| `AppStatusChip` / `AppStatusDot` | `AppStatus` (good/caution/bad/unknown) → ikon + renk + ekran okuyucu etiketi. |
| `AppMetricValue` | Sayı + birim. Tablo rakamı, Türkçe ondalık virgülü, `null` ≠ `0`. |
| `AppSection` / `AppSectionHeader` | Başlıklı bölüm, standart dikey ritim. |
| `AppScreenBody` | Kaydırılabilir gövde; alt çubuk için boşluğu otomatik bırakır. |

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

share_plus (context.md paylaşımı). M5'te: fl_chart,
flutter_local_notifications, timezone.

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

---

## Çalışma biçimi

- **TDD.** Önce başarısız test, sonra asgari kod, sonra commit. Planlar
  bu döngüye göre yazıldı.
- **Her görev sonunda** `flutter analyze` temiz + `flutter test` yeşil.
- **Conventional commits**, İngilizce: `feat:`, `fix:`, `chore:`, `test:`.
- **Kullanıcı dili Türkçe.** Arayüz metinleri, kod yorumları ve commit
  gövdesi dışındaki iletişim Türkçe.
- Kod yorumları *neden*i anlatır, *ne*yi değil. Bir karar tartışmalıysa
  gerekçesi yorumda durur.

## Egzersiz kataloğu

`app/assets/catalog.json` — 17 hareket, PDF programının tamamını kapsar
(Program A, Program B, salon kardiyo, artı geçiş kriterinin ölçütü olan
şınav zinciri). Her kayıtta: özet, başlangıç, 3+ adımlı anlatım, nefes,
tempo, ipuçları, 2+ hata kaydı (hata / neden / düzeltme), güvenlik,
kolaylaştırma-zorlaştırma zinciri.

`app/test/assets/catalog_seed_test.dart` şemayı ve içerik çıtasını
doğrular — çıta M4'te AI'ın önereceği hareketlere uygulanacakla aynı.

**Görseller:** 7 hareketin görseli var (`assets/exercises/*.webp`).
Kaynak free-exercise-db (kamu malı); ham kullanılmıyor — `tools/build_catalog_images.py`
hepsini aynı işlemden geçiriyor: kırpma (üçüncü taraf salon tabelaları
kadraj dışına), duotone (tek görsel dil), başlangıç + bitiş karesi yan yana,
numaralı. Kaynak kareleri hareketi net göstermeyen ya da arka planında
okunur marka kalan kayıtlar **bilerek görselsiz**: yanlış görsel görselsizden
kötüdür. Görsel eklemek için o dosyadaki `SOURCES` tablosuna satır ekle.

## Durum

**M1-M4 tamamlandı** — 289 test yeşil, analiz temiz, emülatörde uçtan uca
doğrulandı.

| | |
|---|---|
| M1 | iskelet, Drift şeması, tasarım sistemi, 5 sekmeli kabuk |
| M2 | egzersiz kataloğu (17 hareket, arama/filtre, dört sekmeli detay) |
| M3 | plan, günlük kayıt, Bugün ve Antrenman ekranları |
| M4 | AI köprüsü, onboarding, profil formu |

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

Tablo eklerken `schemaVersion`'ı artır ve `onUpgrade`'e **yeni bir**
`if (from < N)` bloğu ekle; eskileri değiştirme.

### AI köprüsü — nerede ne var

| Dosya | Sorumluluk |
|---|---|
| `ai_bridge/domain/ports.dart` | Feature'ların uygulayacağı arayüzler. `ai_bridge` hiçbir feature'ın `data/` katmanını import etmez. |
| `domain/json_reader.dart` | Alan yolunu izleyen okuyucu. Hata mesajı AI'a geri yapıştırılabilir olmalı. |
| `domain/plan_validator.dart` | Kapı 1-3. **İlk hatada durmaz**, hepsini tek mesajda toplar. |
| `domain/plan_importer.dart` | Depo tiplerini değil fonksiyon imzalarını alır. |
| `domain/context_md_builder.dart` | Yedi bölümlü belge. `ProfileKeys.form` onboarding formunun da kaynağı. |
| `presentation/import_plan_sheet.dart` | Kapı 4: önizleme ve onay. Onaysız hiçbir şey yazılmaz. |

Yeni bir adaptör eklerken: portu `ports.dart`'a yaz, uygulamasını ilgili
feature'ın `application/` klasörüne koy, `ai_bridge_providers.dart`'ta bağla.

### Sıradaki: M5 — sağlık, ilerleme, alarmlar

[Plan](docs/superpowers/plans/2026-08-28-m5-saglik-ilerleme-alarm.md).
Tahlil tabloları, İlerleme ve Sağlık ekranları, 7 günlük kaydırmalı alarm
penceresi, yedekleme, isteğe bağlı BYOK.

**M5'e girmeden önce plan senkronu:**

- `HealthSourceAdapter.recentLabs()` şu an boş liste dönüyor. `lab_results`
  tablosu gelince gerçek veriyle doldur — `context.md`'nin altıncı bölümü
  o anda kendiliğinden dolar.
- `MetricKinds` (`health/data/body_metric_table.dart`) tüm ölçüm türlerini
  ve Türkçe etiketlerini tutuyor; Sağlık ve İlerleme ekranları bunu kullansın.
- `BodyMetricsRepository.series` / `latestPerKind` grafikler için hazır.
- `TodayRepository.missedStreak` alarm için hazır; M5'in kaçak uyarısı
  bunu okuyacak.
- Ayarlar ekranı var; bildirim tercihleri ve yedekleme oraya eklenecek.
