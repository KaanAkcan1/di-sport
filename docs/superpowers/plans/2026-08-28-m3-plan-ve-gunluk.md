# di@sport M3 — Plan, Günlük Kayıt, Bugün ve Antrenman Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Günlük takip baştan sona çalışır: örnek plan veritabanına yüklenir, Bugün ekranı slotları/kutucukları/tartıyı işler, Antrenman ekranı set set kayıt tutar.

**Architecture:** Dört feature doldurulur: `plan` (tablolar + FullPlan modeli + repository), `today` (daily_logs + ekran), `workout` (exercise_logs + akış ekranı), `health/data` (body_metrics tablosu — ekranı M5'te, tablosu burada çünkü Bugün ekranı tartı/uyku yazar; spec 6-Bugün). Plan bu kilometre taşında AI'dan değil, Dart koduyla kurulan örnek planla gelir — M4'ün importer'ı aynı `PlanRepository.insertFullPlan` kapısını kullanacak, JSON ayrıştırma işi M4'te bir kez yazılacak.

**Tech Stack:** M2 yığını + intl (tarih biçimleme).

**Spec:** `docs/superpowers/specs/2026-08-28-disport-tasarim.md` (özellikle 5.2, 5.3, 5.4-body_metrics, 6-Bugün/Antrenman/Plan)

## Global Constraints

- M1/M2 Global Constraints geçerli
- Tarihler ISO `yyyy-MM-dd` TEXT; saatler `HH:mm` TEXT (spec 5.2)
- `plan_days.type`: `gym | home | rest`; `plan_slots.kind`: `meal | workout | sleep | measurement | lab | other` (spec 5.2)
- `daily_logs.date` UNIQUE; sayısal ölçüm içermez (spec 5.3)
- Tartı ve uyku `body_metrics`'e yazılır (`kind = weight | sleepHours`), Bugün ekranından (spec 6-Bugün)
- Her görev sonunda `flutter analyze` temiz, `flutter test` yeşil

**Önkoşul:** M2 tamamlanmış — katalog dolu, `catalogRepositoryProvider` ve `ExerciseDetailScreen` mevcut.

---

### Task 1: Plan tabloları ve FullPlan modeli

**Files:**
- Create: `app/lib/features/plan/data/plan_tables.dart`
- Create: `app/lib/features/plan/domain/full_plan.dart`
- Modify: `app/lib/core/db/app_database.dart`
- Test: `app/test/features/plan/domain/full_plan_test.dart`

**Interfaces:**
- Produces:
  - Tablolar: `Plans`, `PlanDays`, `PlanSlots`, `PlanExercises` (hepsi SyncColumns'lı, spec 5.2 alanlarıyla)
  - Domain: `FullPlan`, `FullPlanDay`, `PlanSlot`, `PlanExercise` — veritabanından bağımsız saf sınıflar. M4 importer'ı JSON'dan bu tipe map'ler; Task 2 repository'si bu tipi yazar/okur.

- [ ] **Step 1: Tablolar**

`app/lib/features/plan/data/plan_tables.dart`:

```dart
import 'package:drift/drift.dart';

import 'package:disport/core/db/sync_columns.dart';

@DataClassName('PlanRow')
class Plans extends Table with SyncColumns {
  TextColumn get title => text()();
  TextColumn get startDate => text()(); // yyyy-MM-dd
  TextColumn get endDate => text()();
  IntColumn get weeks => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get goalsJson => text()();
  TextColumn get rulesJson => text()();
  TextColumn get sourceRaw => text().withDefault(const Constant(''))();
  IntColumn get schemaVersion => integer()();
}

@DataClassName('PlanDayRow')
class PlanDays extends Table with SyncColumns {
  TextColumn get planId => text().references(Plans, #id)();
  TextColumn get date => text()();
  TextColumn get type => text()(); // gym | home | rest
  IntColumn get weekIndex => integer()();
  TextColumn get headline => text().withDefault(const Constant(''))();
  TextColumn get dinnerSuggestion => text().withDefault(const Constant(''))();
}

@DataClassName('PlanSlotRow')
class PlanSlots extends Table with SyncColumns {
  TextColumn get planDayId => text().references(PlanDays, #id)();
  TextColumn get time => text()(); // HH:mm
  TextColumn get kind => text()(); // meal|workout|sleep|measurement|lab|other
  TextColumn get label => text()();
  TextColumn get note => text().nullable()();
  IntColumn get orderIndex => integer()();
}

@DataClassName('PlanExerciseRow')
class PlanExercises extends Table with SyncColumns {
  TextColumn get planDayId => text().references(PlanDays, #id)();
  TextColumn get exerciseId => text()();
  IntColumn get orderIndex => integer()();
  IntColumn get sets => integer().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSec => integer().nullable()();
  IntColumn get restSec => integer().nullable()();
  TextColumn get intensity => text().nullable()(); // direnç/eğim
  TextColumn get note => text().nullable()();
}
```

`app/lib/core/db/app_database.dart` — import + tables:

```dart
import 'package:disport/features/plan/data/plan_tables.dart';
// ...
@DriftDatabase(tables: [
  ProfileEntries, Exercises,
  Plans, PlanDays, PlanSlots, PlanExercises,
])
```

`schemaVersion` getter'ını `2` yap ve `MigrationStrategy` ekle:

```dart
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(plans);
            await m.createTable(planDays);
            await m.createTable(planSlots);
            await m.createTable(planExercises);
          }
        },
      );
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 2: Failing domain testi**

`app/test/features/plan/domain/full_plan_test.dart`:

```dart
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dayCount and dateOf derive from start date', () {
    final p = FullPlan(
      id: 'pl1',
      title: 'Eylül',
      startDate: DateTime(2026, 8, 31),
      weeks: 4,
      goals: const PlanGoals(
          dailyKcal: 2400,
          proteinG: 170,
          waterL: 3,
          weeklyGym: 3,
          weeklyHome: 4,
          targetLossKg: 3.5),
      rules: const PlanRules(forbidden: ['alkol'], free: ['su']),
      days: const [],
      sourceRaw: '',
    );
    expect(p.dayCount, 28);
    expect(p.endDate, DateTime(2026, 9, 27));
  });
}
```

- [ ] **Step 3: FAIL doğrula** — Run: `flutter test test/features/plan/domain/full_plan_test.dart`

- [ ] **Step 4: Domain implementasyonu**

`app/lib/features/plan/domain/full_plan.dart`:

```dart
class PlanGoals {
  const PlanGoals({
    required this.dailyKcal,
    required this.proteinG,
    required this.waterL,
    required this.weeklyGym,
    required this.weeklyHome,
    required this.targetLossKg,
  });

  final int dailyKcal;
  final int proteinG;
  final double waterL;
  final int weeklyGym;
  final int weeklyHome;
  final double targetLossKg;
}

class PlanRules {
  const PlanRules({required this.forbidden, required this.free});
  final List<String> forbidden;
  final List<String> free;
}

enum PlanDayType { gym, home, rest }

enum SlotKind { meal, workout, sleep, measurement, lab, other }

class PlanSlot {
  const PlanSlot({
    required this.id,
    required this.time, // 'HH:mm'
    required this.kind,
    required this.label,
    this.note,
  });

  final String id;
  final String time;
  final SlotKind kind;
  final String label;
  final String? note;
}

class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.exerciseId,
    this.sets,
    this.reps,
    this.durationSec,
    this.restSec,
    this.intensity,
    this.note,
  });

  final String id;
  final String exerciseId;
  final int? sets;
  final int? reps;
  final int? durationSec;
  final int? restSec;
  final String? intensity;
  final String? note;
}

class FullPlanDay {
  const FullPlanDay({
    required this.id,
    required this.date,
    required this.type,
    required this.weekIndex,
    this.headline = '',
    this.dinnerSuggestion = '',
    this.slots = const [],
    this.exercises = const [],
  });

  final String id;
  final DateTime date;
  final PlanDayType type;
  final int weekIndex;
  final String headline;
  final String dinnerSuggestion;
  final List<PlanSlot> slots;
  final List<PlanExercise> exercises;
}

class FullPlan {
  const FullPlan({
    required this.id,
    required this.title,
    required this.startDate,
    required this.weeks,
    required this.goals,
    required this.rules,
    required this.days,
    required this.sourceRaw,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final int weeks;
  final PlanGoals goals;
  final PlanRules rules;
  final List<FullPlanDay> days;
  final String sourceRaw;

  int get dayCount => weeks * 7;

  DateTime get endDate => startDate.add(Duration(days: dayCount - 1));
}
```

- [ ] **Step 5: PASS doğrula**

- [ ] **Step 6: Commit**

```powershell
git add app/lib/features/plan app/lib/core/db app/test/features/plan
git commit -m "feat: plan tables (schema v2) and FullPlan domain model"
```

### Task 2: PlanRepository

**Files:**
- Create: `app/lib/features/plan/data/plan_repository.dart`
- Test: `app/test/features/plan/data/plan_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `FullPlan` ailesi (Task 1)
- Produces: `class PlanRepository`:
  - `Future<void> insertFullPlan(FullPlan p)` — tek transaction; yeni plan aktif olur, eskisi pasifleşir (spec 7.3 kapı 4: ya hepsi ya hiçbiri)
  - `Future<FullPlan?> activePlan()`
  - `Stream<FullPlanDay?> watchDay(String isoDate)` — aktif planın o günü, slot ve egzersizleriyle
  - `static String iso(DateTime d)` — `yyyy-MM-dd`
  - M4 importer'ı `insertFullPlan`'ı; Bugün/Antrenman ekranları `watchDay`'i; `context.md` (M4) `activePlan`'ı kullanır.

- [ ] **Step 1: Failing test**

`app/test/features/plan/data/plan_repository_test.dart`:

```dart
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

FullPlan samplePlan({String id = 'pl1', DateTime? start}) {
  final s = start ?? DateTime(2026, 8, 31);
  return FullPlan(
    id: id,
    title: 'Test Planı',
    startDate: s,
    weeks: 1,
    goals: const PlanGoals(
        dailyKcal: 2400,
        proteinG: 170,
        waterL: 3,
        weeklyGym: 3,
        weeklyHome: 4,
        targetLossKg: 1),
    rules: const PlanRules(forbidden: ['alkol'], free: ['su']),
    sourceRaw: '{}',
    days: [
      for (var i = 0; i < 7; i++)
        FullPlanDay(
          id: '$id-d$i',
          date: s.add(Duration(days: i)),
          type: i.isEven ? PlanDayType.gym : PlanDayType.home,
          weekIndex: 1,
          slots: [
            PlanSlot(
                id: '$id-d$i-s0',
                time: '06:30',
                kind: SlotKind.meal,
                label: '4 haşlanmış yumurta'),
            PlanSlot(
                id: '$id-d$i-s1',
                time: '22:00',
                kind: SlotKind.workout,
                label: 'Antrenman'),
          ],
          exercises: [
            PlanExercise(
                id: '$id-d$i-e0',
                exerciseId: 'incline_pushup',
                sets: 3,
                reps: 10,
                restSec: 60),
          ],
        ),
    ],
  );
}

void main() {
  late AppDatabase db;
  late PlanRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanRepository(db);
  });
  tearDown(() => db.close());

  test('insertFullPlan then activePlan round-trips', () async {
    await repo.insertFullPlan(samplePlan());
    final p = await repo.activePlan();
    expect(p!.title, 'Test Planı');
    expect(p.days, hasLength(7));
    expect(p.days.first.slots, hasLength(2));
    expect(p.days.first.exercises.single.exerciseId, 'incline_pushup');
  });

  test('new plan deactivates the previous one', () async {
    await repo.insertFullPlan(samplePlan());
    await repo.insertFullPlan(
        samplePlan(id: 'pl2', start: DateTime(2026, 9, 28)));
    final p = await repo.activePlan();
    expect(p!.id, 'pl2');
  });

  test('watchDay returns the matching day with ordered slots', () async {
    await repo.insertFullPlan(samplePlan());
    final day = await repo.watchDay('2026-08-31').first;
    expect(day!.type, PlanDayType.gym);
    expect(day.slots.map((s) => s.time), ['06:30', '22:00']);
  });

  test('watchDay returns null for a date outside the plan', () async {
    await repo.insertFullPlan(samplePlan());
    expect(await repo.watchDay('2027-01-01').first, isNull);
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon**

`app/lib/features/plan/data/plan_repository.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/plan/domain/full_plan.dart';

class PlanRepository {
  PlanRepository(this._db);

  final AppDatabase _db;

  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> insertFullPlan(FullPlan p) => _db.transaction(() async {
        final now = DateTime.now().millisecondsSinceEpoch;
        await (_db.update(_db.plans)..where((t) => t.isActive.equals(true)))
            .write(const PlansCompanion(isActive: Value(false)));

        await _db.into(_db.plans).insert(PlansCompanion.insert(
              id: p.id,
              updatedAt: now,
              title: p.title,
              startDate: iso(p.startDate),
              endDate: iso(p.endDate),
              weeks: p.weeks,
              isActive: const Value(true),
              goalsJson: jsonEncode({
                'dailyKcal': p.goals.dailyKcal,
                'proteinG': p.goals.proteinG,
                'waterL': p.goals.waterL,
                'weeklyGym': p.goals.weeklyGym,
                'weeklyHome': p.goals.weeklyHome,
                'targetLossKg': p.goals.targetLossKg,
              }),
              rulesJson: jsonEncode(
                  {'forbidden': p.rules.forbidden, 'free': p.rules.free}),
              sourceRaw: Value(p.sourceRaw),
              schemaVersion: 1,
            ));

        for (final d in p.days) {
          await _db.into(_db.planDays).insert(PlanDaysCompanion.insert(
                id: d.id,
                updatedAt: now,
                planId: p.id,
                date: iso(d.date),
                type: d.type.name,
                weekIndex: d.weekIndex,
                headline: Value(d.headline),
                dinnerSuggestion: Value(d.dinnerSuggestion),
              ));
          for (final (i, s) in d.slots.indexed) {
            await _db.into(_db.planSlots).insert(PlanSlotsCompanion.insert(
                  id: s.id,
                  updatedAt: now,
                  planDayId: d.id,
                  time: s.time,
                  kind: s.kind.name,
                  label: s.label,
                  note: Value(s.note),
                  orderIndex: i,
                ));
          }
          for (final (i, e) in d.exercises.indexed) {
            await _db
                .into(_db.planExercises)
                .insert(PlanExercisesCompanion.insert(
                  id: e.id,
                  updatedAt: now,
                  planDayId: d.id,
                  exerciseId: e.exerciseId,
                  orderIndex: i,
                  sets: Value(e.sets),
                  reps: Value(e.reps),
                  durationSec: Value(e.durationSec),
                  restSec: Value(e.restSec),
                  intensity: Value(e.intensity),
                  note: Value(e.note),
                ));
          }
        }
      });

  Future<FullPlan?> activePlan() async {
    final row = await (_db.select(_db.plans)
          ..where((t) => t.isActive.equals(true) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;

    final dayRows = await (_db.select(_db.planDays)
          ..where((t) => t.planId.equals(row.id))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();

    final days = <FullPlanDay>[];
    for (final d in dayRows) {
      days.add(await _hydrateDay(d));
    }

    final goals = jsonDecode(row.goalsJson) as Map<String, dynamic>;
    final rules = jsonDecode(row.rulesJson) as Map<String, dynamic>;
    return FullPlan(
      id: row.id,
      title: row.title,
      startDate: DateTime.parse(row.startDate),
      weeks: row.weeks,
      goals: PlanGoals(
        dailyKcal: goals['dailyKcal'] as int,
        proteinG: goals['proteinG'] as int,
        waterL: (goals['waterL'] as num).toDouble(),
        weeklyGym: goals['weeklyGym'] as int,
        weeklyHome: goals['weeklyHome'] as int,
        targetLossKg: (goals['targetLossKg'] as num).toDouble(),
      ),
      rules: PlanRules(
        forbidden: (rules['forbidden'] as List).cast<String>(),
        free: (rules['free'] as List).cast<String>(),
      ),
      days: days,
      sourceRaw: row.sourceRaw,
    );
  }

  Stream<FullPlanDay?> watchDay(String isoDate) {
    final q = _db.select(_db.planDays).join([
      innerJoin(_db.plans, _db.plans.id.equalsExp(_db.planDays.planId)),
    ])
      ..where(_db.plans.isActive.equals(true) &
          _db.planDays.date.equals(isoDate));

    return q.watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      return _hydrateDay(row.readTable(_db.planDays));
    });
  }

  Future<FullPlanDay> _hydrateDay(PlanDayRow d) async {
    final slotRows = await (_db.select(_db.planSlots)
          ..where((t) => t.planDayId.equals(d.id))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    final exRows = await (_db.select(_db.planExercises)
          ..where((t) => t.planDayId.equals(d.id))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();

    return FullPlanDay(
      id: d.id,
      date: DateTime.parse(d.date),
      type: PlanDayType.values.byName(d.type),
      weekIndex: d.weekIndex,
      headline: d.headline,
      dinnerSuggestion: d.dinnerSuggestion,
      slots: [
        for (final s in slotRows)
          PlanSlot(
            id: s.id,
            time: s.time,
            kind: SlotKind.values.byName(s.kind),
            label: s.label,
            note: s.note,
          ),
      ],
      exercises: [
        for (final e in exRows)
          PlanExercise(
            id: e.id,
            exerciseId: e.exerciseId,
            sets: e.sets,
            reps: e.reps,
            durationSec: e.durationSec,
            restSec: e.restSec,
            intensity: e.intensity,
            note: e.note,
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: PASS doğrula**

- [ ] **Step 5: Commit**

```powershell
git add app/lib/features/plan app/test/features/plan
git commit -m "feat: PlanRepository with transactional insert and day watch"
```

### Task 3: Örnek plan tohumu (PDF'in 1. haftası)

**Files:**
- Create: `app/lib/features/plan/data/sample_plan.dart`
- Create: `app/lib/features/plan/application/plan_providers.dart`
- Modify: `app/lib/features/plan/presentation/plan_screen.dart`
- Test: `app/test/features/plan/data/sample_plan_test.dart`

**Interfaces:**
- Consumes: `PlanRepository`, `FullPlan`
- Produces: `FullPlan buildSamplePlan(DateTime start)` — PDF'in gün tiplerini (Pzt/Çar salon 22:00, Cmt salon 10:00, diğerleri ev 05:45, Pazar rahat) ve Program A/B hareketlerini (M2 katalog id'leriyle) üreten saf fonksiyon; 4 hafta. `planRepositoryProvider`, `activePlanProvider`. Plan ekranında "Örnek planı yükle" düğmesi (M4'te "Planı içeri al" ile değiştirilecek).

- [ ] **Step 1: Failing test**

`app/test/features/plan/data/sample_plan_test.dart`:

```dart
import 'package:disport/features/plan/data/sample_plan.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sample plan spans 28 consecutive days from a Monday', () {
    final p = buildSamplePlan(DateTime(2026, 8, 31)); // Pazartesi
    expect(p.days, hasLength(28));
    for (var i = 0; i < 28; i++) {
      expect(p.days[i].date, DateTime(2026, 8, 31).add(Duration(days: i)));
    }
  });

  test('weekly pattern: Mon/Wed/Sat gym, others home', () {
    final p = buildSamplePlan(DateTime(2026, 8, 31));
    final week1 = p.days.take(7).map((d) => d.type).toList();
    expect(week1, [
      PlanDayType.gym, // Pzt
      PlanDayType.home, // Sal
      PlanDayType.gym, // Çar
      PlanDayType.home, // Per
      PlanDayType.home, // Cum
      PlanDayType.gym, // Cmt
      PlanDayType.home, // Paz
    ]);
  });

  test('home days carry Program A or B exercises with sets and reps', () {
    final p = buildSamplePlan(DateTime(2026, 8, 31));
    final tuesday = p.days[1]; // Program A
    expect(tuesday.exercises.map((e) => e.exerciseId),
        contains('incline_pushup'));
    final thursday = p.days[3]; // Program B
    expect(thursday.exercises.map((e) => e.exerciseId),
        contains('chair_squat'));
    expect(tuesday.exercises.every((e) => e.sets != null), isTrue);
  });

  test('every day has at least meal slots and gym/home days a workout slot',
      () {
    final p = buildSamplePlan(DateTime(2026, 8, 31));
    for (final d in p.days) {
      expect(d.slots.where((s) => s.kind == SlotKind.meal), isNotEmpty);
      if (d.type != PlanDayType.rest) {
        expect(d.slots.where((s) => s.kind == SlotKind.workout), hasLength(1));
      }
    }
  });
}
```

- [ ] **Step 2: FAIL doğrula**

- [ ] **Step 3: Implementasyon**

`app/lib/features/plan/data/sample_plan.dart` — PDF sayfa 1'deki saat/menü düzenini kodlar:

```dart
import 'package:disport/features/plan/domain/full_plan.dart';

/// PDF çizelgesinin (kaan-eylul-2026) 4 haftalık örnek plan hali.
/// M4'te AI importu gelene kadar uygulamayı dolduran gerçekçi veri.
FullPlan buildSamplePlan(DateTime start) {
  const programA = [
    ('incline_pushup', 3, 10, null),
    ('band_row', 3, 12, null),
    ('band_pull_apart', 2, 15, null),
    ('superman', 3, 12, null),
    ('plank', 3, null, 30),
    ('dead_bug', 3, 10, null),
  ];
  const programB = [
    ('chair_squat', 3, 12, null),
    ('step_up', 3, 10, null),
    ('glute_bridge', 3, 15, null),
    ('wall_sit', 2, null, 30),
    ('calf_raise', 2, 20, null),
    ('bird_dog', 3, 10, null),
  ];

  List<PlanSlot> slots(String dayId, {required bool gymDay, required bool saturday}) {
    final workoutTime = saturday ? '10:00' : (gymDay ? '22:00' : '05:45');
    var i = 0;
    PlanSlot s(String time, SlotKind kind, String label) =>
        PlanSlot(id: '$dayId-s${i++}', time: time, kind: kind, label: label);
    return [
      if (!gymDay) s('05:45', SlotKind.workout, 'Ev antrenmanı 25 dk'),
      s('06:30', SlotKind.meal, '4 haşlanmış yumurta + yoğurt'),
      s('10:00', SlotKind.meal, '20 badem veya 1 elma + ayran'),
      s('12:00', SlotKind.meal, 'Fabrika menüsü — pilav yarım'),
      s('16:00', SlotKind.meal, 'Protein shake veya 200 g yoğurt'),
      s('19:50', SlotKind.meal, 'Akşam yemeği, ailece'),
      if (gymDay) s(workoutTime, SlotKind.workout, 'Salon — kardiyo 45 dk'),
      s(saturday || !gymDay ? '22:15' : '23:45', SlotKind.sleep, 'Uyku'),
    ]..sort((a, b) => a.time.compareTo(b.time));
  }

  List<PlanExercise> exercises(
      String dayId, List<(String, int, int?, int?)> program) {
    return [
      for (final (i, (exId, sets, reps, durSec)) in program.indexed)
        PlanExercise(
          id: '$dayId-e$i',
          exerciseId: exId,
          sets: sets,
          reps: reps,
          durationSec: durSec,
          restSec: 60,
        ),
    ];
  }

  final days = <FullPlanDay>[];
  for (var i = 0; i < 28; i++) {
    final date = start.add(Duration(days: i));
    final weekday = date.weekday; // 1 = Pzt
    final gymDay = weekday == DateTime.monday ||
        weekday == DateTime.wednesday ||
        weekday == DateTime.saturday;
    final saturday = weekday == DateTime.saturday;
    final dayId = 'sample-d$i';

    final program = switch (weekday) {
      DateTime.tuesday || DateTime.friday => programA,
      DateTime.thursday || DateTime.sunday => programB,
      _ => <(String, int, int?, int?)>[],
    };

    days.add(FullPlanDay(
      id: dayId,
      date: date,
      type: gymDay ? PlanDayType.gym : PlanDayType.home,
      weekIndex: i ~/ 7 + 1,
      headline: switch (i ~/ 7) {
        0 => 'Tempoyu bul. Saatleri oturt.',
        1 => 'Bant eğimi %8, direnç 6.',
        2 => 'Interval başlıyor.',
        _ => 'Ayın kapanışı. Göbek çevreni ölç.',
      },
      dinnerSuggestion: switch (weekday) {
        DateTime.monday => 'Izgara tavuk 200 g + fırın sebze + 3 kaşık bulgur',
        DateTime.tuesday => 'Mercimek çorbası + 3 yumurtalı omlet + salata',
        DateTime.wednesday => 'Izgara hamsi veya uskumru 200 g + roka salata',
        DateTime.thursday => 'Ton balıklı büyük salata + 2 haşlanmış yumurta',
        DateTime.friday => 'Fırında köfte 200 g + cacık + bol salata',
        DateTime.saturday => 'Somon veya uskumru + 1 fırın patates + salata',
        _ => 'Kuru fasulye 1 kepçe + 3 kaşık bulgur + cacık',
      },
      slots: slots(dayId, gymDay: gymDay, saturday: saturday),
      exercises: exercises(dayId, program),
    ));
  }

  return FullPlan(
    id: 'sample-${start.year}-${start.month}',
    title: '4 Haftalık Çizelge (örnek)',
    startDate: start,
    weeks: 4,
    goals: const PlanGoals(
        dailyKcal: 2400,
        proteinG: 170,
        waterL: 3,
        weeklyGym: 3,
        weeklyHome: 4,
        targetLossKg: 3.5),
    rules: const PlanRules(
      forbidden: [
        'Alkol', 'Kola, gazoz, meyve suyu, şekerli çay',
        'Bal, reçel, pekmez, tatlı, dondurma',
        'Sıkma, poğaça, börek, simit, pide',
        'Kızartma', 'Salam, sucuk, sosis, jambon',
        'Cips, kraker, hazır atıştırmalık',
        'Fabrikada tatlı ve ikinci porsiyon pilav',
      ],
      free: [
        'Su — günde 3 litre', 'Sade çay, sade kahve, şekersiz ayran',
        'Yeşillikler', 'Salatalık, domates, biber, kabak, brokoli',
        'Çorba — kremasız', 'Yumurta ve sade yoğurt',
        'Turşu — ölçülü', 'Günde 2 porsiyon katı meyve',
      ],
    ),
    days: days,
    sourceRaw: '',
  );
}
```

- [ ] **Step 4: Provider'lar ve Plan ekranı düğmesi**

`app/lib/features/plan/application/plan_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:disport/app/app.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';

part 'plan_providers.g.dart';

@riverpod
PlanRepository planRepository(Ref ref) =>
    PlanRepository(ref.watch(appDatabaseProvider));

@riverpod
Future<FullPlan?> activePlan(Ref ref) =>
    ref.watch(planRepositoryProvider).activePlan();
```

`app/lib/features/plan/presentation/plan_screen.dart` — yer tutucuyu değiştir:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/data/sample_plan.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider);

    return switch (plan) {
      AsyncData(value: null) => Center(
          child: FilledButton(
            onPressed: () async {
              final monday = _nextMonday(DateTime.now());
              await ref
                  .read(planRepositoryProvider)
                  .insertFullPlan(buildSamplePlan(monday));
              ref.invalidate(activePlanProvider);
            },
            child: const Text('Örnek planı yükle'),
          ),
        ),
      AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(value!.title,
                style: Theme.of(context).textTheme.titleLarge),
            Text('${value.days.length} gün · '
                'hedef −${value.goals.targetLossKg} kg'),
            const SizedBox(height: 8),
            for (final d in value.days)
              ListTile(
                dense: true,
                leading: Icon(switch (d.type) {
                  PlanDayTypeX.gymIcon => Icons.fitness_center,
                }),
                title: Text('${PlanRepositoryX.tr(d.date)} — '
                    '${d.type.name.toUpperCase()}'),
                subtitle:
                    d.headline.isEmpty ? null : Text(d.headline),
              ),
          ],
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  DateTime _nextMonday(DateTime now) {
    final days = (DateTime.monday - now.weekday + 7) % 7;
    return DateTime(now.year, now.month, now.day)
        .add(Duration(days: days == 0 ? 7 : days));
  }
}
```

Not: yukarıdaki liste gösterimindeki `PlanDayTypeX`/`PlanRepositoryX` uzantıları yoktur — implementasyonda sadeleştir: `leading: Icon(d.type == PlanDayType.gym ? Icons.fitness_center : Icons.home)`, başlık `'${d.date.day}.${d.date.month} — ${d.type.name}'`. (Takvim renklendirmesi ve doluluk M5-İlerleme verisine bakar; M4'te bu ekran "Yeni plan iste / Planı içeri al" eylemlerini alacak.)

- [ ] **Step 5: PASS + analyze** — Run: `flutter test` ve `flutter analyze`

- [ ] **Step 6: Commit**

```powershell
git add app/lib/features/plan app/test/features/plan
git commit -m "feat: sample 4-week plan seed and plan screen listing"
```

### Task 4: daily_logs + body_metrics tabloları ve repository'leri

**Files:**
- Create: `app/lib/features/today/data/daily_log_table.dart`
- Create: `app/lib/features/today/data/today_repository.dart`
- Create: `app/lib/features/health/data/body_metric_table.dart`
- Create: `app/lib/features/health/data/body_metrics_repository.dart`
- Modify: `app/lib/core/db/app_database.dart` (schema v3)
- Test: `app/test/features/today/data/today_repository_test.dart`
- Test: `app/test/features/health/data/body_metrics_repository_test.dart`

**Interfaces:**
- Produces:
  - Tablo `DailyLogs` (`date` UNIQUE, `checkedSlotsJson`, `workoutDone`, `waterTargetMet`, `noAlcoholSugar`, `note`) — spec 5.3
  - Tablo `BodyMetrics` (`date`, `kind`, `value`, `unit`, `note?`) — spec 5.4
  - `class TodayRepository`:
    - `Stream<DailyLogView> watchDay(String isoDate)` — kayıt yoksa boş görünüm döner
    - `Future<void> toggleSlot(String isoDate, String slotId)`
    - `Future<void> setFlags(String isoDate, {bool? workoutDone, bool? waterTargetMet, bool? noAlcoholSugar})`
    - `Future<void> setNote(String isoDate, String note)`
  - `class DailyLogView { final Set<String> checkedSlotIds; final bool workoutDone; final bool waterTargetMet; final bool noAlcoholSugar; final String note; }`
  - `class BodyMetricsRepository`:
    - `Future<void> upsert({required String isoDate, required String kind, required double value, required String unit})` — aynı gün+kind güncellenir
    - `Stream<double?> watchValue(String isoDate, String kind)`
    - `Future<List<({String date, double value})>> series(String kind, {int lastDays = 90})` — M5 grafikleri ve M4 kilo serisi bunu kullanır
  - `kind` sabitleri: `weight | waist | belly | sleepHours | pushupMax | plankSec | treadmillIncline` (spec 5.4) — `class MetricKinds` içinde `static const` olarak.

- [ ] **Step 1: Tablolar**

`app/lib/features/today/data/daily_log_table.dart`:

```dart
import 'package:drift/drift.dart';

import 'package:disport/core/db/sync_columns.dart';

@DataClassName('DailyLogRow')
class DailyLogs extends Table with SyncColumns {
  TextColumn get date => text().unique()();
  TextColumn get checkedSlotsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get workoutDone => boolean().withDefault(const Constant(false))();
  BoolColumn get waterTargetMet =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get noAlcoholSugar =>
      boolean().withDefault(const Constant(false))();
  TextColumn get note => text().withDefault(const Constant(''))();
}
```

`app/lib/features/health/data/body_metric_table.dart`:

```dart
import 'package:drift/drift.dart';

import 'package:disport/core/db/sync_columns.dart';

@DataClassName('BodyMetricRow')
class BodyMetrics extends Table with SyncColumns {
  TextColumn get date => text()();
  TextColumn get kind => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  TextColumn get note => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {date, kind},
      ];
}

abstract final class MetricKinds {
  static const weight = 'weight';
  static const waist = 'waist';
  static const belly = 'belly';
  static const sleepHours = 'sleepHours';
  static const pushupMax = 'pushupMax';
  static const plankSec = 'plankSec';
  static const treadmillIncline = 'treadmillIncline';
}
```

`app_database.dart`: iki tabloyu ekle, `schemaVersion => 3`, `onUpgrade`'e `if (from < 3)` bloğuyla `createTable(dailyLogs); createTable(bodyMetrics);` ekle. build_runner koştur.

- [ ] **Step 2: Failing testler**

`app/test/features/today/data/today_repository_test.dart`:

```dart
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TodayRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TodayRepository(db);
  });
  tearDown(() => db.close());

  test('watchDay on empty date yields empty view', () async {
    final v = await repo.watchDay('2026-09-01').first;
    expect(v.checkedSlotIds, isEmpty);
    expect(v.workoutDone, isFalse);
    expect(v.note, '');
  });

  test('toggleSlot adds then removes', () async {
    await repo.toggleSlot('2026-09-01', 's1');
    expect((await repo.watchDay('2026-09-01').first).checkedSlotIds, {'s1'});
    await repo.toggleSlot('2026-09-01', 's1');
    expect((await repo.watchDay('2026-09-01').first).checkedSlotIds, isEmpty);
  });

  test('setFlags updates only provided flags', () async {
    await repo.setFlags('2026-09-01', workoutDone: true);
    await repo.setFlags('2026-09-01', waterTargetMet: true);
    final v = await repo.watchDay('2026-09-01').first;
    expect(v.workoutDone, isTrue);
    expect(v.waterTargetMet, isTrue);
    expect(v.noAlcoholSugar, isFalse);
  });

  test('setNote persists', () async {
    await repo.setNote('2026-09-01', 'şınavda zorlandım');
    expect((await repo.watchDay('2026-09-01').first).note,
        'şınavda zorlandım');
  });
}
```

`app/test/features/health/data/body_metrics_repository_test.dart`:

```dart
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BodyMetricsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BodyMetricsRepository(db);
  });
  tearDown(() => db.close());

  test('upsert overwrites same day+kind', () async {
    await repo.upsert(
        isoDate: '2026-09-01', kind: MetricKinds.weight, value: 110, unit: 'kg');
    await repo.upsert(
        isoDate: '2026-09-01', kind: MetricKinds.weight, value: 109.5, unit: 'kg');
    expect(await repo.watchValue('2026-09-01', MetricKinds.weight).first, 109.5);
  });

  test('series returns ascending by date', () async {
    await repo.upsert(
        isoDate: '2026-09-02', kind: MetricKinds.weight, value: 109, unit: 'kg');
    await repo.upsert(
        isoDate: '2026-09-01', kind: MetricKinds.weight, value: 110, unit: 'kg');
    final s = await repo.series(MetricKinds.weight);
    expect(s.map((p) => p.value), [110, 109]);
  });
}
```

- [ ] **Step 3: FAIL doğrula** — iki test dosyasını da koş.

- [ ] **Step 4: Implementasyonlar**

`app/lib/features/today/data/today_repository.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:disport/core/db/app_database.dart';

class DailyLogView {
  const DailyLogView({
    this.checkedSlotIds = const {},
    this.workoutDone = false,
    this.waterTargetMet = false,
    this.noAlcoholSugar = false,
    this.note = '',
  });

  final Set<String> checkedSlotIds;
  final bool workoutDone;
  final bool waterTargetMet;
  final bool noAlcoholSugar;
  final String note;
}

class TodayRepository {
  TodayRepository(this._db);

  final AppDatabase _db;

  Stream<DailyLogView> watchDay(String isoDate) {
    final q = _db.select(_db.dailyLogs)..where((t) => t.date.equals(isoDate));
    return q.watchSingleOrNull().map((row) => row == null
        ? const DailyLogView()
        : DailyLogView(
            checkedSlotIds:
                (jsonDecode(row.checkedSlotsJson) as List).cast<String>().toSet(),
            workoutDone: row.workoutDone,
            waterTargetMet: row.waterTargetMet,
            noAlcoholSugar: row.noAlcoholSugar,
            note: row.note,
          ));
  }

  Future<void> toggleSlot(String isoDate, String slotId) async {
    final row = await _ensureRow(isoDate);
    final ids =
        (jsonDecode(row.checkedSlotsJson) as List).cast<String>().toSet();
    if (!ids.add(slotId)) ids.remove(slotId);
    await (_db.update(_db.dailyLogs)..where((t) => t.date.equals(isoDate)))
        .write(DailyLogsCompanion(
      checkedSlotsJson: Value(jsonEncode(ids.toList())),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> setFlags(String isoDate,
      {bool? workoutDone, bool? waterTargetMet, bool? noAlcoholSugar}) async {
    await _ensureRow(isoDate);
    await (_db.update(_db.dailyLogs)..where((t) => t.date.equals(isoDate)))
        .write(DailyLogsCompanion(
      workoutDone:
          workoutDone == null ? const Value.absent() : Value(workoutDone),
      waterTargetMet: waterTargetMet == null
          ? const Value.absent()
          : Value(waterTargetMet),
      noAlcoholSugar: noAlcoholSugar == null
          ? const Value.absent()
          : Value(noAlcoholSugar),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> setNote(String isoDate, String note) async {
    await _ensureRow(isoDate);
    await (_db.update(_db.dailyLogs)..where((t) => t.date.equals(isoDate)))
        .write(DailyLogsCompanion(
      note: Value(note),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<DailyLogRow> _ensureRow(String isoDate) async {
    final existing = await (_db.select(_db.dailyLogs)
          ..where((t) => t.date.equals(isoDate)))
        .getSingleOrNull();
    if (existing != null) return existing;
    final companion = DailyLogsCompanion.insert(
      id: const Uuid().v4(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      date: isoDate,
    );
    await _db.into(_db.dailyLogs).insert(companion);
    return (_db.select(_db.dailyLogs)..where((t) => t.date.equals(isoDate)))
        .getSingle();
  }
}
```

`app/lib/features/health/data/body_metrics_repository.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:disport/core/db/app_database.dart';

class BodyMetricsRepository {
  BodyMetricsRepository(this._db);

  final AppDatabase _db;

  Future<void> upsert({
    required String isoDate,
    required String kind,
    required double value,
    required String unit,
  }) async {
    final existing = await (_db.select(_db.bodyMetrics)
          ..where((t) => t.date.equals(isoDate) & t.kind.equals(kind)))
        .getSingleOrNull();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing == null) {
      await _db.into(_db.bodyMetrics).insert(BodyMetricsCompanion.insert(
            id: const Uuid().v4(),
            updatedAt: now,
            date: isoDate,
            kind: kind,
            value: value,
            unit: unit,
          ));
    } else {
      await (_db.update(_db.bodyMetrics)
            ..where((t) => t.id.equals(existing.id)))
          .write(BodyMetricsCompanion(
        value: Value(value),
        updatedAt: Value(now),
      ));
    }
  }

  Stream<double?> watchValue(String isoDate, String kind) {
    final q = _db.select(_db.bodyMetrics)
      ..where((t) => t.date.equals(isoDate) & t.kind.equals(kind));
    return q.watchSingleOrNull().map((r) => r?.value);
  }

  Future<List<({String date, double value})>> series(String kind,
      {int lastDays = 90}) async {
    final rows = await (_db.select(_db.bodyMetrics)
          ..where((t) => t.kind.equals(kind) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.date)])
          ..limit(lastDays))
        .get();
    return [for (final r in rows) (date: r.date, value: r.value)];
  }
}
```

- [ ] **Step 5: PASS doğrula** — iki test dosyası + `flutter test`.

- [ ] **Step 6: Commit**

```powershell
git add app/lib/features/today app/lib/features/health app/lib/core/db app/test/features
git commit -m "feat: daily logs and body metrics (schema v3) with repositories"
```

### Task 5: Bugün ekranı

**Files:**
- Modify: `app/lib/features/today/presentation/today_screen.dart`
- Create: `app/lib/features/today/application/today_providers.dart`
- Test: `app/test/features/today/presentation/today_screen_test.dart`

**Interfaces:**
- Consumes: `PlanRepository.watchDay`, `TodayRepository`, `BodyMetricsRepository`, `MetricKinds`
- Produces: gerçek Bugün ekranı; antrenman kartına dokunuş `WorkoutScreen` (Task 6) açar.

- [ ] **Step 1: Provider'lar**

`app/lib/features/today/application/today_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:disport/app/app.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/data/today_repository.dart';

part 'today_providers.g.dart';

@riverpod
TodayRepository todayRepository(Ref ref) =>
    TodayRepository(ref.watch(appDatabaseProvider));

@riverpod
BodyMetricsRepository bodyMetricsRepository(Ref ref) =>
    BodyMetricsRepository(ref.watch(appDatabaseProvider));

/// Bugünün ISO tarihi. Ayrı provider: testte override edilir.
@riverpod
String todayIso(Ref ref) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

@riverpod
Stream<FullPlanDay?> todayPlanDay(Ref ref) =>
    ref.watch(planRepositoryProvider).watchDay(ref.watch(todayIsoProvider));

@riverpod
Stream<DailyLogView> todayLog(Ref ref) =>
    ref.watch(todayRepositoryProvider).watchDay(ref.watch(todayIsoProvider));
```

Run: build_runner.

- [ ] **Step 2: Failing widget testi**

`app/test/features/today/presentation/today_screen_test.dart`:

```dart
import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/presentation/today_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../plan/data/plan_repository_test.dart' show samplePlan;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await PlanRepository(db).insertFullPlan(samplePlan());
  });
  tearDown(() => db.close());

  Widget wrap() => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          todayIsoProvider.overrideWithValue('2026-08-31'),
        ],
        child: const MaterialApp(home: TodayScreen()),
      );

  testWidgets('renders slots from the plan day', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('4 haşlanmış yumurta'), findsOneWidget);
    expect(find.text('Antrenman'), findsOneWidget);
  });

  testWidgets('tapping a meal slot checks it', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('4 haşlanmış yumurta'));
    await tester.pumpAndSettle();

    final tile = tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text('4 haşlanmış yumurta'),
        matching: find.byType(CheckboxListTile),
      ),
    );
    expect(tile.value, isTrue);
  });

  testWidgets('weight entry saves to body metrics', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('weight-field')), '109.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final row = await db.select(db.bodyMetrics).getSingle();
    expect(row.value, 109.5);
    expect(row.kind, 'weight');
  });
}
```

- [ ] **Step 3: FAIL doğrula**

- [ ] **Step 4: Ekran implementasyonu**

`app/lib/features/today/presentation/today_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iso = ref.watch(todayIsoProvider);
    final planDay = ref.watch(todayPlanDayProvider);
    final log = ref.watch(todayLogProvider);

    final day = planDay.valueOrNull;
    final view = log.valueOrNull;
    if (view == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              key: const Key('weight-field'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Kilo (kg)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed != null) {
                  ref.read(bodyMetricsRepositoryProvider).upsert(
                      isoDate: iso,
                      kind: MetricKinds.weight,
                      value: parsed,
                      unit: 'kg');
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('sleep-field'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Uyku (sa)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (parsed != null) {
                  ref.read(bodyMetricsRepositoryProvider).upsert(
                      isoDate: iso,
                      kind: MetricKinds.sleepHours,
                      value: parsed,
                      unit: 'sa');
                }
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (day == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bugün için plan yok. Plan sekmesinden yükle.'),
            ),
          )
        else ...[
          if (day.headline.isNotEmpty)
            Text(day.headline,
                style: Theme.of(context).textTheme.titleMedium),
          for (final slot in day.slots)
            slot.kind == SlotKind.workout
                ? Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(slot.label),
                      subtitle: Text(slot.time),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => WorkoutScreen(day: day)),
                      ),
                    ),
                  )
                : CheckboxListTile(
                    value: view.checkedSlotIds.contains(slot.id),
                    onChanged: (_) => ref
                        .read(todayRepositoryProvider)
                        .toggleSlot(iso, slot.id),
                    title: Text(slot.label),
                    subtitle: Text(slot.time),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
          if (day.dinnerSuggestion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('Akşam önerisi: ${day.dinnerSuggestion}',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
        const Divider(),
        CheckboxListTile(
          value: view.waterTargetMet,
          onChanged: (v) => ref
              .read(todayRepositoryProvider)
              .setFlags(iso, waterTargetMet: v),
          title: const Text('3 L su'),
        ),
        CheckboxListTile(
          value: view.noAlcoholSugar,
          onChanged: (v) => ref
              .read(todayRepositoryProvider)
              .setFlags(iso, noAlcoholSugar: v),
          title: const Text('Alkol/şeker yok'),
        ),
        CheckboxListTile(
          value: view.workoutDone,
          onChanged: (v) =>
              ref.read(todayRepositoryProvider).setFlags(iso, workoutDone: v),
          title: const Text('Antrenman yapıldı'),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: view.note,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Not — ne yedin, ne zorladı…',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => ref.read(todayRepositoryProvider).setNote(iso, v),
        ),
      ],
    );
  }
}
```

Not: `WorkoutScreen(day: day)` Task 6'da yazılır; derleme için Task 6 Step 1'deki iskelet birlikte eklenir.

- [ ] **Step 5: PASS doğrula**

- [ ] **Step 6: Commit**

```powershell
git add app/lib/features/today app/test/features/today
git commit -m "feat: today screen with slots, flags, weight/sleep entry"
```

### Task 6: exercise_logs + Antrenman ekranı

**Files:**
- Create: `app/lib/features/workout/data/exercise_log_table.dart`
- Create: `app/lib/features/workout/data/workout_repository.dart`
- Create: `app/lib/features/workout/presentation/workout_screen.dart`
- Modify: `app/lib/core/db/app_database.dart` (schema v4)
- Test: `app/test/features/workout/data/workout_repository_test.dart`
- Test: `app/test/features/workout/presentation/workout_screen_test.dart`

**Interfaces:**
- Consumes: `FullPlanDay`/`PlanExercise` (Task 1), `catalogRepositoryProvider` (M2), `todayRepositoryProvider.setFlags` (Task 4), `ExerciseDetailScreen` (M2)
- Produces:
  - Tablo `ExerciseLogs` (`date`, `planExerciseId?`, `exerciseId`, `setIndex`, `reps?`, `weightKg?`, `durationSec?`) — spec 5.3
  - `class WorkoutRepository`:
    - `Future<void> logSet({required String isoDate, String? planExerciseId, required String exerciseId, required int setIndex, int? reps, double? weightKg, int? durationSec})`
    - `Future<List<SetActual>> lastActuals(String exerciseId, {required String beforeIso})` — önceki seansın gerçekleşmeleri (gri gösterim, spec 6-Antrenman)
    - `Stream<Map<String, int>> watchDoneSetCounts(String isoDate)` — exerciseId → tamamlanan set
  - `class SetActual { final int setIndex; final int? reps; final double? weightKg; final int? durationSec; }`
  - `WorkoutScreen({required FullPlanDay day})`

- [ ] **Step 1: Tablo + iskelet ekran**

`app/lib/features/workout/data/exercise_log_table.dart`:

```dart
import 'package:drift/drift.dart';

import 'package:disport/core/db/sync_columns.dart';

@DataClassName('ExerciseLogRow')
class ExerciseLogs extends Table with SyncColumns {
  TextColumn get date => text()();
  TextColumn get planExerciseId => text().nullable()();
  TextColumn get exerciseId => text()();
  IntColumn get setIndex => integer()();
  IntColumn get reps => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get durationSec => integer().nullable()();
}
```

`app_database.dart`: tabloyu ekle, `schemaVersion => 4`, `if (from < 4)` göçü. build_runner.

- [ ] **Step 2: Failing repository testi**

`app/test/features/workout/data/workout_repository_test.dart`:

```dart
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });
  tearDown(() => db.close());

  test('logSet then watchDoneSetCounts', () async {
    await repo.logSet(
        isoDate: '2026-09-01',
        exerciseId: 'incline_pushup',
        setIndex: 0,
        reps: 10);
    await repo.logSet(
        isoDate: '2026-09-01',
        exerciseId: 'incline_pushup',
        setIndex: 1,
        reps: 8);
    final counts = await repo.watchDoneSetCounts('2026-09-01').first;
    expect(counts['incline_pushup'], 2);
  });

  test('lastActuals returns most recent prior session only', () async {
    await repo.logSet(
        isoDate: '2026-08-25',
        exerciseId: 'incline_pushup',
        setIndex: 0,
        reps: 7);
    await repo.logSet(
        isoDate: '2026-08-27',
        exerciseId: 'incline_pushup',
        setIndex: 0,
        reps: 9);
    final actuals = await repo.lastActuals('incline_pushup',
        beforeIso: '2026-09-01');
    expect(actuals.single.reps, 9); // yalnız 27'sinin seansı
  });
}
```

- [ ] **Step 3: FAIL doğrula**

- [ ] **Step 4: Repository implementasyonu**

`app/lib/features/workout/data/workout_repository.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:disport/core/db/app_database.dart';

class SetActual {
  const SetActual(
      {required this.setIndex, this.reps, this.weightKg, this.durationSec});

  final int setIndex;
  final int? reps;
  final double? weightKg;
  final int? durationSec;
}

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  Future<void> logSet({
    required String isoDate,
    String? planExerciseId,
    required String exerciseId,
    required int setIndex,
    int? reps,
    double? weightKg,
    int? durationSec,
  }) =>
      _db.into(_db.exerciseLogs).insert(ExerciseLogsCompanion.insert(
            id: const Uuid().v4(),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            date: isoDate,
            planExerciseId: Value(planExerciseId),
            exerciseId: exerciseId,
            setIndex: setIndex,
            reps: Value(reps),
            weightKg: Value(weightKg),
            durationSec: Value(durationSec),
          ));

  Future<List<SetActual>> lastActuals(String exerciseId,
      {required String beforeIso}) async {
    final lastDateExp = _db.exerciseLogs.date.max();
    final lastDateQ = _db.selectOnly(_db.exerciseLogs)
      ..addColumns([lastDateExp])
      ..where(_db.exerciseLogs.exerciseId.equals(exerciseId) &
          _db.exerciseLogs.date.isSmallerThanValue(beforeIso));
    final lastDate = (await lastDateQ.getSingle()).read(lastDateExp);
    if (lastDate == null) return const [];

    final rows = await (_db.select(_db.exerciseLogs)
          ..where((t) =>
              t.exerciseId.equals(exerciseId) & t.date.equals(lastDate))
          ..orderBy([(t) => OrderingTerm.asc(t.setIndex)]))
        .get();
    return [
      for (final r in rows)
        SetActual(
            setIndex: r.setIndex,
            reps: r.reps,
            weightKg: r.weightKg,
            durationSec: r.durationSec),
    ];
  }

  Stream<Map<String, int>> watchDoneSetCounts(String isoDate) {
    final q = _db.select(_db.exerciseLogs)
      ..where((t) => t.date.equals(isoDate));
    return q.watch().map((rows) {
      final counts = <String, int>{};
      for (final r in rows) {
        counts[r.exerciseId] = (counts[r.exerciseId] ?? 0) + 1;
      }
      return counts;
    });
  }
}
```

- [ ] **Step 5: Failing widget testi**

`app/test/features/workout/presentation/workout_screen_test.dart`:

```dart
import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../catalog/data/catalog_repository_test.dart' show seedJson;

void main() {
  late AppDatabase db;

  final day = FullPlanDay(
    id: 'd1',
    date: DateTime(2026, 9, 1),
    type: PlanDayType.home,
    weekIndex: 1,
    exercises: const [
      PlanExercise(
          id: 'pe1',
          exerciseId: 'incline_pushup',
          sets: 3,
          reps: 10,
          restSec: 60),
    ],
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await CatalogRepository(db).seedFromJson(seedJson());
  });
  tearDown(() => db.close());

  Widget wrap() => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: WorkoutScreen(day: day)),
      );

  testWidgets('shows exercise with target and set progress', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Eğimli Şınav'), findsOneWidget);
    expect(find.textContaining('3 × 10'), findsOneWidget);
    expect(find.text('0 / 3 set'), findsOneWidget);
  });

  testWidgets('completing a set increments counter and logs it',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('done-set-incline_pushup')));
    await tester.pumpAndSettle();

    expect(find.text('1 / 3 set'), findsOneWidget);
    expect(await db.select(db.exerciseLogs).get(), hasLength(1));
  });
}
```

- [ ] **Step 6: FAIL doğrula, sonra ekran implementasyonu**

`app/lib/features/workout/presentation/workout_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:disport/app/app.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_screen.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/workout/data/workout_repository.dart';

part 'workout_screen.g.dart';

@riverpod
WorkoutRepository workoutRepository(Ref ref) =>
    WorkoutRepository(ref.watch(appDatabaseProvider));

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.day});

  final FullPlanDay day;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  int _restRemaining = 0;
  Timer? _restTimer;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() => _restRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restRemaining <= 1) {
        t.cancel();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final iso = PlanRepository.iso(widget.day.date);
    final repo = ref.watch(workoutRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Antrenman')),
      bottomNavigationBar: _restRemaining > 0
          ? Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.all(16),
              child: Text('Dinlenme: $_restRemaining sn',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
            )
          : null,
      body: StreamBuilder<Map<String, int>>(
        stream: repo.watchDoneSetCounts(iso),
        initialData: const {},
        builder: (context, snapshot) {
          final counts = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final pe in widget.day.exercises)
                _ExerciseCard(
                  planExercise: pe,
                  doneSets: counts[pe.exerciseId] ?? 0,
                  isoDate: iso,
                  onSetDone: () {
                    final done = counts[pe.exerciseId] ?? 0;
                    repo.logSet(
                      isoDate: iso,
                      planExerciseId: pe.id,
                      exerciseId: pe.exerciseId,
                      setIndex: done,
                      reps: pe.reps,
                      durationSec: pe.durationSec,
                    );
                    if ((pe.restSec ?? 0) > 0 &&
                        done + 1 < (pe.sets ?? 1)) {
                      _startRest(pe.restSec!);
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.planExercise,
    required this.doneSets,
    required this.isoDate,
    required this.onSetDone,
  });

  final PlanExercise planExercise;
  final int doneSets;
  final String isoDate;
  final VoidCallback onSetDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pe = planExercise;
    final target = pe.reps != null
        ? '${pe.sets} × ${pe.reps}'
        : '${pe.sets} × ${pe.durationSec} sn';
    final total = pe.sets ?? 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: ref
                  .read(catalogRepositoryProvider)
                  .getById(pe.exerciseId),
              builder: (context, snapshot) => InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ExerciseDetailScreen(exerciseId: pe.exerciseId),
                  ),
                ),
                child: Text(
                  snapshot.data?.nameTr ?? pe.exerciseId,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Text('Hedef: $target'
                '${pe.intensity != null ? ' · ${pe.intensity}' : ''}'),
            FutureBuilder<List<SetActual>>(
              future: ref
                  .read(workoutRepositoryProvider)
                  .lastActuals(pe.exerciseId, beforeIso: isoDate),
              builder: (context, snapshot) {
                final prev = snapshot.data ?? const <SetActual>[];
                if (prev.isEmpty) return const SizedBox.shrink();
                final txt = prev
                    .map((a) => a.reps?.toString() ?? '${a.durationSec}sn')
                    .join(' · ');
                return Text('Geçen sefer: $txt',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey));
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$doneSets / $total set'),
                const Spacer(),
                FilledButton(
                  key: Key('done-set-${pe.exerciseId}'),
                  onPressed: doneSets >= total ? null : onSetDone,
                  child: const Text('Set tamam'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: PASS + tam denetim** — `flutter test` ve `flutter analyze`.

- [ ] **Step 8: Emülatörde uçtan uca dene**

Plan sekmesi → örnek planı yükle → Bugün → slot işaretle, kilo gir → antrenman kartı → set tamamla, dinlenme sayacını gör → hareket adı → detay sayfası.

- [ ] **Step 9: Commit**

```powershell
git add app/lib/features/workout app/lib/core/db app/test/features/workout
git commit -m "feat: workout screen with set logging, rest timer, last actuals"
```

---

## Self-Review Notları

- **Spec kapsaması:** 5.2 ✓ (dört plan tablosu), 5.3 ✓ (daily_logs UNIQUE date; exercise_logs), 5.4-body_metrics ✓ (health/data'da, ekranı M5), 6-Bugün ✓ (tartı/uyku → body_metrics; kutucuklar → daily_logs; not; antrenman kartı), 6-Antrenman ✓ (hedef + geçen sefer gri + set sayacı + dinlenme + detaya geçiş), 6-Plan kısmen — takvim renklendirme M5'e, AI eylemleri M4'e (bilinçli).
- **Tip tutarlılığı:** `samplePlan()` ve `seedJson()` test yardımcıları cross-import ediliyor (path'ler doğrulandı). `PlanRepository.iso` statik — WorkoutScreen kullanıyor. `MetricKinds.weight` string sabiti body_metrics testinde ve Today ekranında aynı.
- **Şema göçleri:** v2 (plan), v3 (daily+body), v4 (exercise_logs) — her göç ayrı görevde, `onUpgrade` kademeli.
- **Bilinen sadeleştirme:** Task 3 Step 4'teki plan listesi kod örneğinde hatalı uzantı referansı vardı; implementasyon notuyla düzeltildi (basit ikon/başlık). Kardiyo günü için ayrı büyük sayaç (spec 6) M3'te `durationSec`'li hareket kartıyla karşılanır; özel kardiyo görünümü M4 sonrası cila görevidir — spec'in "tek büyük sayaç" ifadesi tam karşılanmıyor, M5 planına taşındı.
