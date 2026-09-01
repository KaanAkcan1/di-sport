import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
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
            for (final label in _weekdayInitials)
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

  static const _weekdayInitials = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
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

    final checked = log?.checkedSlotIds.length ?? 0;
    final total = day.slots.length;
    final fill = resolveDayFill(day: day, checkedCount: checked, today: today);
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
      DayCellFill.free => 'boş',
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
          '${day.date.day} ${_monthNames[day.date.month - 1]}'
          '${isToday ? ', bugün' : ''}, ${_spoken(fill, checked, total)}',
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

  static String _spoken(DayCellFill fill, int checked, int total) =>
      switch (fill) {
        DayCellFill.done => 'tamamlandı',
        DayCellFill.partial => '$total işten $checked tamam',
        DayCellFill.empty => 'kayıt yok',
        DayCellFill.free => 'serbest gün',
        DayCellFill.future => 'henüz gelmedi',
      };

  static const _monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
}
