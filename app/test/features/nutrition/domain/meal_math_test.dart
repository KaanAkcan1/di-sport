import 'package:disport/features/nutrition/domain/calorie_budget.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/domain/meal_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kuruFasulye = Food(
    id: 'etli_kuru_fasulye',
    nameEn: 'White Beans with Beef',
    nameTr: 'Etli Kuru Fasulye',
    category: FoodCategory.yemek,
    kcal100: 108,
    protein100: 7.2,
    portions: [
      FoodPortion(
        id: 'kase',
        foodId: 'etli_kuru_fasulye',
        labelTr: '1 kase',
        labelEn: '1 bowl',
        grams: 250,
        isDefault: true,
      ),
    ],
  );

  group('mealValues', () {
    test('porsiyon × çarpan gramı verir', () {
      final result = mealValues(
        food: kuruFasulye,
        quantity: 3,
        portion: kuruFasulye.defaultPortion,
      );
      expect(result.grams, 750);
    });

    test('kcal ve protein gramla orantılı', () {
      final result = mealValues(
        food: kuruFasulye,
        quantity: 3,
        portion: kuruFasulye.defaultPortion,
      );
      expect(result.kcal, closeTo(810, 0.5));
      expect(result.protein, closeTo(54, 0.5));
    });

    test('yarım porsiyon da çalışır', () {
      final result = mealValues(
        food: kuruFasulye,
        quantity: 0.5,
        portion: kuruFasulye.defaultPortion,
      );
      expect(result.grams, 125);
      expect(result.kcal, closeTo(135, 0.5));
    });

    test('elle girilen gram porsiyonu ezer', () {
      // Kullanıcı tartmışsa tahminin onu geçersiz kılmaması gerekiyor.
      final result = mealValues(
        food: kuruFasulye,
        quantity: 3,
        portion: kuruFasulye.defaultPortion,
        customGrams: 180,
      );
      expect(result.grams, 180);
      expect(result.kcal, closeTo(194.4, 0.5));
    });

    test('porsiyon yoksa 100 gram varsayılır', () {
      const usdaElma = Food(
        id: 'apple_raw',
        nameEn: 'Apple, raw',
        category: FoodCategory.meyve,
        kcal100: 52,
      );
      final result = mealValues(food: usdaElma, quantity: 2);
      expect(result.grams, 200);
      expect(result.kcal, closeTo(104, 0.5));
    });
  });

  group('remainingBudget', () {
    test('hedef yoksa null — sıfır değil', () {
      // "0 kalori kaldın" demek, bütçesi olduğunu ve bitirdiğini
      // söylemek olurdu.
      expect(
        remainingBudget(
          goalKcal: null,
          day: const DayEnergy(eaten: 500),
        ),
        isNull,
      );
    });

    test('kalan = hedef − yenen + yakılan', () {
      expect(
        remainingBudget(
          goalKcal: 2200,
          day: const DayEnergy(eaten: 1800, burned: 400),
        ),
        closeTo(800, 0.001),
      );
    });

    test('aşımda negatif döner', () {
      expect(
        remainingBudget(
          goalKcal: 2000,
          day: const DayEnergy(eaten: 2350),
        ),
        closeTo(-350, 0.001),
      );
    });
  });

  group('gaugeFraction', () {
    test('kalanla aynı aritmetikten gelir', () {
      const day = DayEnergy(eaten: 1800, burned: 300);
      expect(gaugeFraction(goalKcal: 2000, day: day), closeTo(0.75, 0.001));
      expect(remainingBudget(goalKcal: 2000, day: day), closeTo(500, 0.001));
    });

    test('aşımda 1\'i geçer — kırpılmaz', () {
      // Kırpmak aşımın ne kadar olduğunu gizlerdi; tonu çağıran seçiyor.
      expect(
        gaugeFraction(goalKcal: 2000, day: const DayEnergy(eaten: 2400)),
        greaterThan(1),
      );
    });

    test('hedef yoksa ya da sıfırsa null', () {
      expect(gaugeFraction(goalKcal: null, day: const DayEnergy()), isNull);
      expect(gaugeFraction(goalKcal: 0, day: const DayEnergy()), isNull);
    });
  });
}
