# M12 — Mürekkep Dili (Tasarım Yenilemesi) Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** M6'nın beyaz-kart dilini söküp spec §2a'daki mürekkep dilini kurmak: koyu Vue-laciverti zemin, kart/gölge yerine ton + ince çizgi, ekran başına bir kahraman rakam, yeşil = yalnız ilerleme/eylem.

**Architecture:** Önce token katmanı (palet → şema → bileşen temaları), sonra yeni çekirdek widget'lar, sonra ekranların sırayla taşınması. Ekranlar taşınırken **veri bağları değişmez** — yalnız sunum. M9/M10'un getireceği öğelerin (kalori kahramanı, takvim kalori tonlaması) yeri hazırlanır ama veriye kendi taşlarında bağlanır.

**Tech Stack:** Flutter 3.47.2 · Riverpod 3.4.2 · mevcut tasarım altyapısı (`core/design`, `app/theme`)

**Spec:** `docs/superpowers/specs/2026-08-31-disport-v2-saglikli-yasam.md` §2a (+ karar taslağı `2026-08-31-disport-v2-mockups.html`)

## Global Constraints

- **Döngü TDD DEĞİL (kullanıcı kararı):** her görevde sıra **1) kodu yaz → 2) testleri yaz → 3) `flutter analyze` + `flutter test` çalıştır → 4) review → 5) commit**. Görev testsiz bitmez.
- Çalışma dizini `app/`; komutlar oradan (`export PATH="$PATH:/c/dev/flutter/bin"`).
- Ham renk/ölçü widget'a yazılmaz: `Theme.of(context)` / `context.semantic` / `AppSpacing` / `AppRadius`.
- Renk tek başına anlam taşımaz — ikon ya da metin eşlik eder (contrast_test korur).
- Metin kontrastı 4.5:1, arayüz 3:1, dokunma hedefi 48dp; `contrast_test.dart` güncellenerek **korunur**, silinmez.
- `TurkishText.upper()` kullanılır, `toUpperCase()` asla.
- Commit'ler conventional, İngilizce.
- Ekran veri okumaları **Stream** kalır; bu plan hiçbir provider'ın veri kaynağını değiştirmez.

## Dosya Haritası

| Katman | Dosya | Sorumluluk |
|---|---|---|
| Palet | `lib/core/design/app_palette.dart` | Mürekkep rampası eklenir (ink950…ink500, mist100…mist600) |
| Şema | `lib/app/theme/app_color_schemes.dart` | **Koyu birincil** şema mürekkep dilinde yeniden; açık şema fildişi |
| Anlam | `lib/core/design/app_semantic_colors.dart` | `successSurface`/`dangerSurface` (takvim tonları), `hairline` |
| Bileşen temaları | `lib/app/theme/app_component_themes.dart` | Kart→ton paneli (gölgesiz), sekme, chip, navbar koyu |
| Tema modu | `lib/features/settings/...` + `lib/app/app.dart` | Sistem/Koyu/Açık; varsayılan **Koyu** |
| Yeni widget | `lib/core/widgets/app_section_label.dart` | Harf aralıklı büyük-küçük başlık etiketi |
| Yeni widget | `lib/core/widgets/app_hero_number.dart` | Kahraman rakam + isteğe bağlı gauge |
| Yeni widget | `lib/core/widgets/app_metric_strip.dart` | Tek satır metrik şeridi (AppStatBand'in yerine) |
| Yeni widget | `lib/core/widgets/app_spot_card.dart` | "SIRADA" kartı |
| Yeni widget | `lib/core/widgets/app_week_dots.dart` | 7 noktalı hafta şeridi |
| Ekranlar | `features/*/presentation/*` | Sunum taşınır; veri bağı aynı |

---

### Task 1: Mürekkep paleti + koyu-birincil şemalar

**Files:**
- Modify: `app/lib/core/design/app_palette.dart`
- Modify: `app/lib/app/theme/app_color_schemes.dart`
- Modify: `app/lib/core/design/app_semantic_colors.dart`
- Test: `app/test/core/design/contrast_test.dart` (güncelle), `app/test/core/design/ink_scheme_test.dart` (yeni)

**Interfaces:**
- Produces: `AppPalette.ink950/900/850/800/750/700/600/500`, `AppPalette.mist100/200/400/500/600`, `AppPalette.successSurfaceDarkInk`, `AppPalette.dangerSurfaceDarkInk`, `AppSemanticColors.hairline`, `AppSemanticColors.successSurface`, `AppSemanticColors.dangerSurface`

- [ ] **Step 1: Kodu yaz — palet rampası**

`app_palette.dart`'a ekle (taslaktan birebir alınan değerler):

```dart
  // ---- Mürekkep rampası (M12) ----
  // Zemin Vue laciverti: Vue'nun iki renginden biri zemin, biri vurgu
  // oldu. Yeşil koyu mürekkep üstünde okunur; açıkta kaybolması M6'nın
  // ana şikâyetiydi (spec §2a).
  static const ink950 = Color(0xFF0E1621); // en derin zemin
  static const ink900 = Color(0xFF121D28); // gezinme çubuğu
  static const ink850 = Color(0xFF16232F); // ekran yüzeyi
  static const ink800 = Color(0xFF1A2938); // panel / yükseltilmiş ton
  static const ink750 = Color(0xFF1D2F41); // kıl çizgi (hairline)
  static const ink700 = Color(0xFF24384D); // ayraç
  static const ink600 = Color(0xFF2C4157); // belirgin kenarlık
  static const ink500 = Color(0xFF3D5164); // sönük ikon

  // Metin tonları — koyu zemin için "sis" rampası
  static const mist100 = Color(0xFFF2F6F9); // güçlü metin
  static const mist200 = Color(0xFFDFE8EF); // gövde metni
  static const mist400 = Color(0xFF8DA2B5); // ikincil
  static const mist500 = Color(0xFF68809A); // sönük etiket
  static const mist600 = Color(0xFF5F7387); // en sönük

  // Takvim ton dolguları (renk + sayı birlikte kullanılır)
  static const successSurfaceDarkInk = Color(0xFF183626);
  static const dangerSurfaceDarkInk = Color(0xFF3A2622);

  // Koyu zeminde uyarı/aşım — açık moddakinden daha parlak
  static const amberDarkInk = Color(0xFFE8A33D);
  static const dangerDarkInk = Color(0xFFE06C5F);
```

- [ ] **Step 2: Kodu yaz — koyu şema mürekkep dilinde**

`app_color_schemes.dart` içindeki `dark` şemayı değiştir:

```dart
  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.brand400,          // #42B883 — vurgu artık işaret yeşili
    onPrimary: AppPalette.ink950,
    primaryContainer: Color(0xFF1D3A2E),
    onPrimaryContainer: AppPalette.brand100,
    secondary: AppPalette.mist400,
    onSecondary: AppPalette.ink950,
    secondaryContainer: AppPalette.ink800,
    onSecondaryContainer: AppPalette.mist200,
    tertiary: AppPalette.brand200,         // nane — ikincil yeşil vurgu
    onTertiary: AppPalette.ink950,
    error: AppPalette.dangerDarkInk,
    onError: AppPalette.ink950,
    errorContainer: AppPalette.dangerSurfaceDarkInk,
    onErrorContainer: Color(0xFFF3DDD9),
    surface: AppPalette.ink850,
    onSurface: AppPalette.mist100,
    onSurfaceVariant: AppPalette.mist400,
    surfaceContainerLowest: AppPalette.ink950,
    surfaceContainerLow: AppPalette.ink900,
    surfaceContainer: AppPalette.ink850,
    surfaceContainerHigh: AppPalette.ink800,
    surfaceContainerHighest: AppPalette.ink700,
    outline: AppPalette.ink600,
    outlineVariant: AppPalette.ink750,
    inverseSurface: AppPalette.mist100,
    onInverseSurface: AppPalette.ink900,
    inversePrimary: AppPalette.brand700,
    scrim: Color(0xCC000000),
    shadow: Color(0x00000000),             // gölge yok — mürekkep dili
  );
```

Açık şemada yalnız zemini fildişine çek (kart/gölge sökümü Task 2'de):

```dart
    surface: Color(0xFFF7F6F2),            // fildişi — saf beyaz değil
    surfaceContainer: Color(0xFFEFEDE7),
    surfaceContainerHigh: Color(0xFFE7E4DC),
```

- [ ] **Step 3: Kodu yaz — semantic renkler**

`app_semantic_colors.dart`'a üç alan ekle (`success/warning/danger/chartSeries` yanına):

```dart
  final Color hairline;        // ince ayraç — outlineVariant'tan ayrı,
                               // liste içi bölme çizgisi
  final Color successSurface;  // takvim "bütçe altı" dolgusu
  final Color dangerSurface;   // takvim "bütçe üstü" dolgusu
```

`dark` örneğinde: `hairline: AppPalette.ink750`, `successSurface: AppPalette.successSurfaceDarkInk`, `dangerSurface: AppPalette.dangerSurfaceDarkInk`. `light` örneğinde: `hairline: Color(0xFFE3E0D8)`, `successSurface: Color(0xFFE0F2E9)`, `dangerSurface: Color(0xFFF9E4E0)`. `warning` koyuda `AppPalette.amberDarkInk` olur. `copyWith`/`lerp` metotlarına alanları ekle.

- [ ] **Step 4: Testleri yaz**

`ink_scheme_test.dart` (yeni):

```dart
import 'package:disport/app/theme/app_color_schemes.dart';
import 'package:disport/core/design/app_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('koyu şema mürekkep zemininde ve gölgesiz', () {
    const s = AppColorSchemes.dark;
    expect(s.surface, AppPalette.ink850);
    expect(s.primary, AppPalette.brand400);
    // Mürekkep dilinde gölge yok — ayrım ton ve çizgiyle (spec §2a.2).
    expect(s.shadow.a, 0);
  });

  test('başarı rengi koyu modda da markayla aynı', () {
    // M6 kararının koyu mod izdüşümü.
    expect(AppSemanticColors.dark.success, AppColorSchemes.dark.primary);
  });
}
```

`contrast_test.dart` güncellemeleri:
- Koyu şema çiftlerine ekle: `mist100/ink850`, `mist400/ink850`, `brand400/ink850` (≥3:1, arayüz), `brand400/ink950` (birincil buton metni ink950/brand400 ≥4.5:1).
- Takvim dolguları üstünde rakam okunur mu: `brand400/successSurfaceDarkInk` ≥3:1, `dangerDarkInk/dangerSurfaceDarkInk` ≥3:1.
- Açık şemada değişen fildişi zeminle mevcut çiftleri yeniden doğrula (değerler sabit yazıldıysa güncelle).
- `AppSemanticColors.dark.success == AppColorSchemes.dark.primary` (birleştirme koyu modda da sabitlenir).

- [ ] **Step 5: Çalıştır**

Run: `flutter analyze && flutter test test/core/design/`
Expected: analiz temiz, tüm tasarım testleri yeşil. Kontrast düşen çift varsa **palet değeri** ayarlanır, test eşiği asla düşürülmez.

- [ ] **Step 6: Commit**

```bash
git add lib/core/design lib/app/theme test/core/design
git commit -m "feat: ink palette and dark-first colour schemes for M12 design language"
```

---

### Task 2: Bileşen temaları — kart ve gölge sökümü

**Files:**
- Modify: `app/lib/app/theme/app_component_themes.dart`
- Modify: `app/lib/core/design/app_dimens.dart` (`AppElevation` işaretlenir)
- Test: `app/test/app/theme/component_themes_test.dart` (yeni ya da mevcuta ekle)

**Interfaces:**
- Produces: `CardThemeData` gölgesiz + kıl çizgili; `TabBarTheme`; `NavigationBarTheme` koyu; `FilledButtonTheme` (onPrimary=ink950)

- [ ] **Step 1: Kodu yaz**

`app_component_themes.dart`:

```dart
  static CardThemeData card(ColorScheme scheme) => CardThemeData(
    // Mürekkep dili: gölge yok, ayrım ton + kıl çizgi (spec §2a.2).
    elevation: 0,
    color: scheme.surfaceContainerHigh,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    margin: EdgeInsets.zero,
  );

  static NavigationBarThemeData navigationBar(ColorScheme scheme) =>
      NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: .14),
        elevation: 0,
      );

  static TabBarThemeData tabBar(ColorScheme scheme) => TabBarThemeData(
    labelColor: scheme.tertiary,
    unselectedLabelColor: scheme.onSurfaceVariant,
    indicatorColor: scheme.primary,
    dividerColor: scheme.outlineVariant,
  );
```

`AppElevation`'a yorum: `/// M12'den itibaren kullanım dışı — mürekkep dilinde gölge yok. Yeni kullanım ekleme.` Mevcut `AppElevation.*` kullanımlarını grep'le bul, hepsini kaldır (`card` teması zaten 0 veriyor).

- [ ] **Step 2: Testleri yaz**

```dart
  test('kart gölgesiz ve kıl çizgili — mürekkep dili', () {
    final card = AppTheme.dark.cardTheme;
    expect(card.elevation, 0);
    final shape = card.shape! as RoundedRectangleBorder;
    expect(shape.side.color, AppTheme.dark.colorScheme.outlineVariant);
  });

  test('lib altında AppElevation kullanımı kalmadı', () {
    final dir = Directory('lib');
    final offenders = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.contains('app_dimens.dart'))
        .where((f) => f.readAsStringSync().contains('AppElevation.'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty, reason: 'Mürekkep dilinde gölge yok');
  });
```

- [ ] **Step 3: Çalıştır**

Run: `flutter analyze && flutter test test/app/ test/core/design/`
Expected: yeşil.

- [ ] **Step 4: Commit**

```bash
git add lib/app/theme lib/core/design test/app
git commit -m "feat: shadowless tonal component themes, retire AppElevation"
```

---

### Task 3: Tema modu — Sistem/Koyu/Açık, varsayılan Koyu

**Files:**
- Modify: `app/lib/app/app.dart` (`DisportApp` → `themeMode` provider'dan)
- Modify: `app/lib/features/settings/presentation/settings_screen.dart` (görünüm satırı)
- Modify: `app/lib/features/settings/application/` (mevcut profil provider deseni; `ProfileKeys.themeMode` eklenir — `ProfileKeys` hangi dosyadaysa oraya)
- Test: `app/test/features/settings/theme_mode_test.dart`

**Interfaces:**
- Produces: `themeModeProvider` → `ThemeMode` (varsayılan `ThemeMode.dark`); `ProfileKeys.themeMode = 'gorunum.tema'`

- [ ] **Step 1: Kodu yaz**

`ProfileKeys`'e `static const themeMode = 'gorunum.tema';` ekle. Settings application katmanına, mevcut profil-değeri provider'ları hangi desenle yazıldıysa aynı desenle:

```dart
/// Tema modu. Varsayılan koyu — mürekkep dili koyu öncelikli (spec §2a.1).
/// Değer profil tablosunda 'system' | 'dark' | 'light' olarak durur.
@riverpod
Stream<ThemeMode> themeMode(Ref ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchValue(ProfileKeys.themeMode).map((raw) => switch (raw) {
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    _ => ThemeMode.dark,
  });
}
```

`DisportApp`'te `MaterialApp(themeMode: ...)` bu provider'dan okunur (`.value ?? ThemeMode.dark`). Ayarlar'a "Görünüm" satırı: üç seçenekli `SegmentedButton` — Sistem / Koyu / Açık; seçim profil tablosuna yazılır (mevcut ayar satırları hangi bileşenle yazıldıysa aynı).

- [ ] **Step 2: Testleri yaz**

```dart
  test('değer yokken varsayılan koyu', () async {
    final mode = await container.read(themeModeProvider.future);
    expect(mode, ThemeMode.dark);
  });

  test("'light' yazılınca açık moda geçer", () async {
    await repo.setValue(ProfileKeys.themeMode, 'light');
    await waitFor(() async =>
        await container.read(themeModeProvider.future) == ThemeMode.light);
  });
```

(Akış sağlayıcısında `.future` ilk değeri döner — ikinci testte CLAUDE.md'deki `waitFor` yoklama deseni kullanılır.)

- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/settings/`
- [ ] **Step 4: Commit** — `git commit -m "feat: theme mode setting, dark by default"`

---

### Task 4: Çekirdek widget'lar — AppSectionLabel, AppHeroNumber, AppMetricStrip

**Files:**
- Create: `app/lib/core/widgets/app_section_label.dart`
- Create: `app/lib/core/widgets/app_hero_number.dart`
- Create: `app/lib/core/widgets/app_metric_strip.dart`
- Modify: `app/lib/core/widgets/widgets.dart` (barrel'a ekle)
- Test: `app/test/core/widgets/app_hero_number_test.dart`, `app/test/core/widgets/app_metric_strip_test.dart`

**Interfaces:**
- Produces:
  - `AppSectionLabel(String text, {Widget? trailing})` — `TurkishText.upper` + harf aralığı
  - `AppHeroNumber({String? value, String? unit, required String caption, double? gaugeFraction, bool accent = true})` — 56pt kondanse rakam; `gaugeFraction` verilirse altında 5dp ince bar; değer `null` ise `—` sönük
  - `AppMetric({required String caption, String? value, String? unit, String? delta, bool deltaPositive})` ve `AppMetricStrip(List<AppMetric> metrics)` — tek satır, kondanse, tablo rakamı

- [ ] **Step 1: Kodu yaz**

`app_hero_number.dart` çekirdeği:

```dart
/// Ekranın kahraman rakamı — mürekkep dilinde her ekranın tek büyük
/// sayısı (spec §2a.3). AppStatBand'in halefi: şerit değil, tek odak.
class AppHeroNumber extends StatelessWidget {
  const AppHeroNumber({
    super.key,
    required this.caption,
    this.value,
    this.unit,
    this.gaugeFraction,
    this.accent = true,
  });

  final String caption;
  final String? value;
  final String? unit;
  /// 0..1 — verilirse altta ince ilerleme çubuğu. 1'i aşan değer
  /// kırpılmaz, çubuk dolu + danger tonuna döner (bütçe aşımı).
  final double? gaugeFraction;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final empty = value == null;
    final color = empty
        ? theme.colorScheme.onSurfaceVariant
        : accent ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    // 56pt kondanse; FittedBox ile küçülür, asla kırpılmaz ("1..." kuralı).
    ...
  }
}
```

`AppMetricStrip`: `Row` + aralarında `AppSpacing.xl`; her metrik `caption` (mist500, harf aralıklı, 10sp) üstte, değer altta (16sp kondanse, tablo rakamı); `delta` verilirse değerin yanında `▾/▴` + success/danger rengi **ve** işaret karakteri (renk tek başına anlam taşımaz).

- [ ] **Step 2: Testleri yaz**

```dart
  testWidgets('değer yokken — gösterir ve birim gizlenir', (tester) async {
    await tester.pumpWidget(harness(const AppHeroNumber(caption: 'KALORİ')));
    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('kcal'), findsNothing);
  });

  testWidgets('gauge 1 aşınca danger tonu', (tester) async {
    await tester.pumpWidget(harness(const AppHeroNumber(
        caption: 'KALORİ', value: '2 410', gaugeFraction: 1.15)));
    // bar rengini key ile bul, semantic.danger beklenir
  });

  testWidgets('delta işaret karakteri taşır — renk tek başına değil',
      (tester) async {
    await tester.pumpWidget(harness(const AppMetricStrip([
      AppMetric(caption: 'KİLO', value: '108,9', delta: '0,4',
          deltaPositive: true),
    ])));
    expect(find.textContaining('▾'), findsOneWidget);
  });
```

- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/core/widgets/`
- [ ] **Step 4: Commit** — `git commit -m "feat: hero number, metric strip and section label widgets"`

---

### Task 5: Çekirdek widget'lar — AppSpotCard, AppWeekDots, slot ikonları

**Files:**
- Create: `app/lib/core/widgets/app_spot_card.dart`
- Create: `app/lib/core/widgets/app_week_dots.dart`
- Create: `app/lib/features/plan/presentation/slot_kind_icon.dart` (SlotKind→IconData eşlemesi; plan feature'ında çünkü `SlotKind` orada)
- Modify: `app/lib/core/widgets/widgets.dart`
- Test: `app/test/core/widgets/app_spot_card_test.dart`, `app/test/features/plan/slot_kind_icon_test.dart`

**Interfaces:**
- Produces:
  - `AppSpotCard({required String eyebrow, required String title, String? subtitle, VoidCallback? onTap})` — yeşil kıl çerçeveli, %7 yeşil dolgulu vurgu kartı
  - `AppWeekDots({required List<WeekDotState> states})`, `enum WeekDotState { done, missed, today, future }` — done=yeşil, missed=sönük **içinde gün harfi hep yazılı** (renk tek başına değil)
  - `slotKindIcon(SlotKind kind) → IconData`: meal→`Icons.restaurant`, workout→`Icons.fitness_center`, sleep→`Icons.bedtime`, measurement→`Icons.monitor_weight_outlined`, lab→`Icons.science_outlined`, other→`Icons.circle_outlined`

- [ ] **Step 1: Kodu yaz** — üç dosya; `AppSpotCard` dokunulabilirse `InkWell` + min 48dp.
- [ ] **Step 2: Testleri yaz** — spot kart eyebrow/title'ı basar, `onTap` tetiklenir; `slotKindIcon` altı türün hepsine benzersiz ikon döner (`Set` uzunluğu 6).
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/core/widgets/ test/features/plan/`
- [ ] **Step 4: Commit** — `git commit -m "feat: spot card, week dots and slot kind icons"`

---

### Task 6: Bugün ekranı taşınır

**Files:**
- Modify: `app/lib/features/today/presentation/today_screen.dart`
- Modify: `app/lib/features/today/presentation/slot_list.dart` (ikon + sağ ok + gerçekleşen değeri satırda)
- Modify: `app/lib/core/widgets/app_time_rail.dart` (kıl çizgili sade satır; nokta yerine 3dp çubuk)
- Test: `app/test/features/today/today_screen_ink_test.dart` (mevcut today ekran testleri de güncellenir)

**Interfaces:**
- Consumes: Task 4-5 widget'ları; mevcut `todayPlanDayProvider`, `todayWeightProvider`, `todayLogProvider`, `clockProvider`
- Produces: `_TodayBand` silinir → `AppHeroNumber` + `AppMetricStrip`; `AppStatBand` bu ekrandan çıkar

Kurgu (taslak birebir):
1. Başlık: eyebrow (gün · tarih · hafta) + "Bugün" + ‹ › (M10'a kadar pasif görsel)
2. `AppWeekDots` — son 7 günün `daily_logs` doluluğu (`watchBetween` zaten var)
3. Kahraman: **M9'a dek kilo** (`gaugeFraction` yok); altında `AppMetricStrip`: KİLO(delta) · PROGRAM(5/8) · KURALLAR(2/3). Kalori kahramanı M9'da bunun yerine geçer — yorumla işaretle.
4. Omurga: her slot `slotKindIcon` + saat + etiket + sağda değer/›; **geçmiş slot dokununca ilgili giriş akışı açılır** (tartı→ölçüm alanına kaydır, öğün→not; M9'da öğün kaydına bağlanır)
5. Sıradaki slot listeden çıkar → `AppSpotCard` ("SIRADA · 18:00", başlık, alt bilgi; dokununca workout başlar — mevcut gezinme)
6. Altta üç `OutlinedButton`: +Tartı, +Not, +Aktivite (aktivite M9'a dek gizli — `if (false)` değil, widget hiç eklenmez; yorum bırakılır)

- [ ] **Step 1: Kodu yaz** (yukarıdaki kurgu; `MeasurementInputs`, `DailyFlagsCard`, `DayNoteField` kalır, sırası korunur)
- [ ] **Step 2: Testleri yaz** — provider override ile (CLAUDE.md: widget testinde Drift yok):

```dart
  testWidgets('sıradaki slot spot kartında, listede değil', (tester) async {
    // 18:00 workout slotu olan sahte gün; saat 17:00
    expect(find.byType(AppSpotCard), findsOneWidget);
    expect(find.text('Salon · Program A'),
        findsOneWidget); // yalnız kartta
  });

  testWidgets('kilo yokken kahraman — gösterir', ...);
  testWidgets('hafta şeridi 7 nokta basar', ...);
```

- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/today/`
- [ ] **Step 4: Review + Commit** — emülatörde Bugün ekranı gözle doğrulanır (koyu + açık), sonra `git commit -m "feat: today screen in ink language with hero number and spot card"`

---

### Task 7: Plan takvimi taşınır

**Files:**
- Modify: `app/lib/features/plan/presentation/plan_screen.dart` (takvim hücreleri, gösterge)
- Test: `app/test/features/plan/plan_calendar_ink_test.dart`

**Interfaces:**
- Consumes: mevcut plan/log provider'ları; `context.semantic.successSurface/dangerSurface`
- Produces: `DayCellState` (plan feature içinde): `{ done, missed, free, today, future }` → hücre tonu. **Kalori tonlaması M9'da bu eşlemeye bağlanır**; M12'de ton kaynağı gün doluluğu: tüm slotlar işaretli=successSurface, geçmiş ve eksik=sönük (danger değil — kaçak gün "kötü" değil "boş"), serbest=kesikli çerçeve, bugün=yeşil dış çizgi, gelecek=ink900.

Hücre içeriği: gün rakamı + alt satır küçük bilgi (işaretli sayısı `5/8` ya da `serbest`), antrenman günü ▲ (sağ üst, yeşil). Renk + rakam birlikte.

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — serbest gün kesikli + "serbest" metni; bugün hücresi outline; ▲ yalnız antrenmanlı günlerde; tüm durum eşlemesi (`DayCellState` birim testi).
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/plan/`
- [ ] **Step 4: Commit** — `git commit -m "feat: plan calendar with tonal day cells and free-day marking"`

---

### Task 8: Katalog taşınır — sekmeler, ⚙ filtre, SON YAPTIKLARIN

**Files:**
- Modify: `app/lib/features/catalog/presentation/catalog_screen.dart`
- Create: `app/lib/features/catalog/presentation/catalog_filter_sheet.dart`
- Modify: `app/lib/features/catalog/presentation/exercise_list_tile.dart` (mürekkep satırı; İngilizce ad ana — **yalnız stil**, ad değişimi M8'de)
- Modify: `app/lib/features/catalog/application/` (filtre durumu tek sınıfta: `CatalogFilters{ bool onlyMyEquipment; ExerciseCategory? category; int? difficulty; }`)
- Create: `app/lib/features/catalog/application/recent_exercises_provider.dart` (`exercise_logs`dan son 5 benzersiz hareket + son seans özeti)
- Test: `app/test/features/catalog/catalog_filter_sheet_test.dart`, `app/test/features/catalog/recent_exercises_test.dart`

**Interfaces:**
- Consumes: mevcut katalog + workout log repository'leri (`watch` akışları)
- Produces: üstte `TabBar` **Evde · Salonda** (Dışarıda sekmesi M9'da `activities` ile gelir — yeri yorumla işaretli); arama satırı + ⚙ düğmesi (rozet=aktif filtre sayısı); aktif filtreler ×'li `InputChip`; liste `AppSectionLabel('Son yaptıkların')` + `AppSectionLabel('Tüm hareketler')`
- `RecentExercise{ String exerciseId; DateTime at; String summary; }` — özet "3×12 · 12,5 kg" formatında repository'de kurulur

- [ ] **Step 1: Kodu yaz** — filtre sheet: ekipman anahtarı (`SwitchListTile`), kategori (`SegmentedButton`), zorluk; "Uygula" yok, değişiklik anında (aktif filtre chip'leri canlı güncellenir)
- [ ] **Step 2: Testleri yaz** — rozet sayısı aktif filtre sayısına eşit; × chip'i filtreyi düşürür; `recent_exercises` gerçek DB testi: iki log yaz → son ilk sırada, benzersiz; boş logda bölüm hiç görünmez (başlık dahil).
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/catalog/`
- [ ] **Step 4: Commit** — `git commit -m "feat: catalog with location tabs, filter sheet and recent exercises"`

---

### Task 9: Antrenman taşınır — GEÇEN sütunu, ✓→dinlenme

**Files:**
- Modify: `app/lib/features/workout/presentation/exercise_set_card.dart` (kıl çizgili satır; GEÇEN + PLAN sütunları)
- Modify: `app/lib/features/workout/presentation/rest_timer_bar.dart` (stil)
- Create: `app/lib/features/workout/application/previous_session_provider.dart` (hareket için bir önceki seansın set özetleri)
- Modify: `app/lib/features/workout/application/` (set ✓ kaydında dinlenme sayacı otomatik başlar — mevcut sayaç tetikleme mantığına bağlanır)
- Test: `app/test/features/workout/previous_session_test.dart`, mevcut workout testleri güncellenir

**Interfaces:**
- Consumes: `exercise_logs` repository akışları
- Produces: `PreviousSets{ List<String> perSet; }` — set sırasına göre "10" gibi; yoksa satırda GEÇEN sütunu hiç çizilmez (boş "—" değil)

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — önceki seans yokken sütun yok; varken set sırayla eşleşir; ✓ sonrası dinlenme sayacının başladığı (sayaç durumu provider'ından)
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/workout/`
- [ ] **Step 4: Commit** — `git commit -m "feat: workout rows with previous-session column, auto rest timer"`

---

### Task 10: İlerleme + Sağlık taşınır

**Files:**
- Modify: `app/lib/features/progress/presentation/progress_screen.dart` — kahraman `AppHeroNumber` (toplam değişim, ör. "−2,8 kg"), grafik mürekkep ızgarası (`hairline` çizgiler, yeşil iz, uç nokta vurgusu), hafta kartları kıl çerçeveli
- Modify: `app/lib/features/health/presentation/health_screen.dart` — panel satırları mürekkep diline; `AppStatusChip` renkleri koyu zeminde semantic'ten (zaten öyle; görsel doğrulama)
- Test: mevcut progress/health ekran testleri güncellenir; `progress_reactivity_test.dart` **değişmeden geçmeli** (bu, veri bağının bozulmadığının kanıtı)

Haftalık kalori çubukları M9'da eklenir — grafik bölümünün altına yorum: `// M9: haftalık kalori çubukları buraya (spec §2a İlerleme)`.

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz/güncelle**
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/progress/ test/features/health/`
- [ ] **Step 4: Commit** — `git commit -m "feat: progress and health screens in ink language"`

---

### Task 11: Süpürme — AppStatBand sökümü, Ayarlar, cihaz doğrulaması, dokümantasyon

**Files:**
- Delete: `app/lib/core/widgets/app_stat_band.dart` (tüm kullanıcıları Task 6-10'da taşındı; grep ile doğrula)
- Modify: `app/lib/features/settings/presentation/settings_screen.dart` (mürekkep listesi; Görünüm satırı Task 3'te geldi)
- Modify: kalan ekran/diyalog süpürmesi: `grep -rn "surfaceContainerHighest\|Colors\.white\|shadowColor" lib` — mürekkep diline aykırı kalıntılar
- Modify: `CLAUDE.md` (Tasarım sistemi bölümü: mürekkep dili kuralları, yeni widget tablosu, AppStatBand→AppHeroNumber/AppMetricStrip)
- Test: tüm paket — `flutter test`

- [ ] **Step 1: Kodu yaz** — söküm + süpürme
- [ ] **Step 2: Testleri güncelle** — `app_stat_band_test.dart` silinir; widgets barrel testi varsa güncellenir
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test` (tam paket, ~460+ test)
- [ ] **Step 4: Cihaz doğrulaması** — emülatörde beş sekme + ayarlar, koyu ve açık temada gezilir; `flutter build` çıktısında `√ Built` doğrulanır (CLAUDE.md tuzağı)
- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: complete ink language migration, remove AppStatBand"
```

---

## Öz-değerlendirme notları

- Spec §2a kapsaması: kural 1-5 → Task 1-2-4; Bugün → 6; takvim → 7; katalog → 8; öğün kaydı ekranı **M9'da** (bu planda değil — veri modeli yokken ekran kurulamaz); antrenman → 9; İlerleme → 10; tema seçimi → 3.
- "SIRADA" tek dokunuş başlatma mevcut workout gezinmesini kullanır, yeni akış icat etmez (YAGNI).
- Takvim kalori tonu ve kalori kahramanı bilinçli olarak M9'a bırakıldı; plan bunu her iki görevde yorumla işaretletiyor.
- Tip tutarlılığı: `AppHeroNumber.gaugeFraction`, `AppMetric.delta`, `CatalogFilters`, `RecentExercise`, `PreviousSets`, `DayCellState` — üretici/tüketici görevlerde aynı adlarla geçiyor.
