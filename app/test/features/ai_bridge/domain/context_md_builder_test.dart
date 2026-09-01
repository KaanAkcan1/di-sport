import 'dart:convert';

import 'package:disport/features/ai_bridge/domain/context_md_builder.dart';
import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfile implements ProfileSource {
  _FakeProfile([this.data = const {}]);

  final Map<String, String> data;

  @override
  Future<Map<String, String>> profile() async => data;
}

class _FakeLogs implements LogSource {
  _FakeLogs({this.days = const [], this.notes = const [], this.sets = const []});

  final List<DayCompliance> days;
  final List<({String date, String text})> notes;
  final List<SetActualDump> sets;

  @override
  Future<List<DayCompliance>> compliance({required int lastDays}) async => days;

  @override
  Future<List<({String date, String text})>> userNotes({
    required int lastDays,
  }) async => notes;

  @override
  Future<List<SetActualDump>> actuals({required int lastDays}) async => sets;
}

class _FakeHealth implements HealthSource {
  _FakeHealth({this.metrics = const [], this.labs = const []});

  final List<MetricPoint> metrics;
  final List<LabValueDump> labs;

  @override
  Future<List<MetricPoint>> bodyMetrics({required int lastDays}) async =>
      metrics;

  @override
  Future<List<LabValueDump>> recentLabs() async => labs;
}

class _FakeCatalog implements CatalogSource {
  _FakeCatalog([this.items = const []]);

  final List<ExerciseRef> items;

  @override
  Future<List<ExerciseRef>> selectable() async => items;

  @override
  Future<List<ExerciseRef>> all() async => items;
}

class _FakePlan implements PlanSource {
  _FakePlan([this.summary]);

  final ActivePlanSummary? summary;

  @override
  Future<ActivePlanSummary?> activePlanSummary() async => summary;
}

class _FakeMedical implements MedicalSource {
  _FakeMedical([this.items = const []]);
  final List<MedicalFactDump> items;

  @override
  Future<List<MedicalFactDump>> facts() async => items;
}

class _FakeMedications implements MedicationSource {
  _FakeMedications([this.items = const []]);
  final List<MedicationDump> items;

  @override
  Future<List<MedicationDump>> medications() async => items;
}

class _FakeEnvironment implements EnvironmentSource {
  _FakeEnvironment({
    this.home = const [],
    this.gym = const [],
    this.sports = const [],
  });

  final List<String> home;
  final List<String> gym;
  final List<({String name, String? note})> sports;

  @override
  Future<({List<String> home, List<String> gym})> equipment() async =>
      (home: home, gym: gym);

  @override
  Future<List<({String name, String? note})>> favoriteSports() async => sports;
}

class _FakeRoutine implements RoutineSource {
  _FakeRoutine([this.items = const []]);
  final List<MealBehaviorDump> items;

  @override
  Future<List<MealBehaviorDump>> mealBehaviors() async => items;
}

class _FakeNutrition implements NutritionSource {
  _FakeNutrition({this.items = const [], this.intake = const []});
  final List<FoodDump> items;
  final List<DayIntakeDump> intake;

  @override
  Future<List<FoodDump>> foods() async => items;

  @override
  Future<List<DayIntakeDump>> dailyIntake({required int lastDays}) async =>
      intake;
}

class _FakeRules implements RulesSource {
  _FakeRules([this.items = const []]);
  final List<String> items;

  @override
  Future<List<String>> forbidden() async => items;
}

class _FakeAvailability implements AvailabilitySource {
  const _FakeAvailability(this.items);
  final List<WindowDump> items;

  @override
  Future<List<WindowDump>> windows() async => items;
}

void main() {
  final today = DateTime(2026, 9, 28);

  ContextMdBuilder builder({
    Map<String, String> profile = const {},
    List<DayCompliance> days = const [],
    List<({String date, String text})> notes = const [],
    List<SetActualDump> sets = const [],
    List<MetricPoint> metrics = const [],
    List<LabValueDump> labs = const [],
    List<ExerciseRef> catalog = const [],
    ActivePlanSummary? plan,
    List<WindowDump> windows = const [],
    List<MedicalFactDump> facts = const [],
    List<MedicationDump> meds = const [],
    List<String> homeGear = const [],
    List<String> gymGear = const [],
    List<({String name, String? note})> sports = const [],
    List<MealBehaviorDump> behaviors = const [],
    List<FoodDump> foods = const [],
    List<DayIntakeDump> intake = const [],
    List<String> forbidden = const [],
  }) => ContextMdBuilder(
    profile: _FakeProfile(profile),
    logs: _FakeLogs(days: days, notes: notes, sets: sets),
    health: _FakeHealth(metrics: metrics, labs: labs),
    catalog: _FakeCatalog(catalog),
    plan: _FakePlan(plan),
    availability: _FakeAvailability(windows),
    medical: _FakeMedical(facts),
    medications: _FakeMedications(meds),
    environment: _FakeEnvironment(
      home: homeGear,
      gym: gymGear,
      sports: sports,
    ),
    routine: _FakeRoutine(behaviors),
    nutrition: _FakeNutrition(items: foods, intake: intake),
    rules: _FakeRules(forbidden),
  );

  const fullProfile = {
    ProfileKeys.age: '34',
    ProfileKeys.heightCm: '184',
    ProfileKeys.currentWeightKg: '110',
    ProfileKeys.targetWeightKg: '95',
    ProfileKeys.wakeTime: '06:11',
    ProfileKeys.sleepTime: '23:45',
    ProfileKeys.workSchedule: 'Fabrika, 07:30-17:30',
    ProfileKeys.gymAccessHours: '22:00 sonrası',
    ProfileKeys.familyDinnerTime: '19:50',
    ProfileKeys.equipmentAtHome: 'direnç bandı, sandalye',
    ProfileKeys.healthConstraints: 'karaciğer yağlanması; diz hassasiyeti',
  };

  test('v2 bölümlerinin hepsi var', () async {
    final md = await builder().build(today: today);

    for (final heading in [
      '## 1. Kim',
      '## 2. Hedef',
      '## 3. Medikal',
      '## 4. Ortam',
      '## 5. Kısıtlar ve düzen',
      '## 7. Geçen dönem',
      '## 8. Kendi sözlerim',
      '## 9. Görev ve format',
      '### Besin listesi',
    ]) {
      expect(md, contains(heading), reason: heading);
    }
  });

  test('kapalı bölüm belgeye hiç yazılmaz', () async {
    final md = await builder(
      facts: const [MedicalFactDump(kind: 'condition', label: 'İnsülin direnci')],
    ).build(
      today: today,
      sections: const {ContextSection.recent, ContextSection.notes},
    );

    expect(md, isNot(contains('## 3. Medikal')));
    expect(md, isNot(contains('İnsülin direnci')));
    expect(md, isNot(contains('### Besin listesi')));
    // Sabit bölümler her zaman girer.
    expect(md, contains('## 1. Kim'));
    expect(md, contains('## 9. Görev ve format'));
  });

  test('medikal bölüm ilaçları sınır satırıyla basar', () async {
    final md = await builder(
      facts: const [
        MedicalFactDump(kind: 'restriction', label: 'Diz hassasiyeti'),
      ],
      meds: const [
        MedicationDump(
          name: 'Metformin',
          isPrescription: true,
          doseLabel: '1000 mg',
          times: ['08:00'],
        ),
      ],
    ).build(today: today);

    expect(md, contains('Hareket kısıtı: Diz hassasiyeti'));
    expect(md, contains('Reçeteli: Metformin · 1000 mg · 08:00'));
    expect(md, contains('İlaç etkileşimi, doz değişikliği'));
  });

  test('ortam ekipmanı enum adlarıyla, sporlar notla basılır', () async {
    final md = await builder(
      homeGear: const ['dumbbell', 'chair'],
      gymGear: const ['cable'],
      sports: const [(name: 'Basketball', note: 'haftada 1')],
    ).build(today: today);

    expect(md, contains('Evdeki ekipman: dumbbell, chair'));
    expect(md, contains('Salondaki ekipman: cable'));
    expect(md, contains('Basketball (haftada 1)'));
  });

  test('öğün davranışları ve yasaklılar belgeye girer', () async {
    final md = await builder(
      behaviors: const [
        MealBehaviorDump(meal: 'ogle', behavior: 'external', time: '12:30'),
      ],
      forbidden: const ['şeker'],
    ).build(today: today);

    expect(md, contains('ogle: external · 12:30'));
    expect(md, contains('Bunları **asla önerme**'));
    expect(md, contains('- şeker'));
  });

  test('son 14 gün bloğu su ml ve ilaç uyumunu taşır', () async {
    final md = await builder(
      intake: const [
        DayIntakeDump(
          date: '2026-09-27',
          kcalEaten: 1850,
          waterMl: 2750,
          dosesTaken: 1,
          dosesPlanned: 2,
        ),
      ],
    ).build(today: today);

    expect(md, contains('"waterMl": 2750'));
    expect(md, contains('"doses": "1/2"'));
  });

  test('aşılamada başlangıç seçilen gün ve devam talimatı yazılır', () async {
    final md = await builder().build(
      today: today,
      graftFrom: DateTime(2026, 10, 5),
    );
    expect(md, contains('`2026-10-05` gününden başlayarak'));
    expect(md, contains('devam planı'));
  });

  test('profil bilgileri birinci bölüme yazılır', () async {
    final md = await builder(profile: fullProfile).build(today: today);

    expect(md, contains('Yaş: 34'));
    expect(md, contains('Boy: 184 cm'));
    expect(md, contains('Fabrika, 07:30-17:30'));
  });

  test('eksik profil alanı "belirtilmedi" der, bölümü boş bırakmaz', () async {
    final md = await builder(profile: const {}).build(today: today);
    expect(md, contains('belirtilmedi'));
  });

  test('sağlık kısıtı ve geçiş kriteri üçüncü bölümde', () async {
    final md = await builder(profile: fullProfile).build(today: today);

    expect(md, contains('karaciğer yağlanması'));
    expect(md, contains('105 kg'));
    expect(md, contains('8 nizami şınav'));
    expect(md, contains('Zıplamalı hareket'));
  });

  test('etkin plan varsa devamı istendiği söylenir', () async {
    final md = await builder(
      plan: const ActivePlanSummary(
        title: 'Eylül Planı',
        startDate: '2026-08-31',
        endDate: '2026-09-27',
        weeks: 4,
      ),
    ).build(today: today);

    expect(md, contains('Eylül Planı'));
    expect(md, contains('devamı'));
  });

  group('geçen dönem bloğu', () {
    test('makine okunur JSON üretir', () async {
      final md = await builder(
        days: const [
          DayCompliance(
            date: '2026-09-01',
            dayType: 'home',
            workoutDone: true,
            waterTargetMet: true,
            noAlcoholSugar: false,
            checkedSlots: 5,
            totalSlots: 6,
          ),
        ],
        metrics: const [
          MetricPoint(
            date: '2026-09-01',
            kind: 'weight',
            value: 110,
            unit: 'kg',
          ),
          MetricPoint(
            date: '2026-09-01',
            kind: 'pushupMax',
            value: 6,
            unit: 'tekrar',
          ),
        ],
        sets: const [
          SetActualDump(
            date: '2026-09-01',
            exerciseId: 'incline_pushup',
            setIndex: 0,
            reps: 10,
          ),
        ],
      ).build(today: today);

      final block = _jsonBlock(md);
      final decoded = jsonDecode(block) as Map<String, dynamic>;

      expect((decoded['days'] as List).single, {
        'date': '2026-09-01',
        'type': 'home',
        'workoutDone': true,
        'water3L': true,
        'noAlcoholSugar': false,
        'slotsChecked': '5/6',
      });

      // Kilo serisi ayrı: AI'ın en çok baktığı dizi bu.
      expect((decoded['weightSeries'] as List).single, {
        'date': '2026-09-01',
        'kg': 110,
      });

      // Diğer ölçümler kilo serisini kirletmiyor.
      expect((decoded['otherMeasurements'] as List).single['kind'],
          'pushupMax');

      // Set numarası kullanıcıya 1'den başlıyor.
      expect((decoded['setActuals'] as List).single['set'], 1);
    });

    test('kayıt yoksa boş diziler üretilir, blok bozulmaz', () async {
      final md = await builder().build(today: today);
      final decoded = jsonDecode(_jsonBlock(md)) as Map<String, dynamic>;

      expect(decoded['days'], isEmpty);
      expect(decoded['weightSeries'], isEmpty);
    });
  });

  group('kendi sözlerim', () {
    test('notlar düzenlenmeden, tarihiyle aktarılır', () async {
      final md = await builder(
        notes: const [
          (date: '2026-09-01', text: 'Şınavda zorlandım.'),
          (date: '2026-09-02', text: 'Akşam bir dilim baklava yedim.'),
        ],
      ).build(today: today);

      expect(md, contains('**2026-09-01:** Şınavda zorlandım.'));
      expect(md, contains('baklava'));
    });

    test('not yoksa bölüm boş bırakılmaz', () async {
      final md = await builder().build(today: today);
      expect(md, contains('(not yazılmamış)'));
    });
  });

  group('tahliller', () {
    test('referans aralığıyla yazılır', () async {
      final md = await builder(
        labs: const [
          LabValueDump(
            date: '2026-06-15',
            marker: 'Vitamin D',
            value: 10,
            unit: 'ng/mL',
            refLow: 30,
            refHigh: 100,
          ),
        ],
      ).build(today: today);

      expect(md, contains('Vitamin D: 10.0 ng/mL (referans 30.0-100.0)'));
    });

    test('tahlil yoksa açıkça söylenir', () async {
      final md = await builder().build(today: today);
      expect(md, contains('(tahlil kaydı yok)'));
    });
  });

  group('görev bölümü', () {
    test('yalnızca JSON istenir ve kurallar sayılır', () async {
      final md = await builder().build(today: today);

      expect(md, contains('**yalnızca**'));
      expect(md, contains('markdown'));
      expect(md, contains('bodyOnly'));
      expect(md, contains('1200-4000'));
      expect(md, contains('Dinlenme'));
    });

    test('başlangıç tarihi yarın', () async {
      final md = await builder().build(today: today);
      expect(md, contains('2026-09-29'));
    });

    test('katalog id, ad, yer ve ekipmanla listelenir', () async {
      final md = await builder(
        catalog: const [
          ExerciseRef(
            id: 'incline_pushup',
            name: 'Incline Push-Up',
            location: 'home',
            equipment: [],
            primaryMuscles: ['göğüs'],
          ),
        ],
      ).build(today: today);

      expect(
        md,
        contains('incline_pushup · Incline Push-Up · home · none · göğüs'),
      );
    });

    test('şema örneği geçerli JSON', () async {
      final md = await builder().build(today: today);
      final blocks = _jsonBlocks(md);

      // İki blok: geçen dönem verisi ve şema örneği.
      expect(blocks, hasLength(2));
      final schema = jsonDecode(blocks.last) as Map<String, dynamic>;
      expect(schema['schemaVersion'], 1);
      expect(schema['days'], isNotEmpty);
      expect(schema.containsKey('newExercises'), isTrue);
    });
  });

  test('hafta sayısı isteğe yansır', () async {
    final md = await builder().build(today: today, weeks: 2);
    expect(md, contains('2 haftalık'));
  });

  group('haftalık uygunluk', () {
    test('pencere yoksa belirtilmedi der', () async {
      final md = await builder().build(today: today);
      expect(md, contains('Haftalık uygunluk belirtilmedi'));
    });

    test('mesai ve yasaklı ayrı satırlarda, anlamlarıyla', () async {
      // İkisi tek listede verilseydi AI için ayrım kaybolurdu:
      // mesaide öğün olur, yasaklı saatte hiçbir şey olmaz.
      final md = await builder(
        windows: const [
          WindowDump(
            weekday: 1,
            startTime: '07:30',
            endTime: '17:30',
            kind: 'work',
            label: 'Fabrika',
          ),
          WindowDump(
            weekday: 3,
            startTime: '19:00',
            endTime: '21:00',
            kind: 'blocked',
            label: '',
          ),
        ],
      ).build(today: today);

      expect(md, contains('Pazartesi 07:30-17:30 (Fabrika)'));
      expect(md, contains('öğün olabilir, antrenman olamaz'));
      expect(md, contains('Çarşamba 19:00-21:00'));
      expect(md, contains('hiçbir şey planlama'));
    });

    test('yalnız bir tür varsa diğer satır hiç çıkmaz', () async {
      final md = await builder(
        windows: const [
          WindowDump(
            weekday: 6,
            startTime: '10:00',
            endTime: '12:00',
            kind: 'blocked',
            label: '',
          ),
        ],
      ).build(today: today);

      expect(md, isNot(contains('Mesai (')));
      expect(md, contains('Cumartesi 10:00-12:00'));
    });
  });
}

/// ```json bloklarının içeriğini çıkarır.
List<String> _jsonBlocks(String markdown) {
  final blocks = <String>[];
  final buffer = StringBuffer();
  var inside = false;

  for (final line in markdown.split('\n')) {
    if (line.trim() == '```json') {
      inside = true;
      buffer.clear();
      continue;
    }
    if (inside && line.trim() == '```') {
      inside = false;
      blocks.add(buffer.toString());
      continue;
    }
    if (inside) buffer.writeln(line);
  }

  return blocks;
}

String _jsonBlock(String markdown) => _jsonBlocks(markdown).first;
