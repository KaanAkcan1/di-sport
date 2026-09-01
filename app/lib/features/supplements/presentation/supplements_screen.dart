import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/supplements/presentation/supplement_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Takviye ve ilaç listesi — Ayarlar'dan açılır.
///
/// M6'nın kullanıcı-tanımlı-veri kalıbı: yerleşik tohum yok, silme
/// yumuşak, silme onayı geçmişin korunacağını **açıkça** söylüyor.
class SupplementsScreen extends ConsumerWidget {
  const SupplementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(supplementsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supplementsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-supplement-fab'),
        onPressed: () => showSupplementForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.supplementAddFab),
      ),
      body: AppAsyncView<List<Supplement>>(
        value: items,
        emptyWhen: (list) => list.isEmpty,
        empty: AppEmptyState(
          icon: Icons.medication_outlined,
          title: l10n.supplementsEmptyTitle,
          description: l10n.supplementsEmptyDescription,
        ),
        onRetry: () => ref.invalidate(supplementsProvider),
        data: (list) => AppScreenBody(
          children: [
            for (final supplement in list)
              _SupplementRow(supplement: supplement),
          ],
        ),
      ),
    );
  }
}

class _SupplementRow extends ConsumerWidget {
  const _SupplementRow({required this.supplement});

  final Supplement supplement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final subtitle = [
      if (supplement.doseLabel.isNotEmpty) supplement.doseLabel,
      if (supplement.times.isNotEmpty)
        supplement.times.join(' · ')
      else
        l10n.supplementTimesEmpty,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const Icon(Icons.medication_outlined),
        title: Text(supplement.name),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () => showSupplementForm(context, ref, existing: supplement),
        trailing: IconButton(
          key: Key('delete-supplement-${supplement.id}'),
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.commonDelete,
          onPressed: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.supplementDeleteTitle(supplement.name)),
        // Geçmişin korunacağını söylemek şart: kaybetmekten korkan
        // kullanıcı listesini hiç toparlamıyor (M6 dersi).
        content: Text(l10n.supplementDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(supplementsRepositoryProvider).softDelete(supplement.id);
    }
  }
}
