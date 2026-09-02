import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_text.dart';
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

            const SizedBox(height: AppSpacing.md),
            _ReferenceColumns(
              planExercise: planExercise,
              isoDate: isoDate,
            ),

            if (exercise != null &&
                exercise
                    .contentFor(Localizations.localeOf(context).languageCode)
                    .cues
                    .isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final cue in exercise
                      .contentFor(Localizations.localeOf(context).languageCode)
                      .cues
                      .take(3))
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
                    tooltip: context.l10n.workoutUndoLastSet,
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
                  child: Text(
                    complete
                        ? context.l10n.workoutAllSetsDone
                        : context.l10n.workoutSetDone,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hedef ve geçen seans — iki soluk sütun.
///
/// **Neden iki sütun:** hedef tek başına "iyi gidiyor muyum" sorusunu
/// cevaplamıyor. Hevy'nin deseni: geçen seferki gerçekleşme hedefin
/// yanında durur ve oyunun kendisi onu geçmek olur. Önceden geçen seans
/// hedefin altında düz bir cümleydi ve kıyas kurmak için okumak
/// gerekiyordu; sütun hâlinde göz kendiliğinden karşılaştırıyor.
///
/// Geçen seans yoksa o sütun **hiç çizilmiyor** — boş bir "—" kıyas
/// varmış gibi görünürdü.
class _ReferenceColumns extends ConsumerWidget {
  const _ReferenceColumns({required this.planExercise, required this.isoDate});

  final PlanExercise planExercise;
  final String isoDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actuals =
        ref
            .watch(
              lastActualsProvider(
                lastActualsKey(planExercise.exerciseId, isoDate),
              ),
            )
            .value ??
        const <SetActual>[];

    final intensity = planExercise.intensity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actuals.isNotEmpty) ...[
          _RefColumn(
            caption: context.l10n.workoutRefLast,
            value: actuals.map((a) => a.shortLabel).join('/'),
          ),
          const SizedBox(width: AppSpacing.xl),
        ],
        _RefColumn(
          caption: context.l10n.workoutRefPlan,
          value: planExercise.targetLabel,
          note: intensity,
          accent: true,
        ),
      ],
    );
  }
}

class _RefColumn extends StatelessWidget {
  const _RefColumn({
    required this.caption,
    required this.value,
    this.note,
    this.accent = false,
  });

  final String caption;
  final String value;
  final String? note;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$caption: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TurkishText.upper(caption),
            style: AppTypography.statCaption.copyWith(
              fontSize: 9,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.metricSmall.copyWith(
                  color: accent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (note case final n?) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  n,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
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
      label: context.l10n.workoutSetsDoneSemantics(done, total),
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
