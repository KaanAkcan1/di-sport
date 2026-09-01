import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/domain/recent_exercise_source.dart';
import 'package:disport/features/catalog/presentation/catalog_filter_sheet.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_screen.dart';
import 'package:disport/features/catalog/presentation/exercise_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Egzersiz kütüphanesi: yer sekmesi, arama, filtre, liste.
///
/// **M12'de değişen:** yer artık bir filtre değil **bağlam** — üstteki
/// sekme onu taşıyor. Geri kalan filtreler tek bir ⚙ düğmesinin
/// arkasında; ekranda üç düzensiz çip satırı vardı, biri kalktı ikisi
/// birleşti. Liste "son yaptıkların" ile açılıyor: katalog bir
/// ansiklopedi olmaktan çıkıp antrenman defterine bağlanıyor.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  /// Sekme sırası `_locations` ile aynı olmak zorunda.
  static const _locations = [ExerciseLocation.home, ExerciseLocation.gym];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _locations.length, vsync: this)
      ..addListener(_syncLocation);
    // İlk kare: sekme zaten "Evde"de duruyor, filtre de öyle olmalı.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLocation());
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_syncLocation)
      ..dispose();
    super.dispose();
  }

  void _syncLocation() {
    if (_tabs.indexIsChanging) return;
    ref
        .read(catalogFilterProvider.notifier)
        .setLocation(_locations[_tabs.index]);
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(filteredExercisesProvider);

    return Column(
      children: [
        // "Dışarıda" sekmesi M9'da geliyor: serbest aktiviteler
        // (basketbol, koşu) veri olarak henüz yok, boş sekme açmak
        // kullanıcıya kırık bir söz verirdi.
        TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Evde'), Tab(text: 'Salonda')],
        ),
        const _SearchRow(),
        const _ActiveFilterChips(),
        Expanded(
          child: AppAsyncView<List<Exercise>>(
            value: exercises,
            emptyWhen: (list) => list.isEmpty,
            empty: _NoResults(onClear: () {
              ref.read(catalogFilterProvider.notifier).clear();
            }),
            onRetry: () => ref.invalidate(filteredExercisesProvider),
            data: (list) => _ExerciseList(exercises: list),
          ),
        ),
      ],
    );
  }
}

/// Arama kutusu + ⚙ filtre düğmesi.
class _SearchRow extends ConsumerWidget {
  const _SearchRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(catalogFilterProvider).hiddenFilterCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Expanded(child: _SearchField()),
          const SizedBox(width: AppSpacing.sm),
          _FilterButton(activeCount: count),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.outlined(
          key: const Key('open-filters'),
          icon: const Icon(Icons.tune),
          tooltip: 'Filtreler',
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const CatalogFilterSheet(),
          ),
        ),
        if (activeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: AppRadius.fullAll,
              ),
              child: Text(
                '$activeCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Etkin filtreler — ×'li küçük etiketler.
///
/// Neyin süzüldüğü hep görünür olmalı: aksi hâlde katalog sessizce
/// küçülür ve kullanıcı bunun neden olduğunu anlamaz.
class _ActiveFilterChips extends ConsumerWidget {
  const _ActiveFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(catalogFilterProvider);
    final notifier = ref.read(catalogFilterProvider.notifier);

    if (filter.hiddenFilterCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          if (filter.onlyMyEquipment)
            _ActiveChip(
              label: 'Ekipmanıma uygun',
              onRemove: notifier.toggleOnlyMyEquipment,
            ),
          if (filter.category case final category?)
            _ActiveChip(
              label: switch (category) {
                ExerciseCategory.strength => 'Kuvvet',
                ExerciseCategory.core => 'Gövde',
                ExerciseCategory.cardio => 'Kardiyo',
                ExerciseCategory.mobility => 'Hareketlilik',
              },
              onRemove: () => notifier.toggleCategory(category),
            ),
          if (filter.difficulty case final level?)
            _ActiveChip(
              label: 'Zorluk $level',
              onRemove: () => notifier.toggleDifficulty(level),
            ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputChip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 15),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.07),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.tertiary,
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(catalogFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtre dışarıdan temizlenirse (boş durumdaki düğme) alan da
    // temizlenmeli; aksi halde kutuda yazı kalır ama liste dolu görünür.
    ref.listen(catalogFilterProvider, (previous, next) {
      if (next.query != _controller.text) _controller.text = next.query;
    });

    final hasText = _controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Hareket veya kas ara…',
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Aramayı temizle',
                  onPressed: () {
                    _controller.clear();
                    ref.read(catalogFilterProvider.notifier).setQuery('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          ref.read(catalogFilterProvider.notifier).setQuery(value);
          setState(() {}); // temizle düğmesinin görünürlüğü için
        },
      ),
    );
  }
}

class _ExerciseList extends ConsumerWidget {
  const _ExerciseList({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(catalogFilterProvider);
    final recent = ref.watch(recentExercisesProvider).value ?? const [];

    // "Son yaptıkların" yalnız süzülmemiş listede: kullanıcı arama
    // yaptığında sonuçların üstünde alakasız bir bölüm istemiyor.
    final byId = {for (final e in exercises) e.id: e};
    final showRecent = !filter.isActive || filter.location != null;
    final recentShown = <({RecentExercise entry, Exercise exercise})>[
      if (showRecent)
        for (final entry in recent)
          if (byId[entry.exerciseId] case final exercise?)
            (entry: entry, exercise: exercise),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.bottomBarClearance,
      ),
      children: [
        if (recentShown.isNotEmpty) ...[
          const AppSectionLabel('Son yaptıkların'),
          for (final row in recentShown)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ExerciseListTile(
                exercise: row.exercise,
                overline: row.entry.summary,
                onTap: () => _open(context, row.exercise),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppSectionLabel(
          recentShown.isEmpty ? 'Hareketler' : 'Tüm hareketler',
          trailing: Text(
            '${exercises.length}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final exercise in exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ExerciseListTile(
              exercise: exercise,
              onTap: () => _open(context, exercise),
            ),
          ),
      ],
    );
  }

  void _open(BuildContext context, Exercise exercise) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExerciseDetailScreen(exerciseId: exercise.id),
        ),
      );
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    icon: Icons.search_off,
    title: 'Eşleşen hareket yok',
    description: 'Aramayı değiştir ya da filtreleri kaldır.',
    actionLabel: 'Filtreleri temizle',
    onAction: onClear,
  );
}
