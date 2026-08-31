import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {double width = 360}) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(child: SizedBox(width: width, child: child)),
    ),
  );

  testWidgets('başlık, alt başlık ve sayılar çizilir', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppStatBand(
          title: 'Salı, 1 Eylül',
          subtitle: 'Ev antrenmanı',
          stats: [
            AppStat(caption: 'Kilo', value: 109.4, unit: 'kg'),
            AppStat(caption: 'Program', text: '2/5'),
          ],
        ),
      ),
    );

    expect(find.text('Salı, 1 Eylül'), findsOneWidget);
    expect(find.text('Ev antrenmanı'), findsOneWidget);
    expect(find.text('109,4'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    // Etiketler büyük harfe çevriliyor.
    expect(find.text('KİLO'), findsOneWidget);
  });

  testWidgets('dar sütunda sayı kısaltılmaz, küçültülür', (tester) async {
    // Cihazda yakalanan kusur: üç sütunda "109,4" kesilip "1..." diye
    // çiziliyordu. Kesilen sayı bilgi taşımaz.
    await tester.pumpWidget(
      wrap(
        const AppStatBand(
          title: 'Dar',
          stats: [
            AppStat(caption: 'Kilo', value: 109.4, unit: 'kg'),
            AppStat(caption: 'Program', text: '12/20'),
            AppStat(caption: 'Kural', text: '3/3'),
          ],
        ),
        width: 300,
      ),
    );

    expect(find.text('109,4'), findsOneWidget);
    expect(find.textContaining('…'), findsNothing);
    expect(find.textContaining('...'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('değer yokken', () {
    testWidgets('yer tutucu çizilir ama birim gizlenir', (tester) async {
      // "— kg" bir ölçüm değil; dev bir tirenin yanındaki birim
      // kırık bir değer gibi okunuyordu.
      await tester.pumpWidget(
        wrap(
          const AppStatBand(
            title: 'Boş',
            stats: [AppStat(caption: 'Kilo', unit: 'kg')],
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.text('kg'), findsNothing);
    });

    testWidgets('yer tutucu dolu değerden küçük çizilir', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppStatBand(
            title: 'Karşılaştırma',
            stats: [
              AppStat(caption: 'Boş'),
              AppStat(caption: 'Dolu', value: 8, fractionDigits: 0),
            ],
          ),
        ),
      );

      final placeholder = tester.widget<Text>(find.text('—')).style!.fontSize!;
      final filled = tester.widget<Text>(find.text('8')).style!.fontSize!;
      expect(placeholder, lessThan(filled));
    });

    testWidgets('ekran okuyucuya "girilmedi" der', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppStatBand(
            title: 'Boş',
            stats: [AppStat(caption: 'Kilo', unit: 'kg')],
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Kilo: girilmedi'),
        findsOneWidget,
      );
    });
  });

  testWidgets('sayı yoksa şerit yalnız başlık gösterir', (tester) async {
    await tester.pumpWidget(
      wrap(const AppStatBand(title: 'Yalnız başlık', stats: [])),
    );

    expect(find.text('Yalnız başlık'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
