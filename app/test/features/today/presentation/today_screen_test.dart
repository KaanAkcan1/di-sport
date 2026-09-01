import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/nutrition/domain/calorie_budget.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/daily_rules_repository.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/today/presentation/daily_flags_card.dart';
import 'package:disport/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../plan/plan_fixtures.dart';

/// Ekran testleri veritabanına dokunmaz: Drift akışları gerçek async
/// I/O ile gelir ve `pumpAndSettle` sahte-async bölgesinde asılı kalır.
/// Depo davranışı kendi testlerinde doğrulanıyor.
/// Akışın "tamamı"nı açıp kural kartına kaydırır.
///
/// v3'te ölçüm/kural/not bölümleri akışın genişletme düğmesinin
/// arkasında — test de kullanıcı gibi önce düğmeye basıyor.
/// Akışın "tamamı"nı açar — ölçüm/kural/not v3'te bunun arkasında.
Future<void> expandFlow(WidgetTester tester) async {
  final expander = find.textContaining('Günün tamamı');
  await tester.scrollUntilVisible(
    expander,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  // Alt gezinme çubuğu düğmenin bir kısmını örtebiliyor; kaydırma
  // sonrası bir kare daha bekleyip düğmenin merkezine dokunuyoruz.
  await tester.pumpAndSettle();
  await tester.tap(expander, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> scrollToRules(WidgetTester tester) async {
  await expandFlow(tester);
  await tester.scrollUntilVisible(
    find.text('3 litre su'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  final day = fixturePlan().days.first;

  Widget wrap({
    FullPlanDay? planDay,
    DailyLogView log = const DailyLogView(),
    double? weight,
    double? sleep,
    int missedStreak = 0,
    DayEnergy energy = const DayEnergy(),
    int? kcalGoal,
    List<MealEntry> meals = const [],
  }) => ProviderScope(
    overrides: [
      // Besin ve aktivite akışları da Drift; ekran testi bağlanmamalı.
      dayEnergyProvider(
        '2026-08-31',
      ).overrideWith((ref) => Stream.value(energy)),
      dayMealsProvider(
        '2026-08-31',
      ).overrideWith((ref) => Stream.value(meals)),
      dayActivitiesProvider(
        '2026-08-31',
      ).overrideWith((ref) => Stream.value(const <ActivityLog>[])),
      dailyKcalGoalProvider.overrideWith((ref) async => kcalGoal),
      dailyProteinGoalProvider.overrideWith((ref) async => null),
      frequentFoodsProvider.overrideWith((ref) => Stream.value(const <Food>[])),
      // Takviye dozları da Drift akışı; ekran testi bağlanmamalı.
      todayDosesProvider.overrideWithValue(const <SupplementDose>[]),
      todayIsoProvider.overrideWithValue('2026-08-31'),
      dayPlanDayProvider('2026-08-31').overrideWith((ref) => Stream.value(planDay)),
      dayLogProvider('2026-08-31').overrideWith((ref) => Stream.value(log)),
      dayWeightProvider('2026-08-31').overrideWith((ref) => Stream.value(weight)),
      daySleepProvider('2026-08-31').overrideWith((ref) => Stream.value(sleep)),
      missedStreakProvider.overrideWith((ref) async => missedStreak),
      // Kurallar artık veritabanından geliyor; ekran testi Drift
      // akışına bağlanmamalı (asılır). Yerleşik üçü sabitle veriliyor.
      dailyRulesProvider.overrideWith(
        (ref) => Stream.value(const [
          DailyRule(
            id: BuiltInRules.water,
            label: '3 litre su',
            iconKey: 'water',
            isBuiltIn: true,
          ),
          DailyRule(
            id: BuiltInRules.noAlcoholSugar,
            label: 'Alkol ve şeker yok',
            iconKey: 'noDrinks',
            isBuiltIn: true,
          ),
          DailyRule(
            id: BuiltInRules.workout,
            label: 'Antrenman yapıldı',
            iconKey: 'fitness',
            isBuiltIn: true,
          ),
        ]),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: const Scaffold(body: TodayScreen()),
    ),
  );

  group('plan yokken', () {
    testWidgets('yönlendirme gösterir ama tartı çalışmaya devam eder', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('Bugün için plan yok'), findsOneWidget);
      // Tartı ve kutucuklar plan olmadan da kullanılabilmeli —
      // v3'te akışın "tamamı" arkasındalar.
      await expandFlow(tester);
      expect(find.byKey(const Key('weight-field')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('3 litre su'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('3 litre su'), findsOneWidget);
    });
  });

  group('plan varken', () {
    testWidgets('günün slotlarını saatleriyle listeler', (tester) async {
      await tester.pumpWidget(wrap(planDay: day));
      await tester.pumpAndSettle();

      expect(find.text('4 haşlanmış yumurta'), findsOneWidget);
      expect(find.text('Fabrika menüsü'), findsOneWidget);
      expect(find.text('06:30'), findsOneWidget);
    });

    testWidgets('haftanın notunu ve akşam önerisini gösterir', (tester) async {
      await tester.pumpWidget(wrap(planDay: day));
      await tester.pumpAndSettle();

      expect(find.text('Hafta 1 notu'), findsOneWidget);
      // Ekran M10'da düzenleme eylemleriyle uzadı; öneri artık ilk
      // pencerede kurulmuyor.
      await tester.scrollUntilVisible(
        find.textContaining('Akşam önerisi'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Akşam önerisi: Izgara tavuk'),
        findsOneWidget,
      );
    });

    testWidgets('antrenman slotu kart olarak, hareket sayısıyla çıkar', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(planDay: day));
      await tester.pumpAndSettle();

      expect(find.text('Salon — kardiyo'), findsOneWidget);
      expect(find.textContaining('2 hareket'), findsOneWidget);
    });

    testWidgets('işaretli slot üstü çizili gösterilir', (tester) async {
      await tester.pumpWidget(
        wrap(
          planDay: day,
          log: DailyLogView(checkedSlotIds: {day.slots.first.id}),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('4 haşlanmış yumurta'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });
  });

  group('ölçüm girişleri', () {
    testWidgets('kaydedilmiş kilo alana yansır, virgülle', (tester) async {
      await tester.pumpWidget(wrap(weight: 109.5));
      await tester.pumpAndSettle();
      await expandFlow(tester);

      final field = tester.widget<TextField>(
        find.byKey(const Key('weight-field')),
      );
      expect(field.controller?.text, '109,5');
    });

    testWidgets('değer yokken alan boş', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await expandFlow(tester);

      final field = tester.widget<TextField>(
        find.byKey(const Key('weight-field')),
      );
      expect(field.controller?.text, '');
    });

    testWidgets('uyku alanı ayrı', (tester) async {
      await tester.pumpWidget(wrap(sleep: 6.5));
      await tester.pumpAndSettle();
      await expandFlow(tester);

      final field = tester.widget<TextField>(
        find.byKey(const Key('sleep-field')),
      );
      expect(field.controller?.text, '6,5');
    });
  });

  group('günün kuralları', () {
    testWidgets('üç kutucuk ve sayaç görünür', (tester) async {
      await tester.pumpWidget(
        wrap(log: const DailyLogView(waterTargetMet: true, workoutDone: true)),
      );
      await tester.pumpAndSettle();

      await scrollToRules(tester);
      expect(find.text('3 litre su'), findsOneWidget);
      expect(find.text('Alkol ve şeker yok'), findsOneWidget);
      expect(find.text('Antrenman yapıldı'), findsOneWidget);

      // Sayaç iki yerde: ekranın tepesindeki özet şeridi ve kartın
      // kendi rozeti. İkisi de kasıtlı — şerit bir bakışta durum verir,
      // kart kutucukları çevirirken anlık geri bildirim. Bu yüzden
      // arama karta sınırlanıyor.
      expect(
        find.descendant(
          of: find.byType(DailyFlagsCard),
          matching: find.text('2/3'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('durumlar anahtarlara yansır', (tester) async {
      await tester.pumpWidget(wrap(log: const DailyLogView(workoutDone: true)));
      await tester.pumpAndSettle();

      await scrollToRules(tester);
      final tile = tester.widget<SwitchListTile>(
        find.byKey(const Key('flag-workout')),
      );
      expect(tile.value, isTrue);
    });
  });

  group('kaçak uyarısı', () {
    testWidgets('tek gün kaçırınca çıkmaz', (tester) async {
      await tester.pumpWidget(wrap(missedStreak: 1));
      await tester.pumpAndSettle();
      expect(find.textContaining('üst üste antrenman yok'), findsNothing);
    });

    testWidgets('iki gün üst üste kaçırınca uyarır', (tester) async {
      await tester.pumpWidget(wrap(missedStreak: 2));
      await tester.pumpAndSettle();

      expect(find.text('2 gün üst üste antrenman yok'), findsOneWidget);
      expect(find.textContaining('Kural buydu'), findsOneWidget);
    });
  });

  testWidgets('not alanı kaydedilmiş metni gösterir', (tester) async {
    await tester.pumpWidget(
      wrap(log: const DailyLogView(note: 'Şınavda zorlandım.')),
    );
    await tester.pumpAndSettle();

    // v3: not alanı akışın "tamamı" arkasında.
    await expandFlow(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('day-note-field')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('day-note-field')),
    );
    expect(field.controller?.text, 'Şınavda zorlandım.');
  });
}
