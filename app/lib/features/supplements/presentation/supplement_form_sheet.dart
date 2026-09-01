import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Takviye ekleme/düzenleme formunu açar.
Future<void> showSupplementForm(
  BuildContext context,
  WidgetRef ref, {
  Supplement? existing,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.9,
    child: SupplementFormSheet(existing: existing),
  ),
);

/// Takviye formu: ad, doz, saatler, günler, not.
class SupplementFormSheet extends ConsumerStatefulWidget {
  const SupplementFormSheet({super.key, this.existing});

  final Supplement? existing;

  @override
  ConsumerState<SupplementFormSheet> createState() =>
      _SupplementFormSheetState();
}

class _SupplementFormSheetState extends ConsumerState<SupplementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dose;
  late final TextEditingController _unit;
  late final TextEditingController _note;

  late List<String> _times;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _dose = TextEditingController(text: existing?.dose ?? '');
    _unit = TextEditingController(text: existing?.unit ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _times = [...?existing?.times];
    _weekdays = {...?existing?.weekdays};
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _unit.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;

    final value =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';

    // Aynı saati iki kez eklemek iki özdeş bildirim demek.
    if (_times.contains(value)) return;
    setState(() => _times = [..._times, value]..sort());
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(supplementsRepositoryProvider)
        .upsert(
          Supplement(
            id: widget.existing?.id ?? '',
            name: _name.text.trim(),
            dose: _dose.text.trim(),
            unit: _unit.text.trim(),
            times: _times,
            weekdays: _weekdays,
            note: _note.text.trim(),
          ),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              widget.existing == null
                  ? l10n.supplementAddTitle
                  : l10n.supplementEditTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              key: const Key('supplement-name'),
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.supplementNameLabel,
                hintText: l10n.supplementNameHint,
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.supplementNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('supplement-dose'),
                    controller: _dose,
                    decoration: InputDecoration(
                      labelText: l10n.supplementDoseLabel,
                      hintText: l10n.supplementDoseHint,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: InputDecoration(
                      labelText: l10n.supplementUnitLabel,
                      hintText: l10n.supplementUnitHint,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            AppSectionLabel(l10n.supplementTimesSection),
            if (_times.isEmpty)
              Text(
                // Saatsiz takviye meşru: "alıyorum ama saatini ben
                // bilirim" diyen kullanıcı zorlanmamalı. Yalnız
                // hatırlatma kurulmayacağı söyleniyor.
                l10n.supplementTimesEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final time in _times)
                  InputChip(
                    label: Text(time),
                    onDeleted: () =>
                        setState(() => _times = [..._times]..remove(time)),
                    deleteIcon: const Icon(Icons.close, size: 15),
                  ),
                ActionChip(
                  key: const Key('supplement-add-time'),
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(l10n.supplementAddTime),
                  onPressed: _addTime,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            AppSectionLabel(l10n.supplementDaysSection),
            Text(
              _weekdays.isEmpty ? l10n.supplementEveryDay : '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final (index, label)
                    in l10n.planWeekdayInitials.split(',').indexed)
                  FilterChip(
                    label: Text(label),
                    selected: _weekdays.contains(index + 1),
                    onSelected: (_) => setState(() {
                      final day = index + 1;
                      _weekdays = {..._weekdays};
                      if (!_weekdays.remove(day)) _weekdays.add(day);
                    }),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.supplementNoteLabel,
                hintText: l10n.supplementNoteHint,
              ),
            ),

            const SizedBox(height: AppSpacing.xl2),
            FilledButton(
              key: const Key('supplement-save'),
              onPressed: _save,
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
