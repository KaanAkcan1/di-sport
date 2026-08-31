import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_screen.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Antrenman ekranındaki tek hareket kartı.
///
/// Üç bilgiyi bir arada verir: hedef, geçen seferki gerçekleşme, bugün
/// tamamlanan. Üçü olmadan kullanıcı "iyi gidiyor muyum" sorusunu
/// cevaplayamaz.
class ExerciseSetCard extends ConsumerWidget {
  const ExerciseSetCard({
    super.key,
    required this.planExercise,
    required this.isoDate,
    required this.doneSets,
    required this.onRest,
  });

  final PlanExercise planExercise;
  final String isoDate;
  final int doneSets;
  final void Function(int seconds) onRest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final totalSets = planExercise.sets ?? 1;
    final complete = doneSets >= totalSets;

    final exercise = ref
        .watch(exerciseByIdProvider(planExercise.exerciseId))
        .value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (complete)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: semantic.success,
                    ),
                  ),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExerciseDetailScreen(
                          exerciseId: planExercise.exerciseId,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            exercise?.nameTr ?? planExercise.exerciseId,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.info_outline,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            _TargetRow(planExercise: planExercise),
            _LastSessionRow(
              exerciseId: planExercise.exerciseId,
              isoDate: isoDate,
            ),

            if (exercise != null && exercise.cues.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final cue in exercise.cues.take(3))
                    Chip(
                      label: Text(cue),
                      visualDensity: VisualDensity.compact,
                      labelStyle: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ],

            const Divider(height: AppSpacing.xl2),

            Row(
              children: [
                _SetDots(total: totalSets, done: doneSets),
                const Spacer(),
                if (doneSets > 0)
                  IconButton(
                    key: Key('undo-${planExercise.exerciseId}'),
                    tooltip: 'Son seti geri al',
                    icon: const Icon(Icons.undo),
                    onPressed: () => ref
                        .read(workoutRepositoryProvider)
                        .undoLastSet(isoDate, planExercise.exerciseId),
                  ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  key: Key('done-set-${planExercise.exerciseId}'),
                  onPressed: complete
                      ? null
                      : () {
                          ref
                              .read(workoutRepositoryProvider)
                              .logSet(
                                isoDate: isoDate,
                                planExerciseId: planExercise.id,
                                exerciseId: planExercise.exerciseId,
                                setIndex: doneSets,
                                reps: planExercise.reps,
                                durationSec: planExercise.durationSec,
                              );

                          final rest = planExercise.restSec ?? 0;
                          if (rest > 0 && doneSets + 1 < totalSets) {
                            onRest(rest);
                          }
                        },
                  child: Text(complete ? 'Tamamlandı' : 'Set tamam'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.planExercise});

  final PlanExercise planExercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intensity = planExercise.intensity;

    return Row(
      children: [
        Text('Hedef: ', style: theme.textTheme.bodySmall),
        Text(
          planExercise.targetLabel,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (intensity != null) ...[
          Text(' · ', style: theme.textTheme.bodySmall),
          Text(intensity, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Geçen seferki gerçekleşme — hedefin altında, gri.
class _LastSessionRow extends ConsumerWidget {
  const _LastSessionRow({required this.exerciseId, required this.isoDate});

  final String exerciseId;
  final String isoDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actuals = ref
        .watch(lastActualsProvider(lastActualsKey(exerciseId, isoDate)))
        .value;

    if (actuals == null || actuals.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        'Geçen sefer: ${actuals.map((SetActual a) => a.shortLabel).join(' · ')}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Set sayacı — nokta olarak.
///
/// "2/3" okumak için durup düşünmek gerekir; dolu ve boş noktalar bir
/// bakışta okunur. Ekran okuyucuya sayı olarak bildiriliyor.
class _SetDots extends StatelessWidget {
  const _SetDots({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$done / $total set tamamlandı',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var index = 0; index < total; index++)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < done
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: index < done
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 1.5,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Text('$done / $total', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
