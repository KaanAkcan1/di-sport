import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yasaklı listesinin çift biçim sözleşmesi (v3 §5.4).
void main() {
  test('eski biçim (string listesi) okunur', () {
    final rules = PlanRules.fromJson({
      'forbidden': ['alkol', 'şeker'],
      'free': ['su'],
    });
    expect(rules.forbidden, ['alkol', 'şeker']);
    expect(rules.forbiddenFoodIds, isEmpty);
  });

  test('yeni biçim (label + foodIds) okunur, karışık liste de geçer', () {
    final rules = PlanRules.fromJson({
      'forbidden': [
        'alkol',
        {
          'label': 'hamur işi',
          'foodIds': ['lahmacun', 'pide'],
        },
        {'label': 'şeker', 'foodIds': <String>[]},
      ],
      'free': <String>[],
    });
    expect(rules.forbidden, ['alkol', 'hamur işi', 'şeker']);
    expect(rules.forbiddenFoodIds, {
      'hamur işi': ['lahmacun', 'pide'],
    });
  });

  test('yazma her zaman yeni biçimde ve gidiş-dönüş kayıpsız', () {
    const rules = PlanRules(
      forbidden: ['alkol', 'hamur işi'],
      forbiddenFoodIds: {
        'hamur işi': ['lahmacun'],
      },
      free: ['su'],
    );

    final json = rules.toJson();
    expect(json['forbidden'], [
      {'label': 'alkol', 'foodIds': <String>[]},
      {
        'label': 'hamur işi',
        'foodIds': ['lahmacun'],
      },
    ]);

    final roundTrip = PlanRules.fromJson(json);
    expect(roundTrip.forbidden, rules.forbidden);
    expect(roundTrip.forbiddenFoodIds, rules.forbiddenFoodIds);
    expect(roundTrip.free, rules.free);
  });
}
