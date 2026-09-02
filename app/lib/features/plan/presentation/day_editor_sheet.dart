import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/plan/application/plan_editor_providers.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gün düzenleme: tip, başlık, akşam önerisi.
Future<void> showDayEditorSheet(
  BuildContext context, {
  required FullPlanDay day,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _DayEditor(day: day),
);

class _DayEditor extends ConsumerStatefulWidget {
  const _DayEditor({required this.day});

  final FullPlanDay day;

  @override
  ConsumerState<_DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends ConsumerState<_DayEditor> {
  late PlanDayType _type = widget.day.type;
  late final _headline = TextEditingController(text: widget.day.headline);
  late final _dinner = TextEditingController(
    text: widget.day.dinnerSuggestion,
  );

  @override
  void dispose() {
    _headline.dispose();
    _dinner.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.planEditDay, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),

          Text(l10n.planDayType),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<PlanDayType>(
            segments: [
              ButtonSegment(
                value: PlanDayType.gym,
                label: Text(l10n.planDayTypeGym),
              ),
              ButtonSegment(
                value: PlanDayType.home,
                label: Text(l10n.planDayTypeHome),
              ),
              ButtonSegment(
                value: PlanDayType.rest,
                label: Text(l10n.planDayTypeRest),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (values) =>
                setState(() => _type = values.first),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _headline,
            decoration: InputDecoration(labelText: l10n.planDayHeadline),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _dinner,
            decoration: InputDecoration(labelText: l10n.planDayDinner),
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await ref
                    .read(planEditorRepositoryProvider)
                    .updateDay(
                      widget.day.id,
                      type: _type,
                      headline: _headline.text,
                      dinnerSuggestion: _dinner.text,
                    );
                await ref.read(planChangedProvider)();
                navigator.pop();
              },
              child: Text(l10n.commonSave),
            ),
          ),
        ],
      ),
    );
  }
}
