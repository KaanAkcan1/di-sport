import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/presentation/activity_log_sheet.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/nutrition/presentation/food_picker_screen.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bugünün öğünleri ve serbest aktiviteleri.
///
/// **Öğün başlıkları ancak kayıt varsa çiziliyor.** Altı boş öğün
/// başlığı göstermek ekranı doldurup hiçbir şey söylemez; kullanıcı
/// zaten "ekle" düğmesiyle hangi öğüne yazacağını seçiyor.
class DayMealsCard extends ConsumerWidget {
  const DayMealsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isoDate = ref.watch(viewedDateProvider);
    final meals = ref.watch(dayMealsProvider(isoDate)).value ?? const [];
    final activities =
        ref.watch(dayActivitiesProvider(isoDate)).value ?? const [];

    final byMeal = <MealKind, List<MealEntry>>{};
    for (final entry in meals) {
      byMeal.putIfAbsent(entry.mealKind, () => []).add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(context.l10n.todayMealsTitle),

        for (final kind in MealKind.values)
          if (byMeal[kind] case final entries?)
            _MealGroup(kind: kind, entries: entries),

        if (meals.isEmpty)
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
  const _MealGroup({required this.kind, required this.entries});

  final MealKind kind;
  final List<MealEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = entries.fold(0.0, (sum, entry) => sum + entry.kcal);

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
              const Spacer(),
              Text(
                '${total.round()} kcal',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final entry in entries)
          Dismissible(
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
          ),
      ],
    );
  }
}
