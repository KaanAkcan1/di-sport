import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/dose_adherence.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/supplements/presentation/supplement_form_sheet.dart';
import 'package:disport/features/today/application/today_providers.dart'
    show todayIsoProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Takviye ve ilaç listesi — Ayarlar'dan açılır.
///
/// M6'nın kullanıcı-tanımlı-veri kalıbı: yerleşik tohum yok, silme
/// yumuşak, silme onayı geçmişin korunacağını **açıkça** söylüyor.
class SupplementsScreen extends ConsumerWidget {
  const SupplementsScreen({super.key, this.embedded = false});

  /// Sağlık kabuğunun içinde mi (v3) yoksa kendi sayfasında mı.
  ///
  /// Kabukta ikinci bir başlık çubuğu segment etiketini tekrarlardı;
  /// gömülüyken AppBar çizilmez, FAB kalır.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(supplementsProvider);

    return Scaffold(
      backgroundColor: embedded ? Colors.transparent : null,
      appBar: embedded ? null : AppBar(title: Text(l10n.supplementsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-supplements',
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
        data: (list) {
          // İlaç ve takviye ayrı başlıklar altında (v3 §4): ikisi aynı
          // tabloda yaşıyor ama kullanıcı için farklı şeyler — reçeteli
          // ilaç atlanmaz, takviye esner.
          final meds = [
            for (final s in list)
              if (s.kind == SupplementKind.medication) s,
          ];
          final supplements = [
            for (final s in list)
              if (s.kind == SupplementKind.supplement) s,
          ];
          return AppScreenBody(
            children: [
              const _TodayDoses(),
              const _AdherenceStrip(),
              if (meds.isNotEmpty) ...[
                AppSectionLabel(
                  l10n.supplementKindMedication,
                  trailing: Text('${meds.length}'),
                ),
                for (final supplement in meds)
                  _SupplementRow(supplement: supplement),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (supplements.isNotEmpty) ...[
                AppSectionLabel(
                  l10n.supplementKindSupplement,
                  trailing: Text('${supplements.length}'),
                ),
                for (final supplement in supplements)
                  _SupplementRow(supplement: supplement),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Günün doz listesi + sıradaki doz vurgu çizgisi (v3 §7.4).
class _TodayDoses extends ConsumerWidget {
  const _TodayDoses();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final doses = ref.watch(todayDosesProvider);
    if (doses.isEmpty) return const SizedBox.shrink();

    final repository = ref.read(supplementsRepositoryProvider);
    final iso = ref.watch(todayIsoProvider);
    // Sıradaki doz: alınmamışların ilki. Saat geçmiş olsa da sıradaki
    // odur — atlanan doz "sırada değil" sayılmaz.
    final next = doses.where((d) => !d.isTaken).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(l10n.supplementsTodayTitle),
        for (final dose in doses)
          AppAccentRow(
            color: Theme.of(context).colorScheme.primary,
            active: identical(dose, next),
            child: CheckboxListTile(
              key: Key('dose-${dose.supplement.id}-${dose.time}'),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: dose.isTaken,
              onChanged: (_) => repository.markTaken(
                supplementId: dose.supplement.id,
                isoDate: iso,
                time: dose.time,
                takenAt: dose.isTaken ? null : DateTime.now(),
              ),
              title: Text(dose.supplement.name),
              secondary: Text(dose.time),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Son 7 gün uyum şeridi: tam gün yeşil, eksik amber, planlı doz
/// olmayan gün nötr — nötr ceza değil (v3 §7.4).
class _AdherenceStrip extends ConsumerWidget {
  const _AdherenceStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final l10n = context.l10n;
    final supplements = ref.watch(supplementsProvider).value ?? const [];
    final taken = ref.watch(takenLastWeekProvider).value ?? const {};
    final today = DateTime.parse(ref.watch(todayIsoProvider));

    final days = doseAdherence(
      supplements: supplements,
      takenByDate: taken,
      today: today,
    );
    if (days.every((d) => d.unscheduled)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(l10n.supplementsAdherenceTitle),
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        key: Key('adherence-${day.date}'),
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: day.unscheduled
                              ? theme.colorScheme.surfaceContainerHigh
                              : day.full
                              ? semantic.successSurface
                              : day.partial
                              ? semantic.warningSurface
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: AppRadius.smAll,
                        ),
                        // Renk tek başına anlam taşımaz: sayı da yazıyor.
                        child: Text(
                          day.unscheduled
                              ? '—'
                              : '${day.taken}/${day.planned}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: day.full
                                ? semantic.success
                                : day.partial
                                ? semantic.warning
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TurkishDate.weekdayInitial(DateTime.parse(day.date)),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
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
        // Tür ikon kutusu (v3 §7.4): reçeteli ilaç tehlike tonunda —
        // atlanması takviyeden farklı bir şey.
        leading: supplement.kind == SupplementKind.medication
            ? const AppIconTile(
                icon: LucideIcons.pill,
                area: AppArea.danger,
                small: true,
              )
            : const AppIconTile(
                icon: LucideIcons.pill,
                area: AppArea.med,
                small: true,
              ),
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
