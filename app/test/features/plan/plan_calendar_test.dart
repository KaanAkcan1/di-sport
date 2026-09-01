import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/presentation/plan_calendar.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'day_cell_state_test.dart' show dayWith;

void main() {
  final today = DateTime(2026, 9, 1);

  Widget wrap({
    Map<String, DailyLogView> logs = const {},
    int slots = 3,
    int exercises = 0,
    DateTime? date,
  }) {
    final day = dayWith(
      date: date ?? today,
      slots: slots,
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

  testWidgets('hücrede gün rakamı ve sayaç var — renk tek başına değil', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        logs: {
          PlanRepository.iso(today): const DailyLogView(
            checkedSlotIds: {'s0'},
          ),
        },
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('serbest gün "boş" yazar', (tester) async {
    await tester.pumpWidget(wrap(slots: 0));
    expect(find.text('boş'), findsOneWidget);
  });

  testWidgets('antrenman günü üçgen işareti taşır', (tester) async {
    await tester.pumpWidget(wrap(exercises: 4));
    expect(find.byIcon(Icons.change_history), findsOneWidget);
  });

  testWidgets('antrenmansız günde üçgen yok', (tester) async {
    await tester.pumpWidget(wrap());
    expect(find.byIcon(Icons.change_history), findsNothing);
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
          PlanRepository.iso(today): const DailyLogView(
            checkedSlotIds: {'s0', 's1', 's2'},
          ),
        },
      ),
    );

    final label = tester.getSemantics(find.byType(InkWell).first).label;
    expect(label, contains('bugün'));
    expect(label, contains('tamamlandı'));
  });

  testWidgets('gelecek gün sayaç göstermez', (tester) async {
    // Henüz gelmemiş güne "0/3" yazmak kaçırılmış gibi okunur.
    await tester.pumpWidget(wrap(date: DateTime(2026, 9, 8)));
    expect(find.text('0/3'), findsNothing);
  });
}
