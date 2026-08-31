import 'package:disport/core/design/app_dimens.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Ekipmanım')),
      body: AppAsyncView<List<EquipmentItem>>(
        value: inventory,
        onRetry: () => ref.invalidate(equipmentInventoryProvider),
        emptyWhen: (list) => list.isEmpty,
        empty: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl2),
          child: AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Ekipman listesi boş',
            description: 'Katalog yüklendiğinde liste kendiliğinden dolar. '
                'Aşağıdaki düğmeden elle de ekleyebilirsin.',
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
                      ? 'Hiç ekipman işaretlenmedi. Sadece vücut ağırlığıyla '
                            'yapılan hareketler her zaman kullanılabilir.'
                      : '$owned ekipman işaretli. Katalogda "Ekipmanım" '
                            'filtresi bunlara göre süzüyor.',
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
        label: const Text('Ekipman'),
      ),
    );
  }

  Future<void> _addEquipment(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ekipman ekle'),
        content: TextField(
          key: const Key('equipment-label'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Ekipman',
            hintText: 'Kettlebell',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-add-equipment'),
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (label == null || label.trim().isEmpty) return;
    await ref.read(equipmentRepositoryProvider).add(label);
  }
}
