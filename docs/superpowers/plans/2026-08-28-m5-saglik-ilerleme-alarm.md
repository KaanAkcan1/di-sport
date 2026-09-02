# di@sport M5 — Sağlık, İlerleme, Alarmlar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** v1 tamamlanır: tahlil takibi (lab_results + paneller), İlerleme ekranı (kilo trendi + haftalık özet + geçiş kriteri), 7 günlük pencereli alarmlar, yedekleme, isteğe bağlı BYOK.

**Architecture:** `health` ve `progress` feature'ları doldurulur; `reminders` feature'ı `core/notifications` soyutlaması üstüne kurulur — zamanlama hesabı saf fonksiyondur (`computeWindow`), bildirim katmanı sahtelenebilir. Grafikler fl_chart; hareketli ortalama ve haftalık özet `domain/` içinde saf ve testlidir.

**Tech Stack:** M4 yığını + fl_chart, flutter_local_notifications, timezone, flutter_timezone, http (yalnız BYOK), file_picker + share_plus (yedek).

**Spec:** `docs/superpowers/specs/2026-08-28-disport-tasarim.md` (özellikle 5.4, 5.5, 6-İlerleme/Sağlık, 7.5, 8)

## Global Constraints

- M1-M4 Global Constraints geçerli
- `lab_results.panel`: `liver | metabolic | vitamin | thyroid | lipid | other` (spec 5.4)
- iOS bekleyen bildirim sınırı 64 → yalnız önümüzdeki 7 gün zamanlanır, uygulama açılışında pencere kaydırılır (spec 8)
- Android'de `SCHEDULE_EXACT_ALARM` çalışma anında istenir; `USE_EXACT_ALARM` KULLANILMAZ; izin yoksa `AndroidScheduleMode.inexactAllowWhileIdle`'a düşülür (spec 8)
- Geçiş kriteri: kilo < 105 VE pushupMax ≥ 8 VE kullanıcı onaylı "koşu sonrası ağrı yok" (spec 5.5)
- BYOK: onay ekranı görülmeden hiçbir veri cihazdan çıkmaz (spec 7.5)
- Her görev sonunda `flutter analyze` temiz, `flutter test` yeşil

**Önkoşul:** M4 tamamlanmış — AI döngüsü çalışıyor, `HealthSourceAdapter.recentLabs()` boş dönüyor (bu planda doldurulacak).

---

## Senkron Notu (M4 sonrası, yürütmeden önce)

Bu plan M1-M4 kodu yazılmadan önce yazıldı. Yürütmeden önce gerçek kodla
karşılaştırıldı; beş fark bulundu.

**1. Şema sürümü v5 değil v6.** `exercise_logs` M3'te v5'i aldı
(`app_database.dart:37`). Tahlil tabloları **v6** olacak, göç bloğu
`if (from < 6)`.

**2. `MetricPoint` adı `health`'te yok.** M4'te `ai_bridge`'in port tipiyle
çakıştığı için depodaki typedef `MetricSample` oldu
(`body_metrics_repository.dart:9`). Task 3-4 bu adı kullanacak.

**3. Task 5'in iki testi birbiriyle çelişiyor.** Pencere tanımı belirsiz
kalmış:

- `only next 7 days` testi her bildirimin `2026-09-08 00:00`'dan önce
  olmasını bekliyor (takvim günü penceresi).
- `morning weigh-in` testi `hasLength(7)` bekliyor ve yorumu "2-8 Eylül"
  diyor — 8 Eylül 06:26 dahil (anlık pencere).

İkisi aynı anda doğru olamaz. **Anlık pencere seçildi**
(`now < fireAt < now + windowDays`), çünkü kaydırmalı pencerenin amacı
bu: uygulama her açılışta yeniden kurduğu için "önümüzdeki 7×24 saat"
takvim gününe hizalamaktan daha doğru davranır — akşam 23:00'te açılan
uygulama ertesi haftanın tamamını kapsar. `only next 7 days` testinin
sınırı `DateTime(2026, 9, 8, 8)` olarak düzeltildi.

**4. "Plan bitiyor" kuralı da çelişiyor.** Metin "`planEndDate - 3
gün`den itibaren" diyor ama test `[2, 3, 4]` bekliyor (bitiş 4 Eylül).
**Test doğru kabul edildi:** planın son üç günü, bitiş günü dahil
(`endDate - 2 … endDate`). Metin buna göre okunmalı.

**5. Hazır gelen API'ler — yeniden yazılmayacak.** M3/M4 bu planın
varsaydığı yardımcıları zaten üretti:

| İhtiyaç | Hazır API |
|---|---|
| Task 3 kilo serisi | `BodyMetricsRepository.series(kind)` |
| Task 4 son ölçümler | `BodyMetricsRepository.latestPerKind()` |
| Task 4 günlük kayıtlar | `TodayRepository.rowsBetween(from, to)` |
| Task 5 kaçak serisi | `TodayRepository.missedStreak(...)` — dinlenme gününü zaten eliyor |
| Task 4/6 profil | `ProfileRepository.read/set` |
| Task 2/4 iskelet | `AppScreenBody`, `AppSection`, `AppAsyncView`, `AppStatusChip`, `AppMetricValue`, `AppEmptyState` |

Task 6'nın `payload → sekme` eşlemesi kabuktaki gerçek sırayla uyuşuyor:
`today=0, plan=1, progress=2, health=3` (`app.dart:106`).

---

### Task 1: lab_results + lab_schedules tabloları ve repository

**Files:**
- Create: `app/lib/features/health/data/lab_tables.dart`
- Create: `app/lib/features/health/data/lab_repository.dart`
- Modify: `app/lib/core/db/app_database.dart` (schema v5)
- Modify: `app/lib/features/health/application/health_source_adapter.dart` (recentLabs doldur)
- Test: `app/test/features/health/data/lab_repository_test.dart`

**Interfaces:**
- Produces:
  - Tablo `LabResults`: `date`, `marker`, `value`, `unit`, `refLow?`, `refHigh?`, `panel`, `labName?`, `note?`, `attachmentPath?` (+ SyncColumns) — spec 5.4
  - Tablo `LabSchedules`: `marker`, `lastDate`, `intervalMonths` (+ SyncColumns)
  - `class LabRepository`:
    - `Future<void> add(LabEntry e)` — aynı marker için `lab_schedules.lastDate` de güncellenir
    - `Stream<Map<String, List<LabEntry>>> watchByPanel()` — panel → tarihçe (yeni→eski)
    - `Future<List<LabEntry>> latestPerMarker()`
    - `Future<void> setSchedule(String marker, int intervalMonths)`
    - `Future<List<({String marker, DateTime nextDue})>> dueSchedules(DateTime now)` — `lastDate + intervalMonths <= now`
  - `class LabEntry { final String id; final String date; final String marker; final double value; final String unit; final double? refLow; final double? refHigh; final String panel; final String? labName; final String? note; }`
  - `LabStatus statusOf(LabEntry e)` → `enum LabStatus { low, normal, high, unknown }` (saf; Sağlık ekranı renk kodu, spec 6)

- [ ] **Step 1: Failing test**

`app/test/features/health/data/lab_repository_test.dart`:

```dart
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

LabEntry vitD({String date = '2026-06-15', double value = 10}) => LabEntry(
      id: 'l-$date',
      date: date,
      marker: 'Vitamin D',
      value: value,
      unit: 'ng/mL',
      refLow: 30,
      refHigh: 100,
      panel: 'vitamin',
    );

void main() {
  late AppDatabase db;
  late LabRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LabRepository(db);
  });
  tearDown(() => db.close());

  test('add + watchByPanel groups and orders newest first', () async {
    await repo.add(vitD());
    await repo.add(vitD(date: '2026-09-20', value: 24));
    final map = await repo.watchByPanel().first;
    expect(map['vitamin']!.first.value, 24);
    expect(map['vitamin'], hasLength(2));
  });

  test('statusOf classifies against reference range', () {
    expect(statusOf(vitD(value: 10)), LabStatus.low);
    expect(statusOf(vitD(value: 50)), LabStatus.normal);
    expect(statusOf(vitD(value: 120)), LabStatus.high);
  });

  test('add updates schedule lastDate; dueSchedules honors interval',
      () async {
    await repo.setSchedule('Vitamin D', 3);
    await repo.add(vitD(date: '2026-05-01'));
    final due = await repo.dueSchedules(DateTime(2026, 9, 1));
    expect(due.single.marker, 'Vitamin D');
    expect(due.single.nextDue, DateTime(2026, 8, 1));

    expect(await repo.dueSchedules(DateTime(2026, 6, 1)), isEmpty);
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon**

Tablolar (`lab_tables.dart`) M3'teki kalıpla (`@DataClassName('LabResultRow')` / `('LabScheduleRow')`); `LabSchedules.marker` üzerinde `unique()`. `app_database.dart`: `schemaVersion => 5`, `if (from < 5)` göçü. `statusOf`:

```dart
enum LabStatus { low, normal, high, unknown }

LabStatus statusOf(LabEntry e) {
  if (e.refLow == null || e.refHigh == null) return LabStatus.unknown;
  if (e.value < e.refLow!) return LabStatus.low;
  if (e.value > e.refHigh!) return LabStatus.high;
  return LabStatus.normal;
}
```

`dueSchedules` ay ekleme: `DateTime(d.year, d.month + interval, d.day)` (Dart ay taşmasını normalize eder). `add` içinde: insert + `lastDate` upsert, tek transaction.

`HealthSourceAdapter.recentLabs()` (M4 dosyası) `LabRepository.latestPerMarker()`'dan `LabValueDump` üretir — M4 senkron maddesi kapanır.

- [ ] **Step 4: PASS doğrula**

- [ ] **Step 5: Commit**

```powershell
git add app/lib/features/health app/lib/core/db app/test/features/health
git commit -m "feat: lab results and schedules (schema v5), health source wired"
```

### Task 2: Sağlık ekranı

**Files:**
- Modify: `app/lib/features/health/presentation/health_screen.dart` (yer tutucuyu değiştir)
- Create: `app/lib/features/health/presentation/add_lab_sheet.dart`
- Create: `app/lib/features/health/application/health_providers.dart`
- Test: `app/test/features/health/presentation/health_screen_test.dart`

**Interfaces:**
- Consumes: `LabRepository`, `statusOf`, `BodyMetricsRepository` (ölçüm girişi: bel/göbek/şınav max/plank)
- Produces: Sağlık sekmesi: en üstte vadesi gelen tahlil uyarı şeridi (`dueSchedules`), panel kartları (`liver · metabolic · vitamin · thyroid · lipid · other` → Türkçe başlıklar: Karaciğer, Metabolizma, Vitamin, Tiroid, Lipid, Diğer), her satır: marker, son değer + birim, `statusOf` rengine göre nokta (low/high → hata rengi, normal → yeşil), önceki değere göre trend oku (↑↓→). FAB → `AddLabSheet` (marker, değer, birim, ref aralığı, panel, tarih) ve ölçüm girişi (kind seçici + değer). Test: seed'li db ile panel kartının ve renk noktasının render'ı, sheet ile ekleme.

- [ ] **Step 1: Failing widget testi** — panel başlığı + son değer + ekleme akışı (M3 Task 5 widget test kalıbıyla; `db`'ye `LabRepository(db).add(...)` seed, `find.text('Vitamin')`, `find.text('24 ng/mL')`, FAB → form doldur → kaydet → yeni satır görünür).

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon** — `health_providers.dart`: `labRepositoryProvider`, `labsByPanelProvider` (stream), `dueLabsProvider` (future). Ekran: `ListView` → uyarı şeridi (`MaterialBanner` benzeri `Card`, "Vitamin D tahlilinin vakti geldi (3 ayda bir)") → panel `Card`'ları → her marker `ListTile`. Trend oku: aynı marker'ın son iki değeri karşılaştırılır. `AddLabSheet`: `showModalBottomSheet`, alanlar `Key('lab-<field>')`, panel `DropdownButton`.

- [ ] **Step 4: PASS + analyze**

- [ ] **Step 5: Commit** — `feat: health screen with lab panels, status colors, due banner`

### Task 3: İlerleme domain'i — saf hesaplar

**Files:**
- Create: `app/lib/features/progress/domain/weight_trend.dart`
- Create: `app/lib/features/progress/domain/weekly_summary.dart`
- Create: `app/lib/features/progress/domain/transition_criteria.dart`
- Test: `app/test/features/progress/domain/weight_trend_test.dart`
- Test: `app/test/features/progress/domain/weekly_summary_test.dart`
- Test: `app/test/features/progress/domain/transition_criteria_test.dart`

**Interfaces:**
- Consumes: yalnız Dart çekirdeği (saf katman — spec 4.1 domain tanımı)
- Produces:
  - `List<({String date, double avg})> movingAverage(List<({String date, double value})> points, {int window = 7})` — eksik günleri atlamaz, eldeki son `window` noktayı ortalar
  - `class WeekSummary { final int weekIndex; final double? avgWeight; final double? deltaFromPrevWeek; final int gymDone; final int gymTarget; final int homeDone; final int homeTarget; final int slipDays; }`
  - `List<WeekSummary> summarizeWeeks({required List<({String date, String dayType, bool workoutDone, bool noAlcoholSugar})> days, required List<({String date, double value})> weights, required int gymTarget, required int homeTarget})` — hafta = plan `weekIndex` değil takvim dilimi: `days` listesi plan günleriyle eşlenmiş gelir, 7'şerli dilimlenir; `slipDays` = `noAlcoholSugar == false` gün sayısı (spec 5.5 "kaçak")
  - `class TransitionCriteria { final bool weightOk; final bool pushupOk; final bool painFreeOk; bool get allMet; }`
  - `TransitionCriteria evaluateTransition({double? latestWeight, double? latestPushupMax, required bool painFreeConfirmed})` — eşikler: `< 105`, `>= 8` (spec 5.5)

- [ ] **Step 1: Failing testler**

`weight_trend_test.dart`:

```dart
import 'package:disport/features/progress/domain/weight_trend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moving average with window 3', () {
    final points = [
      (date: '2026-09-01', value: 110.0),
      (date: '2026-09-02', value: 109.0),
      (date: '2026-09-03', value: 111.0),
      (date: '2026-09-04', value: 108.0),
    ];
    final avg = movingAverage(points, window: 3);
    expect(avg.first.avg, 110.0); // tek nokta
    expect(avg[2].avg, closeTo(110.0, 0.001)); // (110+109+111)/3
    expect(avg[3].avg, closeTo(109.333, 0.001)); // (109+111+108)/3
  });

  test('empty input yields empty output', () {
    expect(movingAverage([]), isEmpty);
  });
}
```

`weekly_summary_test.dart`:

```dart
import 'package:disport/features/progress/domain/weekly_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two weeks summarized with averages, counts and slips', () {
    final days = [
      for (var i = 0; i < 14; i++)
        (
          date: '2026-09-${(i + 1).toString().padLeft(2, '0')}',
          dayType: i % 7 == 0 || i % 7 == 2 || i % 7 == 5 ? 'gym' : 'home',
          workoutDone: i != 3, // 4. gün kaçırıldı
          noAlcoholSugar: i != 8, // 9. gün kaçak
        ),
    ];
    final weights = [
      for (var i = 0; i < 14; i++)
        (
          date: '2026-09-${(i + 1).toString().padLeft(2, '0')}',
          value: 110.0 - i * 0.1,
        ),
    ];

    final weeks = summarizeWeeks(
        days: days, weights: weights, gymTarget: 3, homeTarget: 4);

    expect(weeks, hasLength(2));
    expect(weeks[0].avgWeight, closeTo(109.7, 0.001));
    expect(weeks[0].gymDone, 3);
    expect(weeks[0].homeDone, 3); // biri kaçırıldı
    expect(weeks[0].slipDays, 0);
    expect(weeks[1].slipDays, 1);
    expect(weeks[1].deltaFromPrevWeek, closeTo(-0.7, 0.001));
    expect(weeks[0].deltaFromPrevWeek, isNull);
  });
}
```

`transition_criteria_test.dart`:

```dart
import 'package:disport/features/progress/domain/transition_criteria.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all three must hold', () {
    expect(
        evaluateTransition(
                latestWeight: 104.5,
                latestPushupMax: 8,
                painFreeConfirmed: true)
            .allMet,
        isTrue);
    expect(
        evaluateTransition(
                latestWeight: 105.0,
                latestPushupMax: 8,
                painFreeConfirmed: true)
            .allMet,
        isFalse); // 105 dahil değil
    expect(
        evaluateTransition(
                latestWeight: 104.5,
                latestPushupMax: 7,
                painFreeConfirmed: true)
            .allMet,
        isFalse);
    expect(
        evaluateTransition(
                latestWeight: 104.5,
                latestPushupMax: 8,
                painFreeConfirmed: false)
            .allMet,
        isFalse);
  });

  test('missing data counts as not met', () {
    final t = evaluateTransition(
        latestWeight: null, latestPushupMax: null, painFreeConfirmed: false);
    expect(t.weightOk, isFalse);
    expect(t.pushupOk, isFalse);
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon** — üç dosya; `movingAverage` kayan pencere, `summarizeWeeks` 7'şerli `for`-dilimleme + null-güvenli ortalama, `evaluateTransition` üç karşılaştırma. Toplam ~80 satır saf Dart.

- [ ] **Step 4: PASS doğrula**

- [ ] **Step 5: Commit** — `feat: progress domain - moving average, weekly summary, transition criteria`

### Task 4: İlerleme ekranı

**Files:**
- Modify: `app/lib/features/progress/presentation/progress_screen.dart`
- Create: `app/lib/features/progress/application/progress_providers.dart`
- Test: `app/test/features/progress/presentation/progress_screen_test.dart`

**Interfaces:**
- Consumes: Task 3 saf fonksiyonları, `BodyMetricsRepository.series`, `TodayRepository.rowsBetween` (M4'te eklendi), `activePlanProvider`
- Produces: İlerleme sekmesi, yukarıdan aşağı: (1) kilo grafiği — `fl_chart LineChart`, günlük noktalar soluk + 7 günlük hareketli ortalama kalın çizgi (spec 6: "günlük rakama tepki verme"nin görsel karşılığı); (2) haftalık özet kartları (`WeekSummary` başına bir `Card`: ort. kilo, Δ, salon n/3, ev n/4, kaçak gün); (3) ay sonu ölçüm tablosu — `pushupMax`, `plankSec`, `waist`, `belly` son üç kaydı yan yana (`DataTable`); (4) geçiş kriteri kartı — üç satır ✓/✗, `painFreeConfirmed` bir `Switch` (profile `painFreeConfirmed=true/false` yazar).

- [ ] **Step 1: Failing widget testi** — seed'li db (14 gün kilo + daily_log + aktif plan): hareketli ortalama çizgisinin varlığı (`find.byType(LineChart)`), "Hafta 1" kartında "3 / 3" metni, geçiş kartında iki ✗ bir ✓ senaryosu.

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon** — `progressProvider`: db'den serileri çekip Task 3 fonksiyonlarına verir, tek bir `ProgressViewData` nesnesi döner (ekran hesap yapmaz). `flutter pub add fl_chart`.

- [ ] **Step 4: PASS + analyze**

- [ ] **Step 5: Commit** — `feat: progress screen - weight chart, weekly cards, transition card`

### Task 5: Bildirim altyapısı — soyutlama + pencere hesabı

**Files:**
- Create: `app/lib/core/notifications/notification_service.dart`
- Create: `app/lib/features/reminders/domain/reminder_planner.dart`
- Test: `app/test/features/reminders/domain/reminder_planner_test.dart`

**Interfaces:**
- Produces:
  - `class PendingReminder { final int id; final DateTime fireAt; final String title; final String body; final String payload; }` — payload: `today|workout|plan|health` (dokununca açılacak sekme)
  - `abstract interface class NotificationService { Future<bool> requestPermissions(); Future<bool> canScheduleExact(); Future<void> replaceAll(List<PendingReminder> reminders); }` — `replaceAll` = önce tümünü iptal, sonra listeyi kur (kaydırmalı pencerenin idempotent hali)
  - `List<PendingReminder> planWindow({required DateTime now, required List<({String date, String time, String kind, String label, String? slotId})> slots, required Map<String, bool> kindEnabled, required String? wakeTime, required List<({String marker, DateTime nextDue})> dueLabs, required DateTime? planEndDate, required bool twoDayMissStreak, int windowDays = 7, int maxCount = 60})` — spec 8'deki beş tür:
    1. slot hatırlatması (`kindEnabled[kind]` açıksa; geçmiş saatler atlanır)
    2. sabah tartısı (`wakeTime` + 15 dk, her gün)
    3. kaçak uyarısı (`twoDayMissStreak` ise bu akşam 20:00)
    4. tahlil vadesi (`dueLabs` → gün başı 09:00)
    5. plan bitiyor (`planEndDate - 3 gün`den itibaren 09:30)
  - Determinist id üretimi: `fireAt.millisecondsSinceEpoch ~/ 60000 % 0x7FFFFFFF` + tür ofseti — `replaceAll` zaten temizlediği için çakışma zararsız
  - `maxCount` şart: pencere 7 gün olsa da sonuç 60'ı aşarsa en yakın tarihli 60 tanesi kalır (spec 10, iOS 64 sınırı payla)

- [ ] **Step 1: Failing testler**

`app/test/features/reminders/domain/reminder_planner_test.dart`:

```dart
import 'package:disport/features/reminders/domain/reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

List<({String date, String time, String kind, String label, String? slotId})>
    weekSlots() => [
          for (var d = 0; d < 14; d++) ...[
            (
              date: '2026-09-${(d + 1).toString().padLeft(2, '0')}',
              time: '06:30',
              kind: 'meal',
              label: 'Kahvaltı',
              slotId: 's$d-0'
            ),
            (
              date: '2026-09-${(d + 1).toString().padLeft(2, '0')}',
              time: '22:00',
              kind: 'workout',
              label: 'Antrenman',
              slotId: 's$d-1'
            ),
          ]
        ];

void main() {
  final now = DateTime(2026, 9, 1, 8); // 1 Eylül 08:00

  test('only next 7 days are scheduled and past times skipped', () {
    final r = planWindow(
      now: now,
      slots: weekSlots(),
      kindEnabled: {'meal': true, 'workout': true},
      wakeTime: null,
      dueLabs: [],
      planEndDate: null,
      twoDayMissStreak: false,
    );
    // 1 Eylül 06:30 geçmiş → atlanır; 1 Eylül 22:00 dahil
    expect(r.where((p) => p.fireAt.day == 1), hasLength(1));
    // 8 Eylül ve sonrası pencere dışı
    expect(r.every((p) => p.fireAt.isBefore(DateTime(2026, 9, 8))), isTrue);
  });

  test('disabled kinds are excluded', () {
    final r = planWindow(
      now: now,
      slots: weekSlots(),
      kindEnabled: {'meal': false, 'workout': true},
      wakeTime: null,
      dueLabs: [],
      planEndDate: null,
      twoDayMissStreak: false,
    );
    expect(r.every((p) => p.title != 'Kahvaltı'), isTrue);
  });

  test('morning weigh-in derived from wake time', () {
    final r = planWindow(
      now: now,
      slots: [],
      kindEnabled: {},
      wakeTime: '06:11',
      dueLabs: [],
      planEndDate: null,
      twoDayMissStreak: false,
    );
    expect(r.first.fireAt.hour, 6);
    expect(r.first.fireAt.minute, 26); // 06:11 + 15 dk
    expect(r, hasLength(7)); // 2-8 Eylül hariç bugün geçmişse — 08:00 > 06:26
  });

  test('two-day miss streak fires tonight at 20:00', () {
    final r = planWindow(
      now: now,
      slots: [],
      kindEnabled: {},
      wakeTime: null,
      dueLabs: [],
      planEndDate: null,
      twoDayMissStreak: true,
    );
    expect(r.single.fireAt, DateTime(2026, 9, 1, 20));
    expect(r.single.body, contains('iki gün üst üste'));
  });

  test('plan ending produces reminders for last 3 days', () {
    final r = planWindow(
      now: now,
      slots: [],
      kindEnabled: {},
      wakeTime: null,
      dueLabs: [],
      planEndDate: DateTime(2026, 9, 4),
      twoDayMissStreak: false,
    );
    expect(r.map((p) => p.fireAt.day).toList(), [2, 3, 4]);
  });

  test('maxCount keeps soonest', () {
    final r = planWindow(
      now: now,
      slots: weekSlots(),
      kindEnabled: {'meal': true, 'workout': true},
      wakeTime: '06:11',
      dueLabs: [],
      planEndDate: null,
      twoDayMissStreak: false,
      maxCount: 5,
    );
    expect(r, hasLength(5));
    final sorted = [...r]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    expect(r.map((p) => p.fireAt), sorted.map((p) => p.fireAt));
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon** — `planWindow` tümüyle saf: beş üreteci sırayla çalıştır, `fireAt <= now` ve `fireAt >= now + windowDays` eleyip sırala, `take(maxCount)`. `NotificationService` yalnız arayüz (implementasyon Task 6).

- [ ] **Step 4: PASS doğrula**

- [ ] **Step 5: Commit** — `feat: reminder planner - pure 7-day window computation`

### Task 6: Platform bildirim implementasyonu + açılışta kaydırma

**Files:**
- Create: `app/lib/core/notifications/local_notification_service.dart`
- Create: `app/lib/features/reminders/application/reminder_scheduler.dart`
- Modify: `app/lib/bootstrap.dart` (açılışta reschedule)
- Modify: `app/lib/app/app.dart` (payload → sekme yönlendirme)
- Modify: `app/android/app/src/main/AndroidManifest.xml`
- Modify: `app/lib/features/settings/presentation/settings_screen.dart` (bildirim anahtarları)
- Test: `app/test/features/reminders/application/reminder_scheduler_test.dart`

**Interfaces:**
- Consumes: `NotificationService`, `planWindow`, `PlanRepository` (7 günün slotları), `TodayRepository` (miss streak), `LabRepository.dueSchedules`, `ProfileRepository` (wakeTime, kind anahtarları)
- Produces:
  - `class LocalNotificationService implements NotificationService` — flutter_local_notifications + timezone; `canScheduleExact()` Android'de `requestExactAlarmsPermission` sonucu, iOS'ta true; exact reddedilirse `AndroidScheduleMode.inexactAllowWhileIdle`
  - `class ReminderScheduler { ReminderScheduler({required NotificationService service, ...repos}); Future<int> reschedule(DateTime now); }` — kaynakları toplar → `planWindow` → `service.replaceAll`; döner: kurulan sayı
  - `bootstrap()` seed'den sonra `unawaited(scheduler.reschedule(DateTime.now()))`
  - Bildirime dokunma: payload `today|workout|plan|health` → kabuk ilgili sekmeye geçer (`_Shell`'e `initialTabNotifier` — `ValueNotifier<int>` core'da)
  - Manifest: `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />`, `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />`, boot receiver
  - Ayarlar ekranı: tür başına `SwitchListTile` (profile `notif.meal=true` vb.), "Alarm izni ver" satırı

- [ ] **Step 1: Failing scheduler testi** — `FakeNotificationService` (`replaceAll` çağrısını listeye kaydeder) + bellek içi db: plan + wakeTime seed'le, `reschedule` sonrası fake'in aldığı listede 7 günlük slot bildirimleri ve tartı bildirimi var; ikinci `reschedule` çağrısı listeyi ikiye katlamaz (replaceAll semantiği).

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon** — `flutter pub add flutter_local_notifications timezone flutter_timezone`. `LocalNotificationService.replaceAll`: `cancelAll()` → her `PendingReminder` için `zonedSchedule(id, title, body, tz.TZDateTime.from(fireAt, tz.local), details, androidScheduleMode: exactOk ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle, payload: payload)`. Miss streak sorgusu: son iki günün `daily_logs.workoutDone` ikisi de false VE o günler plan'da `rest` değil.

- [ ] **Step 4: PASS + analyze**

- [ ] **Step 5: Gerçek cihazda doğrula** — emülatörde bildirim izni iste, 2 dk sonraya slot koyup bildirimi gör; dokunuşun doğru sekmeyi açtığını kontrol et. (Alarm davranışı emülatörde Doze'suz test edilir; fiziksel cihaz denemesi kullanıcıyla birlikte.)

- [ ] **Step 6: Commit** — `feat: local notifications with 7-day rolling window and tab deep-link`

### Task 7: Yedek al / geri yükle

**Files:**
- Modify: `app/lib/features/settings/presentation/settings_screen.dart`
- Create: `app/lib/features/settings/data/backup_service.dart`
- Test: `app/test/features/settings/data/backup_service_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` dosya yolu
- Produces: `class BackupService { Future<File> exportTo(Directory dir); Future<void> importFrom(File backup); }` — SQLite dosyasının kopyası (`disport-backup-YYYYMMDD.db`); export paylaş menüsüyle (share_plus, dosya olarak), import `file_picker` ile seçilir, **mevcut veritabanının üstüne yazmadan önce onay diyaloğu** + mevcut db yanına `.pre-import` kopyası (spec: geri döndürülebilirlik). Import sonrası uygulama yeniden başlatma uyarısı. Test: geçici dizinde export → içerik değiştir → import → orijinal içerik geri gelir; `.pre-import` dosyası var.

- [ ] **Step 1-4: TDD döngüsü** — test → FAIL → implementasyon (`flutter pub add file_picker path_provider`) → PASS.

- [ ] **Step 5: Commit** — `feat: database backup export/import with pre-import safety copy`

### Task 8 (isteğe bağlı): BYOK — Gemini ile doğrudan istek

**Files:**
- Create: `app/lib/features/ai_bridge/data/byok_client.dart`
- Modify: `app/lib/features/settings/presentation/settings_screen.dart` (API anahtarı alanı)
- Modify: `app/lib/features/plan/presentation/plan_screen.dart` ("AI'a doğrudan sor" düğmesi, anahtar varsa)
- Test: `app/test/features/ai_bridge/data/byok_client_test.dart`

**Interfaces:**
- Consumes: `ContextMdBuilder`, `PlanValidator`, `ImportPlanSheet` akışı
- Produces: `class ByokClient { ByokClient({required this.apiKey, http.Client? inner}); Future<Result<String>> generatePlan(String contextMd); }` — Gemini `generateContent` REST çağrısı (`gemini-flash-latest`), yanıttan JSON bloğu ayıklanır (```json çitleri soyulur), string döner → mevcut doğrulama/önizleme akışına girer (ayrı yol yok). **Onay kapısı:** düğmeye ilk basışta diyalog — "Profilin, son 28 günlük kayıtların ve tahlil özetlerin Google Gemini'ye gönderilecek" — kabul profile `byok.consent=true` yazılır; onaysız istek atılmaz (spec 7.5). Hata → snackbar + kopyala-yapıştır yoluna yönlendirme (spec 10). Test: `MockClient` (package:http/testing) ile başarı/hata/çitli-yanıt ayıklama.

- [ ] **Step 1-4: TDD döngüsü** — `flutter pub add http`.

- [ ] **Step 5: Commit** — `feat: optional BYOK Gemini client behind explicit consent`

---

## Self-Review Notları

- **Spec kapsaması:** 5.4 ✓ (iki lab tablosu + schedules), 5.5 ✓ (üç türetilmiş hesap, saklanmıyor), 6-İlerleme ✓ (7g MA çizgisi, haftalık kartlar, ay sonu tablosu, geçiş kartı), 6-Sağlık ✓ (panel kartları, renk, trend, vade şeridi), 8 ✓ (beş tür, 7 gün penceresi, exact-alarm düşüşü, payload yönlendirme, tür başına kapatma), 7.5 ✓ (Task 8, onay kapılı), 6-Ayarlar yedekleme ✓ (Task 7). M3'ten devreden "kardiyo günü tek büyük sayaç" cilası bilinçli olarak v1 kapsamı DIŞI bırakıldı — `durationSec` kartı işlevi görüyor; istenirse v1.1.
- **Tip tutarlılığı:** `PendingReminder.payload` değerleri kabuktaki sekme sırasıyla eşleşir (today=0, plan=1, progress=2, health=3); `LabValueDump` (M4 ports) ↔ `LabEntry` alanları bire bir map'lenir; `MetricKinds.pushupMax`/`plankSec` Task 3-4'te aynı sabitlerle.
- **Görev 2/4/6-8 adım yoğunluğu:** Task 1, 3, 5 tam kodlu; 2, 4, 6, 7, 8 arayüz + davranış sözleşmesi + test senaryosu düzeyinde — kalıpları (widget test kurulumu, provider, sheet) M3/M4'te birebir kodlanmış görevlerden alır. Yürütme sırasında M4 sonrası senkron turunda bunlar gerekirse tam koda açılır (planlar-arası senkron ilkesi).
