import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/medical/application/medical_providers.dart';
import 'package:disport/features/medical/domain/medical_fact.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/supplements/presentation/supplements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Medikal bilgiler ekranı (v3 §4).
///
/// Dört tür: durum, kısıt, alerji, kan grubu. İlaç listesi de burada
/// **aynalanıyor** — kayıtların sahibi `supplements` feature'ı, bu ekran
/// yalnız gösterip oraya köprü kuruyor: kullanıcı "ilaçlarım nerede"
/// diye iki yer arasında kalmasın.
///
/// Gizlilik notu ekranda: bu bilgiler cihazdan yalnız kullanıcı AI
/// belgesini paylaştığında çıkar.
class MedicalScreen extends ConsumerWidget {
  const MedicalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final facts = ref.watch(medicalFactsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.medicalTitle)),
      body: AppAsyncView<List<MedicalFact>>(
        value: facts,
        onRetry: () => ref.invalidate(medicalFactsProvider),
        data: (list) => _MedicalBody(facts: list),
      ),
    );
  }
}

class _MedicalBody extends ConsumerWidget {
  const _MedicalBody({required this.facts});

  final List<MedicalFact> facts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppScreenBody(
      children: [
        AppPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.lock,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.medicalPrivacyNote,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final kind in MedicalFactKind.values) ...[
          _KindSection(
            kind: kind,
            facts: [for (final f in facts) if (f.kind == kind) f],
            allFacts: facts,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        const _MedicationMirror(),
      ],
    );
  }
}

/// Bir türün bölümü: başlık, kayıt çipleri, öneri çipleri, serbest ekleme.
class _KindSection extends ConsumerWidget {
  const _KindSection({
    required this.kind,
    required this.facts,
    required this.allFacts,
  });

  final MedicalFactKind kind;
  final List<MedicalFact> facts;

  /// Teşhis önerileri condition havuzunu kullanıyor (v3.1 §7);
  /// çift kimlik denetimi tüm kayıtlara bakmak zorunda.
  final List<MedicalFact> allFacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Kan grubunda öneri çipleri sabit sekiz değer; diğerlerinde
    // makine kimlikli yaygın durumlar. Zaten kayıtlı olan öneri
    // gizlenir — aynı şeyi iki kez eklemek anlamsız.
    final existingConditionIds = {
      for (final f in facts)
        if (f.conditionId != null) f.conditionId,
    };
    final existingLabels = {for (final f in facts) f.label.toLowerCase()};

    // Teşhis çipleri condition havuzundan gelir; teşhise dönüşmüş bir
    // kimlik ikinci kez önerilmez. Condition olarak kayıtlı kimlik
    // teşhis bölümünde görünmeye devam eder — dokunuş dönüştürür.
    final diagnosedIds = {
      for (final f in allFacts)
        if (f.kind == MedicalFactKind.diagnosis && f.conditionId != null)
          f.conditionId,
    };
    final suggestions = switch (kind) {
      MedicalFactKind.bloodType => [
        for (final group in _bloodGroups)
          if (!existingLabels.contains(group.toLowerCase())) (null, group),
      ],
      MedicalFactKind.diagnosis => [
        for (final (k, id) in conditionSuggestions)
          if (k == MedicalFactKind.condition && !diagnosedIds.contains(id))
            (id, _conditionLabel(l10n, id)),
      ],
      _ => [
        for (final (k, id) in conditionSuggestions)
          if (k == kind && !existingConditionIds.contains(id))
            (id, _conditionLabel(l10n, id)),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(
          _kindTitle(l10n, kind),
          trailing: facts.isEmpty ? null : Text('${facts.length}'),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (facts.isEmpty && suggestions.isEmpty)
          Text(
            l10n.medicalKindEmpty,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final fact in facts)
              InputChip(
                key: Key('medical-fact-${fact.id}'),
                label: Text(
                  fact.factDate == null
                      ? fact.label
                      : '${fact.label} · '
                            '${TurkishDate.isoToDayMonthYear(fact.factDate!)}',
                ),
                onDeleted: () => _confirmRemove(context, ref, fact),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            for (final (conditionId, label) in suggestions)
              ActionChip(
                key: conditionId == null
                    ? null
                    : Key('medical-suggest-${kind.name}-$conditionId'),
                avatar: const Icon(Icons.add, size: 16),
                label: Text(label),
                onPressed: () => kind == MedicalFactKind.diagnosis
                    ? _addDiagnosis(
                        context,
                        ref,
                        label: label,
                        conditionId: conditionId,
                      )
                    : ref
                          .read(medicalRepositoryProvider)
                          .add(
                            kind: kind,
                            label: label,
                            conditionId: conditionId,
                          ),
              ),
            // Kan grubu kapalı bir küme; serbest metin girişi yalnız
            // diğer türlerde.
            if (kind != MedicalFactKind.bloodType)
              ActionChip(
                key: Key('medical-add-${kind.name}'),
                avatar: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.medicalAddCustom),
                onPressed: () => _addCustom(context, ref),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _addCustom(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_kindTitle(l10n, kind)),
        content: TextField(
          key: const Key('medical-custom-field'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.medicalCustomHint),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('medical-custom-save'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmed = label?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) return;
    if (kind == MedicalFactKind.diagnosis) {
      await _addDiagnosis(context, ref, label: trimmed, conditionId: null);
      return;
    }
    await ref.read(medicalRepositoryProvider).add(kind: kind, label: trimmed);
  }

  /// Teşhis eklerken tarih sorulur (varsayılan bugün).
  Future<void> _addDiagnosis(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String? conditionId,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked == null) return;

    final iso =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    await ref
        .read(medicalRepositoryProvider)
        .addDiagnosis(label: label, factDate: iso, conditionId: conditionId);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    MedicalFact fact,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.medicalRemoveTitle(fact.label)),
        content: Text(l10n.medicalRemoveBody),
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
    if (confirmed != true) return;
    await ref.read(medicalRepositoryProvider).remove(fact.id);
  }
}

/// İlaç aynası — kayıtların sahibi `supplements`.
class _MedicationMirror extends ConsumerWidget {
  const _MedicationMirror();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final supplements = ref.watch(supplementsProvider).value ?? const [];
    final meds = [
      for (final s in supplements)
        if (s.kind == SupplementKind.medication) s,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionLabel(
          l10n.medicalMedsTitle,
          trailing: meds.isEmpty ? null : Text('${meds.length}'),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (meds.isEmpty)
          Text(
            l10n.medicalMedsEmpty,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final med in meds)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  const AppIconTile(
                    icon: LucideIcons.pill,
                    area: AppArea.med,
                    small: true,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(med.name, style: theme.textTheme.bodyMedium),
                  ),
                  if (med.dose.isNotEmpty)
                    Text(
                      med.dose,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('medical-open-supplements'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SupplementsScreen(),
            ),
          ),
          icon: const Icon(LucideIcons.pill, size: 18),
          label: Text(l10n.medicalMedsManage),
        ),
      ],
    );
  }
}

const _bloodGroups = [
  'A Rh+',
  'A Rh-',
  'B Rh+',
  'B Rh-',
  'AB Rh+',
  'AB Rh-',
  '0 Rh+',
  '0 Rh-',
];

String _kindTitle(AppLocalizations l10n, MedicalFactKind kind) =>
    switch (kind) {
      MedicalFactKind.condition => l10n.medicalKindCondition,
      MedicalFactKind.diagnosis => l10n.medicalKindDiagnosis,
      MedicalFactKind.restriction => l10n.medicalKindRestriction,
      MedicalFactKind.allergy => l10n.medicalKindAllergy,
      MedicalFactKind.bloodType => l10n.medicalKindBloodType,
    };

/// Öneri çipinin görünen adı. Bilinmeyen kimlik olduğu gibi döner —
/// çip kataloğu genişlerse arayüz kırılmasın.
String _conditionLabel(AppLocalizations l10n, String conditionId) =>
    switch (conditionId) {
      'insulinResistance' => l10n.medicalCondInsulinResistance,
      'type2Diabetes' => l10n.medicalCondType2Diabetes,
      'hypertension' => l10n.medicalCondHypertension,
      'thyroid' => l10n.medicalCondThyroid,
      'kneeIssue' => l10n.medicalCondKneeIssue,
      'backIssue' => l10n.medicalCondBackIssue,
      'shoulderIssue' => l10n.medicalCondShoulderIssue,
      'lactose' => l10n.medicalCondLactose,
      'gluten' => l10n.medicalCondGluten,
      'nuts' => l10n.medicalCondNuts,
      _ => conditionId,
    };
