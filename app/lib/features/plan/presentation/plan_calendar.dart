import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_text.dart';
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
  });

  final List<FullPlanDay> days;
  final Map<String, DailyLogView> logs;
  final DateTime today;
  final void Function(FullPlanDay day)? onDayTap;

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
  });

  final FullPlanDay day;
  final DailyLogView? log;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    // v3 §6.1: hücre yalnız antrenman bilgisini taşıyor — kalori tonu
    // Diyet'in işi, slot doluluğu gün ekranının.
    final workoutDone = log?.workoutDone ?? false;
    final fill = resolveWorkoutFill(
      day: day,
      workoutDone: workoutDone,
      today: today,
    );
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

    // Alt satır tip etiketi (SALON/EV/DİNLEN): renk tek başına anlam
    // taşımaz kuralının karşılığı — hücre rengi hızlandırır, etiket
    // söyler.
    final caption = TurkishText.upper(switch (day.type) {
      PlanDayType.gym => context.l10n.planDayTypeGym,
      PlanDayType.home => context.l10n.planDayTypeHome,
      PlanDayType.rest => context.l10n.planDayTypeRest,
    });

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
          '$caption, ${_spoken(context, fill)}',
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
                // Antrenman işareti sağ üstte: yapıldıysa ✓, geçmişte
                // kaçırıldıysa ✗, gelecekte küçük üçgen (planlı gün).
                if (day.hasWorkout)
                  Positioned(
                    top: 3,
                    right: 4,
                    child: switch (fill) {
                      DayCellFill.done => Icon(
                        Icons.check,
                        size: 10,
                        color: semantic.success,
                      ),
                      DayCellFill.empty => Icon(
                        Icons.close,
                        size: 10,
                        color: semantic.warning,
                      ),
                      _ => Icon(
                        Icons.change_history,
                        size: 8,
                        color: theme.colorScheme.primary,
                      ),
                    },
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

  static String _spoken(BuildContext context, DayCellFill fill) =>
      switch (fill) {
        DayCellFill.done => context.l10n.planCellDone,
        DayCellFill.partial => context.l10n.planCellToday,
        DayCellFill.empty => context.l10n.planCellEmpty,
        DayCellFill.free => context.l10n.planCellFreeSpoken,
        DayCellFill.future => context.l10n.planCellFuture,
      };
}
