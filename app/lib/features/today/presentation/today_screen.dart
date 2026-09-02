import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_date.dart';
import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart'
    show profileEntriesProvider;
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart'
    show ProfileKeys;
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/calorie_budget.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/presentation/day_editor_sheet.dart';
import 'package:disport/features/plan/presentation/exercise_editor_sheet.dart';
import 'package:disport/features/plan/presentation/slot_kind_icon.dart';
import 'package:disport/features/settings/application/setup_providers.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/presentation/day_flow_section.dart';
import 'package:disport/features/today/presentation/missed_streak_banner.dart';
import 'package:disport/features/today/presentation/setup_panel.dart';
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
    // Bos AppBar mockup'ta yok: yalniz geri oku tasiyan bir bant
    // ekranin tepesini harciyordu. Geri, baslik satirinin sol ucunda
    // (mockup B2'nin eylem dizisi).
    child: const Scaffold(
      body: SafeArea(child: DayBody()),
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
    final position = ref.watch(dayPositionProvider(date));
    final isFuture = position == DayPosition.future;

    // Kurulum paneli yalnız bugünde ve yalnız kurulum bitmemişken;
    // geçmiş güne bakan kullanıcıya "ekipmanını seç" demek yersiz.
    final setup = position == DayPosition.today
        ? ref.watch(setupProgressProvider)
        : null;
    final showSetup = setup != null && !setup.complete;

    return AppAsyncView<FullPlanDay?>(
      value: planDay,
      onRetry: () => ref.invalidate(dayPlanDayProvider(date)),
      // v3: üç bölüm — kahraman, sırada, akış. v2'nin dokuz bölümlük
      // kaydırma duvarı akış satırlarına indi; öğün listesi Diyet
      // sekmesinde, takviye/ölçüm/kural/not akışın "tamamı"nda.
      data: (day) => AppScreenBody(
        children: [
          const _Header(),
          const SizedBox(height: AppSpacing.xl),
          // Kurulum bitmeden kahraman sayı çizilmiyor: kayıt yokken
          // kahraman anlamsız, panel ise ilk işleri gösteriyor.
          // Gelecek günde de çizilmiyor (mockup'ta gelecek karesi
          // kahramansız): yenmemiş bir günün "0 kcal"i bilgi değil.
          if (showSetup)
            SetupPanel(progress: setup)
          else if (!isFuture)
            _Hero(day: day),
          if (showSetup || !isFuture) const SizedBox(height: AppSpacing.xl2),
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
          // yapmaya davet ederdi. Plan (akış) görünür kalıyor —
          // "yarın ne var" meşru bir soru — ama salt okunur.
          if (isFuture) ...[
            _FutureNotice(),
            const SizedBox(height: AppSpacing.lg),
          ],
          DayFlowSection(day: day, readOnly: isFuture),
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

    // Doğum günü kutlaması (v3 §3.1): yalnız bugünde, yalnız ay-gün
    // eşleşince, tek satır — başka hiçbir davranış değişmez.
    String? birthday;
    if (position == DayPosition.today) {
      final profile = ref.watch(profileEntriesProvider).value;
      final birth = DateTime.tryParse(
        profile?[ProfileKeys.birthDate] ?? '',
      );
      final name = (profile?[ProfileKeys.firstName] ?? '').trim();
      if (birth != null &&
          name.isNotEmpty &&
          birth.month == shown.month &&
          birth.day == shown.day) {
        birthday = context.l10n.todayBirthday(name);
      }
    }

    // Mockup B1/B2: büyük başlık günün adı, üst satır tarih · hafta.
    // Geçmişte üst satır amber "GEÇMİŞ GÜN · …" — durum başlığın
    // kendisinde, ayrıca rozet aranmaz.
    final eyebrow = [
      if (position == DayPosition.past)
        TurkishText.upper(context.l10n.dayBadgePast)
      else if (position == DayPosition.future)
        TurkishText.upper(context.l10n.dayBadgeFuture),
      TurkishText.upper(TurkishDate.dayMonth(shown)),
      if (day case final d?)
        TurkishText.upper(context.l10n.todayWeekNumber(d.weekIndex)),
    ].join(' · ');

    // Üst satırın rengi durumu da taşıyor (metinle birlikte): geçmiş
    // amber, gelecek soluk, bugün marka.
    final eyebrowColor = switch (position) {
      DayPosition.today => theme.colorScheme.primary,
      DayPosition.past => semantic.warning,
      DayPosition.future => theme.colorScheme.onSurfaceVariant,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                key: const Key('day-back'),
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
              ),
            Expanded(
              child: Text(
                eyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: eyebrowColor,
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
            TurkishDate.weekdays[shown.weekday - 1],
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (birthday case final text?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        // Durum etiketi üst satıra taşındı; burada yalnız dönüş
        // eylemi kalıyor.
        if (position != DayPosition.today)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _backToToday(context, ref),
              child: Text(context.l10n.dayBackToToday),
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

/// Günün kahraman rakamı ve metrik şeridi — panel içinde (mockup B1).
///
/// Şerit bakılan güne göre değişir: bugün Protein · Yakılan · Su ·
/// İlaç (günün canlı soruları); geçmiş/gelecek Protein · Yakılan ·
/// Kilo (mockup B2 — o günün özeti). Program/kural sayaçları şeritte
/// değil, akış sayacında.
class _Hero extends ConsumerWidget {
  const _Hero({required this.day});

  final FullPlanDay? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(viewedDateProvider);
    final isToday = ref.watch(dayPositionProvider(date)) == DayPosition.today;
    final weight = ref.watch(dayWeightProvider(date)).value;
    final log = ref.watch(dayLogProvider(date)).value;

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

    final waterMl = log?.waterMl;
    final waterTarget = ref.watch(waterTargetMlProvider).value;
    final doses = isToday ? ref.watch(todayDosesProvider) : const <SupplementDose>[];
    final dosesTaken = doses.where((d) => d.isTaken).length;

    // Bütçe yoksa kahraman **yenen** kaloriyi gösteriyor (spec §5.4):
    // "kalan" demek için önce bir hedef olması gerekiyor ve plan içeri
    // alınmamış kullanıcıya hedef uydurmak yanlış olurdu.
    final heroValue = switch ((goal, energy)) {
      (null, final e?) => e.eaten.round().toString(),
      (_, _) => remaining?.round().toString(),
    };

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeroNumber(
            // Mockup B2: geçmiş günün başlığı "O GÜN ..." — dünün
            // ekranında "BUGÜN" yazmak yanlış günü işaret eder.
            caption: switch ((goal, isToday)) {
              (null, true) => context.l10n.todayHeroEatenNoPlan,
              (null, false) => context.l10n.dayHeroEatenPast,
              (_, true) => context.l10n.todayHeroRemaining,
              (_, false) => context.l10n.dayHeroRemainingPast,
            },
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
            // Mockup B1/B2: bugün şeridi su ve ilacı, geçmiş gün o
            // günün kilosunu taşır — dünün su bardağını saymak değil,
            // dünün özetini görmek isteniyor.
            if (isToday) ...[
              AppMetric(
                caption: context.l10n.todayMetricWater,
                value: waterMl == null
                    ? null
                    : TurkishNumber.format(waterMl / 1000, fractionDigits: 1),
                unit: waterTarget == null
                    ? 'L'
                    : '/${TurkishNumber.format(waterTarget / 1000, fractionDigits: 0)} L',
              ),
              AppMetric(
                caption: context.l10n.todayMetricMeds,
                value: doses.isEmpty ? null : '$dosesTaken',
                unit: doses.isEmpty ? null : '/${doses.length}',
              ),
            ] else
              AppMetric(
                caption: TurkishText.upper(
                  MetricKinds.labelOf(MetricKinds.weight),
                ),
                value: weight == null
                    ? null
                    : TurkishNumber.format(weight, fractionDigits: 1),
                unit: MetricKinds.unitOf(MetricKinds.weight),
              ),
          ]),
        ],
      ),
    );
  }
}

/// SIRADA kartı — mockup B1'de akışın üstündeki tek vurgu.
///
/// v3.1 (T19.0): omurga listesi silindi. Aynı slotları hem burada hem
/// GÜNÜN AKIŞI'nda listelemek ekranı ikiye katlıyordu ve mockup'ta
/// ikinci liste yok — akış tek doğruluk kaynağı, SIRADA onun öne
/// çekilmiş satırı.
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
    if (next == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
      child: AppSpotCard(
        eyebrow: context.l10n.todayNextEyebrow(next.time),
        title: next.label,
        subtitle: _subtitleFor(context, next),
        leading: slotKindIcon(next.kind),
        onTap: next.kind == SlotKind.workout
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkoutScreen(day: day),
                ),
              )
            : null,
      ),
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
