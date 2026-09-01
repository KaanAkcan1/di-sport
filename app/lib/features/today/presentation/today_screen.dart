import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/presentation/day_meals_card.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/presentation/slot_kind_icon.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/presentation/daily_flags_card.dart';
import 'package:disport/features/today/presentation/day_note_field.dart';
import 'package:disport/features/today/presentation/measurement_inputs.dart';
import 'package:disport/features/today/presentation/missed_streak_banner.dart';
import 'package:disport/features/today/presentation/slot_list.dart';
import 'package:disport/features/today/presentation/supplement_doses_card.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günlük ekran — mürekkep dilinin ana sahnesi.
///
/// Sıralama sabah 05:45'e göre: başlık ve hafta şeridi (nerede
/// duruyorum), kahraman rakam (bugünün tek sayısı), metrik şeridi,
/// sıradaki iş, omurga, kayıt alanları.
///
/// **M12'de değişen:** `AppStatBand` gitti. Şerit üç sayıyı eşit
/// ağırlıkta gösteriyordu ve ekranın "en önemli sayısı" yoktu; göz
/// üçünü tarayıp hangisine bakacağına karar vermek zorunda kalıyordu.
/// Artık tek kahraman rakam var, geri kalanı altında ince bir satır.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planDay = ref.watch(todayPlanDayProvider);

    return AppAsyncView<FullPlanDay?>(
      value: planDay,
      onRetry: () => ref.invalidate(todayPlanDayProvider),
      data: (day) => AppScreenBody(
        children: [
          const _Header(),
          const SizedBox(height: AppSpacing.lg),
          const _WeekStrip(),
          const SizedBox(height: AppSpacing.xl2),
          _Hero(day: day),
          const SizedBox(height: AppSpacing.xl2),
          const MissedStreakBanner(),

          if (day == null)
            const _NoPlanNotice()
          else ...[
            if (day.headline.isNotEmpty) _Headline(text: day.headline),
            _Spine(day: day),
            if (day.dinnerSuggestion.isNotEmpty)
              _DinnerHint(text: day.dinnerSuggestion),
          ],

          const SizedBox(height: AppSpacing.xl2),
          const DayMealsCard(),
          const SizedBox(height: AppSpacing.xl2),
          const SupplementDosesCard(),
          const SizedBox(height: AppSpacing.xl2),
          const MeasurementInputs(),
          const SizedBox(height: AppSpacing.xl2),
          const DailyFlagsCard(),
          const SizedBox(height: AppSpacing.xl2),
          const DayNoteField(),
        ],
      ),
    );
  }
}

/// Tarih başlığı — eyebrow + gün adı.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final day = ref.watch(todayPlanDayProvider).value;

    final eyebrow = [
      TurkishText.upper(TurkishDate.weekdayAndDay(now)),
      if (day case final d?)
        TurkishText.upper(context.l10n.todayWeekNumber(d.weekIndex)),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Semantics(
          header: true,
          child: Text(
            context.l10n.todayTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Son yedi günün doluluk şeridi.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekFillProvider).value;
    // Boş liste meşru: akış henüz gelmedi ya da test onu boş veriyor.
    if (week == null || week.isEmpty) return const SizedBox.shrink();

    final today = week.last.day;

    return AppWeekDots(
      states: [
        for (final entry in week)
          if (_sameDay(entry.day, today))
            WeekDotState.today
          else if (entry.filled)
            WeekDotState.done
          else
            WeekDotState.missed,
      ],
      labels: [for (final entry in week) TurkishDate.weekdayInitial(entry.day)],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Günün kahraman rakamı ve metrik şeridi.
///
/// M12'de kahraman **kilo**; M9'da kalan kalori onun yerine geçer ve
/// kilo metrik şeridine iner (spec §2a, sıralama notu).
class _Hero extends ConsumerWidget {
  const _Hero({required this.day});

  final FullPlanDay? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = ref.watch(todayWeightProvider).value;
    final log = ref.watch(todayLogProvider).value;
    final rules = ref.watch(dailyRulesProvider).value ?? const [];

    final isoDate = ref.watch(todayIsoProvider);
    final energy = ref.watch(dayEnergyProvider(isoDate)).value;
    final goal = ref.watch(dailyKcalGoalProvider).value;
    final remaining = ref.watch(todayRemainingKcalProvider);
    final gauge = ref.watch(todayGaugeFractionProvider);
    final proteinGoal = ref.watch(dailyProteinGoalProvider).value;
    final protein =
        ref.watch(dayMealsProvider(isoDate)).value?.fold<double>(
          0,
          (sum, entry) => sum + entry.protein,
        ) ??
        0;

    final checked = log?.checkedSlotIds.length ?? 0;
    final total = day?.slots.length ?? 0;
    final rulesMet = log?.metAmong(rules.map((r) => r.id)) ?? 0;

    // Bütçe yoksa kahraman **yenen** kaloriyi gösteriyor (spec §5.4):
    // "kalan" demek için önce bir hedef olması gerekiyor ve plan içeri
    // alınmamış kullanıcıya hedef uydurmak yanlış olurdu.
    final heroValue = switch ((goal, energy)) {
      (null, final e?) => e.eaten.round().toString(),
      (_, _) => remaining?.round().toString(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHeroNumber(
          caption: goal == null
              ? context.l10n.todayHeroEatenNoPlan
              : context.l10n.todayHeroRemaining,
          value: heroValue,
          unit: 'kcal',
          gaugeFraction: gauge,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppMetricStrip([
          AppMetric(
            caption: context.l10n.todayMetricProtein,
            value: energy == null ? null : protein.round().toString(),
            unit: proteinGoal == null ? 'g' : '/$proteinGoal g',
          ),
          AppMetric(
            caption: context.l10n.todayMetricBurned,
            // `≈` her tahminde: hesabın hata payı kolayca %20 ve
            // kesin rakam vaat etmek kullanıcıyı yanıltır.
            value: energy == null ? null : '≈${energy.burned.round()}',
            unit: 'kcal',
          ),
          AppMetric(
            caption: TurkishText.upper(
              MetricKinds.labelOf(MetricKinds.weight),
            ),
            value: weight == null
                ? null
                : TurkishNumber.format(weight, fractionDigits: 1),
            unit: MetricKinds.unitOf(MetricKinds.weight),
          ),
          AppMetric(
            caption: context.l10n.todayMetricProgram,
            value: total == 0 ? null : '$checked',
            unit: total == 0 ? null : '/$total',
          ),
          AppMetric(
            caption: context.l10n.todayMetricRules,
            value: rules.isEmpty ? null : '$rulesMet',
            unit: rules.isEmpty ? null : '/${rules.length}',
          ),
        ]),
      ],
    );
  }
}

/// Sıradaki iş + omurga.
class _Spine extends ConsumerWidget {
  const _Spine({required this.day});

  final FullPlanDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final next = SlotList.nextSlotOf(day, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (next case final slot?) ...[
          AppSpotCard(
            eyebrow: context.l10n.todayNextEyebrow(slot.time),
            title: slot.label,
            subtitle: _subtitleFor(context, slot),
            leading: slotKindIcon(slot.kind),
            onTap: slot.kind == SlotKind.workout
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WorkoutScreen(day: day),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.xl2),
        ],
        AppSectionLabel(context.l10n.todaySpineLabel),
        SlotList(day: day, now: now, hoistNext: true),
      ],
    );
  }

  String? _subtitleFor(BuildContext context, PlanSlot slot) {
    if (slot.kind == SlotKind.workout) {
      return context.l10n.todayExerciseCount(day.exercises.length);
    }
    return slot.note;
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DinnerHint extends StatelessWidget {
  const _DinnerHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.todayDinnerHint(text),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan yokken gösterilen yönlendirme.
///
/// Tartı ve kutucuklar plan olmadan da çalışır — kullanıcı plan almadan
/// önce de kilosunu kaydedebilmeli. Bu yüzden ekranın tamamı değil,
/// yalnız omurga bölümü boş durum gösterir.
class _NoPlanNotice extends StatelessWidget {
  const _NoPlanNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.todayNoPlanTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.todayNoPlanBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
}

/// Gün türünün okunur adı.
///
/// Genişletme (`extension`) yerine işlev: çeviri [BuildContext] ister,
/// `this` üzerinden bağlam taşınamıyor.
String dayTypeLabel(BuildContext context, PlanDayType type) => switch (type) {
  PlanDayType.gym => context.l10n.todayDayTypeGym,
  PlanDayType.home => context.l10n.todayDayTypeHome,
  PlanDayType.rest => context.l10n.todayDayTypeRest,
};
