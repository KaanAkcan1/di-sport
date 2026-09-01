import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/presentation/plan_calendar.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'day_cell_state_test.dart' show dayWith;

/// v3 §6.1: takvim hücresi yalnız antrenman bilgisi taşır — tip
/// etiketi + yapıldı/yapılmadı işareti. Kalori Diyet'in işi.
void main() {
  final today = DateTime(2026, 9, 1);

  Widget wrap({
    Map<String, DailyLogView> logs = const {},
    PlanDayType type = PlanDayType.home,
    int exercises = 1,
    DateTime? date,
  }) {
    final day = dayWith(
      date: date ?? today,
      type: type,
      exercises: exercises,
    );

    return MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: Scaffold(
        body: PlanWeekGrid(days: [day], logs: logs, today: today),
      ),
    );
  }

  testWidgets('hücrede gün rakamı ve tip etiketi var — renk tek başına değil',
      (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('1'), findsOneWidget);
    expect(find.text('EV'), findsOneWidget);
  });

  testWidgets('dinlenme günü DİNLENME yazar', (tester) async {
    await tester.pumpWidget(wrap(type: PlanDayType.rest, exercises: 0));
    expect(find.text('DİNLENME'), findsOneWidget);
  });

  testWidgets('yapılan antrenman ✓, geçmişte kaçırılan ✗ taşır', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        date: DateTime(2026, 8, 30),
        logs: {
          '2026-08-30': const DailyLogView(workoutDone: true),
        },
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pumpWidget(wrap(date: DateTime(2026, 8, 30)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('gelecek antrenman günü üçgen işareti taşır', (tester) async {
    await tester.pumpWidget(wrap(date: DateTime(2026, 9, 8)));
    expect(find.byIcon(Icons.change_history), findsOneWidget);
  });

  testWidgets('antrenmansız günde işaret yok', (tester) async {
    await tester.pumpWidget(wrap(type: PlanDayType.rest, exercises: 0));
    expect(find.byIcon(Icons.change_history), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('bugün vurgulu çerçeve alır', (tester) async {
    await tester.pumpWidget(wrap());

    final container = tester.widget<Container>(
      find
          .descendant(of: find.byType(InkWell), matching: find.byType(Container))
          .first,
    );
    expect((container.decoration! as BoxDecoration).border, isNotNull);
  });

  testWidgets('ekran okuyucu hücreyi tam cümleyle okur', (tester) async {
    await tester.pumpWidget(
      wrap(
        logs: {
          PlanRepository.iso(today): const DailyLogView(workoutDone: true),
        },
      ),
    );

    final label = tester.getSemantics(find.byType(InkWell).first).label;
    expect(label, contains('bugün'));
    expect(label, contains('tamamlandı'));
  });
}
