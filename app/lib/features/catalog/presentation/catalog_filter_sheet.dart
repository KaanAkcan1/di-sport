import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Katalog filtreleri — ⚙ düğmesinin açtığı alt sayfa.
///
/// **Neden alt sayfa:** filtreler ekranda üç ayrı satıra yayılmıştı ve
/// düzensiz görünüyordu. Yer sekmeye taşındı, arama kutuda kaldı;
/// geri kalan her şey tek bir kapının arkasında.
///
/// "Uygula" düğmesi yok: her dokunuş anında etkili. Onay düğmesi
/// kullanıcıyı sonucu görmeden karar vermeye zorlardı — oysa liste
/// arkada güncelleniyor ve alt sayfa kapanmadan sonuç sayısı görünüyor.
class CatalogFilterSheet extends ConsumerWidget {
  const CatalogFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final filter = ref.watch(catalogFilterProvider);
    final notifier = ref.read(catalogFilterProvider.notifier);
    final count = ref.watch(filteredExercisesProvider).value?.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.catalogFilters,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (filter.hiddenFilterCount > 0)
                  TextButton(
                    key: const Key('clear-hidden-filters'),
                    onPressed: notifier.clearHidden,
                    child: Text(l10n.commonClear),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            SwitchListTile(
              key: const Key('filter-my-equipment'),
              contentPadding: EdgeInsets.zero,
              value: filter.onlyMyEquipment,
              onChanged: (_) => notifier.toggleOnlyMyEquipment(),
              title: Text(l10n.catalogOnlyMyEquipment),
              subtitle: Text(l10n.catalogOnlyMyEquipmentDescription),
            ),

            const SizedBox(height: AppSpacing.lg),
            AppSectionLabel(l10n.catalogCategorySection),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (category, label) in [
                  (ExerciseCategory.strength, l10n.catalogCategoryStrength),
                  (ExerciseCategory.core, l10n.catalogCategoryCore),
                  (ExerciseCategory.cardio, l10n.catalogCategoryCardio),
                  (ExerciseCategory.mobility, l10n.catalogCategoryMobility),
                ])
                  FilterChip(
                    label: Text(label),
                    selected: filter.category == category,
                    onSelected: (_) => notifier.toggleCategory(category),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            AppSectionLabel(l10n.catalogDifficultySection),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var level = 1; level <= 5; level++)
                  FilterChip(
                    label: Text('$level'),
                    selected: filter.difficulty == level,
                    onSelected: (_) => notifier.toggleDifficulty(level),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            // Sonuç sayısı kapanmadan görünüyor: kullanıcı filtrenin
            // ne kadar daralttığını anında biliyor.
            Center(
              child: Text(
                count == null ? '' : l10n.catalogResultCount(count),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
