import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/presentation/equipment_labels.dart';
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
    final inventory = ref.watch(equipmentItemsProvider);
    final repository = ref.watch(equipmentRepositoryProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogEquipmentTitle)),
      body: AppAsyncView<List<EquipmentItem>>(
        value: inventory,
        onRetry: () => ref.invalidate(equipmentItemsProvider),
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
          // Yalnız seçilebilir olanlar sayılıyor: vücut ağırlığı ve ev
          // eşyası zaten her yerde geçerli, onları saymak "3 ekipmanım
          // var" gibi yanlış bir izlenim verirdi.
          final selectable = list.where((e) => e.isSelectable).toList();
          final owned = selectable
              .where((e) => e.atHome || e.atGym)
              .length;

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
              // Başlık satırı: iki sütunun ne olduğu bir kez söyleniyor,
              // her satırda tekrarlanmıyor.
              Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ColumnHeader(label: l10n.catalogLocationHome),
                    _ColumnHeader(label: l10n.catalogLocationGym),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: [
                    for (final (index, item) in selectable.indexed) ...[
                      if (index > 0)
                        const Divider(height: 1, indent: AppSpacing.lg),
                      _EquipmentRow(
                        item: item,
                        onChanged: (atHome, atGym) => repository.setOwnedAt(
                          item.id,
                          atHome: atHome,
                          atGym: atGym,
                        ),
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

/// İki sütunun başlığı — 56dp sabit genişlik, satırlardaki kutularla
/// aynı hizada.
class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 56,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Bir ekipman satırı: ad + ev/salon kutuları.
class _EquipmentRow extends StatelessWidget {
  const _EquipmentRow({required this.item, required this.onChanged});

  final EquipmentItem item;
  final void Function(bool? atHome, bool? atGym) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(equipmentLabel(context, item.kind))),
          SizedBox(
            width: 56,
            child: Checkbox(
              key: Key('equipment-home-${item.id}'),
              value: item.atHome,
              onChanged: (value) => onChanged(value ?? false, null),
            ),
          ),
          SizedBox(
            width: 56,
            child: Checkbox(
              key: Key('equipment-gym-${item.id}'),
              value: item.atGym,
              onChanged: (value) => onChanged(null, value ?? false),
            ),
          ),
        ],
      ),
    );
  }
}
