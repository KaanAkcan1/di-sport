import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/metric_definitions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ölçüm türlerinin yönetimi: ekle, adlandır, sırala, sil.
class MetricsEditorScreen extends ConsumerWidget {
  const MetricsEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitions = ref.watch(metricDefinitionsProvider);
    final repository = ref.watch(metricDefinitionsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.healthMetricsEditorTitle)),
      body: AppAsyncView<List<MetricDefinition>>(
        value: definitions,
        onRetry: () => ref.invalidate(metricDefinitionsProvider),
        emptyWhen: (list) => list.isEmpty,
        empty: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: AppEmptyState(
            icon: Icons.straighten,
            title: context.l10n.healthNoMetricsTitle,
            description: context.l10n.healthMetricsEditorEmptyDescription,
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
          onReorderItem: (from, to) {
            final kinds = [for (final d in list) d.kind];
            kinds.insert(to, kinds.removeAt(from));
            repository.reorder(kinds);
          },
          itemBuilder: (context, index) {
            final definition = list[index];
            return _MetricRow(
              key: ValueKey(definition.kind),
              definition: definition,
              index: index,
              onEdit: () => _openSheet(context, definition: definition),
              onDelete: () => _confirmDelete(context, repository, definition),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-metric-fab'),
        onPressed: () => _openSheet(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.healthAddMetricFab),
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context, {
    MetricDefinition? definition,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MetricSheet(definition: definition),
  );

  Future<void> _confirmDelete(
    BuildContext context,
    MetricDefinitionsRepository repository,
    MetricDefinition definition,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.healthDeleteMetricTitle(definition.label)),
        // Ölçülmüş değerlerin durduğunu söylemek şart: aksi hâlde
        // kullanıcı grafiğini kaybetmekten korkup listeyi düzeltmiyor.
        content: Text(context.l10n.healthDeleteMetricBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-delete-metric'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.healthMetricRemove),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await repository.remove(definition.kind);
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    super.key,
    required this.definition,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final MetricDefinition definition;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('metric-row-${definition.kind}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(definition.label),
        subtitle: Text(
          definition.isDaily
              ? context.l10n.healthMetricDailyHint(definition.unit)
              : definition.unit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onEdit,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('delete-metric-${definition.kind}'),
              icon: const Icon(Icons.delete_outline),
              tooltip: context.l10n.healthMetricRemove,
              onPressed: onDelete,
            ),
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

class _MetricSheet extends ConsumerStatefulWidget {
  const _MetricSheet({this.definition});

  final MetricDefinition? definition;

  @override
  ConsumerState<_MetricSheet> createState() => _MetricSheetState();
}

class _MetricSheetState extends ConsumerState<_MetricSheet> {
  late final _label = TextEditingController(
    text: widget.definition?.label ?? '',
  );
  late final _unit = TextEditingController(text: widget.definition?.unit ?? '');
  late var _decimals = widget.definition?.decimals ?? 1;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _error = context.l10n.healthMetricLabelRequired);
      return;
    }

    final repository = ref.read(metricDefinitionsRepositoryProvider);
    if (widget.definition case final existing?) {
      await repository.edit(
        existing.kind,
        label: label,
        unit: _unit.text,
        decimals: _decimals,
      );
    } else {
      await repository.add(
        label: label,
        unit: _unit.text,
        decimals: _decimals,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            Text(
              widget.definition == null
                  ? l10n.healthMetricSheetAddTitle
                  : l10n.healthMetricSheetEditTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('metric-label'),
              controller: _label,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.healthMetricLabelLabel,
                hintText: l10n.healthMetricLabelHint,
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('metric-unit'),
              controller: _unit,
              decoration: InputDecoration(
                labelText: l10n.healthLabUnitLabel,
                hintText: l10n.healthMetricUnitHint,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              l10n.healthMetricDisplayTitle,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<int>(
              key: const Key('metric-decimals'),
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(l10n.healthMetricInteger),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text(l10n.healthMetricDecimal),
                ),
              ],
              selected: {_decimals},
              onSelectionChanged: (values) =>
                  setState(() => _decimals = values.first),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              // Örnek vermek soyut açıklamadan iyi çalışıyor: kullanıcı
              // hangi seçeneğin ne yapacağını görüyor.
              _decimals == 0
                  ? l10n.healthMetricExampleInteger
                  : l10n.healthMetricExampleDecimal,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              key: const Key('save-metric'),
              onPressed: _save,
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
