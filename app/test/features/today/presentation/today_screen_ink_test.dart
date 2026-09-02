import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/nutrition/domain/calorie_budget.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../plan/plan_fixtures.dart';

/// M12 — Bugün ekranının mürekkep dili sözleşmesi.
void main() {
  final day = fixturePlan().days.first;

  Widget wrap({
    FullPlanDay? planDay,
    DailyLogView log = const DailyLogView(),
    double? weight,
    DateTime? now,
    List<({DateTime day, bool filled})>? week,
    DayEnergy energy = const DayEnergy(),
    int? kcalGoal,
  }) {
    final at = now ?? DateTime(2026, 8, 31, 10);

    return ProviderScope(
      overrides: [
        // Takviye dozları da Drift akışı; ekran testi bağlanmamalı.
        todayDosesProvider.overrideWithValue(const <SupplementDose>[]),
        // Besin ve aktivite de Drift akışı.
        dayEnergyProvider(
          '2026-08-31',
        ).overrideWith((ref) => Stream.value(energy)),
        dayMealsProvider(
          '2026-08-31',
        ).overrideWith((ref) => Stream.value(const <MealEntry>[])),
        dayActivitiesProvider(
          '2026-08-31',
        ).overrideWith((ref) => Stream.value(const <ActivityLog>[])),
        dailyKcalGoalProvider.overrideWith((ref) async => kcalGoal),
        dailyProteinGoalProvider.overrideWith((ref) async => null),
        frequentFoodsProvider.overrideWith(
          (ref) => Stream.value(const <Food>[]),
        ),
        todayIsoProvider.overrideWithValue('2026-08-31'),
        clockProvider.overrideWith((ref) => Stream.value(at)),
        dayPlanDayProvider('2026-08-31').overrideWith((ref) => Stream.value(planDay)),
        dayLogProvider('2026-08-31').overrideWith((ref) => Stream.value(log)),
        dayWeightProvider('2026-08-31').overrideWith((ref) => Stream.value(weight)),
        daySleepProvider('2026-08-31').overrideWith((ref) => Stream.value(null)),
      dayStepsProvider('2026-08-31').overrideWith((ref) => Stream.value(null)),
        missedStreakProvider.overrideWith((ref) async => 0),
        dailyRulesProvider.overrideWith((ref) => Stream.value(const [])),
        dayWeekFillProvider('2026-08-31').overrideWith(
          (ref) => Stream.value(
            week ??
                [
                  for (var back = 6; back >= 0; back--)
                    (
                      day: DateTime(2026, 8, 31 - back),
                      filled: back.isEven,
                    ),
                ],
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: const Scaffold(body: TodayScreen()),
      ),
    );
  }

  testWidgets('tek kahraman rakam, tek metrik şeridi', (tester) async {
    // M6'nın `AppStatBand`'i üç sayıyı eşit ağırlıkta gösteriyordu ve
    // ekranın "en önemli sayısı" diye bir şey yoktu. Sınıf M12'de
    // silindi; bu test yerine geçen düzeni sabitliyor.
    await tester.pumpWidget(wrap(planDay: day));
    await tester.pumpAndSettle();

    expect(find.byType(AppHeroNumber), findsOneWidget);
    expect(find.byType(AppMetricStrip), findsOneWidget);
  });

  testWidgets('kilo yokken kahraman — gösterir', (tester) async {
    await tester.pumpWidget(wrap(planDay: day));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsWidgets);
  });

  testWidgets('bütçe varsa kahraman kalan kaloriyi gösterir', (tester) async {
    // M9'da kahraman kilodan kalan kaloriye döndü; kilo metrik
    // şeridine indi (spec §2a).
    await tester.pumpWidget(
      wrap(
        planDay: day,
        weight: 108.9,
        kcalGoal: 2200,
        energy: const DayEnergy(eaten: 1500, burned: 300),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppHeroNumber),
        matching: find.text('1000'),
      ),
      findsOneWidget,
    );
  });

  group('sıradaki iş', () {
    testWidgets('spot kartta öne çekilir, akışta da durur', (
      tester,
    ) async {
      // v3.1: akış tek doğruluk kaynağı — SIRADA onun öne çekilmiş
      // kopyası, satır akıştan silinmez (mockup B1).
      final slots = [...day.slots]..sort((a, b) => a.time.compareTo(b.time));
      final at = DateTime(2026, 8, 31, 0, 1);
      final next = slots.first;

      await tester.pumpWidget(wrap(planDay: day, now: at));
      await tester.pumpAndSettle();

      expect(find.byType(AppSpotCard), findsOneWidget);
      expect(find.text(next.label), findsWidgets);
    });

    testWidgets('gün bitmişse spot kart çizilmez', (tester) async {
      // Gece yarısına yakın "sırada" diye bir şey yok.
      await tester.pumpWidget(
        wrap(planDay: day, now: DateTime(2026, 8, 31, 23, 59)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSpotCard), findsNothing);
    });
  });

  testWidgets('bölüm etiketi büyük harfle çizilir', (tester) async {
    await tester.pumpWidget(wrap(planDay: day));
    await tester.pumpAndSettle();

    // v3.1: omurga gitti, bölüm etiketi artık akışın.
    expect(find.text('GÜNÜN AKIŞI'), findsOneWidget);
  });

  testWidgets('plan yokken kahraman yine çizilir — tartı bağımsız', (
    tester,
  ) async {
    // Plan yoksa bütçe de yok; kahraman **yenen** kaloriyi gösteriyor
    // (spec §5.4) — hedef uydurmak yanlış olurdu.
    await tester.pumpWidget(
      wrap(weight: 108.9, energy: const DayEnergy(eaten: 640)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppHeroNumber), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppHeroNumber),
        matching: find.text('640'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppSpotCard), findsNothing);
  });
}
