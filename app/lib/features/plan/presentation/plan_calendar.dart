import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/day_cell_state.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:flutter/material.dart';

/// Bir haftanın yedi hücresi.
///
/// **Neden ızgara:** v1'de haftalar alt alta kart listesiydi ve "bu ay
/// nasıl geçti" sorusu ancak kaydırarak cevaplanabiliyordu. Izgara
/// haftayı tek bakışta veriyor; boşluklar kendiliğinden görünür oluyor.
class PlanWeekGrid extends StatelessWidget {
  const PlanWeekGrid({
    super.key,
    required this.days,
    required this.logs,
    required this.today,
    this.onDayTap,
    this.netKcalByDay = const {},
    this.kcalGoal,
  });

  final List<FullPlanDay> days;
  final Map<String, DailyLogView> logs;
  final DateTime today;
  final void Function(FullPlanDay day)? onDayTap;

  /// Gün → (yenen − yakılan). Kaydı olmayan gün haritada yok.
  final Map<String, double> netKcalByDay;

  /// Günlük kalori hedefi; plan yoksa null ve ton hiç çizilmez.
  final int? kcalGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final label in context.l10n.planWeekdayInitials.split(','))
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.statCaption.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DayCell(
                    day: day,
                    log: logs[PlanRepository.iso(day.date)],
                    today: today,
                    net: netKcalByDay[PlanRepository.iso(day.date)],
                    kcalGoal: kcalGoal,
                    onTap: onDayTap == null ? null : () => onDayTap!(day),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.log,
    required this.today,
    this.onTap,
    this.net,
    this.kcalGoal,
  });

  final FullPlanDay day;
  final DailyLogView? log;
  final DateTime today;
  final VoidCallback? onTap;
  final double? net;
  final int? kcalGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final checked = log?.checkedSlotIds.length ?? 0;
    final total = day.slots.length;
    final fill = resolveDayFill(day: day, checkedCount: checked, today: today);
    final tone = resolveCalorieTone(goalKcal: kcalGoal, net: net);
    final isToday = _sameDay(day.date, today);

    final (background, border) = switch (fill) {
      DayCellFill.done => (semantic.successSurface, null),
      DayCellFill.partial => (theme.colorScheme.surfaceContainerHigh, null),
      DayCellFill.empty => (
        theme.colorScheme.surfaceContainerHigh,
        null,
      ),
      // Serbest gün kesikli değil şeffaf + kenarlıklı: kesikli çerçeve
      // Flutter'da özel çizim ister ve bu kadar küçük hücrede gürültü
      // yapıyor. Ayrım "dolgusuz + kenarlıklı" ile de net.
      DayCellFill.free => (
        Colors.transparent,
        Border.all(color: theme.colorScheme.outlineVariant),
      ),
      DayCellFill.future => (theme.colorScheme.surfaceContainerLow, null),
    };

    // Alt satır bilgisi: renk tek başına anlam taşımaz kuralının
    // karşılığı. Hücre rengi hızlandırır, rakam söyler.
    final caption = switch (fill) {
      DayCellFill.free => context.l10n.planCellFree,
      DayCellFill.future => '',
      _ => '$checked/$total',
    };

    final captionColor = switch (fill) {
      DayCellFill.done => semantic.success,
      DayCellFill.empty => semantic.warning,
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return Semantics(
      button: onTap != null,
      label:
          '${day.date.day} '
          '${context.l10n.planMonthNames.split(',')[day.date.month - 1]}'
          '${isToday ? ', ${context.l10n.planCellToday}' : ''}, '
          '${_spoken(context, fill, checked, total)}',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smAll,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: AppRadius.smAll,
              border: isToday
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: AppBorder.emphasis,
                    )
                  : border,
            ),
            child: Stack(
              children: [
                // Antrenman günü işareti — sağ üstte küçük üçgen.
                if (day.hasWorkout)
                  Positioned(
                    top: 3,
                    right: 4,
                    child: Icon(
                      Icons.change_history,
                      size: 8,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                // Kalori farkı sol üstte. **Doluluk tonunun yerine
                // geçmiyor, yanına giriyor:** "planı yaptım mı" ve
                // "bütçede kaldım mı" ayrı sorular ve tek renge
                // indirmek ikisini de yanlış cevaplardı.
                if (tone != DayCalorieTone.none && net != null)
                  Positioned(
                    top: 3,
                    left: 4,
                    child: Text(
                      tone == DayCalorieTone.over
                          ? context.l10n.calendarOverBy(
                              (net! - kcalGoal!).round(),
                            )
                          : context.l10n.calendarUnderBy(
                              (kcalGoal! - net!).round(),
                            ),
                      style: AppTypography.statCaption.copyWith(
                        fontSize: 8,
                        color: tone == DayCalorieTone.over
                            ? semantic.danger
                            : semantic.success,
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${day.date.day}',
                        style: AppTypography.metricSmall.copyWith(
                          fontSize: 14,
                          color: fill == DayCellFill.future
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (caption.isNotEmpty)
                        Text(
                          caption,
                          style: AppTypography.statCaption.copyWith(
                            fontSize: 8,
                            letterSpacing: 0.2,
                            color: captionColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _spoken(
    BuildContext context,
    DayCellFill fill,
    int checked,
    int total,
  ) => switch (fill) {
    DayCellFill.done => context.l10n.planCellDone,
    DayCellFill.partial => context.l10n.planCellPartial(total, checked),
    DayCellFill.empty => context.l10n.planCellEmpty,
    DayCellFill.free => context.l10n.planCellFreeSpoken,
    DayCellFill.future => context.l10n.planCellFuture,
  };
}
