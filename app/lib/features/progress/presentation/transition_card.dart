import 'package:disport/core/design/app_dimens.dart';
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

    return AppSection(
      title: 'Koşuya geçiş',
      description: criteria.allMet
          ? 'Üç ölçüt de sağlandı. Kısa koşu denemelerine başlayabilirsin.'
          : '${criteria.metCount} / 3 ölçüt sağlandı.',
      child: Card(
        child: Column(
          children: [
            _CriterionRow(
              met: criteria.weightOk,
              label: 'Kilo ${TurkishNumber.format(transitionWeightMaxKg, fractionDigits: 0)} kg altında',
              detail: latestWeight == null
                  ? 'henüz tartılmadı'
                  : 'şu an ${TurkishNumber.format(latestWeight!)} kg',
            ),
            const Divider(height: 1, indent: AppSpacing.lg),
            _CriterionRow(
              met: criteria.pushupOk,
              label: 'Kesintisiz $transitionPushupMinReps şınav',
              detail: latestPushupMax == null
                  ? 'henüz ölçülmedi'
                  : 'şu an '
                        '${TurkishNumber.format(latestPushupMax!, fractionDigits: 0)}',
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
              title: const Text('Yürüyüş sonrası diz/ayak ağrısı yok'),
              subtitle: Text(
                'Bunu ölçemem, sen bileceksin.',
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
