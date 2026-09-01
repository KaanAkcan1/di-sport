import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/presentation/food_labels.dart';
import 'package:disport/features/plan/application/plan_editor_providers.dart';
import 'package:disport/features/plan/application/plan_providers.dart'
    show activePlanProvider;
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Yasaklı yiyecekler editörü (v3 §5.4).
///
/// Liste plana yazılır (`rulesJson`), üç tüketicisi var: besin listesi
/// rozeti, AI belgesi, içe alma kontrolü. Satır serbest metin; istenirse
/// "besinlere bağla" ile kesin id eşleşmesi eklenir. AI sözleşmesinde
/// `forbidden` string kalır — bağlama kullanıcının işi.
class ForbiddenEditorScreen extends ConsumerStatefulWidget {
  const ForbiddenEditorScreen({super.key});

  @override
  ConsumerState<ForbiddenEditorScreen> createState() =>
      _ForbiddenEditorScreenState();
}

class _ForbiddenEditorScreenState
    extends ConsumerState<ForbiddenEditorScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _write(FullPlan plan, PlanRules rules) async {
    await ref.read(planEditorRepositoryProvider).updateRules(plan.id, rules);
    await ref.read(planChangedProvider)();
  }

  Future<void> _add(FullPlan plan) async {
    final label = _input.text.trim();
    if (label.isEmpty || plan.rules.forbidden.contains(label)) return;
    _input.clear();
    await _write(
      plan,
      PlanRules(
        forbidden: [...plan.rules.forbidden, label],
        forbiddenFoodIds: plan.rules.forbiddenFoodIds,
        free: plan.rules.free,
      ),
    );
  }

  Future<void> _remove(FullPlan plan, String label) => _write(
    plan,
    PlanRules(
      forbidden: [
        for (final item in plan.rules.forbidden)
          if (item != label) item,
      ],
      forbiddenFoodIds: {
        for (final entry in plan.rules.forbiddenFoodIds.entries)
          if (entry.key != label) entry.key: entry.value,
      },
      free: plan.rules.free,
    ),
  );

  Future<void> _linkFoods(FullPlan plan, String label) async {
    final current = plan.rules.forbiddenFoodIds[label] ?? const <String>[];
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FoodLinkSheet(label: label, initial: current.toSet()),
    );
    if (selected == null) return;

    await _write(
      plan,
      PlanRules(
        forbidden: plan.rules.forbidden,
        forbiddenFoodIds: {
          for (final entry in plan.rules.forbiddenFoodIds.entries)
            if (entry.key != label) entry.key: entry.value,
          if (selected.isNotEmpty) label: selected.toList()..sort(),
        },
        free: plan.rules.free,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final plan = ref.watch(activePlanProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forbiddenTitle)),
      body: plan == null
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppEmptyState(
                icon: Icons.rule,
                title: l10n.forbiddenTitle,
                description: l10n.forbiddenNoPlan,
              ),
            )
          : AppScreenBody(
              children: [
                Text(
                  l10n.forbiddenIntro,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('forbidden-input'),
                        controller: _input,
                        decoration: InputDecoration(
                          hintText: l10n.forbiddenAddHint,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _add(plan),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      key: const Key('forbidden-add'),
                      onPressed: () => _add(plan),
                      child: Text(l10n.forbiddenAdd),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (plan.rules.forbidden.isEmpty)
                  Text(
                    l10n.forbiddenEmpty,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                for (final label in plan.rules.forbidden)
                  _ForbiddenRow(
                    key: Key('forbidden-$label'),
                    label: label,
                    linkedCount:
                        plan.rules.forbiddenFoodIds[label]?.length ?? 0,
                    onLink: () => _linkFoods(plan, label),
                    onRemove: () => _remove(plan, label),
                  ),
              ],
            ),
    );
  }
}

class _ForbiddenRow extends StatelessWidget {
  const _ForbiddenRow({
    super.key,
    required this.label,
    required this.linkedCount,
    required this.onLink,
    required this.onRemove,
  });

  final String label;
  final int linkedCount;
  final VoidCallback onLink;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const AppIconTile(
            icon: LucideIcons.ban,
            area: AppArea.danger,
            small: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                if (linkedCount > 0)
                  Text(
                    l10n.forbiddenLinkedCount(linkedCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            key: Key('forbidden-link-$label'),
            onPressed: onLink,
            child: Text(l10n.forbiddenLinkFoods),
          ),
          IconButton(
            key: Key('forbidden-remove-$label'),
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.commonDelete,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Besin bağlama sayfası: arama + çoklu seçim, kapanınca seçim döner.
class _FoodLinkSheet extends ConsumerStatefulWidget {
  const _FoodLinkSheet({required this.label, required this.initial});

  final String label;
  final Set<String> initial;

  @override
  ConsumerState<_FoodLinkSheet> createState() => _FoodLinkSheetState();
}

class _FoodLinkSheetState extends ConsumerState<_FoodLinkSheet> {
  late final Set<String> _selected = {...widget.initial};
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final foods =
        ref.watch(foodLinkResultsProvider(_query)).value ?? const <Food>[];

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.forbiddenLinkFoods} — ${widget.label}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('forbidden-link-search'),
                decoration: InputDecoration(
                  hintText: l10n.foodSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return CheckboxListTile(
                      key: Key('forbidden-food-${food.id}'),
                      dense: true,
                      value: _selected.contains(food.id),
                      title: Text(foodDisplayName(context, food)),
                      onChanged: (checked) => setState(() {
                        if (checked ?? false) {
                          _selected.add(food.id);
                        } else {
                          _selected.remove(food.id);
                        }
                      }),
                    );
                  },
                ),
              ),
              FilledButton(
                key: const Key('forbidden-link-save'),
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(context.l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
