import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/nutrition/data/nutrition_repository.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/plan/data/plan_editor_repository.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PlanEditorRepository editor;
  late PlanRepository plans;

  const goals = PlanGoals(
    dailyKcal: 2200,
    proteinG: 150,
    waterL: 3,
    weeklyGym: 3,
    weeklyHome: 2,
    targetLossKg: 4,
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    editor = PlanEditorRepository(db);
    plans = PlanRepository(db);
  });

  tearDown(() => db.close());

  Future<String> newPlan({DateTime? start, int weeks = 4}) => editor
      .createEmptyPlan(
        title: 'Elle kurulan',
        startDate: start ?? DateTime(2026, 9, 1),
        weeks: weeks,
        goals: goals,
      );

  group('createEmptyPlan', () {
    test('hafta sayısı kadar gün üretir, hepsi dinlenme', () async {
      await newPlan();

      final plan = (await plans.activePlan())!;
      expect(plan.days, hasLength(28));
      expect(
        plan.days.every((day) => day.type == PlanDayType.rest),
        isTrue,
      );
      // Varsayılan slot koymak, silinecek satırlar üretmek olurdu.
      expect(plan.days.every((day) => day.slots.isEmpty), isTrue);
    });

    test('bitiş tarihi hafta sayısından türer', () async {
      await newPlan(start: DateTime(2026, 9, 1), weeks: 2);

      final plan = (await plans.activePlan())!;
      expect(plan.startDate, DateTime(2026, 9, 1));
      expect(plan.endDate, DateTime(2026, 9, 14));
    });

    test('sourceRaw boş — bu plan AI belgesinden doğmadı', () async {
      await newPlan();
      expect((await plans.activePlan())!.sourceRaw, isEmpty);
    });

    test('yeni plan aktif olur, eskisi pasifleşir', () async {
      // İçe alma davranışının aynısı; iki yol arasında sürpriz olmasın.
      await newPlan();
      await editor.createEmptyPlan(
        title: 'İkinci',
        startDate: DateTime(2026, 10, 1),
        weeks: 1,
        goals: goals,
      );

      expect((await plans.activePlan())!.title, 'İkinci');
      final rows = await db.select(db.plans).get();
      expect(rows.where((row) => row.isActive), hasLength(1));
    });

    test('sıfır hafta reddedilir', () {
      expect(
        () => editor.createEmptyPlan(
          title: 'Boş',
          startDate: DateTime(2026, 9, 1),
          weeks: 0,
          goals: goals,
        ),
        throwsArgumentError,
      );
    });
  });

  group('plan düzeyi', () {
    test('hedef güncellemesi okumaya yansır', () async {
      final planId = await newPlan();
      await editor.updateGoals(
        planId,
        const PlanGoals(
          dailyKcal: 1900,
          proteinG: 160,
          waterL: 3.5,
          weeklyGym: 4,
          weeklyHome: 1,
          targetLossKg: 5,
        ),
      );

      expect((await plans.activePlan())!.goals.dailyKcal, 1900);
    });

    test('kural listeleri güncellenir', () async {
      final planId = await newPlan();
      await editor.updateRules(
        planId,
        const PlanRules(forbidden: ['şeker'], free: ['sebze']),
      );

      expect((await plans.activePlan())!.rules.forbidden, ['şeker']);
    });

    test('boş başlık reddedilir', () async {
      final planId = await newPlan();
      expect(() => editor.updateTitle(planId, '  '), throwsArgumentError);
    });
  });

  group('gün düzeyi', () {
    test('tip ve başlık güncellenir', () async {
      await newPlan();
      final plan = (await plans.activePlan())!;
      final day = plan.days.first;

      await editor.updateDay(
        day.id,
        type: PlanDayType.gym,
        headline: 'Bacak günü',
      );

      final updated = (await plans.activePlan())!.days.first;
      expect(updated.type, PlanDayType.gym);
      expect(updated.headline, 'Bacak günü');
    });

    test('verilmeyen alan olduğu gibi kalır', () async {
      // Kısmi güncelleme: editör sayfası yalnız dokunulan alanı
      // gönderiyor ve gerisi silinmemeli.
      await newPlan();
      final day = (await plans.activePlan())!.days.first;
      await editor.updateDay(day.id, headline: 'Başlık');
      await editor.updateDay(day.id, type: PlanDayType.home);

      final updated = (await plans.activePlan())!.days.first;
      expect(updated.headline, 'Başlık');
      expect(updated.type, PlanDayType.home);
    });
  });

  group('slot düzeyi', () {
    test('yeni slot eklenir ve okunur', () async {
      await newPlan();
      final day = (await plans.activePlan())!.days.first;

      await editor.upsertSlot(
        day.id,
        time: '08:00',
        kind: SlotKind.meal,
        mealKind: MealKind.kahvalti,
        label: 'Kahvaltı',
      );

      final slot = (await plans.activePlan())!.days.first.slots.single;
      expect(slot.time, '08:00');
      expect(slot.mealKind, MealKind.kahvalti);
    });

    test('mevcut slot güncellenir, yenisi eklenmez', () async {
      await newPlan();
      final day = (await plans.activePlan())!.days.first;
      final slotId = await editor.upsertSlot(
        day.id,
        time: '08:00',
        kind: SlotKind.meal,
        mealKind: MealKind.kahvalti,
        label: 'Kahvaltı',
      );

      await editor.upsertSlot(
        day.id,
        slotId: slotId,
        time: '08:30',
        kind: SlotKind.meal,
        mealKind: MealKind.kahvalti,
        label: 'Geç kahvaltı',
      );

      final slots = (await plans.activePlan())!.days.first.slots;
      expect(slots, hasLength(1));
      expect(slots.single.time, '08:30');
    });

    test('tür öğünden çıkınca öğün türü temizlenir', () async {
      // Kalırsa sonraki okuma "kahvaltı olan bir antrenman" görürdü.
      await newPlan();
      final day = (await plans.activePlan())!.days.first;
      final slotId = await editor.upsertSlot(
        day.id,
        time: '08:00',
        kind: SlotKind.meal,
        mealKind: MealKind.kahvalti,
        label: 'Kahvaltı',
      );

      await editor.upsertSlot(
        day.id,
        slotId: slotId,
        time: '08:00',
        kind: SlotKind.workout,
        label: 'Antrenman',
      );

      expect(
        (await plans.activePlan())!.days.first.slots.single.mealKind,
        isNull,
      );
    });

    test('bozuk saat reddedilir', () async {
      await newPlan();
      final day = (await plans.activePlan())!.days.first;

      expect(
        () => editor.upsertSlot(
          day.id,
          time: '25:00',
          kind: SlotKind.meal,
          label: 'Yanlış',
        ),
        throwsArgumentError,
      );
      expect(
        () => editor.upsertSlot(
          day.id,
          time: '8:00',
          kind: SlotKind.meal,
          label: 'Yanlış',
        ),
        throwsArgumentError,
      );
    });

    test('silinen slot okumadan düşer ama satır durur', () async {
      await newPlan();
      final day = (await plans.activePlan())!.days.first;
      final slotId = await editor.upsertSlot(
        day.id,
        time: '08:00',
        kind: SlotKind.meal,
        label: 'Kahvaltı',
      );

      await editor.deleteSlot(slotId);

      expect((await plans.activePlan())!.days.first.slots, isEmpty);
      expect(await db.select(db.planSlots).get(), hasLength(1));
    });

    test('slot silinince o slota yazılmış öğün kaydı bozulmaz', () async {
      // Kullanıcı bir slotu silince o gün yediklerinin de silinmesi
      // felaket olurdu; kayıt plansız kayda dönüyor.
      final nutrition = NutritionRepository(db);
      await nutrition.seedFromJson(
        '{"version":1,"foods":[{"id":"apple_raw","nameEn":"Apples, raw",'
        '"category":"meyve","kcal100":52.0,"source":"usda"}]}',
      );

      await newPlan();
      final day = (await plans.activePlan())!.days.first;
      final slotId = await editor.upsertSlot(
        day.id,
        time: '08:00',
        kind: SlotKind.meal,
        mealKind: MealKind.kahvalti,
        label: 'Kahvaltı',
      );

      final apple = (await nutrition.foodById('apple_raw'))!;
      await nutrition.addEntry(
        food: apple,
        mealKind: MealKind.kahvalti,
        isoDate: '2026-09-01',
        quantity: 1,
        slotId: slotId,
      );

      await editor.deleteSlot(slotId);

      final entries = await nutrition.watchDay('2026-09-01').first;
      expect(entries, hasLength(1));
      expect(entries.single.kcal, closeTo(52, 1));
    });

    test('yeni slotlar sıraya eklenir', () async {
      await newPlan();
      final day = (await plans.activePlan())!.days.first;
      await editor.upsertSlot(
        day.id,
        time: '08:00',
        kind: SlotKind.meal,
        label: 'Kahvaltı',
      );
      final second = await editor.upsertSlot(
        day.id,
        time: '13:00',
        kind: SlotKind.meal,
        label: 'Öğle',
      );
      await editor.deleteSlot(second);
      await editor.upsertSlot(
        day.id,
        time: '19:00',
        kind: SlotKind.meal,
        label: 'Akşam',
      );

      // Silinmiş satır sıra numarasını düşürmemeli; iki satır aynı
      // sıraya oturursa liste kararsız olurdu.
      final rows = await db.select(db.planSlots).get();
      expect(rows.map((row) => row.orderIndex).toSet(), hasLength(3));
    });
  });

  group('hareket düzeyi', () {
    test('hareket eklenir, şiddet alanlarıyla', () async {
      await newPlan();
      final day = (await plans.activePlan())!.days.first;

      await editor.upsertExercise(
        day.id,
        exerciseId: 'treadmill_incline_walk',
        durationSec: 1800,
        speedKmh: 5.5,
        gradePct: 8,
      );

      final exercise =
          (await plans.activePlan())!.days.first.exercises.single;
      expect(exercise.exerciseId, 'treadmill_incline_walk');
      expect(exercise.speedKmh, 5.5);
      expect(exercise.gradePct, 8);
    });

    test('mevcut hareket güncellenir', () async {
      await newPlan();
      final day = (await plans.activePlan())!.days.first;
      final id = await editor.upsertExercise(
        day.id,
        exerciseId: 'pushup',
        sets: 3,
        reps: 8,
      );

      await editor.upsertExercise(
        day.id,
        planExerciseId: id,
        exerciseId: 'pushup',
        sets: 4,
        reps: 10,
      );

      final exercises = (await plans.activePlan())!.days.first.exercises;
      expect(exercises, hasLength(1));
      expect(exercises.single.sets, 4);
    });

    test('silinen hareket okumadan düşer', () async {
      await newPlan();
      final day = (await plans.activePlan())!.days.first;
      final id = await editor.upsertExercise(
        day.id,
        exerciseId: 'pushup',
        sets: 3,
      );

      await editor.deleteExercise(id);

      expect((await plans.activePlan())!.days.first.exercises, isEmpty);
    });
  });
}
