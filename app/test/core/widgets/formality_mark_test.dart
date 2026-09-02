import 'package:disport/core/widgets/formality_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormalityMark', () {
    testWidgets('ilerleme oranına göre çizer ve hata vermez',
        (tester) async {
      for (final progress in [0.0, 0.3, 0.7, 1.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(child: FormalityMark(progress: progress)),
          ),
        );
        expect(find.byType(FormalityMark), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('boyut oranı geometriden gelir (306x194)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: FormalityMark(size: 153))),
      );
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(FormalityMark),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(paint.size.width, 153);
      expect(paint.size.height, closeTo(153 * 194 / 306, 0.01));
    });
  });

  group('AnimatedFormalityMark', () {
    testWidgets('animasyon 0dan başlar ve tamamlanınca tam işaret kalır',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: AnimatedFormalityMark())),
      );
      // Animasyonu sonuna kadar oynat: süre + pay.
      await tester.pumpAndSettle();
      final mark = tester.widget<FormalityMark>(find.byType(FormalityMark));
      expect(mark.progress, 1.0);
    });

    testWidgets('hareketi azalt açıkken animasyonsuz tam işaret gösterir',
        (tester) async {
      // MediaQuery, MaterialApp'in İÇİNE konur: MaterialApp kendi
      // MediaQuery'sini pencereden kurar ve üsttekini gölgeler.
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: AnimatedFormalityMark()),
          ),
        ),
      );
      // Tek kare: animasyon beklenmeden işaret tam olmalı.
      await tester.pump();
      final mark = tester.widget<FormalityMark>(find.byType(FormalityMark));
      expect(mark.progress, 1.0);
    });
  });
}
