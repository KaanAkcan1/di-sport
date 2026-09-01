import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günün takviye ve ilaç dozları.
///
/// **Neden omurgada değil ayrı bölüm:** takviye plan slotu değil.
/// Omurgaya karıştırmak `SlotKind` enum'una yeni değer eklemeyi
/// gerektirirdi ve o enum plan verisinin ve AI sözleşmesinin parçası —
/// görsel bir ayrım için veri modelini değiştirmek yanlış olurdu.
///
/// Ayrıca takviye **SIRADA kartına terfi etmiyor**: sıradaki iş
/// kavramı planın işi, bir vitamin haplarını almak günün ana eylemi
/// değil.
class SupplementDosesCard extends ConsumerWidget {
  const SupplementDosesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doses = ref.watch(todayDosesProvider);
    if (doses.isEmpty) return const SizedBox.shrink();

    final taken = doses.where((d) => d.isTaken).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(
          context.l10n.supplementSectionLabel,
          trailing: Text(
            '$taken/${doses.length}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final dose in doses) _DoseRow(dose: dose),
      ],
    );
  }
}

class _DoseRow extends ConsumerWidget {
  const _DoseRow({required this.dose});

  final SupplementDose dose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: dose.isTaken
          ? l10n.supplementTakenSemantics(dose.supplement.name, dose.time)
          : l10n.supplementNotTakenSemantics(dose.supplement.name, dose.time),
      excludeSemantics: true,
      child: InkWell(
        key: Key('dose-${dose.supplement.id}-${dose.time}'),
        onTap: () => _toggle(ref),
        borderRadius: AppRadius.mdAll,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppTouch.minSize),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: semantic.hairline),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                child: Text(
                  dose.time,
                  style: AppTypography.metricSmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                dose.isTaken
                    ? Icons.check_circle
                    : Icons.medication_outlined,
                size: 20,
                color: dose.isTaken
                    ? semantic.success
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  dose.supplement.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    // Alınan doz üstü çizili: renkten bağımsız olarak da
                    // okunuyor (spec §2a.4).
                    decoration: dose.isTaken
                        ? TextDecoration.lineThrough
                        : null,
                    color: dose.isTaken
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
              ),
              if (dose.supplement.doseLabel.isNotEmpty)
                Text(
                  dose.supplement.doseLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// İşareti kurar ya da kaldırır — yanlış dokunuş geri alınabilmeli.
  void _toggle(WidgetRef ref) {
    ref
        .read(supplementsRepositoryProvider)
        .markTaken(
          supplementId: dose.supplement.id,
          isoDate: ref.read(todayIsoProvider),
          time: dose.time,
          takenAt: dose.isTaken ? null : DateTime.now(),
        );
  }
}
