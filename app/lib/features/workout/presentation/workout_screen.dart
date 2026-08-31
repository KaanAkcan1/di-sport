import 'dart:async';

import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:disport/features/workout/presentation/exercise_set_card.dart';
import 'package:disport/features/workout/presentation/rest_timer_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Antrenman akışı: hareketler sırayla, set sayacı, dinlenme geri sayımı.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.day});

  final FullPlanDay day;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Timer? _restTimer;
  var _restRemaining = 0;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() => _restRemaining = seconds);

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _restRemaining--);
      if (_restRemaining <= 0) timer.cancel();
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  /// Tüm setler tamamlanınca günün antrenman kutucuğunu işaretler.
  ///
  /// Kullanıcının aynı bilgiyi iki kez girmesi gerekmiyor: Bugün
  /// ekranındaki kutucuk buradan doluyor.
  Future<void> _syncWorkoutFlag(Map<String, int> counts) async {
    final allDone = widget.day.exercises.every(
      (exercise) => (counts[exercise.exerciseId] ?? 0) >= (exercise.sets ?? 1),
    );
    if (!allDone) return;

    final iso = PlanRepository.iso(widget.day.date);
    final log = await ref.read(todayRepositoryProvider).readDay(iso);
    if (log.workoutDone) return;

    await ref.read(todayRepositoryProvider).setFlags(iso, workoutDone: true);
  }

  @override
  Widget build(BuildContext context) {
    final iso = PlanRepository.iso(widget.day.date);
    final counts = ref.watch(doneSetCountsProvider(iso));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: _ProgressLine(day: widget.day, counts: counts.value),
        ),
      ),
      bottomNavigationBar: _restRemaining > 0
          ? RestTimerBar(remaining: _restRemaining, onSkip: _skipRest)
          : null,
      body: AppAsyncView<Map<String, int>>(
        value: counts,
        onRetry: () => ref.invalidate(doneSetCountsProvider(iso)),
        data: (value) {
          // Sayılar değiştiğinde kutucuğu senkronla. Build sırasında
          // yazma yapılmaz; kare sonrasına bırakılıyor.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _syncWorkoutFlag(value),
          );

          if (widget.day.exercises.isEmpty) {
            return const AppEmptyState(
              icon: Icons.self_improvement,
              title: 'Bugün hareket yok',
              description: 'Bu gün dinlenme günü olarak planlanmış.',
            );
          }

          return AppScreenBody(
            children: [
              for (final exercise in widget.day.exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ExerciseSetCard(
                    planExercise: exercise,
                    isoDate: iso,
                    doneSets: value[exercise.exerciseId] ?? 0,
                    onRest: _startRest,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Antrenmanın ne kadarının bittiğini gösteren ince çizgi.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.day, required this.counts});

  final FullPlanDay day;
  final Map<String, int>? counts;

  @override
  Widget build(BuildContext context) {
    final targetSets = day.exercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise.sets ?? 1),
    );
    final doneSets = day.exercises.fold<int>(0, (sum, exercise) {
      final done = counts?[exercise.exerciseId] ?? 0;
      // Hedefin üstüne çıkan setler ilerlemeyi %100'ün ötesine taşımasın.
      return sum + done.clamp(0, exercise.sets ?? 1);
    });

    final ratio = targetSets == 0 ? 0.0 : doneSets / targetSets;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      child: Semantics(
        label: '$doneSets / $targetSets set tamamlandı',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.fullAll,
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$doneSets / $targetSets set',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
