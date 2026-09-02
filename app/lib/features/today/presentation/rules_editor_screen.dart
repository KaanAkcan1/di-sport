import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/daily_rules_repository.dart';
import 'package:disport/features/today/presentation/rule_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günlük kuralların yönetimi: ekle, adlandır, sırala, sil.
class RulesEditorScreen extends ConsumerWidget {
  const RulesEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(dailyRulesProvider);
    final repository = ref.watch(dailyRulesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.todayRulesTitle)),
      body: AppAsyncView<List<DailyRule>>(
        value: rules,
        onRetry: () => ref.invalidate(dailyRulesProvider),
        emptyWhen: (list) => list.isEmpty,
        empty: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: AppEmptyState(
            icon: Icons.rule,
            title: context.l10n.todayNoRulesTitle,
            description: context.l10n.todayRulesEditorEmptyBody,
          ),
        ),
        data: (list) => ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.lg,
            AppSpacing.screenH,
            AppSpacing.bottomBarClearance,
          ),
          itemCount: list.length,
          // `onReorderItem` hedef dizini kendi düzeltiyor; kullanımdan
          // kalkan `onReorder` çıkarılan öğeyi hesaba katmadığı için
          // aşağı taşımada elle bir eksiltmek gerekiyordu.
          onReorderItem: (from, to) {
            final ids = [for (final rule in list) rule.id];
            ids.insert(to, ids.removeAt(from));
            repository.reorder(ids);
          },
          itemBuilder: (context, index) {
            final rule = list[index];
            return _RuleRow(
              key: ValueKey(rule.id),
              rule: rule,
              index: index,
              onEdit: () => _openSheet(context, ref, rule: rule),
              onDelete: () => _confirmDelete(context, repository, rule),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-rules',
        key: const Key('add-rule-fab'),
        onPressed: () => _openSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.todayRuleFabLabel),
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, {
    DailyRule? rule,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RuleSheet(rule: rule),
  );

  Future<void> _confirmDelete(
    BuildContext context,
    DailyRulesRepository repository,
    DailyRule rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.todayDeleteRuleTitle(rule.label)),
        // Geçmişin bozulmadığını söylemek önemli: kullanıcı silmenin
        // eski kayıtlarını da sileceğinden çekinip listeyi
        // temizlemekten kaçınıyor.
        content: Text(context.l10n.todayDeleteRuleBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-delete-rule'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await repository.remove(rule.id);
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    super.key,
    required this.rule,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final DailyRule rule;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('rule-row-${rule.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(RuleIcons.resolve(rule.iconKey)),
        title: Text(rule.label),
        subtitle: rule.isBuiltIn
            ? Text(
                context.l10n.todayBuiltInRuleNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        onTap: onEdit,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('delete-rule-${rule.id}'),
              icon: const Icon(Icons.delete_outline),
              tooltip: context.l10n.commonDelete,
              onPressed: onDelete,
            ),
            // Sürükleme tutamağı: sürüklemenin tek yol olmaması için
            // satırın kendisi de dokunulabilir (ui-ux §2
            // `gesture-alternative`).
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  Icons.drag_handle,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kural ekleme/düzenleme formu.
class _RuleSheet extends ConsumerStatefulWidget {
  const _RuleSheet({this.rule});

  final DailyRule? rule;

  @override
  ConsumerState<_RuleSheet> createState() => _RuleSheetState();
}

class _RuleSheetState extends ConsumerState<_RuleSheet> {
  late final _label = TextEditingController(text: widget.rule?.label ?? '');
  late var _iconKey = widget.rule?.iconKey ?? 'check';
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _error = context.l10n.todayRuleNameRequired);
      return;
    }

    final repository = ref.read(dailyRulesRepositoryProvider);
    if (widget.rule case final existing?) {
      await repository.rename(existing.id, label: label, iconKey: _iconKey);
    } else {
      await repository.add(label: label, iconKey: _iconKey);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            Text(
              widget.rule == null
                  ? context.l10n.todayAddRule
                  : context.l10n.todayEditRule,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('rule-label'),
              controller: _label,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.todayRuleLabel,
                hintText: context.l10n.todayRuleHint,
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              context.l10n.todayIconLabel,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final key in RuleIcons.keys)
                  _IconChoice(
                    iconKey: key,
                    selected: key == _iconKey,
                    onTap: () => setState(() => _iconKey = key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              key: const Key('save-rule'),
              onPressed: _save,
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('icon-$iconKey'),
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: AppTouch.minSize,
          height: AppTouch.minSize,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainer,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? AppBorder.emphasis : AppBorder.hairline,
            ),
          ),
          child: Icon(
            RuleIcons.resolve(iconKey),
            size: 22,
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
