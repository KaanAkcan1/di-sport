import 'package:disport/features/nutrition/domain/food.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const raw = {
    'id': 'mercimek_corbasi',
    'nameEn': 'Red Lentil Soup',
    'nameTr': 'Mercimek Çorbası',
    'category': 'corba',
    'kcal100': 62.0,
    'protein100': 3.1,
    'carb100': 9.4,
    'fat100': 1.4,
    'source': 'curated',
    'sourceRef': 'TÜBER 2022',
    'portions': [
      {
        'id': 'kase',
        'labelTr': '1 kase',
        'labelEn': '1 bowl',
        'grams': 250.0,
        'isDefault': true,
      },
      {'id': 'kupa', 'labelTr': '1 kupa', 'labelEn': '1 mug', 'grams': 200.0},
    ],
  };

  test('fromJson tüm alanları okur', () {
    final food = Food.fromJson(raw);

    expect(food.id, 'mercimek_corbasi');
    expect(food.nameTr, 'Mercimek Çorbası');
    expect(food.category, FoodCategory.corba);
    expect(food.kcal100, 62);
    expect(food.source, FoodSource.curated);
    expect(food.portions, hasLength(2));
    expect(food.portions.first.foodId, 'mercimek_corbasi');
  });

  test('gidiş-dönüş kaybetmez', () {
    final food = Food.fromJson(raw);
    final again = Food.fromJson(food.toJson());

    expect(again.id, food.id);
    expect(again.nameTr, food.nameTr);
    expect(again.kcal100, food.kcal100);
    expect(again.sourceRef, food.sourceRef);
    expect(again.portions.map((p) => p.grams), food.portions.map((p) => p.grams));
    expect(again.defaultPortion?.id, 'kase');
  });

  test('Türkçe adı olmayan kayıt İngilizcesini gösterir', () {
    // USDA'da karşılığı olmayan bir kayda ad uydurmak, kullanıcının
    // markette arayamayacağı bir sözcük üretmek olurdu.
    final food = Food.fromJson({
      'id': 'quinoa_cooked',
      'nameEn': 'Quinoa, cooked',
      'category': 'tahil',
      'kcal100': 120.0,
      'source': 'usda',
    });

    expect(food.nameTr, isNull);
    expect(food.displayNameTr, 'Quinoa, cooked');
  });

  test('porsiyonsuz kayıtta varsayılan porsiyon yok', () {
    final food = Food.fromJson({
      'id': 'apple_raw',
      'nameEn': 'Apple, raw',
      'category': 'meyve',
      'kcal100': 52.0,
    });

    expect(food.portions, isEmpty);
    expect(food.defaultPortion, isNull);
  });

  test('isDefault işaretlenmemişse ilk porsiyon varsayılan olur', () {
    final food = Food.fromJson({
      'id': 'x',
      'nameEn': 'X',
      'category': 'diger',
      'kcal100': 10.0,
      'portions': [
        {'id': 'a', 'labelTr': 'a', 'labelEn': 'a', 'grams': 50.0},
        {'id': 'b', 'labelTr': 'b', 'labelEn': 'b', 'grams': 90.0},
      ],
    });

    expect(food.defaultPortion?.id, 'a');
  });

  group('bilinmeyen enum değeri hata verir — sessiz düşüş yok', () {
    test('besin türü', () {
      // Kendi ürettiğimiz dosyada tanımadığımız değer bir yazım
      // hatasıdır; `diger`'e düşmesi onu gizlerdi.
      expect(() => FoodCategory.fromName('tatli'), throwsArgumentError);
    });

    test('kaynak', () {
      expect(() => FoodSource.fromName('scraped'), throwsArgumentError);
    });

    test('öğün', () {
      expect(() => MealKind.fromName('brunch'), throwsArgumentError);
    });
  });
}
