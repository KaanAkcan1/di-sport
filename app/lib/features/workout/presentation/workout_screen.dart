import 'dart:async';

import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
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

  /// Seansın başlangıcı — ekran açıldığı an.
  ///
  /// M9'da `workout_sessions` tablosuna yazılacak; kuvvet antrenmanının
  /// kalorisi seans süresinden hesaplanıyor ve o veri şu an hiçbir yerde
  /// tutulmuyor. Şimdilik ekran ömrü boyunca bellekte: ekran kapanıp
  /// açılırsa sayaç sıfırlanır, kabul edilmiş sınır.
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

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

  bool _allSetsDone(Map<String, int> counts) =>
      widget.day.exercises.isNotEmpty &&
      widget.day.exercises.every(
        (exercise) =>
            (counts[exercise.exerciseId] ?? 0) >= (exercise.sets ?? 1),
      );

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
        title: Text(context.l10n.workoutTitle),
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
            return AppEmptyState(
              icon: Icons.self_improvement,
              title: context.l10n.workoutNoExercisesTitle,
              description: context.l10n.workoutNoExercisesDescription,
            );
          }

          return AppScreenBody(
            children: [
              _SessionHeader(
                // Saat `clockProvider`'dan: dakikada bir ilerliyor ve
                // testte sabitlenebiliyor. Widget'ın kendi `Timer`ı
                // olsaydı ekran söküldüğünde sızma riski doğardı ve
                // test onu sahte-async bölgesinde kovalamak zorunda
                // kalırdı.
                elapsed: (ref.watch(clockProvider).value ?? _startedAt)
                    .difference(_startedAt),
                day: widget.day,
                counts: value,
              ),
              const SizedBox(height: AppSpacing.xl2),
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
              // Değerlendirme (v3.1 §6): tüm setler bitince görünür.
              // Kaydetmek seansı da yazar — kuvvet kalorisi seans
              // süresinden hesaplanıyor ve süreyi bu ekran biliyor.
              if (_allSetsDone(value)) ...[
                const SizedBox(height: AppSpacing.xl),
                _DebriefCard(isoDate: iso, startedAt: _startedAt),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Seans sonu değerlendirmesi (v3.1 §6): RPE 1-10 + ağrı notu.
///
/// Kaydet, seansı da yazar: `startSession` idempotent (açık seans
/// varsa onu döner), sonra kapatılıp değerlendirme iliştirilir. Bu
/// aynı zamanda kuvvet kalorisinin ihtiyaç duyduğu seans kaydını
/// canlı ekrandan üretiyor — M9'dan beri açık duran boşluk.
class _DebriefCard extends ConsumerStatefulWidget {
  const _DebriefCard({required this.isoDate, required this.startedAt});

  final String isoDate;
  final DateTime startedAt;

  @override
  ConsumerState<_DebriefCard> createState() => _DebriefCardState();
}

class _DebriefCardState extends ConsumerState<_DebriefCard> {
  int? _rpe;
  final _pain = TextEditingController();
  var _saved = false;

  @override
  void dispose() {
    _pain.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repository = ref.read(workoutRepositoryProvider);
    final sessionId = await repository.startSession(
      widget.isoDate,
      now: widget.startedAt,
    );
    await repository.endSession(widget.isoDate);
    await repository.setSessionDebrief(
      sessionId: sessionId,
      rpe: _rpe,
      painNote: _pain.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (_saved) {
      return Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.sessionDebriefSaved, style: theme.textTheme.bodyMedium),
        ],
      );
    }

    return Column(
      key: const Key('debrief-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sessionDebriefTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.sessionRpeLabel, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (var value = 1; value <= 10; value++)
              ChoiceChip(
                key: Key('debrief-rpe-$value'),
                label: Text('$value'),
                selected: _rpe == value,
                visualDensity: VisualDensity.compact,
                onSelected: (_) =>
                    setState(() => _rpe = _rpe == value ? null : value),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('debrief-pain'),
          controller: _pain,
          decoration: InputDecoration(
            labelText: l10n.sessionPainLabel,
            hintText: l10n.sessionPainHint,
            isDense: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: const Key('debrief-save'),
          onPressed: _save,
          child: Text(l10n.sessionDebriefSave),
        ),
      ],
    );
  }
}

/// Seansın kahraman rakamı: geçen süre.
///
/// Her ekranın bir kahraman rakamı var (spec §2a.3); Antrenman'ınki
/// süre. Kol mesafesinden okunuyor — telefon yerde, kullanıcı set
/// arasında ona bakıyor.
///
/// ≈kcal M9'da bunun yanına geliyor: hesap seans süresi × MET ve MET
/// verisi katalogda henüz yok.
class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.elapsed,
    required this.day,
    required this.counts,
  });

  final Duration elapsed;
  final FullPlanDay day;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final targetSets = day.exercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise.sets ?? 1),
    );
    final doneSets = day.exercises.fold<int>(0, (sum, exercise) {
      final done = counts[exercise.exerciseId] ?? 0;
      return sum + done.clamp(0, exercise.sets ?? 1);
    });

    // Negatife düşemez: saat kaynağı ile başlangıç anı arasında kayma
    // olabilir (yaz saati, cihaz saatinin elle değiştirilmesi) ve
    // "-3 dakikadır çalışıyorsun" saçma olurdu.
    final minutes = elapsed.inMinutes.clamp(0, 24 * 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHeroNumber(
          caption: context.l10n.workoutElapsedCaption,
          // İlk dakikada "0" yazmak sayacın bozuk olduğunu düşündürüyor;
          // bir dakika dolana kadar başlangıç anı gösteriliyor.
          value: minutes == 0 ? context.l10n.workoutElapsedNew : '$minutes',
          unit: minutes == 0 ? null : context.l10n.workoutMinuteUnit,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppMetricStrip([
          AppMetric(
            caption: context.l10n.workoutSetsCaption,
            value: '$doneSets',
            unit: '/$targetSets',
          ),
          AppMetric(
            caption: context.l10n.workoutExercisesCaption,
            value: '${day.exercises.length}',
          ),
        ]),
      ],
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
        label: context.l10n.workoutSetsDoneSemantics(doneSets, targetSets),
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
              context.l10n.workoutSetsProgress(doneSets, targetSets),
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
