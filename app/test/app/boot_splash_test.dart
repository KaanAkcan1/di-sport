import 'dart:async';

import 'package:disport/app/boot_splash.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BootSplash', () {
    testWidgets('iş sürerken döngüde kalır, onFinished çağrılmaz',
        (tester) async {
      final ready = Completer<void>();
      var finished = false;
      await tester.pumpWidget(
        BootSplash(ready: ready.future, onFinished: () => finished = true),
      );
      // İki tam tur + nefes payları geçse de iş bitmedi: geçilmez.
      await tester.pump(BootSplash.drawDuration);
      await tester.pump(BootSplash.restDuration);
      await tester.pump(BootSplash.drawDuration);
      await tester.pump(BootSplash.restDuration);
      expect(finished, isFalse);
      expect(find.byType(FormalityMark), findsOneWidget);
      // Sarkan zamanlayıcı kalmasın diye kapat.
      ready.complete();
      await tester.pump(BootSplash.drawDuration);
      await tester.pump(BootSplash.holdDuration);
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('iş bitince o anki turu tamamlayıp geçer', (tester) async {
      final ready = Completer<void>();
      var finished = false;
      await tester.pumpWidget(
        BootSplash(ready: ready.future, onFinished: () => finished = true),
      );
      // Tur ortasında iş biter.
      await tester.pump(const Duration(milliseconds: 500));
      ready.complete();
      await tester.pump();
      // Tur bitmeden geçilmez: işaret yarıda kesilmez.
      expect(finished, isFalse);
      // Turun kalanı + tam işaretin gösterildiği an.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(BootSplash.holdDuration);
      await tester.pump(const Duration(milliseconds: 50));
      expect(finished, isTrue);
    });

    testWidgets('hareketi azalt açıkken animasyonsuz ve beklemesiz geçer',
        (tester) async {
      final ready = Completer<void>();
      var finished = false;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures.allOn;
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(
        BootSplash(ready: ready.future, onFinished: () => finished = true),
      );
      ready.complete();
      await tester.pump();
      await tester.pump();
      expect(finished, isTrue);
      // İşaret animasyonsuz, tam çizili durur.
      final mark = tester.widget<FormalityMark>(find.byType(FormalityMark));
      expect(mark.progress, 1.0);
    });
  });
}
