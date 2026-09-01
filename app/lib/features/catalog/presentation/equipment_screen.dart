import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart'
    show profileEntriesProvider, profileRepositoryProvider;
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/data/favorite_sports_repository.dart';
import 'package:disport/features/catalog/domain/equipment_impact.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/equipment_labels.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart'
    show activityCatalogProvider;
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Salona gitme tercihi `profile_entries`e yazılır.
///
/// Ayrı tablo açmaya değmez: tek bayrak. Eski kurulumda anahtar yok —
/// o zaman salonda işaretli ekipman varsa "gidiyor" sayılır, kullanıcı
/// v2'de verdiği cevabı yeniden vermek zorunda kalmaz.
const _goesToGymKey = 'equipment.goesToGym';

/// Ekipman ve sporlar ekranı (v3 §3.3).
///
/// Üç segment: EVDE · SALONDA · SEVDİĞİN SPORLAR. Envanter katalog
/// filtresini ve AI belgesini besliyor; sevilen sporlar AI belgesine
/// ayrı bölüm olarak gidiyor. "Etkisi" paneli işaretlerin ne işe
/// yaradığını sayıyla gösteriyor — soyut bir form doldurma hissi
/// yerine "3 işaret = 41 hareket".
class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  var _segment = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogEquipmentTitle)),
      floatingActionButton: _segment == 2
          ? null
          : FloatingActionButton.extended(
              key: const Key('add-equipment-fab'),
              onPressed: () => _addEquipment(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.catalogEquipmentAddFab),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          AppSegmented(
            labels: [
              l10n.equipmentTabHome,
              l10n.equipmentTabGym,
              l10n.equipmentTabSports,
            ],
            index: _segment,
            onChanged: (i) => setState(() => _segment = i),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: switch (_segment) {
              0 => const _EquipmentTab(where: ExerciseLocation.home),
              1 => const _GymTab(),
              _ => const _SportsTab(),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addEquipment(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.catalogEquipmentAddTitle),
        content: TextField(
          key: const Key('equipment-label'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.catalogEquipmentFieldLabel,
            hintText: l10n.catalogEquipmentFieldHint,
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-add-equipment'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.catalogEquipmentAddAction),
          ),
        ],
      ),
    );
    controller.dispose();

    if (label == null || label.trim().isEmpty) return;
    await ref.read(equipmentRepositoryProvider).add(label);
  }
}

/// Ev ya da salon envanter listesi + "Etkisi" paneli.
class _EquipmentTab extends ConsumerWidget {
  const _EquipmentTab({required this.where});

  final ExerciseLocation where;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(equipmentItemsProvider);
    final catalog = ref.watch(allExercisesProvider).value ?? const <Exercise>[];
    final repository = ref.watch(equipmentRepositoryProvider);
    final isHome = where == ExerciseLocation.home;

    return AppAsyncView<List<EquipmentItem>>(
      value: items,
      onRetry: () => ref.invalidate(equipmentItemsProvider),
      data: (list) {
        final selectable = [
          for (final item in list)
            if (item.isSelectable) item,
        ];
        final owned = {
          for (final item in selectable)
            if (isHome ? item.atHome : item.atGym) item.kind,
        };
        final doable = doableCount(catalog, owned, where);

        return AppScreenBody(
          children: [
            AppPanel(
              child: Row(
                children: [
                  const AppIconTile(
                    icon: LucideIcons.dumbbell,
                    area: AppArea.sport,
                    small: true,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      isHome
                          ? l10n.equipmentImpactHome(doable)
                          : l10n.equipmentImpactGym(doable),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final item in selectable)
              _EquipmentRow(
                item: item,
                checked: isHome ? item.atHome : item.atGym,
                // Açılacak hareket sayısı işaretsiz satırda anlamlı;
                // işaretli satıra "+0" yazmak gürültü.
                unlocks: unlockCount(catalog, owned, where, item.kind),
                onChanged: (value) => repository.setOwnedAt(
                  item.id,
                  atHome: isHome ? value : null,
                  atGym: isHome ? null : value,
                ),
              ),
            const SizedBox(height: AppSpacing.xl4 * 2),
          ],
        );
      },
    );
  }
}

class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({
    required this.item,
    required this.checked,
    required this.unlocks,
    required this.onChanged,
  });

  final EquipmentItem item;
  final bool checked;
  final int unlocks;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return InkWell(
      key: Key('equipment-row-${item.id}'),
      onTap: () => onChanged(!checked),
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Checkbox(
              key: Key('equipment-check-${item.id}'),
              value: checked,
              onChanged: (value) => onChanged(value ?? false),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(equipmentLabel(context, item.kind))),
            if (!checked && unlocks > 0)
              Text(
                l10n.equipmentUnlocks(unlocks),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Salon segmenti: önce "salona gidiyor musun" anahtarı.
class _GymTab extends ConsumerWidget {
  const _GymTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = ref.watch(profileEntriesProvider).value;
    final items = ref.watch(equipmentItemsProvider).value;
    if (profile == null || items == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Anahtar hiç yazılmamışsa v2 davranışı korunur: salonda işaretli
    // ekipmanı olan kullanıcı "gidiyor" sayılır.
    final stored = profile[_goesToGymKey];
    final goesToGym = stored == null
        ? items.any((item) => item.atGym)
        : stored == '1';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('goes-to-gym-switch'),
          title: Text(l10n.equipmentGymToggle),
          value: goesToGym,
          onChanged: (value) => ref
              .read(profileRepositoryProvider)
              .set(_goesToGymKey, value ? '1' : '0'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
          ),
        ),
        if (!goesToGym)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            child: Text(
              l10n.equipmentGymOffBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          const Expanded(
            child: _EquipmentTab(where: ExerciseLocation.gym),
          ),
      ],
    );
  }
}

/// Sevilen sporlar segmenti: arama + çoklu seçim + sıklık notu.
class _SportsTab extends ConsumerStatefulWidget {
  const _SportsTab();

  @override
  ConsumerState<_SportsTab> createState() => _SportsTabState();
}

class _SportsTabState extends ConsumerState<_SportsTab> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final favorites =
        ref.watch(favoriteSportsProvider).value ?? const <FavoriteSport>[];
    final favoriteIds = {for (final f in favorites) f.activityId};
    final results =
        ref.watch(activityCatalogProvider(_query)).value ??
        const <Activity>[];

    return AppScreenBody(
      children: [
        Text(
          l10n.sportsIntro,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (favorites.isNotEmpty) ...[
          AppSectionLabel(
            l10n.sportsChosen,
            trailing: Text('${favorites.length}'),
          ),
          for (final favorite in favorites)
            _FavoriteRow(
              favorite: favorite,
              activity: _findActivity(results, favorite.activityId),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        TextField(
          key: const Key('sports-search'),
          decoration: InputDecoration(
            hintText: l10n.sportsSearchHint,
            prefixIcon: const Icon(Icons.search, size: 20),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final activity in results)
              if (!favoriteIds.contains(activity.id))
                ActionChip(
                  key: Key('sport-add-${activity.id}'),
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(_activityName(context, activity)),
                  onPressed: () => ref
                      .read(favoriteSportsRepositoryProvider)
                      .toggle(activity.id),
                ),
          ],
        ),
      ],
    );
  }

  Activity? _findActivity(List<Activity> pool, String id) {
    for (final activity in pool) {
      if (activity.id == id) return activity;
    }
    return null;
  }
}

class _FavoriteRow extends ConsumerWidget {
  const _FavoriteRow({required this.favorite, required this.activity});

  final FavoriteSport favorite;

  /// Arama süzgeci seçili sporu dışarıda bırakmış olabilir; ad
  /// bulunamazsa kimlik gösterilir — satır asla kaybolmaz.
  final Activity? activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final name = activity == null
        ? favorite.activityId
        : _activityName(context, activity!);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const AppIconTile(
            icon: LucideIcons.bike,
            area: AppArea.sport,
            small: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium),
                if (favorite.note case final note?)
                  Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: Key('sport-note-${favorite.activityId}'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: l10n.sportsNoteTooltip,
            onPressed: () => _editNote(context, ref),
          ),
          IconButton(
            key: Key('sport-remove-${favorite.activityId}'),
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.commonDelete,
            onPressed: () => ref
                .read(favoriteSportsRepositoryProvider)
                .toggle(favorite.activityId),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: favorite.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sportsNoteTitle),
        content: TextField(
          key: const Key('sport-note-field'),
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.sportsNoteHint),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;
    await ref
        .read(favoriteSportsRepositoryProvider)
        .setNote(favorite.activityId, note);
  }
}

/// Aktivite adı — katalog kuralı (§4.1): TR arayüzde `nameTr` varsa o,
/// yoksa İngilizcesi.
String _activityName(BuildContext context, Activity activity) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'tr' && (activity.nameTr ?? '').isNotEmpty) {
    return activity.nameTr!;
  }
  return activity.nameEn;
}
