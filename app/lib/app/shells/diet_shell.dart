import 'package:disport/app/shells/shell_header.dart';
import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/calorie_tone.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/domain/food_sort.dart';
import 'package:disport/features/nutrition/domain/forbidden_match.dart';
import 'package:disport/features/nutrition/presentation/calorie_week_chart.dart';
import 'package:disport/features/nutrition/presentation/day_meals_card.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/nutrition/presentation/forbidden_editor_screen.dart';
import 'package:disport/features/nutrition/presentation/portion_sheet.dart';
import 'package:disport/features/nutrition/presentation/water_row.dart';
import 'package:disport/features/plan/application/plan_providers.dart'
    show activePlanProvider;
import 'package:disport/features/plan/data/plan_repository.dart'
    show PlanRepository;
import 'package:disport/features/today/application/today_providers.dart'
    show todayIsoProvider;
import 'package:disport/features/today/presentation/today_screen.dart'
    show DayScreen;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      header: ShellHeader(
        title: l10n.tabDiet,
        actions: [
          ShellAction(
            key: const Key('open-forbidden-editor'),
            icon: LucideIcons.ban,
            tooltip: l10n.forbiddenTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ForbiddenEditorScreen(),
              ),
            ),
          ),
        ],
      ),
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

/// Besin listesi (v3 §5.2): arama + tür çipleri + sıralama + yasaklı
/// rozeti. 368 kayıt bellekte sıralanır.
class _FoodsTab extends ConsumerStatefulWidget {
  const _FoodsTab();

  @override
  ConsumerState<_FoodsTab> createState() => _FoodsTabState();
}

class _FoodsTabState extends ConsumerState<_FoodsTab> {
  var _sort = FoodSort.az;

  /// Öne çıkan sekiz tür (spec §5.2) — tam liste çip sırasını taşırırdı.
  static const _prominentCategories = [
    FoodCategory.yemek,
    FoodCategory.corba,
    FoodCategory.kahvaltilik,
    FoodCategory.meyve,
    FoodCategory.sebze,
    FoodCategory.etBalik,
    FoodCategory.sutUrunu,
    FoodCategory.icecek,
  ];

  String _sortLabel(BuildContext context, FoodSort sort) => switch (sort) {
    FoodSort.az => context.l10n.foodSortAz,
    FoodSort.kcalAsc => context.l10n.foodSortKcalAsc,
    FoodSort.kcalDesc => context.l10n.foodSortKcalDesc,
    FoodSort.proteinDesc => context.l10n.foodSortProteinDesc,
    FoodSort.frequent => context.l10n.foodSortFrequent,
  };

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(foodSearchProvider);
    final results = ref.watch(foodResultsProvider);
    final frequent =
        ref.watch(frequentFoodsProvider).value ?? const <Food>[];
    final rules = ref.watch(activePlanProvider).value?.rules;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.sm,
            AppSpacing.screenH,
            AppSpacing.xs,
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
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
            ),
            children: [
              // Sıralama solda tek menü: beş seçeneği çip olarak dizmek
              // tür çipleriyle karışırdı.
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: PopupMenuButton<FoodSort>(
                  key: const Key('food-sort-menu'),
                  initialValue: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (context) => [
                    for (final sort in FoodSort.values)
                      PopupMenuItem(
                        value: sort,
                        child: Text(_sortLabel(context, sort)),
                      ),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.sort, size: 16),
                    label: Text(_sortLabel(context, _sort)),
                  ),
                ),
              ),
              for (final category in _prominentCategories)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(foodCategoryLabel(context, category)),
                    selected: query.category == category,
                    onSelected: (_) => ref
                        .read(foodSearchProvider.notifier)
                        .toggleCategory(category),
                  ),
                ),
            ],
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
            data: (list) {
              final sorted = sortFoods(
                list,
                _sort,
                frequentIds: [for (final food in frequent) food.id],
              );
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
                itemCount: sorted.length,
                itemBuilder: (context, index) => _FoodRow(
                  food: sorted[index],
                  forbidden:
                      rules != null &&
                      isForbiddenFood(
                        food: sorted[index],
                        labels: rules.forbidden,
                        foodIds: rules.forbiddenFoodIds,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food, required this.forbidden});

  final Food food;
  final bool forbidden;

  @override
  Widget build(BuildContext context) {
    final portion = food.defaultPortion;
    // Porsiyon kalorisi ile 100 g değeri birlikte (spec §5.2): biri
    // "ne kadar yerim", öteki "ne kadar yoğun" sorusuna cevap.
    final per100 = context.l10n.foodPer100g(food.kcal100.round());
    final subtitle = portion == null
        ? per100
        : '${context.l10n.foodPerPortion(portionLabel(context, portion), (food.kcal100 * portion.grams / 100).round())} · $per100';

    return ListTile(
      title: Row(
        children: [
          Flexible(child: Text(foodDisplayName(context, food))),
          if (forbidden) ...[
            const SizedBox(width: AppSpacing.sm),
            AppStatusChip(
              status: AppStatus.bad,
              label: context.l10n.foodForbiddenBadge,
              compact: true,
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle),
      trailing: AppIconTile(
        icon: foodCategoryIcon(food.category),
        area: AppArea.diet,
        small: true,
      ),
      onTap: () => showPortionSheet(context, food: food),
    );
  }
}

/// Kalori geçmişi — İlerleme'den taşındı; gün dökümüyle (v3 §5.3).
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final todayIso = ref.watch(todayIsoProvider);
    final today = DateTime.parse(todayIso);
    final from = today.subtract(const Duration(days: 6));
    final goal = ref.watch(dailyKcalGoalProvider).value;
    final net =
        ref
            .watch(
              netKcalByDayProvider(
                PlanRepository.iso(from),
                PlanRepository.iso(today),
              ),
            )
            .value ??
        const <String, double>{};

    return AppScreenBody(
      children: [
        const CalorieWeekChart(),
        const SizedBox(height: AppSpacing.xl),
        AppSectionLabel(context.l10n.dietHistoryDays),
        for (var back = 0; back <= 6; back++)
          Builder(
            builder: (context) {
              final day = today.subtract(Duration(days: back));
              final iso = PlanRepository.iso(day);
              final value = net[iso];
              final tone = resolveCalorieTone(goalKcal: goal, net: value);

              return ListTile(
                key: Key('diet-history-$iso'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(TurkishDate.weekdayAndDay(day)),
                trailing: Text(
                  // Kayıtsız gün `—` — sıfır çizmek "hiç yemedin"
                  // derdi, oysa yalnız girilmedi (spec §5.3).
                  value == null ? '—' : '${value.round()} kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: switch (tone) {
                      DayCalorieTone.over => semantic.danger,
                      DayCalorieTone.under => semantic.success,
                      DayCalorieTone.none =>
                        theme.colorScheme.onSurfaceVariant,
                    },
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DayScreen(dateKey: iso),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
