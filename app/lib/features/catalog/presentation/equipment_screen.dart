import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ekipman envanteri: kullanıcı elindekileri işaretler.
///
/// Katalogdaki hareketler ekipman listesi taşıyor; bu ekran o listeyi
/// "bende var / yok" bilgisine bağlıyor. Katalog filtresi ve M4'te
/// AI'a giden `context.md` aynı envanteri okuyor — AI'ın yapamayacağın
/// bir hareketi önermesinin önüne geçen şey bu.
class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(equipmentInventoryProvider);
    final repository = ref.watch(equipmentRepositoryProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogEquipmentTitle)),
      body: AppAsyncView<List<EquipmentItem>>(
        value: inventory,
        onRetry: () => ref.invalidate(equipmentInventoryProvider),
        emptyWhen: (list) => list.isEmpty,
        empty: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: l10n.catalogEquipmentEmptyTitle,
            description: l10n.catalogEquipmentEmptyDescription,
          ),
        ),
        data: (list) {
          final owned = list.where((e) => e.isOwned).length;

          return AppScreenBody(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  owned == 0
                      ? l10n.catalogEquipmentNoneOwned
                      : l10n.catalogEquipmentOwnedCount(owned),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final (index, item) in list.indexed) ...[
                      if (index > 0)
                        const Divider(height: 1, indent: AppSpacing.lg),
                      SwitchListTile(
                        key: Key('equipment-${item.id}'),
                        value: item.isOwned,
                        onChanged: (value) =>
                            repository.setOwned(item.id, owned: value),
                        title: Text(item.label),
                        secondary: const Icon(Icons.fitness_center),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-equipment-fab'),
        onPressed: () => _addEquipment(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.catalogEquipmentAddFab),
      ),
    );
  }

  Future<void> _addEquipment(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.catalogEquipmentAddTitle),
        content: TextField(
          key: const Key('equipment-label'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.catalogEquipmentFieldLabel,
            hintText: l10n.catalogEquipmentFieldHint,
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirm-add-equipment'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.catalogEquipmentAddAction),
          ),
        ],
      ),
    );
    controller.dispose();

    if (label == null || label.trim().isEmpty) return;
    await ref.read(equipmentRepositoryProvider).add(label);
  }
}
