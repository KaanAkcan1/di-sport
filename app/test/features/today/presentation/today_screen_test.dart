import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/supplements/application/supplement_providers.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
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
void main() {
  final day = fixturePlan().days.first;

  Widget wrap({
    FullPlanDay? planDay,
    DailyLogView log = const DailyLogView(),
    double? weight,
    double? sleep,
    int missedStreak = 0,
  }) => ProviderScope(
    overrides: [
      // Takviye dozları da Drift akışı; ekran testi bağlanmamalı.
      todayDosesProvider.overrideWithValue(const <SupplementDose>[]),
      todayIsoProvider.overrideWithValue('2026-08-31'),
      todayPlanDayProvider.overrideWith((ref) => Stream.value(planDay)),
      todayLogProvider.overrideWith((ref) => Stream.value(log)),
      todayWeightProvider.overrideWith((ref) => Stream.value(weight)),
      todaySleepProvider.overrideWith((ref) => Stream.value(sleep)),
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
      // Tartı ve kutucuklar plan olmadan da kullanılabilmeli.
      expect(find.byKey(const Key('weight-field')), findsOneWidget);
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

      final field = tester.widget<TextField>(
        find.byKey(const Key('weight-field')),
      );
      expect(field.controller?.text, '109,5');
    });

    testWidgets('değer yokken alan boş', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const Key('weight-field')),
      );
      expect(field.controller?.text, '');
    });

    testWidgets('uyku alanı ayrı', (tester) async {
      await tester.pumpWidget(wrap(sleep: 6.5));
      await tester.pumpAndSettle();

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

    // Not alanı ekranın en altında ve `ListView` görünmeyeni tembel
    // kuruyor; okumadan önce görünür kılınması gerekiyor.
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
