import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/data/metric_definitions_repository.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/nutrition/domain/calorie_budget.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/progress/application/progress_providers.dart';
import 'package:disport/features/progress/domain/transition_criteria.dart';
import 'package:disport/features/settings/application/settings_providers.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/daily_rules_repository.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Widget wrap() => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      // Kabuk testi sekme geçişini sınar, katalog içeriğini değil.
      // Bu override olmadan Katalog sekmesi gerçek Drift akışına bağlanır
      // ve `pumpAndSettle` o akışı bekleyerek asılı kalır — akış gerçek
      // async I/O ile gelir, testWidgets ise sahte-async bölgesinde çalışır.
      filteredExercisesProvider.overrideWith(
        (ref) => Stream.value(const <Exercise>[]),
      ),
      // Besin, aktivite ve kalori akışları da Drift; kabuk testi
      // bunlara bağlanırsa aynı şekilde asılır.
      activityCatalogProvider('').overrideWith(
        (ref) => Stream.value(const <Activity>[]),
      ),
      todayIsoProvider.overrideWithValue('2026-09-01'),
      dayEnergyProvider(
        '2026-09-01',
      ).overrideWith((ref) => Stream.value(const DayEnergy())),
      dayMealsProvider(
        '2026-09-01',
      ).overrideWith((ref) => Stream.value(const <MealEntry>[])),
      dayActivitiesProvider(
        '2026-09-01',
      ).overrideWith((ref) => Stream.value(const <ActivityLog>[])),
      dailyKcalGoalProvider.overrideWith((ref) async => null),
      dailyProteinGoalProvider.overrideWith((ref) async => null),
      frequentFoodsProvider.overrideWith((ref) => Stream.value(const <Food>[])),
      netKcalByDayProvider(
        '2026-08-26',
        '2026-09-01',
      ).overrideWith((ref) => Stream.value(const <String, double>{})),
      // Bugün ekranı da veritabanına bağlı; kabuk testi içeriği değil
      // sekme geçişini sınıyor.
      dayPlanDayProvider('2026-09-01').overrideWith((ref) => Stream.value(null)),
      dayLogProvider('2026-09-01').overrideWith((ref) => Stream.value(const DailyLogView())),
      dayWeightProvider('2026-09-01').overrideWith((ref) => Stream.value(null)),
      daySleepProvider('2026-09-01').overrideWith((ref) => Stream.value(null)),
      missedStreakProvider.overrideWith((ref) async => 0),
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
      // Kabuk artık onboarding kontrolünün arkasında; test doğrudan
      // sekmelere bakıyor.
      isOnboardedProvider.overrideWith((ref) async => true),
      // M12: `DisportApp` tema modunu Drift akışından okuyor — kabuk
      // testinde gerçek akışa bağlanırsa `pumpAndSettle` asılır.
      themeModeProvider.overrideWith((ref) => Stream.value(ThemeMode.dark)),
      // M7: dil ayarı da Drift akışı; aynı sebeple sabitleniyor.
      appLocaleProvider.overrideWith((ref) => Stream.value(const Locale('tr'))),
      // Hafta şeridi de günlük kayıtları akışla okuyor.
      // Takviye dozları da Drift akışı; ekran testi bağlanmamalı.
      todayDosesProvider.overrideWithValue(const <SupplementDose>[]),
      dayWeekFillProvider('2026-09-01').overrideWith(
        (ref) => Stream.value(const <({DateTime day, bool filled})>[]),
      ),
      // Plan ekranı da veritabanına bağlı.
      activePlanProvider.overrideWith((ref) async => null),
      // Sağlık sekmesi de öyle. `IndexedStack` beş ekranı birden
      // kurduğu için görünmeyen sekmenin akışı da açılıyor; biri
      // gerçek Drift akışına bağlı kalırsa `pumpAndSettle` asılır.
      labsByPanelProvider.overrideWith(
        (ref) => Stream.value(const <String, List<LabEntry>>{}),
      ),
      dueLabsProvider.overrideWith((ref) async => const <DueSchedule>[]),
      latestMetricsProvider.overrideWith(
        (ref) => Stream.value(const <String, MetricSample>{}),
      ),
      // Ölçüm tanımları da Drift akışı; ekran testi bağlanmamalı.
      periodicMetricsProvider.overrideWith(
        (ref) => Stream.value(const [
          MetricDefinition(
            kind: MetricKinds.waist,
            label: 'Bel çevresi',
            unit: 'cm',
            decimals: 1,
            isBuiltIn: true,
            isDaily: false,
          ),
          MetricDefinition(
            kind: MetricKinds.pushupMax,
            label: 'Şınav',
            unit: 'tekrar',
            decimals: 0,
            isBuiltIn: true,
            isDaily: false,
          ),
        ]),
      ),
      // İlerleme sekmesi de aynı sebeple.
      progressViewProvider.overrideWith(
        (ref) async => ProgressViewData(
          weights: const [],
          trend: const [],
          weeks: const [],
          latestMetrics: const {},
          criteria: evaluateTransition(
            latestWeight: null,
            latestPushupMax: null,
            painFreeConfirmed: false,
          ),
          hasPlan: false,
        ),
      ),
    ],
    child: const DisportApp(),
  );

  testWidgets('shows five tabs and starts on Today', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // 'Bugün' hem sekme etiketi hem AppBar başlığı olarak görünür.
    expect(find.text('Bugün'), findsWidgets);
    for (final label in ['Plan', 'İlerleme', 'Sağlık', 'Katalog']) {
      expect(find.text(label), findsOneWidget);
    }
    // Tartı alanı ekranın alt yarısında; gövde tembel bir liste ve
    // M9'da öğün bölümü eklenince artık ilk pencerede kurulmuyor.
    // Kaydırmak testin kullanıcıyı taklit etmesi.
    await tester.scrollUntilVisible(
      find.byKey(const Key('weight-field')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('weight-field')), findsOneWidget);
  });

  testWidgets('tapping a tab switches screen and title', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();

    // Katalog ekranı geldi: yer sekmeleri ve filtre düğmesi görünür.
    // M12'de yer bir filtre çipi değil bağlam sekmesi oldu.
    //
    // `TextField` sayısına bakılmıyor: sekmeler `IndexedStack` içinde
    // canlı kaldığı için Bugün ekranının tartı, uyku ve not alanları da
    // ağaçta duruyor — bu kasıtlı, durum korunsun diye.
    expect(find.widgetWithText(Tab, 'Salonda'), findsOneWidget);
    expect(find.byKey(const Key('open-filters')), findsOneWidget);

    // Başlangıçta 'Bugün' iki yerde: AppBar başlığı + sekme etiketi.
    // Katalog'a geçince başlık değişir, geriye yalnız sekme etiketi kalır.
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Katalog'), findsNWidgets(2)); // başlık + sekme
  });

  testWidgets('IndexedStack keeps all five screens alive', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.children, hasLength(5));
    expect(stack.index, 0);
  });
}
