import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../catalog/exercise_fixtures.dart';
import '../../plan/plan_fixtures.dart';

/// Tüm setler bitince `_syncWorkoutFlag` günün kaydını okuyor; ekran
/// testi Drift'e bağlanmasın diye kutucuk zaten işaretliymiş gibi
/// davranan sahte (yazma yolu repository testinde).
class _NoopTodayRepository extends TodayRepository {
  _NoopTodayRepository()
    : super(AppDatabase.forTesting(NativeDatabase.memory()));

  @override
  Future<DailyLogView> readDay(String isoDate) async =>
      const DailyLogView(workoutDone: true);
}

void main() {
  final day = fixturePlan().days.first;
  const iso = '2026-08-31';

  final pushup = fixtureExercise(
    id: 'incline_pushup',
    nameTr: 'Eğimli Şınav',
    nameEn: 'Incline Push-Up',
  );
  final plank = fixtureExercise(
    id: 'plank',
    nameTr: 'Plank',
    nameEn: 'Plank',
  );

  Widget wrap({
    Map<String, int> counts = const {},
    List<SetActual> lastPushup = const [],
  }) => ProviderScope(
    overrides: [
      doneSetCountsProvider(iso).overrideWith((ref) => Stream.value(counts)),
      exerciseByIdProvider('incline_pushup').overrideWith((ref) async => pushup),
      exerciseByIdProvider('plank').overrideWith((ref) async => plank),
      lastActualsProvider(
        lastActualsKey('incline_pushup', iso),
      ).overrideWith((ref) async => lastPushup),
      lastActualsProvider(
        lastActualsKey('plank', iso),
      ).overrideWith((ref) async => const []),
      todayRepositoryProvider.overrideWithValue(_NoopTodayRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: WorkoutScreen(day: day),
    ),
  );

  testWidgets('hareketleri adı ve hedefiyle listeler', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Eğimli Şınav'), findsOneWidget);
    expect(find.text('3 × 10'), findsOneWidget);
    expect(find.text('Plank'), findsOneWidget);
    // Süreli hareket saniyeyle gösterilir.
    expect(find.text('3 × 30 sn'), findsOneWidget);
  });

  testWidgets('set sayacı ve ilerleme çubuğu başlangıçta sıfır', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('0 / 3'), findsNWidgets(2));
    expect(find.text('0 / 6 set'), findsOneWidget);
  });

  testWidgets('tamamlanan setler sayaca ve ilerlemeye yansır', (tester) async {
    await tester.pumpWidget(wrap(counts: const {'incline_pushup': 2}));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('2 / 6 set'), findsOneWidget);
  });

  testWidgets('hedef tamamlanınca düğme kapanır ve onay çıkar', (tester) async {
    await tester.pumpWidget(wrap(counts: const {'incline_pushup': 3}));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('done-set-incline_pushup')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Tamamlandı'), findsOneWidget);
  });

  // İki ayrı test: aynı test içinde ikinci kez `pumpWidget` çağırmak
  // ProviderScope'u yeniden kurmuyor ve ilk override yürürlükte kalıyor.
  testWidgets('set yokken geri al düğmesi çıkmaz', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('undo-incline_pushup')), findsNothing);
  });

  testWidgets('set varken geri al düğmesi çıkar', (tester) async {
    await tester.pumpWidget(wrap(counts: const {'incline_pushup': 1}));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('undo-incline_pushup')), findsOneWidget);
  });

  testWidgets('geçen seferki gerçekleşme gösterilir', (tester) async {
    await tester.pumpWidget(
      wrap(
        lastPushup: const [
          SetActual(setIndex: 0, reps: 9),
          SetActual(setIndex: 1, reps: 8),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // M12: düz cümle yerine GEÇEN sütunu.
    expect(find.text('GEÇEN'), findsOneWidget);
    expect(find.text('9/8'), findsOneWidget);
  });

  testWidgets('geçmiş yoksa satır hiç çıkmaz', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    // Boş bir "—" kıyas varmış gibi görünürdü; sütun hiç çizilmiyor.
    expect(find.text('GEÇEN'), findsNothing);
  });

  testWidgets('hareketin ipuçları kartta görünür', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Karın sıkı'), findsWidgets);
  });

  testWidgets('tüm setler bitince değerlendirme kartı görünür (v3.1)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(counts: const {'incline_pushup': 3, 'plank': 3}),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('debrief-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('debrief-card')), findsOneWidget);
    expect(find.byKey(const Key('debrief-rpe-8')), findsOneWidget);
    expect(find.byKey(const Key('debrief-pain')), findsOneWidget);
  });

  testWidgets('setler bitmeden değerlendirme kartı yok', (tester) async {
    await tester.pumpWidget(wrap(counts: const {'incline_pushup': 3}));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debrief-card')), findsNothing);
  });

  testWidgets('her hareket PLAN sütunu taşır', (tester) async {
    // fixturePlan'ın ilk günü salon günü değil; yoğunluk taşıyan bir
    // hareketle ayrı doğrulama gerekiyorsa örnek plan testinde yapılıyor.
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('PLAN'), findsNWidgets(2));
  });
}
