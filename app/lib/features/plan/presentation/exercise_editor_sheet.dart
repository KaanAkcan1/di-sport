import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/display_name.dart';
import 'package:disport/features/plan/application/plan_editor_providers.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hareket düzenleme: katalogdan seçim + hedefler + kardiyo şiddeti.
Future<void> showExerciseEditorSheet(
  BuildContext context, {
  required String dayId,
  PlanExercise? exercise,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _ExerciseEditor(dayId: dayId, exercise: exercise),
);

class _ExerciseEditor extends ConsumerStatefulWidget {
  const _ExerciseEditor({required this.dayId, this.exercise});

  final String dayId;
  final PlanExercise? exercise;

  @override
  ConsumerState<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends ConsumerState<_ExerciseEditor> {
  late String? _exerciseId = widget.exercise?.exerciseId;
  late final _sets = _field(widget.exercise?.sets);
  late final _reps = _field(widget.exercise?.reps);
  late final _minutes = _field(
    widget.exercise?.durationSec == null
        ? null
        : widget.exercise!.durationSec! ~/ 60,
  );
  late final _rest = _field(widget.exercise?.restSec);
  late final _speed = _field(widget.exercise?.speedKmh);
  late final _grade = _field(widget.exercise?.gradePct);
  late Effort? _effort = widget.exercise?.effort;
  String? _error;

  static TextEditingController _field(num? value) =>
      TextEditingController(text: value == null ? '' : '$value');

  @override
  void dispose() {
    for (final controller in [_sets, _reps, _minutes, _rest, _speed, _grade]) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  double? _double(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _exerciseId == null
        ? null
        : ref.watch(exerciseByIdProvider(_exerciseId!)).value;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exercise == null
                        ? l10n.planExerciseNew
                        : l10n.planExerciseEdit,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.exercise case final existing?)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.commonDelete,
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await ref
                          .read(planEditorRepositoryProvider)
                          .deleteExercise(existing.id);
                      await ref.read(planChangedProvider)();
                      navigator.pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fitness_center),
              title: Text(
                selected == null
                    ? l10n.planExercisePick
                    : exerciseDisplayName(context, selected),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickExercise,
            ),
            if (_error case final message?)
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),

            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Number(controller: _sets, label: l10n.planExerciseSets),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Number(controller: _reps, label: l10n.planExerciseReps),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _Number(
                    controller: _minutes,
                    label: l10n.planExerciseDuration,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Number(
                    controller: _rest,
                    label: l10n.planExerciseRest,
                  ),
                ),
              ],
            ),

            // Şiddet alanları yalnız kardiyo hareketlerinde: bir
            // şınavın hızını ve eğimini sormak anlamsız ve alanları
            // her zaman göstermek formu iki katına çıkarırdı.
            if (selected?.category == ExerciseCategory.cardio) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _Number(
                      controller: _speed,
                      label: l10n.planExerciseSpeed,
                      decimal: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _Number(
                      controller: _grade,
                      label: l10n.planExerciseGrade,
                      decimal: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.planExerciseEffort),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final effort in Effort.values)
                    ChoiceChip(
                      label: Text(_effortLabel(context, effort)),
                      selected: _effort == effort,
                      onSelected: (selectedNow) => setState(
                        () => _effort = selectedNow ? effort : null,
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.commonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _effortLabel(BuildContext context, Effort effort) =>
      switch (effort) {
        Effort.light => context.l10n.effortLight,
        Effort.moderate => context.l10n.effortModerate,
        Effort.vigorous => context.l10n.effortVigorous,
      };

  /// Katalogdan seçim.
  ///
  /// Basit bir arama listesi: katalog ekranının tamamını buraya
  /// getirmek (sekmeler, filtre alt sayfası, envanter rozetleri)
  /// bir plan satırı eklerken fazlasıyla ağır olurdu.
  Future<void> _pickExercise() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _ExercisePicker(),
    );
    if (picked != null) setState(() => _exerciseId = picked);
  }

  Future<void> _save() async {
    if (_exerciseId == null) {
      setState(() => _error = context.l10n.planExerciseRequired);
      return;
    }

    final navigator = Navigator.of(context);
    final minutes = _int(_minutes);

    await ref
        .read(planEditorRepositoryProvider)
        .upsertExercise(
          widget.dayId,
          planExerciseId: widget.exercise?.id,
          exerciseId: _exerciseId!,
          sets: _int(_sets),
          reps: _int(_reps),
          durationSec: minutes == null ? null : minutes * 60,
          restSec: _int(_rest),
          speedKmh: _double(_speed),
          gradePct: _double(_grade),
          effort: _effort,
        );
    await ref.read(planChangedProvider)();
    navigator.pop();
  }
}

class _Number extends StatelessWidget {
  const _Number({
    required this.controller,
    required this.label,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final bool decimal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
    ),
  );
}

class _ExercisePicker extends ConsumerStatefulWidget {
  const _ExercisePicker();

  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(catalogSearchProvider(_query));

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.catalogSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 320,
            child: ListView(
              children: [
                for (final exercise in results.value ?? const <Exercise>[])
                  ListTile(
                    title: Text(exerciseDisplayName(context, exercise)),
                    subtitle: Text(exercise.primaryMuscles.join(', ')),
                    onTap: () => Navigator.of(context).pop(exercise.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
