import 'package:disport/core/design/app_dimens.dart';
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
      appBar: AppBar(title: const Text('Ölçüm türleri')),
      body: AppAsyncView<List<MetricDefinition>>(
        value: definitions,
        onRetry: () => ref.invalidate(metricDefinitionsProvider),
        emptyWhen: (list) => list.isEmpty,
        empty: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl2),
          child: AppEmptyState(
            icon: Icons.straighten,
            title: 'Ölçüm türü yok',
            description: 'Aşağıdaki düğmeden ilk ölçümünü ekle.',
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
        label: const Text('Ölçüm'),
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
        title: Text('"${definition.label}" kaldırılsın mı?'),
        // Ölçülmüş değerlerin durduğunu söylemek şart: aksi hâlde
        // kullanıcı grafiğini kaybetmekten korkup listeyi düzeltmiyor.
        content: const Text(
          'Listeden çıkar. Şimdiye kadar girdiğin değerler silinmez; '
          'türü geri eklersen yeniden görünür.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-delete-metric'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kaldır'),
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
              ? '${definition.unit} · her gün Bugün ekranından'
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
              tooltip: 'Kaldır',
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
      setState(() => _error = 'Ölçüm adı gerekli');
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

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            Text(
              widget.definition == null ? 'Ölçüm ekle' : 'Ölçümü düzenle',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('metric-label'),
              controller: _label,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Ölçüm',
                hintText: 'Kol çevresi',
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
              decoration: const InputDecoration(
                labelText: 'Birim',
                hintText: 'cm',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Gösterim', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<int>(
              key: const Key('metric-decimals'),
              segments: const [
                ButtonSegment(value: 0, label: Text('Tam sayı')),
                ButtonSegment(value: 1, label: Text('Ondalıklı')),
              ],
              selected: {_decimals},
              onSelectionChanged: (values) =>
                  setState(() => _decimals = values.first),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              // Örnek vermek soyut açıklamadan iyi çalışıyor: kullanıcı
              // hangi seçeneğin ne yapacağını görüyor.
              _decimals == 0 ? 'Örnek: 12' : 'Örnek: 104,5',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            FilledButton(
              key: const Key('save-metric'),
              onPressed: _save,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
