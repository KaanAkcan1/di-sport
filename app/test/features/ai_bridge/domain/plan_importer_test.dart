import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_importer.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
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
