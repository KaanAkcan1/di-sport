import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:disport/features/workout/presentation/exercise_set_card.dart';
import 'package:disport/features/workout/presentation/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../plan/plan_fixtures.dart';

/// M12 — Antrenman ekranının mürekkep dili sözleşmesi.
void main() {
  const planExercise = PlanExercise(
    id: 'pe1',
    exerciseId: 'pushup',
    sets: 3,
    reps: 12,
    restSec: 60,
  );

  Widget wrapCard({List<SetActual> last = const []}) => ProviderScope(
    overrides: [
      exerciseByIdProvider('pushup').overrideWith((ref) async => null),
      lastActualsProvider(
        lastActualsKey('pushup', '2026-09-01'),
      ).overrideWith((ref) async => last),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: ExerciseSetCard(
          planExercise: planExercise,
          isoDate: '2026-09-01',
          doneSets: 0,
          onRest: (_) {},
        ),
      ),
    ),
  );

  group('referans sütunları', () {
    testWidgets('geçen seans yoksa GEÇEN sütunu hiç çizilmez', (
      tester,
    ) async {
      // Boş bir "—" kıyas varmış gibi görünürdü.
      await tester.pumpWidget(wrapCard());
      await tester.pumpAndSettle();

      expect(find.text('GEÇEN'), findsNothing);
      expect(find.text('PLAN'), findsOneWidget);
    });

    testWidgets('geçen seans varsa iki sütun yan yana', (tester) async {
      await tester.pumpWidget(
        wrapCard(
          last: const [
            SetActual(setIndex: 0, reps: 10),
            SetActual(setIndex: 1, reps: 10),
            SetActual(setIndex: 2, reps: 9),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GEÇEN'), findsOneWidget);
      expect(find.text('10/10/9'), findsOneWidget);
      expect(find.text('PLAN'), findsOneWidget);
      expect(find.text('3 × 12'), findsOneWidget);
    });

    testWidgets('etiketler Türkçe büyük harf kuralıyla', (tester) async {
      await tester.pumpWidget(
        wrapCard(last: const [SetActual(setIndex: 0, reps: 10)]),
      );
      await tester.pumpAndSettle();

      // "Geçen".toUpperCase() ASCII kuralıyla "GEÇEN" verir ama
      // "Plan" gibi i taşıyan etiketlerde kural kritik; ikisi de
      // LocaleText yolundan geçiyor.
      expect(find.text('GEÇEN'), findsOneWidget);
    });
  });

  group('seans başlığı', () {
    // Mevcut ekran testiyle aynı kurulum: `days.first` 2026-08-31 ve
    // iki hareket taşıyor. iso'yu elde hesaplamak override'ı ıskalıyor
    // ve ekran gerçek veritabanına düşüyor (o da testi asıyor).
    final day = fixturePlan().days.first;
    const iso = '2026-08-31';

    Widget wrapScreen() => ProviderScope(
      overrides: [
        // Saat sabitleniyor: seans sayacı buna bağlı.
        clockProvider.overrideWith(
          (ref) => Stream.value(DateTime(2026, 8, 31, 18)),
        ),
        doneSetCountsProvider(
          iso,
        ).overrideWith((ref) => Stream.value(const <String, int>{})),
        exerciseByIdProvider(
          'incline_pushup',
        ).overrideWith((ref) async => null),
        exerciseByIdProvider('plank').overrideWith((ref) async => null),
        lastActualsProvider(
          lastActualsKey('incline_pushup', iso),
        ).overrideWith((ref) async => const <SetActual>[]),
        lastActualsProvider(
          lastActualsKey('plank', iso),
        ).overrideWith((ref) async => const <SetActual>[]),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: WorkoutScreen(day: day),
      ),
    );

    testWidgets('kahraman rakam ve metrik şeridi çizilir', (tester) async {
      await tester.pumpWidget(wrapScreen());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeroNumber), findsOneWidget);
      expect(find.byType(AppMetricStrip), findsOneWidget);
    });

    testWidgets('ilk dakikada 0 değil "yeni" yazar', (tester) async {
      // "0 dk" sayacın bozuk olduğunu düşündürüyor.
      await tester.pumpWidget(wrapScreen());
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppHeroNumber),
          matching: find.text('yeni'),
        ),
        findsOneWidget,
      );
      // Metrik şeridindeki "0 set" meşru; kahramanda 0 olmamalı.
      expect(
        find.descendant(
          of: find.byType(AppHeroNumber),
          matching: find.text('0'),
        ),
        findsNothing,
      );
    });
  });
}
