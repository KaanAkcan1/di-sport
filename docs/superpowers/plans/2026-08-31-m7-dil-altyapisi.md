# M7 — Dil Altyapısı (TR/EN) Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Uygulamayı iki dilli yapmak: tüm arayüz metinleri ARB'ye, Türkçe'ye özel yardımcılar locale'e bağlanır, Ayarlar'dan Sistem/Türkçe/English seçilir.

**Architecture:** `flutter_localizations` + `gen_l10n`; şablon `app_tr.arb` (metinler önce Türkçe yazıldı, anahtarlar oradan çıkar). `TurkishText` → `LocaleText`'e evrilir; `TurkishDate`/`TurkishNumber` `intl`'e devreder. Katalog/besin veri iki dilliliği **bu planda değil** — veri tarafı M8/M9'da, buradaki iş arayüz + altyapı.

**Tech Stack:** flutter_localizations · intl · gen_l10n

**Spec:** `docs/superpowers/specs/2026-08-31-disport-v2-saglikli-yasam.md` §3

## Global Constraints

- **Döngü TDD DEĞİL:** her görevde **kod → testler → `flutter analyze` + `flutter test` → review → commit**.
- AI köprüsü kapsam DIŞI: `context_md_builder`, `plan_validator`, `json_reader` metinleri Türkçe kalır — bunlara dokunan değişiklik bu planda hatadır.
- Kullanıcının girdiği metin (not, özel kural adı, özel ölçüm etiketi) çevrilmez.
- `toUpperCase()` yasağı sürer; artık `LocaleText.upper` üzerinden.
- Commit'ler conventional, İngilizce. Çalışma dizini `app/`.

## Dosya Haritası

| Dosya | Sorumluluk |
|---|---|
| `app/l10n.yaml` | gen_l10n yapılandırması |
| `app/lib/l10n/app_tr.arb` | Şablon — tüm anahtarlar + açıklamalar |
| `app/lib/l10n/app_en.arb` | İngilizce çeviri |
| `app/lib/core/utils/locale_text.dart` | `upper`/`fold` — locale'e bağlı |
| `app/lib/core/utils/turkish_text.dart` | Kalır; `LocaleText` TR yolunda bunu çağırır |
| `app/lib/features/settings/...` | Dil seçimi satırı + `ProfileKeys.locale` |
| `app/lib/app/app.dart` | `locale`, `localizationsDelegates`, `supportedLocales` |

---

### Task 1: gen_l10n altyapısı + ilk ARB çifti

**Files:**
- Create: `app/l10n.yaml`
- Create: `app/lib/l10n/app_tr.arb`, `app/lib/l10n/app_en.arb`
- Modify: `app/pubspec.yaml` (`flutter_localizations` sdk, `intl`; `generate: true`)
- Modify: `app/lib/app/app.dart`
- Test: `app/test/l10n/arb_parity_test.dart`

**Interfaces:**
- Produces: `AppLocalizations` (üretilen sınıf), `context.l10n` uzantısı (`lib/core/utils/l10n_ext.dart`: `extension L10nX on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this)!; }`)

- [ ] **Step 1: Kodu yaz**

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_tr.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

`app_tr.arb` başlangıcı (ilk parti: kabuk + sekme adları):

```json
{
  "@@locale": "tr",
  "tabToday": "Bugün",
  "tabPlan": "Plan",
  "tabProgress": "İlerleme",
  "tabHealth": "Sağlık",
  "tabCatalog": "Katalog",
  "commonSave": "Kaydet",
  "commonCancel": "Vazgeç",
  "commonDelete": "Sil",
  "commonEdit": "Düzenle"
}
```

`app_en.arb` aynı anahtarlarla İngilizce. `DisportApp`'e delegates + `supportedLocales: [Locale('tr'), Locale('en')]`. Sekme adları `context.l10n.tabToday`… olur.

**Windows tuzağı:** `flutter pub add paket:^x` bozuk — `pubspec.yaml` elle düzenlenir, sonra `flutter pub get`.

- [ ] **Step 2: Testleri yaz**

`arb_parity_test.dart` — planın en önemli nöbetçisi:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> load(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;
  Set<String> keysOf(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  test('tr ve en anahtar kümeleri birebir aynı', () {
    final tr = keysOf(load('app_tr.arb'));
    final en = keysOf(load('app_en.arb'));
    // Çift yönlü: eksik de fazlalık da hata (spec §3.5).
    expect(en.difference(tr), isEmpty, reason: 'en fazla anahtar taşıyor');
    expect(tr.difference(en), isEmpty, reason: 'çevrilmemiş anahtar var');
  });

  test('değerler boş değil', () {
    for (final name in ['app_tr.arb', 'app_en.arb']) {
      final arb = load(name);
      for (final e in arb.entries) {
        if (e.key.startsWith('@')) continue;
        expect((e.value as String).trim(), isNotEmpty,
            reason: '$name → ${e.key}');
      }
    }
  });
}
```

- [ ] **Step 3: Çalıştır** — `flutter gen-l10n && flutter analyze && flutter test test/l10n/`
- [ ] **Step 4: Commit** — `git commit -m "feat: l10n scaffolding with tr template and en translation"`

---

### Task 2: LocaleText — upper ve fold locale'e bağlanır

**Files:**
- Create: `app/lib/core/utils/locale_text.dart`
- Modify: `app/lib/core/utils/turkish_text.dart` (silinmez; belge yorumu `LocaleText`'i işaret eder)
- Test: `app/test/core/utils/locale_text_test.dart`

**Interfaces:**
- Produces:

```dart
abstract final class LocaleText {
  /// TR: İ/I kuralı (TurkishText.upper). Diğerleri: standart toUpperCase.
  static String upper(Locale locale, String input);

  /// Arama katlaması. TR katlaması diakritik + İ/ı indirger;
  /// EN katlaması yalnız lowercase + diakritik indirger.
  static String fold(Locale locale, String input);

  /// Katalog araması için: her iki dilin katlamasıyla da dener —
  /// TR arayüzde "pushup" yazan kullanıcı sonuç görmeli (spec §3.3).
  static bool matchesAnyLocale(String query, String haystack);
}
```

- [ ] **Step 1: Kodu yaz** — TR yolu mevcut `TurkishText`'i çağırır (kod ikizlenmez, DRY); EN yolu `toLowerCase()` + mevcut diakritik indirgeme.
- [ ] **Step 2: Testleri yaz**

```dart
  test('TR: Kilo → KİLO', () =>
      expect(LocaleText.upper(const Locale('tr'), 'Kilo'), 'KİLO'));
  test('EN: kilo → KILO (i→I doğru)', () =>
      expect(LocaleText.upper(const Locale('en'), 'kilo'), 'KILO'));
  test('matchesAnyLocale: "pushup" ↔ "Push-Up (Şınav)"', () =>
      expect(LocaleText.matchesAnyLocale('pushup', 'Push-Up Şınav'), isTrue));
  test('matchesAnyLocale: "sinav" Türkçe katlamayla tutar', () =>
      expect(LocaleText.matchesAnyLocale('sinav', 'Şınav'), isTrue));
```

- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/core/utils/`
- [ ] **Step 4: Commit** — `git commit -m "feat: locale-aware text casing and folding"`

---

### Task 3: Dil seçimi — ProfileKeys.locale + Ayarlar satırı

**Files:**
- Modify: `ProfileKeys` dosyası (`static const locale = 'gorunum.dil';`)
- Modify: settings application (provider) + `settings_screen.dart` (üç seçenekli satır: Sistem/Türkçe/English)
- Modify: `app/lib/app/app.dart` (`MaterialApp.locale`)
- Test: `app/test/features/settings/locale_setting_test.dart`

**Interfaces:**
- Produces: `appLocaleProvider` → `Locale?` (`null` = sistem); değerler `'system' | 'tr' | 'en'`, varsayılan `system`

- [ ] **Step 1: Kodu yaz** — Task 3 (M12) tema modu deseninin aynısı; `MaterialApp(locale: ...)` null ise Flutter sistemden alır.
- [ ] **Step 2: Testleri yaz** — varsayılan null; `'en'` yazınca `Locale('en')`; ekran testi: satır üç seçenek gösterir (provider override ile).
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/settings/`
- [ ] **Step 4: Commit** — `git commit -m "feat: language setting with system default"`

---

### Task 4: Metin göçü — feature feature ARB'ye taşıma

En büyük görev; **feature başına bir alt-adım ve bir commit**. Sıra: `today → plan → workout → catalog → progress → health → settings → reminders(başlık/gövde) → core/widgets → onboarding`. Her alt-adımda:

1. Feature'ın `presentation/` dosyalarındaki tüm Türkçe string sabitleri `app_tr.arb`'ye anahtar olarak taşınır (`todayNoPlanTitle` gibi feature önekiyle), `app_en.arb`'ye çevirisi yazılır, widget `context.l10n.x` okur.
2. Parametreli metinler ICU ile: `"planExerciseTarget": "{count} × {reps}"`, çoğullar `plural` sözdizimiyle.
3. `TurkishDate`/`TurkishNumber` çağrıları `intl` `DateFormat('EEEE d MMMM', locale)` / `NumberFormat.decimalPattern(locale)`'e çevrilir. **`TurkishNumber` silinmez** — Drift/CSV gibi locale'siz bağlamlarda kalan kullanımlar duruyorsa dokunulmaz.
4. Bildirim metinleri (`reminder_planner` başlık/gövde üretimi): planner saf kalır — metin üretimi planner'dan çıkar, çağırana (scheduler) taşınır; scheduler `AppLocalizations`'ı **seçili locale ile elle kurar** (`lookupAppLocalizations(locale)`) çünkü arka planda `BuildContext` yok.

**Files:** her feature'ın `presentation/` dosyaları + iki ARB; reminders için `reminder_scheduler.dart`
**Test:** her alt-adımda mevcut ekran testleri güncellenir (metin bulma `find.text` → l10n üzerinden); parite testi kendiliğinden nöbet tutar.

- [ ] Step 1: today taşı → test → çalıştır → `git commit -m "feat: localise today feature strings"`
- [ ] Step 2: plan → … → `"feat: localise plan feature strings"`
- [ ] Step 3: workout → `"feat: localise workout feature strings"`
- [ ] Step 4: catalog (arama `LocaleText.matchesAnyLocale`'e bağlanır) → `"feat: localise catalog strings and search"`
- [ ] Step 5: progress → `"feat: localise progress feature strings"`
- [ ] Step 6: health → `"feat: localise health feature strings"`
- [ ] Step 7: settings + onboarding → `"feat: localise settings and onboarding strings"`
- [ ] Step 8: reminders + core/widgets (`AppEmptyState` vb. hazır metinleri parametre alır, sabit taşımaz) → `"feat: localise reminders and shared widgets"`

---

### Task 5: Gömülü metin nöbetçisi + tam doğrulama

**Files:**
- Test: `app/test/l10n/hardcoded_text_test.dart`

- [ ] **Step 1: Testi yaz**

```dart
  test('presentation dosyalarında gömülü Türkçe metin kalmadı', () {
    final tr = RegExp("['\"]([^'\"]*[çğıöşüÇĞİÖŞÜ][^'\"]*)['\"]");
    final allow = RegExp(r'//|TurkishText|LocaleText|_test\.dart');
    final offenders = <String>[];
    for (final f in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('presentation'))
        .where((f) => f.path.endsWith('.dart'))) {
      for (final (i, line) in f.readAsLinesSync().indexed) {
        if (allow.hasMatch(line)) continue;
        if (tr.hasMatch(line)) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty,
        reason: 'ARB\'ye taşınmamış metin:\n${offenders.join('\n')}');
  });
```

(Kaba ama etkili — spec §3.5. Yorum satırları muaf; yanlış pozitif çıkan meşru satırlar `// l10n-exempt` işaretiyle muaf tutulur ve teste bu muafiyet eklenir.)

- [ ] **Step 2: Çalıştır** — `flutter analyze && flutter test` (tam paket). EN locale'de duman testi: `testWidgets` ile uygulama `locale: Locale('en')` pompalanır, beş sekme başlığı İngilizce bulunur.
- [ ] **Step 3: Cihaz doğrulaması** — emülatörde dil değiştir: Ayarlar → English → ekranlar gezilir; Türkçe'ye dönülür.
- [ ] **Step 4: Commit** — `git commit -m "test: guard against hardcoded UI strings, english smoke test"`

---

## Öz-değerlendirme notları

- Spec §3 kapsaması: 3.1 kapsam sınırı → Global Constraints; 3.2 → Task 1; 3.3 üç yardımcı → Task 2 + Task 4.3; 3.4 → Task 3; 3.5 testler → Task 1 (parite) + Task 5 (gömülü metin).
- Bildirimlerin `BuildContext`siz locale sorunu Task 4.8'de `lookupAppLocalizations` ile çözülüyor — planner saf kalıyor (CLAUDE.md mimari kuralı).
- ARB şablonunun TR olması gen_l10n'de sorun değil; `@@locale` doğru yazıldığı sürece.


---

## Review düzeltmeleri (2026-08-31) — BAĞLAYICI

1. **[T5] Nöbetçi regex düzeltmesi.** Muafiyet yalnız `line.trimLeft().startsWith('//')` ve açık `// l10n-exempt` işaretiyle; `_test\.dart` alternatifi ölü koddu, kalkar. Satır sonu yorumu taşıyan gömülü metin artık kaçamaz.
2. **[T5] Tarama kökü genişler.** `lib/features/*/presentation` + `lib/core/widgets` + `lib/app` taranır.
3. **[T4] `import_plan_sheet` taşınır.** Kullanıcıya görünen arayüzdür; Task 4'e alt-adım eklenir. Sınır netleşir: **doğrulayıcı hata metinleri ve context.md Türkçe kalır** (AI'a gider), sheet'in kendi başlık/düğme/açıklama metinleri ARB'ye taşınır.
4. **[T4.8] Planner API değişikliği açık yazılır.** `PendingReminder` başlık/gövdeyi hazır metin olarak değil **tür + parametre** olarak taşıyacak şekilde evrilir; metni scheduler, seçili locale'in `AppLocalizations`'ından üretir. Mevcut planner testleri metin yerine tür+parametre doğrulamaya güncellenir. `slot.label` VERİdir — olduğu gibi geçer, çevrilmez.
5. **[T4.8] Locale çözümü.** `appLocaleProvider` null (Sistem) ise scheduler `PlatformDispatcher.instance.locale`'i `supportedLocales`'e indirger; widget dışı `DateFormat` için `initializeDateFormatting` bootstrap'a eklenir.
6. **[T4.4] Arama gerçeği.** Katalog araması DB'deki katlanmış `searchBlob` üstünde LIKE ile çalışıyor. `matchesAnyLocale` sorgu tarafında uygulanamaz; çözüm **yazım tarafında**: `searchText` üretimi her iki adın hem TR hem EN katlamasını blob'a ekler (M8 tohum damgası yeniden tohumlamayı tetikleyecek). `matchesAnyLocale` yalnız bellek-içi listelerde (besin araması M9) kullanılır.
7. **[T3] Anahtar yeri.** Global kısıta ek: `ProfileKeys`'e anahtar eklemek serbest, metin/mantık değişikliği yasak — ama tercih edilen yol M12 düzeltmesi 12: yeni anahtarlar `settings/domain/settings_keys.dart`'a.
8. **[T4.8] Paylaşılan bileşen eşlemeleri.** `AppStatus → l10n` etiket eşlemesi tek yerde: `core/widgets` içinde `AppLocalizations` alan yardımcı (`statusLabel(l10n, status)`). Diyalog, snackbar ve `Semantics(label:)` metinleri her Task 4 alt-adımının kontrol listesine dahildir.
9. **[T4] M12 senkronu.** M12 ekranları yeniden yazdığı için Task 4 başlarken alt-adım envanteri fiilî dosyalarla senkronize edilir (CLAUDE.md "sonraki planı gözden geçir" kuralı).
10. **[T5] EN duman testi genişler.** Beş sekme başlığına ek, her sekmeden 2-3 bilinen metin EN locale'de doğrulanır (ASCII-Türkçe metinler regex'e yakalanmadığı için tek güvence bu).
