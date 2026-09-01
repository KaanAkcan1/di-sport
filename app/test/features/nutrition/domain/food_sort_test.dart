import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/domain/food_sort.dart';
import 'package:flutter_test/flutter_test.dart';

Food food(
  String id, {
  String? nameTr,
  String nameEn = '',
  double kcal = 100,
  double protein = 10,
}) => Food.fromJson({
  'id': id,
  'nameEn': nameEn.isEmpty ? id : nameEn,
  'nameTr': nameTr,
  'category': 'yemek',
  'kcal100': kcal,
  'protein100': protein,
  'source': 'curated',
});

void main() {
  final foods = [
    food('cilek', nameTr: 'Çilek', kcal: 33, protein: 0.7),
    food('ayran', nameTr: 'Ayran', kcal: 37, protein: 1.7),
    food('somon', nameTr: 'Somon', kcal: 208, protein: 20),
    food('irmik', nameTr: 'İrmik', kcal: 360, protein: 12.7),
  ];

  test('A–Z Türkçe katlamayla sıralar — Çilek İrmik ile doğru yerde', () {
    final sorted = sortFoods(foods, FoodSort.az);
    expect(sorted.map((f) => f.id), ['ayran', 'cilek', 'irmik', 'somon']);
  });

  test('kalori artan/azalan', () {
    expect(
      sortFoods(foods, FoodSort.kcalAsc).map((f) => f.id),
      ['cilek', 'ayran', 'somon', 'irmik'],
    );
    expect(
      sortFoods(foods, FoodSort.kcalDesc).first.id,
      'irmik',
    );
  });

  test('protein azalan', () {
    expect(sortFoods(foods, FoodSort.proteinDesc).first.id, 'somon');
  });

  test('sık yenen öne gelir, gerisi alfabetik arkaya düşer', () {
    final sorted = sortFoods(
      foods,
      FoodSort.frequent,
      frequentIds: ['somon', 'ayran'],
    );
    expect(sorted.map((f) => f.id), ['somon', 'ayran', 'cilek', 'irmik']);
  });

  test('girdi listesine dokunmaz', () {
    final before = [...foods.map((f) => f.id)];
    sortFoods(foods, FoodSort.kcalDesc);
    expect(foods.map((f) => f.id), before);
  });
}
