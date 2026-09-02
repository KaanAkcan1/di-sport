import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_importer.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ai_fixtures.dart';

void main() {
  late List<FullPlan> insertedPlans;
  late List<Exercise> addedExercises;
  late PlanImporter importer;

  setUp(() {
    insertedPlans = [];
    addedExercises = [];
    importer = PlanImporter(
      insertPlan: (plan) async => insertedPlans.add(plan),
      addExercise: (exercise) async => addedExercises.add(exercise),
    );
  });

  ValidatedPlan validate(Map<String, dynamic> document) {
    final result = fixtureValidator().validate(jsonEncode(document));
    if (result is! Ok<ValidatedPlan>) {
      fail('Fixture doğrulamayı geçmeliydi: '
          '${(result as Err<ValidatedPlan>).failure.message}');
    }
    return result.value;
  }

  group('dönüştürme', () {
    test('gün, slot ve hareketler domain modeline aktarılır', () async {
      final result = await importer.import(
        validate(validPlanMap()),
        acceptedNewExerciseIds: const {},
      );

      expect(result.isOk, isTrue);
      final plan = insertedPlans.single;

      expect(plan.title, 'Eylül Planı');
      expect(plan.weeks, 1);
      expect(plan.days, hasLength(7));
      expect(plan.startDate, DateTime(2026, 8, 31));
      expect(plan.days.first.slots, hasLength(2));
      expect(plan.days.first.type, PlanDayType.gym);
      expect(plan.days.last.type, PlanDayType.rest);
    });

    test('öğün türü ve kalemler taşınır, eksikse eski davranış (v3)', () async {
      final document = validPlanMap();
      final day0 = (document['days'] as List).first as Map<String, dynamic>;
      // Fixture'ın slot listesi dar tipte (`List<Map<String, String>>`)
      // çıkabiliyor; kalem ekleyebilmek için listeyi baştan kuruyoruz.
      final slots = [
        for (final slot in day0['slots'] as List)
          Map<String, dynamic>.from(slot as Map),
      ];
      slots[0]['mealKind'] = 'kahvalti';
      slots[0]['items'] = [
        {'foodId': 'egg', 'quantity': 4, 'portionId': 'egg-piece'},
        {'foodId': 'cheese'},
      ];
      day0['slots'] = slots;

      await importer.import(
        validate(document),
        acceptedNewExerciseIds: const {},
      );

      final slot = insertedPlans.single.days.first.slots.first;
      expect(slot.mealKind, MealKind.kahvalti);
      expect(slot.items, hasLength(2));
      expect(slot.items.first.foodId, 'egg');
      expect(slot.items.first.quantity, 4);
      expect(slot.items.first.portionId, 'egg-piece');
      // Eksik alanlar varsayılan: çarpan 1, porsiyon null.
      expect(slot.items.last.quantity, 1);
      expect(slot.items.last.portionId, isNull);

      // items/mealKind vermeyen slot eski davranışta.
      final other = insertedPlans.single.days[1].slots.first;
      expect(other.mealKind, isNull);
      expect(other.items, isEmpty);
    });

    test('hedefler ve kurallar taşınır', () async {
      await importer.import(
        validate(validPlanMap()),
        acceptedNewExerciseIds: const {},
      );

      final plan = insertedPlans.single;
      expect(plan.goals.dailyKcal, 2400);
      expect(plan.goals.proteinG, 170);
      expect(plan.rules.forbidden, ['Alkol']);
    });

    test('ham JSON sourceRaw olarak saklanır', () async {
      final document = validPlanMap();
      await importer.import(
        validate(document),
        acceptedNewExerciseIds: const {},
      );

      expect(insertedPlans.single.sourceRaw, jsonEncode(document));
    });

    test('hareket ayrıntıları korunur', () async {
      await importer.import(
        validate(validPlanMap()),
        acceptedNewExerciseIds: const {},
      );

      final gymDay = insertedPlans.single.days.first;
      final bike = gymDay.exercises.single;
      expect(bike.exerciseId, 'stationary_bike');
      expect(bike.durationSec, 1500);
      expect(bike.intensity, 'direnç 5');
      // 1500 saniye kullanıcıya dakika olarak gösterilir.
      expect(bike.targetLabel, '25 dk');
    });

    test('id\'ler plan id\'sinden türetilir ve benzersizdir', () async {
      await importer.import(
        validate(validPlanMap()),
        acceptedNewExerciseIds: const {},
      );

      final plan = insertedPlans.single;
      final dayIds = plan.days.map((d) => d.id).toList();
      expect(dayIds.toSet().length, dayIds.length);
      expect(dayIds.first, startsWith(plan.id));

      final slotIds = [
        for (final day in plan.days) ...day.slots.map((s) => s.id),
      ];
      expect(slotIds.toSet().length, slotIds.length);
    });

    test('iki içe alma farklı plan id üretir', () async {
      await importer.import(
        validate(validPlanMap()),
        acceptedNewExerciseIds: const {},
      );
      await importer.import(
        validate(validPlanMap()),
        acceptedNewExerciseIds: const {},
      );

      expect(insertedPlans[0].id, isNot(insertedPlans[1].id));
    });
  });

  group('aşılama (v3 §9.1)', () {
    // Aktif plan 31 Ağustos'ta başlıyor; dönen belge 7 Eylül'den (2.
    // hafta) itibaren yenisini getiriyor.
    FullPlan activePlan() {
      final start = DateTime(2026, 8, 31);
      return FullPlan(
        id: 'active-1',
        title: 'Eski Plan',
        startDate: start,
        weeks: 2,
        goals: const PlanGoals(
          dailyKcal: 2200,
          proteinG: 160,
          waterL: 3,
          weeklyGym: 2,
          weeklyHome: 3,
          targetLossKg: 2,
        ),
        rules: const PlanRules(forbidden: ['alkol'], free: []),
        sourceRaw: '{"eski": true}',
        days: [
          for (var i = 0; i < 14; i++)
            FullPlanDay(
              id: 'active-1-d$i',
              date: start.add(Duration(days: i)),
              type: PlanDayType.home,
              weekIndex: i ~/ 7 + 1,
            ),
        ],
      );
    }

    PlanImporter graftImporter(FullPlan active, Set<String>? prunedKeep) =>
        PlanImporter(
          insertPlan: (plan) async => insertedPlans.add(plan),
          addExercise: (exercise) async => addedExercises.add(exercise),
          loadActivePlan: () async => active,
          pruneDays: (planId, keep) async {
            expect(planId, active.id);
            prunedKeep?.addAll(keep);
          },
        );

    Map<String, dynamic> incomingFrom(String startDate) {
      final document = validPlanMap();
      (document['meta'] as Map<String, dynamic>)['startDate'] = startDate;
      final days = document['days'] as List;
      final start = DateTime.parse(startDate);
      for (final (index, raw) in days.indexed) {
        (raw as Map<String, dynamic>)['date'] = [
          start.add(Duration(days: index)),
        ].map((d) =>
            '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}').single;
      }
      return document;
    }

    test('kesimden önceki günler korunur, sonrası değişir', () async {
      final keep = <String>{};
      final importer = graftImporter(activePlan(), keep);

      final result = await importer.import(
        validate(incomingFrom('2026-09-07')),
        acceptedNewExerciseIds: const {},
        graft: true,
      );

      expect(result.isOk, isTrue);
      final merged = insertedPlans.single;
      // Aynı plan güncellenir — yeni plan açılmaz.
      expect(merged.id, 'active-1');
      // 7 korunan + 7 yeni gün.
      expect(merged.days, hasLength(14));
      expect(
        merged.days.take(7).map((d) => d.id),
        everyElement(startsWith('active-1-d')),
      );
      expect(
        merged.days.skip(7).map((d) => d.id),
        everyElement(startsWith('active-1-g')),
      );
      // Budama korunacak günlerin tam kümesini alır.
      expect(keep, merged.days.map((d) => d.id).toSet());
    });

    test('startDate değişmez, weekIndex tarihten yeniden atanır', () async {
      final importer = graftImporter(activePlan(), null);
      await importer.import(
        validate(incomingFrom('2026-09-07')),
        acceptedNewExerciseIds: const {},
        graft: true,
      );

      final merged = insertedPlans.single;
      expect(merged.startDate, DateTime(2026, 8, 31));
      expect(merged.weeks, 2);
      // Dönen belge weekIndex=1 diyordu; tarih aritmetiği 2 der.
      expect(merged.days.last.weekIndex, 2);
      expect(merged.days.first.weekIndex, 1);
    });

    test('başlık ve hedefler dönen belgeden, sourceRaw eklenir', () async {
      final importer = graftImporter(activePlan(), null);
      await importer.import(
        validate(incomingFrom('2026-09-07')),
        acceptedNewExerciseIds: const {},
        graft: true,
      );

      final merged = insertedPlans.single;
      expect(merged.title, 'Eylül Planı');
      expect(merged.sourceRaw, contains('{"eski": true}'));
      expect(merged.sourceRaw, contains('aşılama (2026-09-07)'));
    });

    test('graft=false eski davranış — yeni plan açılır', () async {
      final importer = graftImporter(activePlan(), null);
      await importer.import(
        validate(incomingFrom('2026-09-07')),
        acceptedNewExerciseIds: const {},
      );
      expect(insertedPlans.single.id, isNot('active-1'));
    });
  });

  group('yeni hareketler', () {
    Map<String, dynamic> documentWithNew({bool useInPlan = false}) {
      final document = validPlanMap();
      (document['newExercises'] as List).add(validNewExercise());

      if (useInPlan) {
        final day = (document['days'] as List)[1] as Map<String, dynamic>;
        (day['exercises'] as List).add({
          'exerciseId': 'custom_burpee',
          'sets': 3,
          'reps': 8,
        });
      }
      return document;
    }

    test('onaylanan hareket kataloğa kullanıcı tanımlı olarak eklenir',
        () async {
      final result = await importer.import(
        validate(documentWithNew()),
        acceptedNewExerciseIds: const {'custom_burpee'},
      );

      expect(result.isOk, isTrue);
      expect((result as Ok<ImportSummary>).value.addedExercises, 1);
      expect(addedExercises.single.id, 'custom_burpee');
      expect(addedExercises.single.isUserDefined, isTrue);
      expect(addedExercises.single.nameTr, 'Burpee');
    });

    test('onaylanmayan hareket eklenmez', () async {
      final result = await importer.import(
        validate(documentWithNew()),
        acceptedNewExerciseIds: const {},
      );

      expect(result.isOk, isTrue);
      expect(addedExercises, isEmpty);
    });

    test('hareket plandan önce eklenir', () async {
      // Plan o id'ye referans veriyor; ters sırada eklenirse plan
      // bir an için tanımsız harekete işaret eder.
      final order = <String>[];
      final orderedImporter = PlanImporter(
        insertPlan: (_) async => order.add('plan'),
        addExercise: (_) async => order.add('exercise'),
      );

      await orderedImporter.import(
        validate(documentWithNew(useInPlan: true)),
        acceptedNewExerciseIds: const {'custom_burpee'},
      );

      expect(order, ['exercise', 'plan']);
    });

    test('planda kullanılan hareket onaylanmazsa import reddedilir', () async {
      final result = await importer.import(
        validate(documentWithNew(useInPlan: true)),
        acceptedNewExerciseIds: const {},
      );

      expect(result.isOk, isFalse);
      final message = (result as Err<ImportSummary>).failure.message;
      expect(message, contains('custom_burpee'));
      expect(message, contains('onaylamadın'));

      // Hiçbir şey yazılmamalı: yarım import bozuk plan bırakır.
      expect(insertedPlans, isEmpty);
      expect(addedExercises, isEmpty);
    });

    test('planda kullanılmayan hareket onaylanmasa da import geçer', () async {
      final result = await importer.import(
        validate(documentWithNew()),
        acceptedNewExerciseIds: const {},
      );

      expect(result.isOk, isTrue);
      expect(insertedPlans, hasLength(1));
    });
  });
}
