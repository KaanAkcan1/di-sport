import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_screen.dart';
import 'package:disport/features/catalog/presentation/exercise_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Egzersiz kütüphanesi: arama, filtre, liste.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(filteredExercisesProvider);

    return Column(
      children: [
        const _SearchField(),
        const _FilterBar(),
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

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(catalogFilterProvider);
    final notifier = ref.read(catalogFilterProvider.notifier);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        children: [
          for (final (location, label) in const [
            (ExerciseLocation.home, 'Ev'),
            (ExerciseLocation.gym, 'Salon'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(label),
                selected: filter.location == location,
                onSelected: (_) => notifier.toggleLocation(location),
              ),
            ),
          const _ChipDivider(),
          for (final (category, label) in const [
            (ExerciseCategory.strength, 'Kuvvet'),
            (ExerciseCategory.core, 'Gövde'),
            (ExerciseCategory.cardio, 'Kardiyo'),
            (ExerciseCategory.mobility, 'Hareketlilik'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(label),
                selected: filter.category == category,
                onSelected: (_) => notifier.toggleCategory(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipDivider extends StatelessWidget {
  const _ChipDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.md,
    ),
    child: VerticalDivider(
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.bottomBarClearance,
      ),
      // +1: listenin başındaki sonuç sayısı satırı
      itemCount: exercises.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              '${exercises.length} hareket',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final exercise = exercises[index - 1];
        return ExerciseListTile(
          exercise: exercise,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ExerciseDetailScreen(exerciseId: exercise.id),
            ),
          ),
        );
      },
    );
  }
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
