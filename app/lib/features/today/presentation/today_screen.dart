import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/calorie_budget.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/presentation/day_editor_sheet.dart';
import 'package:disport/features/plan/presentation/exercise_editor_sheet.dart';
import 'package:disport/features/plan/presentation/slot_editor_sheet.dart';
import 'package:disport/features/plan/presentation/slot_kind_icon.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/presentation/day_flow_section.dart';
import 'package:disport/features/today/presentation/missed_streak_banner.dart';
import 'package:disport/features/today/presentation/slot_list.dart';
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
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  /// Bugün, gün ekranının `dateKey = bugün` hâli.
  ///
  /// Sekme burayı çiziyor ve `viewedDate` varsayılanı zaten bugün;
  /// ayrı bir kapsam açmaya gerek yok.
  @override
  Widget build(BuildContext context) => const DayBody();
}

/// Belirli bir günün ekranı — takvimden ya da başlıktaki oklardan.
class DayScreen extends StatelessWidget {
  const DayScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  Widget build(BuildContext context) => ProviderScope(
    // Kapsam, `dateKey`i onlarca widget yapıcısından geçirmenin
    // yerine geçiyor: gün ekranının her parçası "hangi gün" sorusunu
    // aynı provider'a soruyor.
    overrides: [viewedDateProvider.overrideWithValue(dateKey)],
    child: Scaffold(
      appBar: AppBar(),
      body: const DayBody(),
    ),
  );
}

/// Gün ekranının gövdesi.
class DayBody extends ConsumerWidget {
  const DayBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(viewedDateProvider);
    final planDay = ref.watch(dayPlanDayProvider(date));
    final isFuture =
        ref.watch(dayPositionProvider(date)) == DayPosition.future;

    return AppAsyncView<FullPlanDay?>(
      value: planDay,
      onRetry: () => ref.invalidate(dayPlanDayProvider(date)),
      // v3: üç bölüm — kahraman, sırada, akış. v2'nin dokuz bölümlük
      // kaydırma duvarı akış satırlarına indi; öğün listesi Diyet
      // sekmesinde, takviye/ölçüm/kural/not akışın "tamamı"nda.
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
            _DayEditActions(day: day),
          ],

          const SizedBox(height: AppSpacing.xl2),

          // Gelecek güne kayıt girilmiyor: yarın ne yediğini yazmak
          // anlamsız ve alanı bırakmak kullanıcıyı yanlış güne kayıt
          // yapmaya davet ederdi. Plan bölümü görünür kalıyor —
          // "yarın ne var" meşru bir soru.
          if (isFuture) _FutureNotice() else DayFlowSection(day: day),
        ],
      ),
    );
  }
}

/// Tarih başlığı — eyebrow, gün adı ve tarih gezinmesi.
///
/// Oklar ve tarihe dokunma geçmişe (ve plan varsa geleceğe) açılıyor.
/// **Bugüne dönmek push değil pop:** `dateKey = bugün` ile ikinci bir
/// ekran açmak, Bugün sekmesinin ikizini üretirdi.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(viewedDateProvider);
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final position = ref.watch(dayPositionProvider(date));
    final shown = DateTime.parse(date);
    final day = ref.watch(dayPlanDayProvider(date)).value;

    final eyebrow = [
      TurkishText.upper(TurkishDate.weekdayAndDay(shown)),
      if (day case final d?)
        TurkishText.upper(context.l10n.todayWeekNumber(d.weekIndex)),
    ].join(' · ');

    // Geçmiş ve gelecek farklı etiketler taşıyor: ikisi de "bugün
    // değil" ama kullanıcının yapabildikleri farklı ve renk tek başına
    // bunu söylemiyor.
    final (badge, badgeColor) = switch (position) {
      DayPosition.today => (null, null),
      DayPosition.past => (context.l10n.dayBadgePast, semantic.warning),
      DayPosition.future => (
        context.l10n.dayBadgeFuture,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                eyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: context.l10n.dayPrevious,
              onPressed: () => _goTo(
                context,
                ref,
                shown.subtract(const Duration(days: 1)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: context.l10n.dayPickDate,
              onPressed: () => _pickDate(context, ref, shown),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: context.l10n.dayNext,
              onPressed: () =>
                  _goTo(context, ref, shown.add(const Duration(days: 1))),
            ),
          ],
        ),
        Semantics(
          header: true,
          child: Text(
            position == DayPosition.today
                ? context.l10n.todayTitle
                : TurkishDate.weekdayAndDay(shown),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (badge case final label?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () => _backToToday(context, ref),
                  child: Text(context.l10n.dayBackToToday),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 2),
      lastDate: DateTime(current.year + 2),
    );
    if (picked == null || !context.mounted) return;
    _goTo(context, ref, picked);
  }

  void _goTo(BuildContext context, WidgetRef ref, DateTime target) {
    final key = dateKeyOf(target);
    if (key == ref.read(todayIsoProvider)) {
      _backToToday(context, ref);
      return;
    }

    // Gün ekranından güne geçerken yığına yenisini eklemek yerine
    // mevcut olanı değiştiriyoruz; aksi hâlde bir hafta gezinen
    // kullanıcı geri tuşuna yedi kez basmak zorunda kalırdı.
    final route = MaterialPageRoute<void>(
      builder: (_) => DayScreen(dateKey: key),
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  /// Bugüne dönmek: push edilmişse pop, sekmedeyse zaten bugündeyiz.
  void _backToToday(BuildContext context, WidgetRef ref) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }
}

/// Son yedi günün doluluk şeridi.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(viewedDateProvider);
    final week = ref.watch(dayWeekFillProvider(date)).value;
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
    final date = ref.watch(viewedDateProvider);
    final weight = ref.watch(dayWeightProvider(date)).value;
    final log = ref.watch(dayLogProvider(date)).value;
    final rules = ref.watch(dailyRulesProvider).value ?? const [];

    final isoDate = date;
    final energy = ref.watch(dayEnergyProvider(isoDate)).value;
    final goal = ref.watch(dailyKcalGoalProvider).value;
    // **Bakılan günden** hesaplanıyor, bugünden değil: geçmiş bir
    // günün ekranında bugünün bütçesini göstermek, kullanıcıya o gün
    // hiç olmamış bir sayı sunmak olurdu.
    final remaining = energy == null
        ? null
        : remainingBudget(goalKcal: goal, day: energy);
    final gauge = energy == null
        ? null
        : gaugeFraction(goalKcal: goal, day: energy);
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
    final date = ref.watch(viewedDateProvider);
    final isToday = ref.watch(dayPositionProvider(date)) == DayPosition.today;
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    // "Sıradaki iş" ve canlı şimdi işareti yalnız bugünde. Geçmiş bir
    // günde "şimdi" diye bir şey yok; dünün ekranında bugünün saatine
    // göre bir kart göstermek yanlış olurdu.
    final next = isToday ? SlotList.nextSlotOf(day, now) : null;

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
        AppSectionLabel(
          context.l10n.todaySpineLabel,
          trailing: IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.l10n.planSlotNew,
            onPressed: () => showSlotEditorSheet(context, dayId: day.id),
          ),
        ),
        SlotList(day: day, now: isToday ? now : null, hoistNext: isToday),

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

/// Planı düzenleme girişleri.
///
/// **Gün ekranında, plan sekmesinde değil:** kullanıcı "bugün 08:00
/// yerine 09:00'da kahvaltı edeceğim" derken zaten o güne bakıyor;
/// plan sekmesine gidip günü yeniden bulması gereksiz bir yolculuk
/// olurdu.
class _DayEditActions extends StatelessWidget {
  const _DayEditActions({required this.day});

  final FullPlanDay day;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Wrap(
      spacing: AppSpacing.sm,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: Text(context.l10n.planEditDay),
          onPressed: () => showDayEditorSheet(context, day: day),
        ),
        TextButton.icon(
          icon: const Icon(Icons.fitness_center),
          label: Text(context.l10n.planExerciseNew),
          onPressed: () => showExerciseEditorSheet(context, dayId: day.id),
        ),
      ],
    ),
  );
}

/// Gelecek günde kayıt alanlarının yerine geçen tek satır.
class _FutureNotice extends StatelessWidget {
  const _FutureNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.dayFutureNoEntry,
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
