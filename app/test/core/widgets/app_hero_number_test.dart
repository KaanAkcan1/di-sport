import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {double width = 360}) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(child: SizedBox(width: width, child: child)),
    ),
  );

  /// Kahraman rakamın çizildiği rengi okur.
  Color numberColor(WidgetTester tester, String text) {
    return tester.widget<Text>(find.text(text)).style!.color!;
  }

  testWidgets('değer ve birim çizilir', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppHeroNumber(
          caption: 'kcal kaldı · 2 100 bütçe',
          value: '510',
          unit: 'kcal',
        ),
      ),
    );

    expect(find.text('510'), findsOneWidget);
    expect(find.text('kcal'), findsOneWidget);
    expect(find.text('kcal kaldı · 2 100 bütçe'), findsOneWidget);
  });

  testWidgets('değer yokken — gösterir ve birim gizlenir', (tester) async {
    // "— kcal" bir ölçüm değil; kırık bir değer gibi okunur.
    await tester.pumpWidget(
      wrap(const AppHeroNumber(caption: 'Kilo', unit: 'kg')),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('kg'), findsNothing);
  });

  testWidgets('boş değer solar — 0 ile karışmaz', (tester) async {
    await tester.pumpWidget(
      wrap(const AppHeroNumber(caption: 'Kilo')),
    );

    final theme = AppTheme.dark;
    expect(numberColor(tester, '—'), theme.colorScheme.onSurfaceVariant);
  });

  testWidgets('vurgulu değer marka renginde', (tester) async {
    await tester.pumpWidget(
      wrap(const AppHeroNumber(caption: 'Kalan', value: '510')),
    );

    expect(numberColor(tester, '510'), AppTheme.dark.colorScheme.primary);
  });

  testWidgets('gauge yoksa çubuk hiç çizilmez', (tester) async {
    // Hedefi olmayan bir sayının doluluk oranı da yoktur.
    await tester.pumpWidget(
      wrap(const AppHeroNumber(caption: 'Kilo', value: '108,9')),
    );

    expect(find.byType(FractionallySizedBox), findsNothing);
  });

  testWidgets('gauge verilince çubuk çizilir', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppHeroNumber(
          caption: 'Kalan',
          value: '510',
          gaugeFraction: 0.76,
        ),
      ),
    );

    final box = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(box.widthFactor, closeTo(0.76, 0.001));
  });

  testWidgets('gauge 1 aşınca danger tonuna döner ve dolar', (tester) async {
    // Bütçe aşımı susturulacak değil söylenecek bir şey.
    await tester.pumpWidget(
      wrap(
        const AppHeroNumber(
          caption: 'Aşım',
          value: '2 410',
          gaugeFraction: 1.15,
        ),
      ),
    );

    final box = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(box.widthFactor, 1.0, reason: 'aşımda çubuk dolar');
    expect(
      numberColor(tester, '2 410'),
      AppSemanticColors.dark.danger,
      reason: 'aşımda rakam da uyarır',
    );
  });

  testWidgets('ekran okuyucu değeri ve etiketi birlikte okur', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AppHeroNumber(caption: 'Kalan', value: '510', unit: 'kcal'),
      ),
    );

    expect(
      tester
          .getSemantics(find.byType(AppHeroNumber))
          .label,
      contains('510 kcal'),
    );
  });
}
