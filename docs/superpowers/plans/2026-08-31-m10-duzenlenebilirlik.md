# M10 — Düzenlenebilirlik Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Geçmiş günler tam yetkiyle açılır (takvimden ve Bugün başlığından), plan uygulama içinden düzenlenir (hedefler, günler, slotlar, hareketler, boş plan), saatler Günlük Düzen'e taşınır, "aile yemeği saati" kalkar.

**Architecture:** İki hat: (1) `todayProviders` → `dayProviders(date)` ailesine genelleme — Bugün ekranı `date=bugün` özel hâli olur; (2) plan yazma yolu — `plan` feature'ına editör repository metotları + dört düzenleme ekranı. `FullPlan.sourceRaw` korunur: planın kökeni olur, tanımı olmaktan çıkar.

**Tech Stack:** Riverpod aile provider'ları (argüman String — `yyyy-MM-dd`; CLAUDE.md tuzağı: List/DateTime aile argümanı yasak, değer eşitliği şart) · Drift

**Spec:** `docs/superpowers/specs/2026-08-31-disport-v2-saglikli-yasam.md` §6

## Global Constraints

- **Döngü TDD DEĞİL:** her görevde **kod → testler → çalıştır → review → commit**.
- Şema değişikliği yalnız Task 3'te: **v14 — `plan_slots.mealKind`**. Başka tablo değişmez; kalan iş provider + ekran katmanında. (`plans.updatedAt` SyncColumns'ta zaten var.)
- Ölçüm kaydı (kilo, uyku, öğün, aktivite, takviye işareti) yalnız **bugün ve geçmişe**; plan düzenleme her tarihte (spec §6.2).
- Plan değişince alarmlar `rescheduleQuietly` ile hemen yeniden kurulur (M6 kuralı).
- Metinler ARB'ye; görsel dil M12.
- Riverpod aile argümanı `String dateKey` (`'2026-09-01'`); `DateTime` geçilmez.

## Dosya Haritası

| Dosya | Sorumluluk |
|---|---|
| `app/lib/features/today/application/day_providers.dart` | `dayLogProvider(dateKey)`, `dayPlanDayProvider(dateKey)`… aile |
| `app/lib/features/today/presentation/day_screen.dart` | Tarihli gün ekranı (Bugün bunun özel hâli) |
| `app/lib/features/plan/data/plan_editor_repository.dart` | Plan yazma: hedef/gün/slot/hareket upsert-sil |
| `app/lib/features/plan/presentation/plan_settings_screen.dart` | Başlık, hedefler, kurallar |
| `app/lib/features/plan/presentation/day_editor_sheet.dart` | Gün tipi, başlık, akşam önerisi |
| `app/lib/features/plan/presentation/slot_editor_sheet.dart` | Saat, tür (`SlotKind` + `MealKind`), etiket, not |
| `app/lib/features/plan/presentation/exercise_editor_sheet.dart` | Katalogdan seç + hedefler + şiddet |
| `app/lib/features/settings/presentation/daily_rhythm_screen.dart` | "Günlük Düzen" — kalkış/uyku/mesai/uygun-değil (M6 weekly_windows ekranının evrimi) |

---

### Task 1: dayProviders ailesi

**Files:**
- Create: `day_providers.dart` (mevcut `today_providers.dart` mantığı tarihe parametrelenir; `todayXProvider`'lar `dayXProvider(todayKey)`'e delege eden sarmalayıcılar olur — mevcut ekran/test kırılmaz)
- Test: `day_providers_test.dart`

**Interfaces:**
- Produces:

```dart
String dateKeyOf(DateTime d);                    // 'yyyy-MM-dd'
@riverpod Stream<DailyLog?> dayLog(Ref ref, String dateKey);
@riverpod Stream<FullPlanDay?> dayPlanDay(Ref ref, String dateKey);
@riverpod Stream<double?> dayWeight(Ref ref, String dateKey);
// + repository'lerde eksik tarihli yazma metotları:
Future<void> setWeightOn(DateTime day, double kg);   // body_metrics
Future<void> setSleepOn(DateTime day, ...);
// daily_logs/meal_entries/activity_logs zaten tarihli — değişmez
```

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — `dayLog('2026-08-30')` o günün kaydını akıtır; `todayLogProvider` delegasyonu aynı veriyi verir (geriye uyum); geçmişe kilo yazılır, akış günceller.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/today/`
- [ ] **Step 4: Commit** — `git commit -m "feat: date-parameterised day providers"`

---

### Task 2: Gün ekranı — tarihle açılır, takvimden ve başlıktan

**Files:**
- Create: `day_screen.dart` (mevcut `TodayScreen` gövdesi taşınır; `TodayScreen` → `DayScreen(dateKey: today)` sarmalayıcısı)
- Modify: başlık: ‹ › okları aktif; tarih dokununca `showDatePicker`; bugün değilse eyebrow amber "GEÇMİŞ GÜN" + "bugüne dön" düğmesi; **gelecek** tarihte ölçüm/öğün giriş alanları gizlenir, yerine tek satır bilgi ("Gelecek güne kayıt girilmez"), plan bölümü görünür
- Modify: `plan_screen.dart` — takvim hücresine dokunuş `DayScreen(dateKey)` push eder; kayıtlı günler işaretli (M12 tonları zaten yapıyor)
- Test: `day_screen_test.dart`

- [ ] **Step 1: Kodu yaz** — SIRADA kartı yalnız bugünde (geçmişte "şimdi" yok); `AppWeekDots` seçili günü merkez alır.
- [ ] **Step 2: Testleri yaz** — dünün ekranında tartı girişi görünür ve `setWeightOn(dün)` çağrılır; yarının ekranında giriş yok; "bugüne dön" bugüne getirir; takvim dokunuşu doğru dateKey push eder.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/today/ test/features/plan/`
- [ ] **Step 4: Commit** — `git commit -m "feat: day screen with past-day editing and calendar entry"`

---

### Task 3: Plan editör repository'si

**Files:**
- Create: `plan_editor_repository.dart`
- Test: `plan_editor_repository_test.dart` (gerçek DB — planın en kapsamlı repo testi)

**Interfaces:**
- Produces:

```dart
class PlanEditorRepository {
  Future<void> updateGoals(String planId, PlanGoals goals);
  Future<void> updateRules(String planId, PlanRules rules);
  Future<void> updateTitle(String planId, String title);
  Future<void> updateDay(String dayId,
      {PlanDayType? type, String? headline, String? dinnerSuggestion});
  Future<String> upsertSlot(String dayId, {String? slotId,
      required String time, required SlotKind kind, MealKind? mealKind,
      required String label, String? note});
  Future<void> deleteSlot(String slotId);                 // yumuşak
  Future<String> upsertExercise(String dayId, {String? planExerciseId,
      required String exerciseId, int? sets, int? reps, int? durationSec,
      int? restSec, double? speedKmh, double? gradePct, Effort? effort,
      String? note});
  Future<void> deleteExercise(String planExerciseId);     // yumuşak
  Future<String> createEmptyPlan({required String title,
      required DateTime startDate, required int weeks,
      required PlanGoals goals});   // sourceRaw = '' — elle kurulmuş
}
```

Not: `mealKind` slot tablosuna **yeni sütun ister mi?** — hayır: `plan_slots.kind` zaten var; `MealKind` slot `label`ından bağımsız ayrı sütun olarak v13'te AÇILMADI. Karar: `plan_slots`'a `mealKind TEXT?` **v14 açmak yerine** `note`/`label` kirletmek de yanlış — **şema gerekiyor**. Bu görev v13'ü M9 yazdıysa **v14 göçü burada açılır**: `if (from < 14) plan_slots.mealKind` + `schemaVersion=14`. (Spec §2 tablosuna v14 işlenir.)

- [ ] **Step 1: Kodu yaz** (+ v14 göçü + build_runner)
- [ ] **Step 2: Testleri yaz** — upsert yeni slot ekler / mevcutu günceller; silme yumuşak ve `FullPlan` okumasından düşer; `createEmptyPlan` 28 boş gün üretir (`weeks×7`), tip `rest`; hedef güncelleme `watchActivePlan` akışına yansır; **öğün slotu silinince bağlı `meal_entries.slotId` kaydı bozulmaz** (slotId nullable — serbest kayda döner).
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/plan/ test/core/db/`
- [ ] **Step 4: Commit** — `git commit -m "feat: plan editor repository, mealKind column v14"`

---

### Task 4: Editör ekranları

**Files:**
- Create: `plan_settings_screen.dart`, `day_editor_sheet.dart`, `slot_editor_sheet.dart`, `exercise_editor_sheet.dart`
- Modify: `plan_screen.dart` (✎ → plan ayarları; gün detayında "düzenle"; slot/hareket satırlarında düzenleme girişi)
- Modify: plan değişikliklerinde `rescheduleQuietly`
- Test: dört ekran testi (provider override)

Ekran içerikleri (spec §6.3 tablosu):
- **Plan ayarları:** başlık; hedefler (kcal, protein g, su L, haftalık salon/ev, hedef kayıp kg — `TextFormField` sayısal + `NumberFormat`); kurallar: yasak/serbest listeleri (satır ekle/sil).
- **Gün:** tip (`SegmentedButton`: Salon/Ev/Dinlenme), başlık, akşam önerisi.
- **Slot:** saat (`showTimePicker`), tür (`SlotKind` seçimi; tür `meal` ise `MealKind` seçimi — spec "öğün türü burada seçilir"), etiket, not; sil.
- **Hareket:** katalogdan seçim (M8 katalog seçici — arama + filtre; `onPicked` callback'li), set/tekrar/süre/dinlenme, kardiyoysa hız/eğim/effort (M9 alanları), not; sil.
- Plan detayında köken satırı: `sourceRaw` doluysa "AI planı · düzenlendi" / boşsa "Elle kuruldu" (updatedAt > createdAt kıyası).

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — form doğrulamaları (kcal ≤ 0 reddedilir, saat biçimi); meal slotunda MealKind seçimi zorunlu; hareket editörü kataloğa gider ve dönen id yazılır; düzenleme sonrası `rescheduleQuietly` çağrıldı (sahte scheduler).
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/plan/`
- [ ] **Step 4: Commit** — `git commit -m "feat: plan editor screens with reschedule on change"`

---

### Task 5: Boş plan kurma + içe alma yolunun korunması

**Files:**
- Modify: plan boş durumu — iki eylem: "Örnek planı yükle" (mevcut) + **"Boş plan kur"** (başlık/başlangıç/hafta/hedef formu → `createEmptyPlan`)
- Modify: `import_plan_sheet.dart` DEĞİŞMEZ — doğrulama testi: içe alma akışı editörden bağımsız çalışır (regresyon koruması)
- Test: boş plan akış testi + mevcut ai_bridge testlerinin bozulmadığının koşusu

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — boş plan kur → Bugün "dinlenme" gösterir → slot ekle → Bugün'de belirir (uçtan uca, gerçek DB).
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/plan/ test/features/ai_bridge/`
- [ ] **Step 4: Commit** — `git commit -m "feat: create empty plan flow"`

---

### Task 6: Günlük Düzen — saatlerin taşınması

**Files:**
- Modify: M6 `weekly_windows` ekranı → `daily_rhythm_screen.dart` adı ve kapsamı: **kalkış, uyku, mesai, uygun-değil-1/2** tek yerde (spec §6.4); kalkış/uyku değerleri `profile_entries`'teki mevcut anahtarlarda kalır (veri göçü yok — yalnız girişin yeri değişir)
- Modify: `settings_screen.dart` profil formundan uyanma/uyku saati alanları ve **"aile yemeği saati" serbest metni kaldırılır**; form yalnız kimlik/ölçü bilgisi tutar
- Modify: `context_md_builder` — aile yemeği alanı okuyorsa boş değerle geriye uyumlu (alan `profile_entries`'te kalır, yeni girilemez; builder "belirtilmemiş" der)
- Modify: alarm zamanlayıcı uyanma saatini aynı anahtardan okumaya devam eder (değişiklik yok — test bunu kanıtlar)
- Test: ekran testi + `reminder` regresyon testi + `context_md` testi güncellenir

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — Günlük Düzen'de kalkış saati değişince tartı alarmı yeniden kurulur (`rescheduleQuietly` sahte); Ayarlar formunda kaldırılan alanlar yok; context.md aile yemeği olmadan üretili.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/settings/ test/features/reminders/ test/features/ai_bridge/`
- [ ] **Step 4: Commit** — `git commit -m "feat: daily rhythm screen, remove wake/sleep and family-dinner from profile form"`

---

### Task 7: Süpürme + dokümantasyon + kapanış

- [ ] **Step 1:** `CLAUDE.md` — dayProviders deseni, plan editörü, v14, Günlük Düzen; spec §2 tablosuna v14. Bilinen boşluklardan "geçmişe erişim yok" düşülür.
- [ ] **Step 2:** Tam paket `flutter analyze && flutter test`; emülatörde uçtan uca: takvimden düne git → tartı gir → İlerleme'de gör → plan slotu düzenle → alarm penceresi yenilendi → boş plan kur.
- [ ] **Step 3:** `git commit -m "docs: record editability architecture and v14"`

---

## Öz-değerlendirme notları

- Spec §6 kapsaması: 6.1→bütün; 6.2→T1-2 (tam yetki + takvim girişi + gelecek kuralı + görsel ayrışma); 6.3→T3-5 (dört ekran + boş plan + sourceRaw kökeni); 6.4→T6.
- v14 bu planda doğdu (mealKind) — spec şema tablosu güncellenecek; M9 `meal_entries.mealKind`'i zaten taşıyor, v14 yalnız **plan slotuna** tür ekliyor; ikisi ayrı şey (kayıt ≠ plan).
- Geriye uyum iki kilitle korunuyor: `todayXProvider` delegasyonları (T1) ve ai_bridge içe alma regresyon koşusu (T5).
- "Kayıt girilmiş günler takvimde işaretlenir" M12 ton sisteminden bedavaya geliyor; ayrıca iş yok.


---

## Review düzeltmeleri (2026-08-31) — BAĞLAYICI

1. **[T2] Geçmiş güne antrenman kaydı eksikti.** Spec §6.2 açıkça ister. Task 2'ye eklenir: geçmiş günün antrenman bölümü kayıtlı setleri düzenlenebilir gösterir (tekrar/kilo düzelt, set ekle/sil — basit sheet; canlı sayaç akışı yalnız bugünde). `exercise_logs` upsert'i tarihli, yeni şema gerekmez.
2. **[T3] `MealKind` plan domain'inden.** M9 düzeltmesi 4: `plan/domain/meal_kind.dart`. Çift yönlü feature bağımlılığı doğmaz.
3. **[T1] İkiz metot yazılmaz.** `setWeightOn/setSleepOn` iptal — mevcut `BodyMetricsRepository.upsert(isoDate:, kind:, ...)` dateKey ile çağrılır. Taslak imzalar gerçek tiplerle: `Stream<DailyLogView> dayLog(String dateKey)` (null olmayan view), `Stream<FullPlanDay?> dayPlanDay(String dateKey)`.
4. **[T6] Doğru dosyalar.** Kaldırılacak alanlar `settings_screen.dart`'ta değil: form `ProfileKeys.form` listesinden üretiliyor ve `profile_form.dart` hem Ayarlar hem **onboarding**. Görev bu iki dosya + form listesi üzerinden yürür.
5. **[T6] Onboarding istisnası.** Uyanma/uyku saati onboarding'de SORULMAYA DEVAM EDER (girilmezse sabah tartı alarmı sessizce kurulmuyor — scheduler `wakeTime` boşsa atlıyor); yalnız Ayarlar'daki profil formundan kalkar, kalıcı düzenleme yeri Günlük Düzen.
6. **[T2] "Bugüne dön" davranışı.** Push bağlamında = pop; sekme bağlamında = state'i bugüne sıfırlama. `dateKey=bugün` push edilmez — Bugün sekmesinin ikizi üretilmez. Teste yazılır.
7. **[T2] Gelecek gün etiketi.** Eyebrow gelecekte "PLANLANAN GÜN"; amber "GEÇMİŞ GÜN" yalnız geçmişte.
8. **[T2] Şimdi işareti + tarihli yazım testleri.** Bugün olmayan günde `AppNowMarker`/spot kart/`clockProvider` bağı çizilmez; "+Öğün dünün ekranında düne yazar" testi eklenir.
9. **[T3] Test koşusu.** Öğün-slotu-silme testi nutrition tablolarına dokunuyor; koşuya `test/features/nutrition/` eklenir.
10. **[T5] `createEmptyPlan` sözleşmesi.** Aktif plan varsa yenisi aktif olur, eskisi pasifleşir (içe alma davranışıyla aynı).
