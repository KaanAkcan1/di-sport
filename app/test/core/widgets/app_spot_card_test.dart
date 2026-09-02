import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(child: SizedBox(width: 340, child: child)),
    ),
  );

  testWidgets('eyebrow büyük harfe Türkçe kuralıyla çevrilir', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AppSpotCard(
          eyebrow: 'Sırada · 18:00',
          title: 'Salon · Program A',
        ),
      ),
    );

    expect(find.text('SIRADA · 18:00'), findsOneWidget);
    expect(find.text('Salon · Program A'), findsOneWidget);
  });

  testWidgets('dokunuş tetiklenir', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(
        AppSpotCard(
          eyebrow: 'Sırada',
          title: 'Salon · Program A',
          subtitle: '6 hareket · ≈50 dk',
          onTap: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.byType(AppSpotCard));
    expect(tapped, 1);
  });

  testWidgets('dokunulamayan kartta ok işareti yok', (tester) async {
    // Etkileşimli olmayan bir şey etkileşimli görünmemeli.
    await tester.pumpWidget(
      wrap(const AppSpotCard(eyebrow: 'Sırada', title: 'Uyku')),
    );

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('dokunma hedefi asgari 48dp', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppSpotCard(eyebrow: 'Sırada', title: 'Kısa', onTap: () {}),
      ),
    );

    expect(
      tester.getSize(find.byType(AppSpotCard)).height,
      greaterThanOrEqualTo(48.0),
    );
  });

  testWidgets('ekran okuyucu kartı tek cümlede okur', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppSpotCard(
          eyebrow: 'Sırada · 18:00',
          title: 'Salon · Program A',
          subtitle: '6 hareket',
          onTap: () {},
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(AppSpotCard));
    expect(node.label, contains('Salon · Program A'));
    expect(node.label, contains('6 hareket'));
  });
}
