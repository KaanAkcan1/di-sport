import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/progress/application/progress_providers.dart';
import 'package:disport/features/progress/domain/transition_criteria.dart';
import 'package:disport/features/today/application/today_providers.dart';
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
      // Bugün ekranı da veritabanına bağlı; kabuk testi içeriği değil
      // sekme geçişini sınıyor.
      todayPlanDayProvider.overrideWith((ref) => Stream.value(null)),
      todayLogProvider.overrideWith((ref) => Stream.value(const DailyLogView())),
      todayWeightProvider.overrideWith((ref) => Stream.value(null)),
      todaySleepProvider.overrideWith((ref) => Stream.value(null)),
      missedStreakProvider.overrideWith((ref) async => 0),
      // Kabuk artık onboarding kontrolünün arkasında; test doğrudan
      // sekmelere bakıyor.
      isOnboardedProvider.overrideWith((ref) async => true),
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
    expect(find.byKey(const Key('weight-field')), findsOneWidget);
  });

  testWidgets('tapping a tab switches screen and title', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();

    // Katalog ekranı geldi: filtre çipleri görünür.
    //
    // `TextField` sayısına bakılmıyor: sekmeler `IndexedStack` içinde
    // canlı kaldığı için Bugün ekranının tartı, uyku ve not alanları da
    // ağaçta duruyor — bu kasıtlı, durum korunsun diye.
    expect(find.widgetWithText(FilterChip, 'Salon'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Kuvvet'), findsOneWidget);

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
