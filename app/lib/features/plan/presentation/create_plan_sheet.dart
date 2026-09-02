import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/features/plan/application/plan_editor_providers.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Boş plan kurma.
///
/// **Neden bu kadar az alan:** iskelet kurmanın önündeki her soru
/// kullanıcının vazgeçme ihtimali. Başlık, başlangıç, süre ve kalori
/// hedefi yeterli; gerisi plan ayarlarından, günler editörden
/// dolduruluyor.
Future<void> showCreatePlanSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _CreatePlanSheet(),
    );

class _CreatePlanSheet extends ConsumerStatefulWidget {
  const _CreatePlanSheet();

  @override
  ConsumerState<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends ConsumerState<_CreatePlanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _kcal = TextEditingController(text: '2200');
  int _weeks = 4;
  DateTime _start = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _kcal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.planCreateTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextFormField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.planSettingsName),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.planSettingsNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(l10n.planCreateStart),
              trailing: Text(TurkishDate.weekdayAndDay(_start)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _start,
                  firstDate: DateTime(_start.year - 1),
                  lastDate: DateTime(_start.year + 2),
                );
                if (picked != null) setState(() => _start = picked);
              },
            ),

            const SizedBox(height: AppSpacing.sm),
            Text(l10n.planCreateWeeks),
            Slider(
              value: _weeks.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '$_weeks',
              onChanged: (value) => setState(() => _weeks = value.round()),
            ),

            TextFormField(
              controller: _kcal,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.planGoalKcal),
              validator: (raw) {
                final value = int.tryParse((raw ?? '').trim());
                if (value == null || value < 800 || value > 6000) {
                  return l10n.planGoalRange('800', '6000');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _create,
                child: Text(l10n.planCreateDone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final navigator = Navigator.of(context);
    final kcal = int.parse(_kcal.text.trim());

    await ref
        .read(planEditorRepositoryProvider)
        .createEmptyPlan(
          title: _title.text,
          startDate: _start,
          weeks: _weeks,
          // Kalan hedefler makul varsayılanlarla açılıyor ve plan
          // ayarlarından düzeltiliyor. Hepsini burada sormak, iskelet
          // kurmayı bir forma çevirirdi.
          goals: PlanGoals(
            dailyKcal: kcal,
            proteinG: 120,
            waterL: 3,
            weeklyGym: 3,
            weeklyHome: 2,
            targetLossKg: 0,
          ),
        );

    await ref.read(planChangedProvider)();
    navigator.pop();
  }
}
