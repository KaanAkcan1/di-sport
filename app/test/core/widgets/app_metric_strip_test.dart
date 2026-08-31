import 'package:disport/app/theme/app_theme.dart';
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

  testWidgets('etiketler büyük harfe Türkçe kuralıyla çevrilir', (
    tester,
  ) async {
    // "Kilo".toUpperCase() ASCII kuralıyla "KILO" verir ve bu Türkçede
    // "kılo" okunur — başka bir sözcük.
    await tester.pumpWidget(
      wrap(
        const AppMetricStrip([
          AppMetric(caption: 'Kilo', value: '108,9'),
          AppMetric(caption: 'İlerleme', value: '5/8'),
        ]),
      ),
    );

    expect(find.text('KİLO'), findsOneWidget);
    expect(find.text('İLERLEME'), findsOneWidget);
  });

  testWidgets('delta işaret karakteri taşır — renk tek başına değil', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AppMetricStrip([
          AppMetric(caption: 'Kilo', value: '108,9', delta: '0,4'),
        ]),
      ),
    );

    expect(find.text('▾0,4'), findsOneWidget);
  });

  testWidgets('kötü yöndeki delta yukarı ok gösterir', (tester) async {
    // Yön kararı çağrı yerinde: kilo takibinde azalma iyidir, kalori
    // bütçesinde artış kötüdür. Widget böyle bir kural bilmez.
    await tester.pumpWidget(
      wrap(
        const AppMetricStrip([
          AppMetric(
            caption: 'Kilo',
            value: '109,3',
            delta: '0,4',
            deltaPositive: false,
          ),
        ]),
      ),
    );

    expect(find.text('▴0,4'), findsOneWidget);
  });

  testWidgets('değer yokken — çizilir, birim ve delta gizlenir', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AppMetricStrip([
          AppMetric(caption: 'Kilo', unit: 'kg', delta: '0,4'),
        ]),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('kg'), findsNothing);
    expect(find.textContaining('0,4'), findsNothing);
  });

  testWidgets('ekran okuyucu girilmemiş değeri açıkça söyler', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const AppMetricStrip([AppMetric(caption: 'Kilo')])),
    );

    expect(
      tester.getSemantics(find.text('—')).label,
      contains('girilmedi'),
    );
  });

  testWidgets('dar ekranda sayılar küçülür, kesilmez', (tester) async {
    // "1..." diye kesilen bir sayı bilgi taşımaz.
    await tester.pumpWidget(
      wrap(
        const AppMetricStrip([
          AppMetric(caption: 'Kalori', value: '2 100', unit: 'kcal'),
          AppMetric(caption: 'Protein', value: '140', unit: 'g'),
          AppMetric(caption: 'Program', value: '5/8'),
        ]),
        width: 200,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('2 100'), findsOneWidget);
    expect(find.byType(FittedBox), findsNWidgets(3));
  });
}
