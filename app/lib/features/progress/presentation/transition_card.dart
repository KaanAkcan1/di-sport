import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/progress/domain/transition_criteria.dart';
import 'package:flutter/material.dart';

/// Koşuya geçiş ölçütleri kartı.
///
/// PDF'in "bunlar olmadan koşma" uyarısının ekrandaki hâli. Üç satır,
/// her biri açıkça sağlandı/sağlanmadı — "yaklaştın" gibi bulanık bir
/// ara durum yok, çünkü ölçütlerin amacı sakatlanmayı önlemek.
class TransitionCard extends StatelessWidget {
  const TransitionCard({
    super.key,
    required this.criteria,
    required this.latestWeight,
    required this.latestPushupMax,
    required this.onPainFreeChanged,
  });

  final TransitionCriteria criteria;
  final double? latestWeight;
  final double? latestPushupMax;
  final ValueChanged<bool> onPainFreeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppSection(
      title: l10n.progressTransitionTitle,
      description: criteria.allMet
          ? l10n.progressTransitionAllMet
          : l10n.progressTransitionProgress('${criteria.metCount}'),
      child: Card(
        child: Column(
          children: [
            _CriterionRow(
              met: criteria.weightOk,
              label: l10n.progressCriterionWeight(
                TurkishNumber.format(
                  transitionWeightMaxKg,
                  fractionDigits: 0,
                ),
              ),
              detail: latestWeight == null
                  ? l10n.progressCriterionNotWeighed
                  : l10n.progressCriterionWeightNow(
                      TurkishNumber.format(latestWeight!),
                    ),
            ),
            const Divider(height: 1, indent: AppSpacing.lg),
            _CriterionRow(
              met: criteria.pushupOk,
              label: l10n.progressCriterionPushups(
                '$transitionPushupMinReps',
              ),
              detail: latestPushupMax == null
                  ? l10n.progressCriterionNotMeasured
                  : l10n.progressCriterionPushupsNow(
                      TurkishNumber.format(
                        latestPushupMax!,
                        fractionDigits: 0,
                      ),
                    ),
            ),
            const Divider(height: 1, indent: AppSpacing.lg),
            SwitchListTile(
              key: const Key('pain-free-switch'),
              value: criteria.painFreeOk,
              onChanged: onPainFreeChanged,
              secondary: Icon(
                (criteria.painFreeOk ? AppStatus.good : AppStatus.unknown).icon,
                color: (criteria.painFreeOk ? AppStatus.good : AppStatus.unknown)
                    .color(context),
              ),
              title: Text(l10n.progressCriterionPainFree),
              subtitle: Text(
                l10n.progressCriterionPainFreeHint,
                style: theme.textTheme.bodySmall?.copyWith(
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

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({
    required this.met,
    required this.label,
    required this.detail,
  });

  final bool met;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = met ? AppStatus.good : AppStatus.unknown;

    return ListTile(
      leading: Icon(status.icon, color: status.color(context)),
      title: Text(label),
      subtitle: Text(
        detail,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
