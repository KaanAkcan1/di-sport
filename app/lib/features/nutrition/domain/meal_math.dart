import 'package:disport/features/nutrition/domain/food.dart';

/// Bir öğün kaleminin gram ve besin değerleri — **saf**.
///
/// Üç giriş yolu var ve önceliği net: elle girilen gram > seçilen
/// porsiyon × çarpan > 100 gram. Kullanıcı gramı bilerek yazdıysa
/// porsiyon tahmininin onu ezmemesi gerekiyor.
({double grams, double kcal, double protein}) mealValues({
  required Food food,
  required double quantity,
  FoodPortion? portion,
  double? customGrams,
}) {
  final grams = switch (customGrams) {
    final value? when value > 0 => value,
    // Porsiyon yoksa 100 gram: besin değerleri zaten o birimde ve
    // kullanıcıya "kaç gram" diye sorabilmek için bir başlangıç lazım.
    _ => (portion?.grams ?? 100) * quantity,
  };

  final ratio = grams / 100;
  return (
    grams: grams,
    kcal: food.kcal100 * ratio,
    protein: food.protein100 * ratio,
  );
}
