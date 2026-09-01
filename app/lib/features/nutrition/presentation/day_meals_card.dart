import 'dart:convert';

import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/domain/meal_math.dart';
import 'package:disport/features/nutrition/presentation/activity_log_sheet.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/nutrition/presentation/food_picker_screen.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/settings/application/meal_behavior_providers.dart';
import 'package:disport/features/settings/domain/meal_behavior.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günün öğünleri: plan ve gerçekleşen bir arada (v3 §5.1).
///
/// Her öğün grubunda gerçekleşen kayıtlar dolu satır, plandan gelip
/// henüz kayda dönmemiş kalemler soluk + italik + `PLAN` rozetli satır.
/// "Plandaki gibi yedim" plan kalemlerini tek dokunuşta kayda çevirir;
/// `fixed` öğünde düğme "Her zamanki" olur ve bağlı kalemleri yazar.
/// `external` öğünde plan beklentisi yok — yalnız serbest giriş.
class DayMealsCard extends ConsumerWidget {
  const DayMealsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isoDate = ref.watch(viewedDateProvider);
    final meals = ref.watch(dayMealsProvider(isoDate)).value ?? const [];
    final activities =
        ref.watch(dayActivitiesProvider(isoDate)).value ?? const [];
    final planDay = ref.watch(dayPlanDayProvider(isoDate)).value;
    final behaviors =
        ref.watch(mealBehaviorsProvider).value ?? const <MealBehaviorEntry>[];

    final byMeal = <MealKind, List<MealEntry>>{};
    for (final entry in meals) {
      byMeal.putIfAbsent(entry.mealKind, () => []).add(entry);
    }

    final slotByMeal = <MealKind, PlanSlot>{};
    if (planDay != null) {
      for (final slot in planDay.slots) {
        if (slot.kind != SlotKind.meal) continue;
        final meal = slot.mealKind;
        if (meal == null) continue;
        // Aynı öğüne iki slot yazılmışsa ilki kazanır — çizelgede öğün
        // günde bir kez.
        slotByMeal.putIfAbsent(meal, () => slot);
      }
    }
    final behaviorByMeal = {for (final b in behaviors) b.meal: b};

    final visibleKinds = [
      for (final kind in MealKind.values)
        if (_groupVisible(
          entries: byMeal[kind],
          slot: slotByMeal[kind],
          behavior: behaviorByMeal[kind],
        ))
          kind,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(context.l10n.todayMealsTitle),

        for (final kind in visibleKinds)
          _MealGroup(
            kind: kind,
            isoDate: isoDate,
            entries: byMeal[kind] ?? const [],
            slot: slotByMeal[kind],
            behavior: behaviorByMeal[kind],
          ),

        if (visibleKinds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              context.l10n.foodStartMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(context.l10n.todayAddMeal),
              onPressed: () => _pickMeal(context, ref, isoDate),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.directions_run),
              label: Text(context.l10n.todayAddActivity),
              onPressed: () => showActivityLogSheet(context, isoDate: isoDate),
            ),
          ],
        ),

        if (activities.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          AppSectionLabel(context.l10n.todayActivitiesTitle),
          for (final log in activities)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.directions_run),
              title: Text(log.activityName ?? log.activityId),
              subtitle: Text('${log.minutes} dk'),
              trailing: Text('≈${log.kcal.round()} kcal'),
              onLongPress: () => ref
                  .read(activitiesRepositoryProvider)
                  .removeLog(log.id),
            ),
        ],
      ],
    );
  }

  static bool _groupVisible({
    List<MealEntry>? entries,
    PlanSlot? slot,
    MealBehaviorEntry? behavior,
  }) {
    if (entries != null && entries.isNotEmpty) return true;
    final kind = behavior?.behavior ?? MealBehavior.planned;
    // Dışarıda yenen öğünün boş grubu çizilmez: plan beklentisi yok,
    // boş bir başlık yalnız suçluluk üretirdi.
    if (kind == MealBehavior.external) return false;
    if (kind == MealBehavior.fixed) {
      return (behavior?.fixedNote ?? '').isNotEmpty ||
          (behavior?.fixedItemsJson ?? '').isNotEmpty;
    }
    return slot != null && slot.items.isNotEmpty;
  }

  /// Önce hangi öğün, sonra ne yenildi.
  ///
  /// Sıra bilinçli: kullanıcı "öğle yemeğine tavuk ekleyeceğim" diye
  /// düşünüyor, "tavuğu öğle yemeğine" diye değil. Ters sırada besini
  /// seçtikten sonra öğün sormak, seçimi yaptıktan sonra bağlam
  /// istemek olurdu.
  Future<void> _pickMeal(
    BuildContext context,
    WidgetRef ref,
    String isoDate,
  ) async {
    final kind = await showModalBottomSheet<MealKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final kind in MealKind.values)
              ListTile(
                leading: Icon(mealKindIcon(kind)),
                title: Text(mealKindLabel(context, kind)),
                onTap: () => Navigator.of(context).pop(kind),
              ),
          ],
        ),
      ),
    );

    if (kind == null || !context.mounted) return;

    final repository = ref.read(nutritionRepositoryProvider);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FoodPickerScreen(
          mealKind: kind,
          onCopyLast: () =>
              repository.copyMeal(mealKind: kind, toIsoDate: isoDate),
          onPicked: (choice) => repository.addEntry(
            food: choice.food,
            mealKind: kind,
            isoDate: isoDate,
            quantity: choice.quantity,
            portion: choice.portion,
            customGrams: choice.customGrams,
          ),
        ),
      ),
    );
  }
}

class _MealGroup extends ConsumerWidget {
  const _MealGroup({
    required this.kind,
    required this.isoDate,
    required this.entries,
    this.slot,
    this.behavior,
  });

  final MealKind kind;
  final String isoDate;
  final List<MealEntry> entries;
  final PlanSlot? slot;
  final MealBehaviorEntry? behavior;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final behaviorKind = behavior?.behavior ?? MealBehavior.planned;
    final total = entries.fold(0.0, (sum, entry) => sum + entry.kcal);

    // Plan kalemleri: yalnız `planned` davranışta ve kayda dönmemişler.
    final loggedFoodIds = {for (final e in entries) e.foodId};
    final planItems = behaviorKind == MealBehavior.planned
        ? [
            for (final item in slot?.items ?? const <PlanMealItem>[])
              if (!loggedFoodIds.contains(item.foodId)) item,
          ]
        : const <PlanMealItem>[];

    // PLANA UYGUN rozeti: plan toplamı çözülebildiyse ve gerçekleşen
    // ±%15 içindeyse. Besinler hâlâ yükleniyorsa rozet çizilmez —
    // yanlış rozet, geç rozetten kötü.
    double? planTotal;
    if (behaviorKind == MealBehavior.planned &&
        (slot?.items.isNotEmpty ?? false)) {
      var sum = 0.0;
      var resolved = true;
      for (final item in slot!.items) {
        final food = ref.watch(foodByIdProvider(item.foodId)).value;
        if (food == null) {
          resolved = false;
          break;
        }
        FoodPortion? portion;
        for (final candidate in food.portions) {
          if (candidate.id == item.portionId) portion = candidate;
        }
        sum += mealValues(
          food: food,
          quantity: item.quantity,
          portion: portion,
        ).kcal;
      }
      if (resolved) planTotal = sum;
    }
    final compliant =
        planTotal != null &&
        planTotal > 0 &&
        entries.isNotEmpty &&
        (total - planTotal).abs() / planTotal <= 0.15;

    final fixedItems = _fixedItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            children: [
              Icon(mealKindIcon(kind), size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                mealKindLabel(context, kind),
                style: theme.textTheme.titleSmall,
              ),
              if (compliant) ...[
                const SizedBox(width: AppSpacing.sm),
                AppStatusChip(
                  status: AppStatus.good,
                  label: l10n.dietPlanCompliantBadge,
                  compact: true,
                ),
              ],
              const Spacer(),
              if (entries.isNotEmpty)
                Text(
                  '${total.round()} kcal',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),

        for (final entry in entries) _EntryRow(entry: entry),

        if (behaviorKind == MealBehavior.external && entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              l10n.dietExternalMeal,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        if (behaviorKind == MealBehavior.fixed &&
            (behavior?.fixedNote ?? '').isNotEmpty &&
            entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              l10n.dietFixedUnbound(behavior!.fixedNote!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        for (final item in planItems)
          _PlanItemRow(key: Key('plan-item-${item.foodId}'), item: item),

        if (planItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: OutlinedButton.icon(
              key: Key('ate-as-planned-${kind.name}'),
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(l10n.dietAteAsPlanned),
              onPressed: () => ref
                  .read(nutritionRepositoryProvider)
                  .addResolvedItems(
                    isoDate: isoDate,
                    mealKind: kind,
                    slotId: slot?.id,
                    items: [
                      for (final item in planItems)
                        (
                          foodId: item.foodId,
                          quantity: item.quantity,
                          portionId: item.portionId,
                        ),
                    ],
                  ),
            ),
          ),

        // "Her zamanki": yalnız kalem bağı varsa. Bağsız sabit öğünde
        // düğme çizilmez — kalorisiz kayıt yazılmaz (spec §3.4).
        if (behaviorKind == MealBehavior.fixed &&
            fixedItems.isNotEmpty &&
            entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: OutlinedButton.icon(
              key: Key('ate-usual-${kind.name}'),
              icon: const Icon(Icons.replay, size: 18),
              label: Text(l10n.dietAteUsual),
              onPressed: () => ref
                  .read(nutritionRepositoryProvider)
                  .addResolvedItems(
                    isoDate: isoDate,
                    mealKind: kind,
                    items: fixedItems,
                  ),
            ),
          ),
      ],
    );
  }

  List<({String foodId, double quantity, String? portionId})> _fixedItems() {
    final raw = behavior?.fixedItemsJson;
    if (raw == null || raw.isEmpty) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List)
          (
            foodId: (item as Map)['foodId'] as String,
            quantity: ((item['quantity'] as num?) ?? 1).toDouble(),
            portionId: item['portionId'] as String?,
          ),
      ];
    } on FormatException {
      // Bozuk bağ düğmeyi gizler; öğün serbest girişe düşer.
      return const [];
    } on TypeError {
      return const [];
    }
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry});

  final MealEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: context.semantic.danger,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Icon(Icons.delete_outline),
          ),
        ),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final label = context.l10n.mealEntryRemoved;
        await ref.read(nutritionRepositoryProvider).removeEntry(entry.id);
        messenger.showSnackBar(SnackBar(content: Text(label)));
      },
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(entry.foodName ?? entry.foodId),
        subtitle: Text('${entry.grams.round()} g'),
        trailing: Text('${entry.kcal.round()} kcal'),
      ),
    );
  }
}

/// Plandan gelen, henüz kayda dönmemiş öneri satırı.
///
/// Soluk ve italik: bu bir kayıt değil, bir beklenti. `PLAN` rozeti
/// renkten bağımsız aynı şeyi söylüyor.
class _PlanItemRow extends ConsumerWidget {
  const _PlanItemRow({super.key, required this.item});

  final PlanMealItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final food = ref.watch(foodByIdProvider(item.foodId)).value;

    final muted = theme.colorScheme.onSurfaceVariant;
    String? subtitle;
    if (food != null) {
      FoodPortion? portion;
      for (final candidate in food.portions) {
        if (candidate.id == item.portionId) portion = candidate;
      }
      final values = mealValues(
        food: food,
        quantity: item.quantity,
        portion: portion,
      );
      subtitle = '${values.grams.round()} g · ≈${values.kcal.round()} kcal';
    }

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        food == null ? item.foodId : foodDisplayName(context, food),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: muted,
          fontStyle: FontStyle.italic,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
            )),
      trailing: Text(
        context.l10n.dietPlanBadge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: muted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
