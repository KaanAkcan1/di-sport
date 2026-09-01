import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart'
    show exerciseByIdProvider;
import 'package:disport/features/catalog/presentation/display_name.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart'
    show energySourceProvider;
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Planlanan / Yapılan (v3 §6.2).
///
/// Bir günün antrenmanı iki sütun: hareket başına plan hedefi ve
/// gerçekleşen setler. v2'nin bilinen boşluğu burada kapanıyor:
/// **geçmiş güne set yazılabilir ve düzeltilebilir.** Canlı sayaç
/// yalnız bugünde — geçmiş için elle seans saati girilir.
class PlannedVsDoneScreen extends ConsumerWidget {
  const PlannedVsDoneScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final planDay = ref.watch(dayPlanDayProvider(dateKey)).value;
    final logs =
        ref.watch(dayWorkoutLogsProvider(dateKey)).value ??
        const <LoggedSet>[];
    final isToday = dateKey == ref.watch(todayIsoProvider);

    final byExercise = <String, List<LoggedSet>>{};
    for (final log in logs) {
      byExercise.putIfAbsent(log.exerciseId, () => []).add(log);
    }

    final planned = planDay?.exercises ?? const <PlanExercise>[];
    // Plansız yapılanlar da listelenir — kullanıcı programda olmayan
    // bir hareket yaptıysa kaybolmamalı.
    final unplanned = [
      for (final id in byExercise.keys)
        if (!planned.any((e) => e.exerciseId == id)) id,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.plannedVsDoneTitle} — '
          '${TurkishDate.weekdayAndDay(DateTime.parse(dateKey))}',
        ),
      ),
      body: AppScreenBody(
        children: [
          _SessionSection(dateKey: dateKey),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppSectionLabel(l10n.plannedVsDoneExercises),
              ),
              Text(
                l10n.plannedVsDoneColumns,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          if (planned.isEmpty && unplanned.isEmpty)
            AppEmptyState(
              icon: Icons.fitness_center,
              title: l10n.plannedVsDoneEmptyTitle,
              description: l10n.plannedVsDoneEmptyBody,
            ),
          for (final exercise in planned)
            _ExerciseRow(
              key: Key('pvd-${exercise.exerciseId}'),
              dateKey: dateKey,
              exerciseId: exercise.exerciseId,
              planned: exercise,
              done: byExercise[exercise.exerciseId] ?? const [],
            ),
          for (final id in unplanned)
            _ExerciseRow(
              key: Key('pvd-$id'),
              dateKey: dateKey,
              exerciseId: id,
              planned: null,
              done: byExercise[id]!,
            ),
          if (isToday && planDay != null) ...[
            const SizedBox(height: AppSpacing.xl),
            // Canlı sayaç yalnız bugün: geçmişte dinlenme süreleri
            // saymanın anlamı yok.
            OutlinedButton.icon(
              key: const Key('open-live-workout'),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.plannedVsDoneOpenLive),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkoutScreen(day: planDay),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl4),
        ],
      ),
    );
  }
}

/// Seans satırı: süre + saat aralığı + ≈kcal; dokununca düzenleme.
class _SessionSection extends ConsumerWidget {
  const _SessionSection({required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sessions =
        ref.watch(daySessionsProvider(dateKey)).value ??
        const <SessionInfo>[];
    final burned = ref.watch(_dayBurnedProvider(dateKey)).value;

    String time(DateTime at) =>
        '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconTile(
                icon: LucideIcons.timer,
                area: AppArea.sport,
                small: true,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.plannedVsDoneSession,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (burned != null && burned > 0)
                Text(
                  '≈${burned.round()} kcal',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (sessions.isEmpty)
            Text(
              l10n.plannedVsDoneNoSession,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          for (final session in sessions)
            InkWell(
              key: Key('session-${session.id}'),
              onTap: () => _editSession(context, ref, session),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.endedAt == null
                            ? l10n.plannedVsDoneSessionOpen(
                                time(session.startedAt),
                              )
                            : '${time(session.startedAt)}–'
                                  '${time(session.endedAt!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (session.duration case final duration?)
                      Text(
                        l10n.plannedVsDoneMinutes(duration.inMinutes),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            key: const Key('add-session'),
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.plannedVsDoneAddSession),
            onPressed: () => _editSession(context, ref, null),
          ),
        ],
      ),
    );
  }

  Future<void> _editSession(
    BuildContext context,
    WidgetRef ref,
    SessionInfo? session,
  ) async {
    final l10n = context.l10n;
    final day = DateTime.parse(dateKey);
    var start = session?.startedAt ?? day.add(const Duration(hours: 18));
    var end =
        session?.endedAt ?? day.add(const Duration(hours: 18, minutes: 45));

    Future<DateTime?> pick(DateTime initial) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (picked == null) return null;
      return DateTime(day.year, day.month, day.day, picked.hour, picked.minute);
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.plannedVsDoneSessionEdit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('session-start'),
                dense: true,
                title: Text(l10n.plannedVsDoneStart),
                trailing: Text(TimeOfDay.fromDateTime(start).format(
                  dialogContext,
                )),
                onTap: () async {
                  final picked = await pick(start);
                  if (picked != null) setState(() => start = picked);
                },
              ),
              ListTile(
                key: const Key('session-end'),
                dense: true,
                title: Text(l10n.plannedVsDoneEnd),
                trailing: Text(
                  TimeOfDay.fromDateTime(end).format(dialogContext),
                ),
                onTap: () async {
                  final picked = await pick(end);
                  if (picked != null) setState(() => end = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              key: const Key('session-save'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    // Bitiş başlangıçtan önceyse yazmıyoruz: negatif süreli seans
    // kalori hesabını da geçmiş listesini de bozar.
    if (!end.isAfter(start)) return;
    await ref
        .read(workoutRepositoryProvider)
        .setSessionTimes(
          isoDate: dateKey,
          sessionId: session?.id,
          start: start,
          end: end,
        );
  }
}

/// ≈kcal — `EnergySource` portu üzerinden (yalnız kapalı seanslar).
final _dayBurnedProvider = StreamProvider.autoDispose
    .family<double, String>((ref, isoDate) async* {
      final source = await ref.watch(energySourceProvider.future);
      yield* source.burnedOn(isoDate);
    });

class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({
    super.key,
    required this.dateKey,
    required this.exerciseId,
    required this.planned,
    required this.done,
  });

  final String dateKey;
  final String exerciseId;
  final PlanExercise? planned;
  final List<LoggedSet> done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final exercise = ref.watch(exerciseByIdProvider(exerciseId)).value;
    final name = exercise == null
        ? exerciseId
        : exerciseDisplayName(context, exercise);

    final planText = switch (planned) {
      null => '—',
      final p when p.durationSec != null =>
        '${p.sets ?? 1}×${(p.durationSec! / 60).round()} dk',
      final p => '${p.sets ?? '?'}×${p.reps ?? '?'}',
    };
    final doneText = done.isEmpty
        ? l10n.plannedVsDoneAdd
        : done
              .map(
                (s) => s.durationSec != null
                    ? '${(s.durationSec! / 60).round()}dk'
                    : '${s.reps ?? '—'}',
              )
              .join(' · ');

    final targetSets = planned?.sets ?? 0;
    final (statusColor, statusIcon) = done.isEmpty
        ? (theme.colorScheme.onSurfaceVariant, null)
        : done.length >= targetSets && targetSets > 0
        ? (semantic.success, Icons.check)
        : planned == null
        ? (theme.colorScheme.onSurfaceVariant, Icons.check)
        : (semantic.warning, Icons.remove);

    return InkWell(
      onTap: () => _openSetEditor(context, ref, name),
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            if (statusIcon != null)
              Icon(statusIcon, size: 16, color: statusColor)
            else
              const SizedBox(width: 16),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(name, style: theme.textTheme.bodyMedium),
            ),
            SizedBox(
              width: 64,
              child: Text(
                planText,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 96,
              child: Text(
                doneText,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: done.isEmpty ? FontWeight.w600 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSetEditor(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SetEditorSheet(
      dateKey: dateKey,
      exerciseId: exerciseId,
      title: name,
    ),
  );
}

/// Set düzenleme alt sayfası: satır düzelt, sil, yeni set ekle.
///
/// Geçmiş güne yazmak burada meşru — `exercise_logs` tarih taşıyor ve
/// akış (`dayWorkoutLogsProvider`) her yazımda ekranı tazeliyor.
class _SetEditorSheet extends ConsumerWidget {
  const _SetEditorSheet({
    required this.dateKey,
    required this.exerciseId,
    required this.title,
  });

  final String dateKey;
  final String exerciseId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final logs =
        (ref.watch(dayWorkoutLogsProvider(dateKey)).value ??
                const <LoggedSet>[])
            .where((log) => log.exerciseId == exerciseId)
            .toList();
    final repository = ref.read(workoutRepositoryProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (logs.isEmpty)
              Text(
                l10n.plannedVsDoneNoSets,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            for (final log in logs)
              _SetRow(
                key: Key('set-${log.id}'),
                log: log,
                onChanged: (reps, weight, duration) => repository.updateSet(
                  log.id,
                  reps: reps,
                  weightKg: weight,
                  durationSec: duration,
                ),
                onDelete: () => repository.deleteSet(log.id),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('add-set'),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.plannedVsDoneAddSet),
              onPressed: () => repository.logSet(
                isoDate: dateKey,
                exerciseId: exerciseId,
                setIndex: logs.length,
                reps: logs.isNotEmpty ? logs.last.reps : null,
                weightKg: logs.isNotEmpty ? logs.last.weightKg : null,
                durationSec: logs.isNotEmpty ? logs.last.durationSec : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    super.key,
    required this.log,
    required this.onChanged,
    required this.onDelete,
  });

  final LoggedSet log;
  final void Function(int? reps, double? weightKg, int? durationSec)
  onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text('${log.setIndex + 1}.'),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextFormField(
              key: Key('set-reps-${log.id}'),
              initialValue: log.durationSec != null
                  ? '${log.durationSec}'
                  : '${log.reps ?? ''}',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: log.durationSec != null
                    ? l10n.plannedVsDoneSeconds
                    : l10n.plannedVsDoneReps,
                isDense: true,
              ),
              onFieldSubmitted: (value) {
                final parsed = int.tryParse(value.trim());
                if (parsed == null) return;
                if (log.durationSec != null) {
                  onChanged(null, null, parsed);
                } else {
                  onChanged(parsed, null, null);
                }
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextFormField(
              key: Key('set-weight-${log.id}'),
              initialValue: log.weightKg == null ? '' : '${log.weightKg}',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: 'kg', isDense: true),
              onFieldSubmitted: (value) {
                final parsed = double.tryParse(
                  value.trim().replaceAll(',', '.'),
                );
                if (parsed != null) onChanged(null, parsed, null);
              },
            ),
          ),
          IconButton(
            key: Key('set-delete-${log.id}'),
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: l10n.commonDelete,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
