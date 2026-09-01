import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/nutrition/presentation/portion_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Besin seçici.
///
/// **Boş bir arama kutusuyla açılmıyor.** Kullanıcının yediği şey büyük
/// ölçüde tekrar ediyor; "sık yediklerin" bölümü çoğu kaydı tek
/// dokunuşa indiriyor. Boş bir kutu ise her seferinde yazmayı
/// gerektirir ve kayıt hiç girilmez.
///
/// Doğrudan kaydetmiyor, [onPicked] ile sonucu geri veriyor: aynı
/// seçici M10'da plan editöründen de açılacak ve orada kayıt değil
/// plana ekleme yapılıyor.
class FoodPickerScreen extends ConsumerWidget {
  const FoodPickerScreen({
    super.key,
    required this.mealKind,
    required this.onPicked,
    this.onCopyLast,
  });

  final MealKind mealKind;

  /// Porsiyon sayfası onaylanınca çağrılır.
  final void Function(PortionChoice choice) onPicked;

  /// "Son girdiğini kopyala" — bu öğünde kayıt varsa görünür.
  final Future<int> Function()? onCopyLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(foodSearchProvider);
    final results = ref.watch(foodResultsProvider);
    final frequent = ref.watch(frequentFoodsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(mealKindLabel(context, mealKind))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: context.l10n.foodSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: context.l10n.commonClear,
                        onPressed: () =>
                            ref.read(foodSearchProvider.notifier).clear(),
                      ),
              ),
              onChanged: (value) =>
                  ref.read(foodSearchProvider.notifier).setText(value),
            ),
          ),
          _CategoryStrip(selected: query.category),
          Expanded(
            child: query.text.isEmpty && query.category == null
                ? _StartView(
                    frequent: frequent,
                    onCopyLast: onCopyLast,
                    onTap: (food) => _openPortion(context, food),
                  )
                : AppAsyncView(
                    value: results,
                    emptyWhen: (list) => list.isEmpty,
                    empty: AppEmptyState(
                      icon: Icons.no_food,
                      title: context.l10n.foodSearchEmptyTitle,
                      description: context.l10n.foodSearchEmptyMessage,
                    ),
                    data: (list) => ListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
                      itemCount: list.length,
                      itemBuilder: (context, index) => _FoodTile(
                        food: list[index],
                        onTap: () => _openPortion(context, list[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPortion(BuildContext context, Food food) async {
    final choice = await showPortionSheet(context, food: food);
    if (choice == null || !context.mounted) return;
    onPicked(choice);
    Navigator.of(context).pop();
  }
}

/// Tür kartları — arama yazmadan gezinmenin tek yolu.
class _CategoryStrip extends ConsumerWidget {
  const _CategoryStrip({required this.selected});

  final FoodCategory? selected;

  /// Ekranda öne çıkan sekiz tür.
  ///
  /// Enumda on iki var; kalanlar (`etBalik`, `sutUrunu`, `diger`,
  /// `tahil`) aramadan geliyor. Sekiz çip tek satıra sığıyor ve
  /// kullanıcı hangisine dokunacağına bakmadan karar verebiliyor;
  /// on iki çip iki satıra taşıp seçim yapmayı zorlaştırıyordu.
  static const _featured = [
    FoodCategory.yemek,
    FoodCategory.corba,
    FoodCategory.kahvaltilik,
    FoodCategory.meyve,
    FoodCategory.sebze,
    FoodCategory.kuruyemis,
    FoodCategory.icecek,
    FoodCategory.atistirmalik,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height: AppTouch.minSize,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _featured.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = _featured[index];
        return FilterChip(
          label: Text(foodCategoryLabel(context, category)),
          avatar: Icon(foodCategoryIcon(category), size: 18),
          selected: selected == category,
          onSelected: (_) => ref
              .read(foodSearchProvider.notifier)
              .toggleCategory(category),
        );
      },
    ),
  );
}

/// Arama boşken görünen açılış: kopyala + sık yedikler.
class _StartView extends StatelessWidget {
  const _StartView({
    required this.frequent,
    required this.onTap,
    this.onCopyLast,
  });

  final List<Food> frequent;
  final void Function(Food) onTap;
  final Future<int> Function()? onCopyLast;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
    children: [
      if (onCopyLast case final copy?)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.content_copy),
            label: Text(context.l10n.foodCopyLastMeal),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final l10n = context.l10n;

              final count = await copy();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    count == 0
                        ? l10n.foodCopyNothingToCopy
                        : l10n.foodCopyDone(count),
                  ),
                ),
              );
              if (count > 0) navigator.pop();
            },
          ),
        ),
      if (frequent.isNotEmpty) ...[
        AppSectionLabel(context.l10n.foodFrequentTitle),
        for (final food in frequent)
          _FoodTile(food: food, onTap: () => onTap(food)),
      ] else
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppEmptyState(
            icon: Icons.restaurant_menu,
            title: context.l10n.foodStartTitle,
            description: context.l10n.foodStartMessage,
          ),
        ),
    ],
  );
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.onTap});

  final Food food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portion = food.defaultPortion;

    return ListTile(
      onTap: onTap,
      title: Text(foodDisplayName(context, food)),
      subtitle: Text(
        portion == null
            ? context.l10n.foodPer100g(food.kcal100.round())
            : context.l10n.foodPerPortion(
                portionLabel(context, portion),
                (food.kcal100 * portion.grams / 100).round(),
              ),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Icon(
        foodCategoryIcon(food.category),
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
