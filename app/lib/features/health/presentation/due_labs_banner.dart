import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:flutter/material.dart';

/// Vadesi gelen tahlillerin uyarı şeridi.
///
/// Ekranın en tepesinde duruyor çünkü tek "yapılacak iş" bu; panel
/// kartları geçmişi anlatır, bu satır bir eylem ister.
///
/// Ton `warning`, `danger` değil: geciken tahlil bir aciliyet değil
/// hatırlatma. Kırmızı, referans dışı bir değere ayrılmış — ikisini
/// aynı renkle göstermek "kötü" sinyalini ucuzlatırdı.
class DueLabsBanner extends StatelessWidget {
  const DueLabsBanner({super.key, required this.due});

  final List<DueSchedule> due;

  @override
  Widget build(BuildContext context) {
    if (due.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final semantic = context.semantic;

    return Card(
      key: const Key('due-labs-banner'),
      color: semantic.warningSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.xl2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.event_repeat_outlined,
              color: semantic.warning,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    due.length == 1
                        ? context.l10n.healthDueLabsTitleOne
                        : context.l10n.healthDueLabsTitleMany(
                            '${due.length}',
                          ),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final schedule in due)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        _describe(context, schedule),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _describe(BuildContext context, DueSchedule schedule) {
    final l10n = context.l10n;
    final interval = l10n.healthDueInterval('${schedule.intervalMonths}');

    // Takvim kurulmuş ama hiç sonuç girilmemişse "gecikti" demek
    // yanlış olur — gecikecek bir tarih hiç oluşmamış.
    if (schedule.nextDue case final next?) {
      return l10n.healthDueWithDate(
        schedule.marker,
        interval,
        TurkishDate.dayMonthYear(next),
      );
    }
    return l10n.healthDueNoRecord(schedule.marker, interval);
  }
}
