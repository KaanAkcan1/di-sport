import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart'
    show profileEntriesProvider;
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart'
    show ProfileKeys;
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/body_metric_table.dart'
    show MetricKinds;
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/domain/bmi.dart';
import 'package:disport/features/health/domain/checkup_rules.dart';
import 'package:disport/features/medical/application/medical_providers.dart';
import 'package:disport/features/medical/domain/medical_fact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Check-up rehberi bölümü (v3 §7.2).
///
/// Kullanıcının kendi vadeleri (`lab_schedules`) önceliklidir; rehber
/// yalnız öneri. "Vakti geldi" satırına dokunmak öneriyi bir vade
/// olarak takvime ekler — rehber kendi başına alarm kurmaz.
class CheckupGuideSection extends ConsumerWidget {
  const CheckupGuideSection({super.key, required this.byPanel});

  final Map<String, List<LabEntry>> byPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final profile = ref.watch(profileEntriesProvider).value ?? const {};
    final weight =
        ref.watch(latestMetricsProvider).value?[MetricKinds.weight]?.value;
    final facts =
        ref.watch(medicalFactsProvider).value ?? const <MedicalFact>[];

    final height = double.tryParse(
      (profile[ProfileKeys.heightCm] ?? '').replaceAll(',', '.'),
    );
    final bmi = bodyMassIndex(weightKg: weight, heightCm: height);
    final age = _age(profile);
    // Kimlikli teşhis, condition ile aynı yoldan okunur (v3.1 §7).
    final conditionIds = {
      for (final fact in facts)
        if ((fact.kind == MedicalFactKind.condition ||
                fact.kind == MedicalFactKind.diagnosis) &&
            fact.conditionId != null)
          fact.conditionId!,
    };

    final advice = checkupAdvice(
      today: DateTime.now(),
      age: age,
      bmi: bmi,
      conditionIds: conditionIds,
      lastDone: _lastDone(),
      lastLipidBorderline: _lipidBorderline(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        AppSectionLabel(TurkishText.upper(l10n.checkupTitle)),
        // Tıbbi tavsiye değil — bölüm başında tek açıklama satırı.
        Text(
          l10n.checkupDisclaimer,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (bmi == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.checkupNeedsWeight,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        for (final item in advice)
          _AdviceRow(key: Key('checkup-${item.test.name}'), advice: item),
      ],
    );
  }

  /// Yaş: doğum tarihi varsa ondan, yoksa eski `age` anahtarından.
  static int? _age(Map<String, String> profile) {
    final birthRaw = profile[ProfileKeys.birthDate];
    if (birthRaw != null) {
      final birth = DateTime.tryParse(birthRaw);
      if (birth != null) {
        final now = DateTime.now();
        var age = now.year - birth.year;
        if (now.month < birth.month ||
            (now.month == birth.month && now.day < birth.day)) {
          age--;
        }
        return age;
      }
    }
    return int.tryParse(profile[ProfileKeys.age] ?? '');
  }

  Map<CheckupTest, DateTime?> _lastDone() {
    DateTime? latestWhere(bool Function(LabEntry) test) {
      DateTime? latest;
      for (final entries in byPanel.values) {
        for (final entry in entries) {
          if (!test(entry)) continue;
          final date = DateTime.tryParse(entry.date);
          if (date == null) continue;
          if (latest == null || date.isAfter(latest)) latest = date;
        }
      }
      return latest;
    }

    bool markerHas(LabEntry e, List<String> needles) {
      final folded = TurkishText.fold(e.marker);
      return needles.any(folded.contains);
    }

    return {
      // Tam panel yaklaşık: herhangi bir tahlil tarihi — kullanıcı
      // laboratuvara gittiğinde genelde paneli birlikte yaptırıyor.
      CheckupTest.fullPanel: latestWhere((_) => true),
      CheckupTest.hba1c: latestWhere((e) => markerHas(e, ['hba1c', 'a1c'])),
      CheckupTest.lipid: latestWhere((e) => e.panel == LabPanels.lipid),
      CheckupTest.vitaminDB12: latestWhere(
        (e) => markerHas(e, ['vitamin d', 'd vitamini', 'b12']),
      ),
    };
  }

  /// Son lipit sonuçlarında referans dışı değer var mı.
  bool _lipidBorderline() {
    final entries = byPanel[LabPanels.lipid];
    if (entries == null || entries.isEmpty) return false;

    final seen = <String>{};
    for (final entry in entries) {
      if (!seen.add(entry.marker)) continue; // yalnız son değer
      final status = statusOf(entry);
      if (status == LabStatus.low || status == LabStatus.high) return true;
    }
    return false;
  }
}

class _AdviceRow extends ConsumerWidget {
  const _AdviceRow({super.key, required this.advice});

  final CheckupAdvice advice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final label = _testLabel(l10n, advice.test);

    return InkWell(
      // Dokunuş vadeyi kullanıcının kendi takvimine yazar; rehber
      // satırı öneri olarak kalır.
      onTap: advice.due
          ? () async {
              final messenger = ScaffoldMessenger.of(context);
              final confirmation = l10n.checkupScheduled(label);
              await ref
                  .read(labRepositoryProvider)
                  .setSchedule(label, advice.intervalMonths);
              messenger.showSnackBar(
                SnackBar(content: Text(confirmation)),
              );
            }
          : null,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            AppStatusDot(
              status: advice.due ? AppStatus.caution : AppStatus.good,
              semanticsLabel: advice.due
                  ? l10n.checkupDue
                  : l10n.checkupInMonths(advice.monthsLeft ?? 0),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(
              advice.due
                  ? l10n.checkupDue
                  : l10n.checkupInMonths(advice.monthsLeft ?? 0),
              style: theme.textTheme.bodySmall?.copyWith(
                color: advice.due
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: advice.due ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _testLabel(AppLocalizations l10n, CheckupTest test) =>
      switch (test) {
        CheckupTest.fullPanel => l10n.checkupFullPanel,
        CheckupTest.hba1c => l10n.checkupHba1c,
        CheckupTest.lipid => l10n.checkupLipid,
        CheckupTest.vitaminDB12 => l10n.checkupVitaminDB12,
      };
}
