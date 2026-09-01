import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
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
  }) {
    final at = now ?? DateTime(2026, 8, 31, 10);

    return ProviderScope(
      overrides: [
        // Takviye dozları da Drift akışı; ekran testi bağlanmamalı.
        todayDosesProvider.overrideWithValue(const <SupplementDose>[]),
        todayIsoProvider.overrideWithValue('2026-08-31'),
        clockProvider.overrideWith((ref) => Stream.value(at)),
        todayPlanDayProvider.overrideWith((ref) => Stream.value(planDay)),
        todayLogProvider.overrideWith((ref) => Stream.value(log)),
        todayWeightProvider.overrideWith((ref) => Stream.value(weight)),
        todaySleepProvider.overrideWith((ref) => Stream.value(null)),
        missedStreakProvider.overrideWith((ref) async => 0),
        dailyRulesProvider.overrideWith((ref) => Stream.value(const [])),
        weekFillProvider.overrideWith(
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

  testWidgets('kilo varsa kahraman rakam olarak çizilir', (tester) async {
    await tester.pumpWidget(wrap(planDay: day, weight: 108.9));
    await tester.pumpAndSettle();

    // Ölçüm giriş alanı da aynı değeri taşıyor; kahramandakini arıyoruz.
    expect(
      find.descendant(
        of: find.byType(AppHeroNumber),
        matching: find.text('108,9'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hafta şeridi yedi nokta basar', (tester) async {
    await tester.pumpWidget(wrap(planDay: day));
    await tester.pumpAndSettle();

    expect(find.byType(AppWeekDots), findsOneWidget);
  });

  group('sıradaki iş', () {
    testWidgets('spot kartta gösterilir, listede tekrarlanmaz', (
      tester,
    ) async {
      // Aynı slotun hem kartta hem listede durması tekrar olurdu.
      final slots = [...day.slots]..sort((a, b) => a.time.compareTo(b.time));
      final at = DateTime(2026, 8, 31, 0, 1);
      final next = slots.first;

      await tester.pumpWidget(wrap(planDay: day, now: at));
      await tester.pumpAndSettle();

      expect(find.byType(AppSpotCard), findsOneWidget);
      expect(find.text(next.label), findsOneWidget);
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

    expect(find.text('GÜNÜN OMURGASI'), findsOneWidget);
  });

  testWidgets('plan yokken kahraman yine çizilir — tartı bağımsız', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(weight: 108.9));
    await tester.pumpAndSettle();

    expect(find.byType(AppHeroNumber), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppHeroNumber),
        matching: find.text('108,9'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppSpotCard), findsNothing);
  });
}
