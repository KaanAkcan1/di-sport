import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/presentation/day_meals_card.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/settings/application/meal_behavior_providers.dart';
import 'package:disport/features/settings/domain/meal_behavior.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const iso = '2026-09-02';
  late List<String> skipCalls;

  setUp(() => skipCalls = []);

  final day = FullPlanDay(
    id: 'd1',
    date: DateTime(2026, 9, 2),
    type: PlanDayType.home,
    weekIndex: 1,
    slots: const [
      PlanSlot(
        id: 's1',
        time: '08:00',
        kind: SlotKind.meal,
        label: 'Kahvaltı',
        mealKind: MealKind.kahvalti,
        items: [PlanMealItem(foodId: 'egg')],
      ),
    ],
    exercises: const [],
  );

  Widget wrap({DailyLogView log = const DailyLogView()}) => ProviderScope(
    overrides: [
      todayIsoProvider.overrideWithValue(iso),
      dayMealsProvider(iso).overrideWith(
        (ref) => Stream.value(const <MealEntry>[]),
      ),
      dayActivitiesProvider(iso).overrideWith(
        (ref) => Stream.value(const <ActivityLog>[]),
      ),
      dayPlanDayProvider(iso).overrideWith((ref) => Stream.value(day)),
      dayLogProvider(iso).overrideWith((ref) => Stream.value(log)),
      mealBehaviorsProvider.overrideWith(
        (ref) => Stream.value(const <MealBehaviorEntry>[]),
      ),
      // Plan toplamı çözülemesin — test rozetle değil atlama ile ilgili.
      foodByIdProvider('egg').overrideWith((ref) async => null),
      mealSkipWriterProvider.overrideWithValue((
        String isoDate, {
        required String mealKindName,
        String? reason,
      }) async {
        skipCalls.add('$mealKindName:$reason');
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: const Scaffold(
        body: SingleChildScrollView(child: DayMealsCard()),
      ),
    ),
  );

  testWidgets('planlı boş öğünde atlandı eylemi neden çipiyle yazar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('skip-meal-kahvalti')));
    await tester.pumpAndSettle();

    expect(find.text('Neden atlandı?'), findsOneWidget);
    await tester.tap(find.text('Mesai'));
    await tester.pumpAndSettle();

    expect(skipCalls, ['kahvalti:Mesai']);
  });

  testWidgets('atlanmış öğün nedeniyle görünür, geri alınabilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(log: const DailyLogView(skippedMeals: {'kahvalti': 'mesai'})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atlandı: mesai'), findsOneWidget);
    // Atlanmışken "Atlandı" eylemi ikinci kez sunulmaz.
    expect(find.byKey(const Key('skip-meal-kahvalti')), findsNothing);

    await tester.tap(find.byKey(const Key('skip-undo-kahvalti')));
    await tester.pumpAndSettle();

    expect(skipCalls, ['kahvalti:null']);
  });
}
