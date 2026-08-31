import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );

  const labels = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
  const states = [
    WeekDotState.done,
    WeekDotState.done,
    WeekDotState.missed,
    WeekDotState.done,
    WeekDotState.done,
    WeekDotState.missed,
    WeekDotState.today,
  ];

  testWidgets('yedi nokta çizilir', (tester) async {
    await tester.pumpWidget(
      wrap(const AppWeekDots(states: states, labels: labels)),
    );

    // Gün harfleri tekrarlı olduğu için toplam metin sayısıyla bakıyoruz.
    expect(find.byType(Container), findsNWidgets(7));
  });

  testWidgets('her nokta gün harfini taşır — renk tek başına değil', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AppWeekDots(
          states: [WeekDotState.missed],
          labels: ['Ç'],
        ),
      ),
    );

    // Renk körü bir kullanıcı hangi günün boş olduğunu okuyabilmeli.
    expect(find.text('Ç'), findsOneWidget);
  });

  testWidgets('ekran okuyucu kaçak günü söyler', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppWeekDots(
          states: [WeekDotState.missed],
          labels: ['Ç'],
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Ç')).label,
      contains('kayıt yok'),
    );
  });

  testWidgets('bugün vurgulu çerçeve alır', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppWeekDots(
          states: [WeekDotState.today],
          labels: ['P'],
        ),
      ),
    );

    final decoration =
        tester.widget<Container>(find.byType(Container)).decoration!
            as BoxDecoration;
    expect(decoration.border, isNotNull);
  });
}
