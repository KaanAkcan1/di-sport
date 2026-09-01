import 'package:disport/app/shells/shell_header.dart';
import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/presentation/calorie_week_chart.dart';
import 'package:disport/features/nutrition/presentation/day_meals_card.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/nutrition/presentation/portion_sheet.dart';
import 'package:disport/features/nutrition/presentation/water_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Diyet sekmesi: GÜNLÜK · BESİNLER · GEÇMİŞ.
///
/// GÜNLÜK M13'te mevcut öğün kartını taşıyor — öğün kaydı M15'in
/// plan/gerçekleşen görünümü gelene kadar işlevsiz kalmasın. BESİNLER
/// v3'ün kapattığı boşluk: 368 kayıt ilk kez gezilebilir bir yerde.
class DietShell extends StatelessWidget {
  const DietShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppSegmentedShell(
      header: ShellHeader(title: l10n.tabDiet),
      labels: [l10n.dietTabDaily, l10n.dietTabFoods, l10n.dietTabHistory],
      children: const [_DailyTab(), _FoodsTab(), _HistoryTab()],
    );
  }
}

class _DailyTab extends StatelessWidget {
  const _DailyTab();

  @override
  Widget build(BuildContext context) => const AppScreenBody(
    children: [
      WaterRow(),
      SizedBox(height: AppSpacing.xl),
      DayMealsCard(),
    ],
  );
}

/// Besin listesi — M13 iskeleti.
///
/// Arama + liste; sıralama ve yasaklı rozetleri M15'te. Boş bir sekme
/// bırakmak yerine mevcut arama sağlayıcısıyla gezilebilir hâlde
/// açılıyor.
class _FoodsTab extends ConsumerWidget {
  const _FoodsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(foodSearchProvider);
    final results = ref.watch(foodResultsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.sm,
            AppSpacing.screenH,
            AppSpacing.sm,
          ),
          child: TextField(
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
        Expanded(
          child: AppAsyncView<List<Food>>(
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
              itemBuilder: (context, index) {
                final food = list[index];
                final portion = food.defaultPortion;
                return ListTile(
                  title: Text(foodDisplayName(context, food)),
                  subtitle: Text(
                    portion == null
                        ? context.l10n.foodPer100g(food.kcal100.round())
                        : context.l10n.foodPerPortion(
                            portionLabel(context, portion),
                            (food.kcal100 * portion.grams / 100).round(),
                          ),
                  ),
                  trailing: AppIconTile(
                    icon: foodCategoryIcon(food.category),
                    area: AppArea.diet,
                    small: true,
                  ),
                  onTap: () => showPortionSheet(context, food: food),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Kalori geçmişi — İlerleme'den taşındı.
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) => const AppScreenBody(
    children: [CalorieWeekChart()],
  );
}
