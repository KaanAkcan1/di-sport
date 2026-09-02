import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart'
    show profileEntriesProvider;
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/nutrition/domain/calorie_budget.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/settings/application/setup_providers.dart';
import 'package:disport/features/settings/domain/setup_progress.dart';
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

/// Tarihli gün ekranının sözleşmesi (spec §6.2).
void main() {
  const todayKey = '2026-08-31';
  final day = fixturePlan().days.first;

  Widget wrap({required String dateKey, FullPlanDay? planDay}) => ProviderScope(
    overrides: [
      todayIsoProvider.overrideWithValue(todayKey),
      clockProvider.overrideWith(
        (ref) => Stream.value(DateTime(2026, 8, 31, 10)),
      ),
      todayDosesProvider.overrideWithValue(const <SupplementDose>[]),
      // v3: kurulum paneli ve doğum günü satırı Drift akışlarına bakıyor.
      setupProgressProvider.overrideWith(
        (ref) => const SetupProgress(
          wizardDone: true,
          equipmentDone: true,
          medicalDone: true,
          rhythmDone: true,
        ),
      ),
      profileEntriesProvider.overrideWith(
        (ref) => Stream.value(const <String, String>{}),
      ),
      dayPlanDayProvider(dateKey).overrideWith((ref) => Stream.value(planDay)),
      dayLogProvider(
        dateKey,
      ).overrideWith((ref) => Stream.value(const DailyLogView())),
      dayWeightProvider(dateKey).overrideWith((ref) => Stream.value(null)),
      daySleepProvider(dateKey).overrideWith((ref) => Stream.value(null)),
      dayStepsProvider(dateKey).overrideWith((ref) => Stream.value(null)),
      dailyRulesProvider.overrideWith((ref) => Stream.value(const [])),
      missedStreakProvider.overrideWith((ref) async => 0),
      dayEnergyProvider(
        dateKey,
      ).overrideWith((ref) => Stream.value(const DayEnergy())),
      dayMealsProvider(
        dateKey,
      ).overrideWith((ref) => Stream.value(const <MealEntry>[])),
      dayActivitiesProvider(
        dateKey,
      ).overrideWith((ref) => Stream.value(const <ActivityLog>[])),
      dailyKcalGoalProvider.overrideWith((ref) async => null),
      dailyProteinGoalProvider.overrideWith((ref) async => null),
      frequentFoodsProvider.overrideWith((ref) => Stream.value(const <Food>[])),
      // v3: su satırı hedefi plandan okuyor — Drift'e bağlanmasın.
      waterTargetMlProvider.overrideWith((ref) async => 3000),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: DayScreen(dateKey: dateKey),
    ),
  );

  testWidgets('geçmiş gün amber rozetle işaretlenir', (tester) async {
    await tester.pumpWidget(wrap(dateKey: '2026-08-30', planDay: day));
    await tester.pumpAndSettle();

    // v3.1: durum etiketi üst satıra taşındı, tarihle birleşik.
    expect(find.textContaining('GEÇMİŞ GÜN'), findsOneWidget);
    expect(find.text('Bugüne dön'), findsOneWidget);
  });

  testWidgets('gelecek gün farklı etiket taşır', (tester) async {
    // İkisi de "bugün değil" ama kullanıcının yapabildikleri farklı;
    // aynı etiket ikisini de yanlış anlatırdı.
    await tester.pumpWidget(wrap(dateKey: '2026-09-05', planDay: day));
    await tester.pumpAndSettle();

    expect(find.textContaining('PLANLANAN GÜN'), findsOneWidget);
    expect(find.textContaining('GEÇMİŞ GÜN'), findsNothing);
  });

  testWidgets('geçmiş günde tartı girişi açık', (tester) async {
    // Spec §6.2: geçmiş gün tam yetkiyle açılıyor.
    await tester.pumpWidget(wrap(dateKey: '2026-08-30', planDay: day));
    await tester.pumpAndSettle();

    // v3: ölçüm alanları akışın "tamamı" arkasında.
    final expander = find.textContaining('Günün tamamı');
    await tester.scrollUntilVisible(
      expander,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(expander, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('weight-field')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('weight-field')), findsOneWidget);
  });

  testWidgets('gelecek günde kayıt alanları yok', (tester) async {
    // Yarın ne yediğini yazmak anlamsız; alanı bırakmak kullanıcıyı
    // yanlış güne kayıt yapmaya davet ederdi.
    await tester.pumpWidget(wrap(dateKey: '2026-09-05', planDay: day));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weight-field')), findsNothing);
    await tester.scrollUntilVisible(
      find.textContaining('kayıt günü gelince'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Planı görebilirsin ama kayıt günü gelince girilir.'),
      findsOneWidget,
    );
  });

  testWidgets('gelecek günde plan bölümü yine görünür', (tester) async {
    // "Yarın ne var" meşru bir soru.
    await tester.pumpWidget(wrap(dateKey: '2026-09-05', planDay: day));
    await tester.pumpAndSettle();

    // v3.1: omurga listesi silindi — plan, akış satırları olarak
    // görünüyor (T19.0).
    await tester.scrollUntilVisible(
      find.text('GÜNÜN AKIŞI'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('GÜNÜN AKIŞI'), findsOneWidget);
  });

  testWidgets('gelecek günde kahraman ve tartı satırı çizilmez', (
    tester,
  ) async {
    // Kullanıcı bildirimi: gelecek gün "BUGÜN YENEN 0" paneli ve
    // yapılamayacak bir tartı işi gösteriyordu.
    await tester.pumpWidget(wrap(dateKey: '2026-09-05', planDay: day));
    await tester.pumpAndSettle();

    expect(find.byType(AppHeroNumber), findsNothing);
    expect(find.text('Tartı'), findsNothing);
  });

  testWidgets('gün ekranında geri oku başlık satırında, AppBar yok', (
    tester,
  ) async {
    // Cihazda DayScreen hep push ediliyor; geri oku yalnız pop
    // edilebilen yığında çizilir. Test de aynı yığını kuruyor.
    await tester.pumpWidget(wrap(dateKey: '2026-08-30', planDay: day));
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(DayBody))).push(
      MaterialPageRoute<void>(
        builder: (_) => const DayScreen(dateKey: '2026-08-30'),
      ),
    );
    await tester.pumpAndSettle();

    // Mockup B2: boş bir AppBar bandı yok; geri, eylem dizisinin
    // ilk üyesi.
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const Key('day-back')), findsOneWidget);

    await tester.tap(find.byKey(const Key('day-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day-back')), findsNothing);
  });

  testWidgets('bugün olmayan günde sıradaki iş kartı çizilmez', (
    tester,
  ) async {
    // Geçmişte "şimdi" diye bir şey yok; bugünün saatine göre bir kart
    // göstermek yanlış olurdu.
    await tester.pumpWidget(wrap(dateKey: '2026-08-30', planDay: day));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sırada'), findsNothing);
  });
}
