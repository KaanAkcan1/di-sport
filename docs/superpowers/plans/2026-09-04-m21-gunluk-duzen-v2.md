# Günlük Düzen v2 (M21) Uygulama Planı

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development
> (if subagents available) or superpowers:executing-plans to implement this plan.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kalkış/uyku ve öğünler haftanın gününe göre özelleştirilebilsin;
öğünlere besin listesinden şablon tanımlansın; gün akışı düzenleme kapısı olsun.

**Architecture:** Varsayılanlar yerinde (profil + meal_behaviors), istisnalar
yeni satırlarda; saf `rhythm_resolver` tek doğruluk kaynağı; alarm/Diyet/AI
katmanları çözücüden okur. Spec: `docs/superpowers/specs/2026-09-04-gunluk-duzen-v2-tasarim.md`
(bölüm numaraları oradan). Mimari karar: `...gun-kapsayici-mimari-karar.md`.

**Tech Stack:** Flutter 3.47 / Drift 2.34 / Riverpod 3.4. **Döngü: önce kod →
sonra test → çalıştır → commit** (CLAUDE.md — TDD DEĞİL). Her görev sonunda
`flutter analyze` temiz + ilgili testler yeşil. Komutlar `app/` içinde çalışır:
`export PATH="$PATH:/c/dev/flutter/bin" && cd app`.

---

## Chunk 1: Veri katmanı

### Task 1: Şema v17 + sürüm kusuru düzeltme

**Files:**
- Create: `app/lib/features/settings/data/rhythm_override_table.dart`
- Modify: `app/lib/features/medical/data/medical_tables.dart` (MealBehaviors'a `weekday`)
- Modify: `app/lib/features/plan/data/plan_tables.dart` (PlanSlots'a `remind`)
- Modify: `app/lib/core/db/app_database.dart` (tablo kaydı, `schemaVersion => 17`, `if (from < 17)` bloğu)
- Test: `app/test/core/db/migration_v17_test.dart`

- [ ] **Step 1:** `rhythm_override_table.dart` yaz:

```dart
import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Gün bazlı kalkış/uyku istisnaları (spec §1). Satır = tek günün
/// istisnası; null alan = o alanda profil varsayılanı geçerli.
class RhythmOverrides extends Table with SyncColumns {
  IntColumn get weekday => integer()(); // DateTime.monday..sunday (1-7)
  TextColumn get wakeTime => text().nullable()(); // "HH:mm"
  TextColumn get sleepTime => text().nullable()();
}
```

- [ ] **Step 2:** `medical_tables.dart` MealBehaviors'a
  `IntColumn get weekday => integer().nullable()();` ekle (null = varsayılan
  satır). `plan_tables.dart` PlanSlots'a
  `BoolColumn get remind => boolean().nullable()();` ekle (null = tür
  varsayılanı; yorumda "AI içe alma daima null yazar" notu).
- [ ] **Step 3:** `app_database.dart`: `RhythmOverrides` import + `tables`
  listesine ekle; **`schemaVersion => 17`** (DİKKAT: kodda 15 kalmış, v16
  bloğu sahada hiç çalışmamış — spec §1 uyarısı); `onUpgrade`'e ekle:

```dart
if (from < 17) {
  await m.createTable(rhythmOverrides);
  await _addColumnIfAbsent(m, mealBehaviors, mealBehaviors.weekday);
  await _addColumnIfAbsent(m, planSlots, planSlots.remind);
}
```

- [ ] **Step 4:** `dart run build_runner build --delete-conflicting-outputs`
- [ ] **Step 5:** `migration_v17_test.dart` yaz — mevcut
  `app/test/core/db/migration_test.dart` kalıbıyla **v15 şemasından** aç
  ve yükselt; hem v16 sütununun (`daily_logs.bedTime`) hem v17
  sütunlarının (`meal_behaviors.weekday`, `plan_slots.remind`,
  `rhythm_overrides` tablosu) geldiğini iddia et. Bu, sahada hiç
  çalışmamış v16 bloğunun v17 yükseltmesinde ilk kez ve sorunsuz
  çalıştığını kanıtlar (spec §1 şartı).
- [ ] **Step 6:** `flutter test test/core/db/ && flutter analyze` → yeşil/temiz
- [ ] **Step 7:** `git add -A && git commit -m "feat: schema v17 with rhythm overrides, meal weekday, slot remind"`

### Task 2: Depolar — istisna CRUD + (mealKind, weekday) upsert

**Files:**
- Create: `app/lib/features/settings/data/rhythm_overrides_repository.dart`
- Modify: `app/lib/features/settings/data/meal_behaviors_repository.dart`
- Modify: `app/lib/features/settings/domain/meal_behavior.dart` (`weekday` alanı)
- Test: `app/test/features/settings/data/rhythm_overrides_repository_test.dart`
- Test: `app/test/features/settings/data/meal_behaviors_repository_test.dart` (mevcutsa genişlet)

- [ ] **Step 1:** `RhythmOverridesRepository`: `watchAll()` (deletedAt null),
  `setForDays(Set<int> days, {String? wakeTime, String? sleepTime})` — gün
  başına upsert (aynı `weekday` canlı satırı varsa güncelle;
  `weekly_windows_repository.addForDays` kalıbını örnek al), `remove(id)`
  yumuşak silme.
- [ ] **Step 2:** `MealBehaviorEntry`'ye `final int? weekday` ekle;
  repository `upsert` sorgusunu `mealKind AND weekday IS ?` ikilisine indir
  (varsayılanı düzenlerken varyasyonu ezmemeli — spec §1). `watchAll()`
  değişmez (tüm satırlar; süzme çözücüde).
- [ ] **Step 3:** Testler: (a) `setForDays({6,7}, wake:"09:00")` 2 satır yazar,
  tekrar çağrı günceller (satır sayısı sabit); (b) öğün varsayılanı + Paz
  varyasyonu ayrı satırlar, varsayılan upsert'i varyasyona dokunmaz;
  (c) yumuşak silme `watchAll`'dan düşürür.
- [ ] **Step 4:** `flutter test test/features/settings/data/ && flutter analyze`
- [ ] **Step 5:** `git commit -m "feat: rhythm override repository and day-aware meal behavior upsert"`

### Task 3: Saf çözücü — rhythm_resolver

**Files:**
- Create: `app/lib/features/settings/domain/rhythm_resolver.dart`
- Test: `app/test/features/settings/domain/rhythm_resolver_test.dart`

- [ ] **Step 1:** Spec §2 sözleşmesini uygula:

```dart
class DayRhythm {
  const DayRhythm({this.wakeTime, this.sleepTime, required this.meals});
  final String? wakeTime; // "HH:mm"
  final String? sleepTime;
  final List<ResolvedMeal> meals;
}

class ResolvedMeal {
  const ResolvedMeal({required this.behavior, this.isVariant = false});
  final MealBehaviorEntry behavior; // weekday'li satırın kendisi
  final bool isVariant; // o güne özel satır mı
}

DayRhythm resolveDay(
  int weekday, {
  String? defaultWake,
  String? defaultSleep,
  required List<RhythmOverrideEntry> overrides,
  required List<MealBehaviorEntry> mealRows,
}) { /* istisna alanı doluysa kazanır; öğünde weekday==gün satırı
       varsa BÜTÜN olarak weekday==null satırının yerine geçer */ }
```

- [ ] **Step 2:** Testler: istisna yalnız kalkışı ezer (uyku varsayılan kalır);
  varyasyon satırı bütün kazanır (saat null'sa bile varsayılanın saati
  SIZMAZ); istisnasız/varyasyonsuz girişte çıktı varsayılanla birebir;
  aynı öğüne iki farklı gün varyasyonu karışmaz.
- [ ] **Step 3:** `flutter test test/features/settings/domain/rhythm_resolver_test.dart && flutter analyze`
- [ ] **Step 4:** `git commit -m "feat: pure day rhythm resolver"`

## Chunk 2: Tüketiciler

### Task 4: Alarm planlayıcı gün-farkındalı

**Files:**
- Modify: `app/lib/features/reminders/domain/reminder_planner.dart`
- Modify: `app/lib/features/reminders/application/reminder_scheduler.dart`
- Test: `app/test/features/reminders/domain/reminder_planner_test.dart` (genişlet)

- [ ] **Step 1:** `planWindow` imzası (spec §4): `wakeTime: String?` →
  `wakeTimeByWeekday: Map<int, String>`; `MealTimeFact`'e `int? weekday`
  (null = her gün); `SlotFact`'e `bool? remind`. Tartı ve öğün üretim
  döngüleri günün çözülmüş saatini kullanır. `skipMeals` küresel bayrağı
  kalkar: slot ancak aynı **gün+öğün** için davranış saati varsa bastırılır.
  `remind == false` slot hiç alarm üretmez; `remind == true` tür bayrağını
  ezer (tür kapalıysa bile kurar — slot bazlı açık niyet).
- [ ] **Step 2:** `reminder_scheduler`: çözücüyü çağırıp 7 günün
  `wakeTimeByWeekday` + gün-bazlı `MealTimeFact` listesini üret
  (`resolveDay` × `DateTime.monday..sunday`); `SlotFact.remind` slottan taşınır.
- [ ] **Step 3:** Planner testleri: cumartesi tartı 09:00 / hafta içi 06:30;
  yalnız pazar kahvaltı saati tanımlıyken pazartesi plan-slotu öğün alarmı
  SUSTURULMAZ (eski küresel kuralın regresyonu); `remind:false` slot alarm
  üretmez; `remind:true` tür kapalıyken bile üretir.
- [ ] **Step 4:** `flutter test test/features/reminders/ && flutter analyze`
- [ ] **Step 5:** `git commit -m "feat: day-aware reminder planning with per-slot remind"`

### Task 5: Diyet günlüğü + şablondan kayıt

**Files:**
- Modify: `app/lib/features/nutrition/presentation/day_meals_card.dart`
- Create: `app/lib/features/settings/application/rhythm_providers.dart`
  (`dayRhythmProvider(String dateKey)` — çözücüyü depolara bağlar; aile
  argümanı String, DateTime DEĞİL — CLAUDE.md tuzağı)
- Test: `app/test/features/nutrition/presentation/day_meals_card_test.dart` (genişlet)

- [ ] **Step 1:** `day_meals_card` `mealBehaviorsProvider` yerine
  `dayRhythmProvider(dateKey)` okur; davranış/saat/şablon çözülmüş satırdan.
- [ ] **Step 2:** "Şablondan kaydet" eylemi: çözülmüş öğünde `fixedItemsJson`
  doluysa grup başlığında buton; dokununca kalemler mevcut
  `addResolvedItems(...)` yoluyla snapshot'lanır (kcal donuk — mevcut ilke;
  `slotId: null`, kaynak şablon plana bağ değildir).
- [ ] **Step 3:** Widget testleri (provider override ile — Drift'i widget
  testine sokma!): pazar görünümünde varyasyon saati/şablonu görünür;
  şablondan kaydet çağrısı doğru kalemleri geçirir (repo'yu sahtele).
- [ ] **Step 4:** `flutter test test/features/nutrition/ && flutter analyze`
- [ ] **Step 5:** `git commit -m "feat: resolved meals and template logging in diet card"`

### Task 6: context.md + amber uyarı kuralı

**Files:**
- Modify: `app/lib/features/ai_bridge/domain/context_md_builder.dart` (§1 satırı + öğün tablosu)
- Modify: `app/lib/features/settings/application/routine_source_adapter.dart` (varyasyon dökümü)
- Modify: `app/lib/features/ai_bridge/domain/import_warnings.dart` + `ai_bridge_providers.dart`
- Test: ilgili mevcut testleri genişlet (`context_md_builder_test`, `import_warnings_test`)

- [ ] **Step 1:** §1: "Kalkış 06:30; Cmt-Paz 09:00" biçimi (istisnaları
  gün-aralığı gruplayarak yaz); öğün tablosuna varyasyon satırları
  ("Kahvaltı (Paz): 10:00 · planlı").
- [ ] **Step 2:** Amber kural (spec §4): öğün **herhangi bir günde**
  `external`/`fixed` ise uyarı tetiklenir; `mealBehaviorByKind` düz haritası
  bu kurala göre kurulur.
- [ ] **Step 3:** Testler: istisnalı context çıktısı beklenen satırları
  içerir; yalnız-pazar-external öğüne plan yazan içe alma amber üretir.
- [ ] **Step 4:** `flutter test test/features/ai_bridge/ && flutter analyze`
- [ ] **Step 5:** `git commit -m "feat: day-aware routine in context.md and import warnings"`

## Chunk 3: UI + deneyim katmanı

### Task 7: Ayar ekranı — kural listesi + birleşik ekleme

**Files:**
- Modify: `app/lib/features/settings/presentation/weekly_schedule_screen.dart`
- Create: `app/lib/features/settings/presentation/day_picker_chips.dart`
  (`_WindowSheet`'ten çıkarılan gün-çipi ızgarası; settings-içi — core'a girmez)
- Create: `app/lib/features/settings/presentation/routine_entry_sheet.dart`
  (birleşik ekleme: Mesai · Yasaklı · Kalkış/uyku istisnası · Öğün varyasyonu)
- Test: `app/test/features/settings/presentation/weekly_schedule_screen_test.dart` (genişlet)

- [ ] **Step 1:** Mockup'a göre bölümler
  (`docs/superpowers/mockups/2026-09-04-gunluk-duzen-mockup.html`): RİTİM
  (varsayılan + istisna satırları, ✕ yumuşak silme + "geçmiş bozulmaz"
  onay diyaloğu), ÖĞÜNLER (kart + varyasyon satırları), PENCERELER (aynen),
  HAFTA ÖNİZLEME (7 kart, çözücüden; istisnalı gün vurgulu). Tek FAB →
  `routine_entry_sheet`.
- [ ] **Step 2:** `day_picker_chips` çıkarımı: `_WindowSheet` ve yeni sayfa
  aynı widget'ı kullanır; boş seçim satır-altı hata. Kaydet →
  `rescheduleQuietly` (mevcut kural — alarm hemen kurulur).
- [ ] **Step 3:** Öğün şablonu düzenleme: Diyet'teki mevcut besin arama +
  porsiyon seçiciye yönlendir (yeni seçici yazma); kalem listesi ≈kcal
  toplamı gösterir (`AppMetricValue`, ≈ işareti — tahmin ilkesi).
- [ ] **Step 4:** Widget testleri: istisna ekleme akışı satırı gösterir;
  hafta önizleme cumartesiyi farklı gösterir; boş gün hata (hepsi provider
  override ile).
- [ ] **Step 5:** `flutter test test/features/settings/ && flutter analyze`
- [ ] **Step 6:** `git commit -m "feat: rule-list schedule screen with unified entry sheet"`

### Task 8: Deneyim katmanı — derin bağlantı, remind toggle, geçmiş dozlar

**Files:**
- Modify: `app/lib/features/today/domain/day_flow.dart` (+ öğeye `editTarget` türü, `remind`, AI-doldurma durumu)
- Modify: `app/lib/features/today/presentation/day_flow_section.dart` (uzun basış → düzenleyici; dokunma işaretleme olarak KALIR)
- Modify: `app/lib/features/plan/presentation/slot_editor_sheet.dart` (remind toggle)
- Modify: `app/lib/features/supplements/application/supplement_providers.dart` (geçmiş gün dozları loglardan)
- Test: `app/test/features/today/domain/day_flow_test.dart` + widget testleri (genişlet)

- [ ] **Step 1:** `buildDayFlow` öğelerine düzenleme hedefi ekle (öğün →
  öğün varyasyon/şablon sayfası, doz → takviye düzenleyici, antrenman →
  plan editörü); `day_flow_section` uzun basışı yönlendirir.
- [ ] **Step 2:** Slot düzenleyiciye "Hatırlatma" üç-durum alanı (varsayılan/
  açık/kapalı → `remind` null/true/false); plan importer `remind`'e
  DOKUNMAZ (null kalır), graft korunan slotların değerini korur — importer
  testine iddia ekle.
- [ ] **Step 3:** Geçmiş günde doz satırları: `dosesForDate(dateKey)`
  (kural × o gün + log durumu); gelecek günde salt-okunur kural gösterimi,
  işaretleme alanı yok (düzenlenebilirlik kuralları). `day_flow_section`
  `isToday ? doses : []` kısıtını buna göre değiştirir.
- [ ] **Step 3b:** Bugün/gün ekranının tartı saati çözücüden gelsin
  (spec §4 son madde): `weighInTime`'ı besleyen kaynak tek profil
  `wakeTime`'ı yerine `dayRhythmProvider(dateKey)` çıktısını kullanır
  (kalkış + 15dk kuralı korunur). Test: cumartesi istisnası 09:00 iken
  cumartesi görünümünde tartı satırı 09:15.
- [ ] **Step 4:** Testler: akış öğesi hedefleri; graft remind koruması;
  geçmiş gün dozu logdan "alındı" gösterir, gelecek gün işaretlenemez.
- [ ] **Step 5:** `flutter test test/features/today/ test/features/supplements/ && flutter analyze`
- [ ] **Step 6:** `git commit -m "feat: day flow deep links, slot remind toggle, historical doses"`

### Task 9: Süpürme

- [ ] **Step 1:** `flutter analyze` temiz + `flutter test` TÜM paket yeşil.
- [ ] **Step 2:** Emülatörde duman testi: istisna ekle → cumartesi önizlemesi
  değişti mi; alarm logunda cumartesi 09:00 var mı; şablondan kayıt kcal'i
  doğru mu. (CLAUDE.md tuzakları: `adb` Türkçe karakter, build retry.)
- [ ] **Step 3:** CLAUDE.md güncelle: şema tablosuna v17 satırı, M21 durumu,
  "sürüm kusuru düzeltildi" notu; Günlük Düzen açıklaması.
- [ ] **Step 4:** `git commit -m "docs: record M21 daily rhythm v2 completion"`
