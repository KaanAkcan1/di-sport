import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:flutter/material.dart';

/// Besinin kullanıcıya görünen adı.
///
/// Katalog hareketlerinin kuralıyla aynı (spec §4.1): İngilizce arayüzde
/// yalnız `nameEn`, Türkçe arayüzde `nameTr` varsa o, yoksa `nameEn`.
/// Fark: besinde parantezli çift ad gösterilmiyor — "Elma (Apples,
/// raw)" satırı gereksiz uzatıyor ve kullanıcı besini markette değil
/// listede arıyor.
String foodDisplayName(BuildContext context, Food food) =>
    context.l10n.localeName == 'tr' ? food.displayNameTr : food.nameEn;

String activityDisplayName(BuildContext context, Activity activity) =>
    context.l10n.localeName == 'tr' ? activity.displayNameTr : activity.nameEn;

String portionLabel(BuildContext context, FoodPortion portion) =>
    context.l10n.localeName == 'tr' ? portion.labelTr : portion.labelEn;

String foodCategoryLabel(BuildContext context, FoodCategory category) {
  final l10n = context.l10n;
  return switch (category) {
    FoodCategory.yemek => l10n.foodCategoryYemek,
    FoodCategory.corba => l10n.foodCategoryCorba,
    FoodCategory.kahvaltilik => l10n.foodCategoryKahvaltilik,
    FoodCategory.meyve => l10n.foodCategoryMeyve,
    FoodCategory.sebze => l10n.foodCategorySebze,
    FoodCategory.kuruyemis => l10n.foodCategoryKuruyemis,
    FoodCategory.icecek => l10n.foodCategoryIcecek,
    FoodCategory.tahil => l10n.foodCategoryTahil,
    FoodCategory.etBalik => l10n.foodCategoryEtBalik,
    FoodCategory.sutUrunu => l10n.foodCategorySutUrunu,
    FoodCategory.atistirmalik => l10n.foodCategoryAtistirmalik,
    FoodCategory.diger => l10n.foodCategoryDiger,
  };
}

/// Tür ikonu.
///
/// **Neden ikon, görsel değil:** M12 taslağında tür kartlarında fotoğraf
/// vardı. 12 besin fotoğrafı ya lisanslı olacaktı ya da üretilecekti;
/// ikisi de bir tür kartı için fazla. İkon aynı işi görüyor — ayırt
/// edici olması yeterli, güzel olması gerekmiyor.
IconData foodCategoryIcon(FoodCategory category) => switch (category) {
  FoodCategory.yemek => Icons.dinner_dining,
  FoodCategory.corba => Icons.soup_kitchen,
  FoodCategory.kahvaltilik => Icons.egg_alt,
  FoodCategory.meyve => Icons.apple,
  FoodCategory.sebze => Icons.grass,
  FoodCategory.kuruyemis => Icons.spa,
  FoodCategory.icecek => Icons.local_cafe,
  FoodCategory.tahil => Icons.bakery_dining,
  FoodCategory.etBalik => Icons.set_meal,
  FoodCategory.sutUrunu => Icons.icecream,
  FoodCategory.atistirmalik => Icons.cookie,
  FoodCategory.diger => Icons.restaurant,
};

String mealKindLabel(BuildContext context, MealKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    MealKind.kahvalti => l10n.mealKahvalti,
    MealKind.araOgun => l10n.mealAraOgun,
    MealKind.ogle => l10n.mealOgle,
    MealKind.ikindi => l10n.mealIkindi,
    MealKind.aksam => l10n.mealAksam,
    MealKind.gece => l10n.mealGece,
  };
}

IconData mealKindIcon(MealKind kind) => switch (kind) {
  MealKind.kahvalti => Icons.wb_twilight,
  MealKind.araOgun => Icons.coffee,
  MealKind.ogle => Icons.lunch_dining,
  MealKind.ikindi => Icons.emoji_food_beverage,
  MealKind.aksam => Icons.dinner_dining,
  MealKind.gece => Icons.bedtime,
};
