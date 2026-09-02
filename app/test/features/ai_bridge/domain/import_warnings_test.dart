import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/import_warnings.dart';
import 'package:disport/features/ai_bridge/domain/plan_json.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ai_fixtures.dart';

/// v3 §9.4 — uyarılar amber bilgidir, reddettirmez; o yüzden doğrulama
/// kapılarından ayrı sınanıyor.
void main() {
  PlanJson parse(Map<String, dynamic> document) {
    final result = fixtureValidator().validate(jsonEncode(document));
    if (result is! Ok<ValidatedPlan>) {
      fail((result as Err<ValidatedPlan>).failure.message);
    }
    return result.value.plan;
  }

  Map<String, dynamic> documentWith({
    List<Map<String, dynamic>>? items,
    String? mealKind,
    String? exerciseId,
  }) {
    final document = validPlanMap();
    final day0 = (document['days'] as List).first as Map<String, dynamic>;
    final slots = [
      for (final slot in day0['slots'] as List)
        Map<String, dynamic>.from(slot as Map),
    ];
    if (mealKind != null) slots[0]['mealKind'] = mealKind;
    if (items != null) slots[0]['items'] = items;
    day0['slots'] = slots;
    if (exerciseId != null) {
      // 1. gün fikstürde salon günü; ev hareketi oraya konursa
      // doğrulayıcı (haklı olarak) reddeder. Ev günü olan 2. gün
      // kullanılıyor — uyarı katmanı doğrulamanın ÜSTÜNE çalışır.
      final day1 = (document['days'] as List)[1] as Map<String, dynamic>;
      day1['exercises'] = [
        {'exerciseId': exerciseId, 'sets': 3, 'reps': 10},
      ];
    }
    return document;
  }

  List<ImportWarning> collect(
    Map<String, dynamic> document, {
    Set<String> knownFoods = const {'egg', 'cheese'},
    Map<String, List<String>> forbidden = const {},
    Map<String, ({List<String> equipment, String location})> facts =
        const {},
    Set<String> home = const {},
    Set<String> gym = const {},
    Map<String, String> behaviors = const {},
    Set<String> restricted = const {},
  }) => collectImportWarnings(
    plan: parse(document),
    knownFoodIds: knownFoods,
    forbiddenFoodIds: forbidden,
    exerciseFacts: facts,
    homeEquipment: home,
    gymEquipment: gym,
    mealBehaviorByKind: behaviors,
    restrictedExerciseIds: restricted,
  );

  test('temiz plan uyarı üretmez', () {
    expect(collect(documentWith()), isEmpty);
  });

  test('bilinmeyen ve yasaklı besin kalemleri uyarır', () {
    final warnings = collect(
      documentWith(
        mealKind: 'kahvalti',
        items: [
          {'foodId': 'egg'},
          {'foodId': 'no_such'},
          {'foodId': 'baklava'},
        ],
      ),
      knownFoods: const {'egg', 'baklava'},
      forbidden: const {
        'tatlı': ['baklava'],
      },
    );

    expect(
      warnings.map((w) => (w.kind, w.subject)),
      containsAll([
        (ImportWarningKind.unknownFood, 'no_such'),
        (ImportWarningKind.forbiddenFood, 'baklava'),
      ]),
    );
  });

  test('envanterle yapılamayan hareket uyarır, yapılabilen uyarmaz', () {
    final warnings = collect(
      documentWith(exerciseId: 'incline_pushup'),
      facts: const {
        'incline_pushup': (equipment: ['dumbbell'], location: 'home'),
      },
      home: const {'bands'},
    );
    expect(warnings.single.kind, ImportWarningKind.cannotPerform);

    final ok = collect(
      documentWith(exerciseId: 'incline_pushup'),
      facts: const {
        'incline_pushup': (equipment: ['dumbbell'], location: 'home'),
      },
      home: const {'dumbbell'},
    );
    expect(ok, isEmpty);
  });

  test('envanter istemeyen tür engel değildir', () {
    final warnings = collect(
      documentWith(exerciseId: 'incline_pushup'),
      facts: const {
        'incline_pushup': (equipment: ['bodyOnly'], location: 'home'),
      },
    );
    expect(warnings, isEmpty);
  });

  test('external öğüne plan ve farklı fixed öğün uyarır', () {
    final external = collect(
      documentWith(mealKind: 'kahvalti'),
      behaviors: const {'kahvalti': 'external'},
    );
    expect(external.single.kind, ImportWarningKind.externalMealPlanned);

    final fixed = collect(
      documentWith(
        mealKind: 'kahvalti',
        items: [
          {'foodId': 'egg'},
        ],
      ),
      behaviors: const {'kahvalti': 'fixed'},
    );
    expect(
      fixed.map((w) => w.kind),
      contains(ImportWarningKind.fixedMealDiffers),
    );
  });

  test('kısıt eşleşen hareket uyarır ve aynı özne tekrarlanmaz', () {
    final document = documentWith(exerciseId: 'incline_pushup');
    // Aynı hareketi üçüncü güne de koy — uyarı yine tek olmalı.
    final day2 = (document['days'] as List)[2] as Map<String, dynamic>;
    day2['exercises'] = [
      {'exerciseId': 'incline_pushup', 'sets': 3, 'reps': 10},
    ];

    final warnings = collect(
      document,
      restricted: const {'incline_pushup'},
    );
    expect(warnings, hasLength(1));
    expect(warnings.single.kind, ImportWarningKind.restrictionMatch);
  });
}
