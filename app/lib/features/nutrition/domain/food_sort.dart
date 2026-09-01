import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/nutrition/domain/food.dart';

/// Besin listesi sıralamaları (v3 §5.2). Bellekte sıralanır — 368
/// kayıt için sorguyu karmaşıklaştırmaya değmez.
enum FoodSort { az, kcalAsc, kcalDesc, proteinDesc, frequent }

/// Sıralanmış yeni liste döner — girdiye dokunmaz (saf).
///
/// [frequentIds] "sık yenen" sıralamasının kaynağı: id'ler sıklık
/// sırasında gelir, listede olmayan besinler alfabetik olarak arkaya
/// dizilir — hiç yenmemiş besin kaybolmaz, yalnız sona düşer.
List<Food> sortFoods(
  List<Food> foods,
  FoodSort sort, {
  List<String> frequentIds = const [],
}) {
  int byName(Food a, Food b) => TurkishText.fold(
    a.nameTr ?? a.nameEn,
  ).compareTo(TurkishText.fold(b.nameTr ?? b.nameEn));

  final sorted = [...foods];
  switch (sort) {
    case FoodSort.az:
      sorted.sort(byName);
    case FoodSort.kcalAsc:
      sorted.sort((a, b) {
        final compared = a.kcal100.compareTo(b.kcal100);
        return compared != 0 ? compared : byName(a, b);
      });
    case FoodSort.kcalDesc:
      sorted.sort((a, b) {
        final compared = b.kcal100.compareTo(a.kcal100);
        return compared != 0 ? compared : byName(a, b);
      });
    case FoodSort.proteinDesc:
      sorted.sort((a, b) {
        final compared = b.protein100.compareTo(a.protein100);
        return compared != 0 ? compared : byName(a, b);
      });
    case FoodSort.frequent:
      final rank = {
        for (final (index, id) in frequentIds.indexed) id: index,
      };
      sorted.sort((a, b) {
        final rankA = rank[a.id];
        final rankB = rank[b.id];
        if (rankA != null && rankB != null) return rankA.compareTo(rankB);
        if (rankA != null) return -1;
        if (rankB != null) return 1;
        return byName(a, b);
      });
  }
  return sorted;
}
