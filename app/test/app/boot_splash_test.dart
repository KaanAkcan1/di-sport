import 'dart:async';

import 'package:disport/app/boot_splash.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BootSplash', () {
    testWidgets('iş sürerken süpürme döngüsünde kalır, onFinished çağrılmaz',
        (tester) async {
      final ready = Completer<void>();
      var finished = false;
      await tester.pumpWidget(
        BootSplash(ready: ready.future, onFinished: () => finished = true),
      );
      // İki tam süpürme + sessizlikler geçse de iş bitmedi: geçilmez.
      await tester.pump(BootSplash.sweepDuration);
      await tester.pump(BootSplash.restDuration);
      await tester.pump(BootSplash.sweepDuration);
      await tester.pump(BootSplash.restDuration);
      expect(finished, isFalse);
      expect(find.byType(FormalityMark), findsOneWidget);
      // Süpürme kipinde kuyruk kısadır: tam çizim gösterilmez.
      final sweeping =
          tester.widget<FormalityMark>(find.byType(FormalityMark));
      expect(sweeping.trail, lessThan(1.0));
      // Sarkan zamanlayıcı kalmasın diye kapat (kare payı +32ms).
      ready.complete();
      await tester.pump(BootSplash.sweepDuration + const Duration(milliseconds: 32));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(BootSplash.drawDuration + const Duration(milliseconds: 32));
      await tester.pump(BootSplash.holdDuration + const Duration(milliseconds: 50));
    });

    testWidgets('iş bitince süpürmeyi bitirir, final çizimi oynatıp geçer',
        (tester) async {
      final ready = Completer<void>();
      var finished = false;
      await tester.pumpWidget(
        BootSplash(ready: ready.future, onFinished: () => finished = true),
      );
      // Süpürme ortasında iş biter.
      await tester.pump(const Duration(milliseconds: 400));
      ready.complete();
      await tester.pump();
      expect(finished, isFalse);
      // Süpürme sonuna kadar oynar (yarıda kesilmez), sessizlik
      // atlanır ve final çizim başlar.
      await tester.pump(BootSplash.sweepDuration);
      await tester.pump(const Duration(milliseconds: 16));
      // Final çizim tam kuyrukla (baştan sona) çizer.
      final finishing =
          tester.widget<FormalityMark>(find.byType(FormalityMark));
      expect(finishing.trail, 1.0);
      // +32ms pay: kare zamanlaması tik başlangıcını bir kare
      // kaydırabilir; pay olmazsa çizim "tam bitmemiş" sayılır.
      await tester.pump(BootSplash.drawDuration + const Duration(milliseconds: 32));
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
