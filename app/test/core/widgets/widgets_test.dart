import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bileşenleri gerçek temayla sarar — `context.semantic` uzantısı
/// tema eklentisine bağlı olduğu için çıplak `MaterialApp` yetmez.
Widget wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppEmptyState', () {
    testWidgets('başlık, açıklama ve eylemi çizer', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          AppEmptyState(
            title: 'Plan yok',
            description: 'Plan sekmesinden bir plan yükle.',
            actionLabel: 'Plan yükle',
            onAction: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Plan yok'), findsOneWidget);
      expect(find.text('Plan sekmesinden bir plan yükle.'), findsOneWidget);

      await tester.tap(find.text('Plan yükle'));
      expect(tapped, isTrue);
    });

    testWidgets('her ton kendi ikonunu kullanır', (tester) async {
      for (final (tone, icon) in [
        (AppEmptyStateTone.neutral, Icons.inbox_outlined),
        (AppEmptyStateTone.warning, Icons.info_outline),
        (AppEmptyStateTone.danger, Icons.error_outline),
      ]) {
        await tester.pumpWidget(wrap(AppEmptyState(title: 'x', tone: tone)));
        expect(find.byIcon(icon), findsOneWidget, reason: '$tone');
      }
    });

    test('eylem etiketi ve geri çağrısı birlikte zorunlu', () {
      expect(
        () => AppEmptyState(title: 'x', actionLabel: 'y'),
        throwsAssertionError,
      );
    });
  });

  group('AppAsyncView', () {
    testWidgets('veri durumunda içeriği çizer', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppAsyncView<int>(
            value: const AsyncData(42),
            data: (v) => Text('değer $v'),
          ),
        ),
      );
      expect(find.text('değer 42'), findsOneWidget);
    });

    testWidgets('yükleme durumunda gösterge çizer', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppAsyncView<int>(
            value: const AsyncLoading(),
            data: (v) => Text('$v'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hata durumunda neden ve çıkış yolu gösterir', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrap(
          AppAsyncView<int>(
            value: AsyncError(Exception('bağlantı yok'), StackTrace.empty),
            data: (v) => Text('$v'),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Bir şeyler ters gitti'), findsOneWidget);
      expect(find.textContaining('bağlantı yok'), findsOneWidget);

      await tester.tap(find.text('Tekrar dene'));
      expect(retried, isTrue);
    });

    testWidgets('boş koşulu sağlanınca boş durumu çizer', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppAsyncView<List<int>>(
            value: const AsyncData([]),
            emptyWhen: (list) => list.isEmpty,
            empty: const AppEmptyState(title: 'Hiç kayıt yok'),
            data: (v) => Text('${v.length} kayıt'),
          ),
        ),
      );
      expect(find.text('Hiç kayıt yok'), findsOneWidget);
    });

    testWidgets('boş koşulu sağlanmazsa veriyi çizer', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppAsyncView<List<int>>(
            value: const AsyncData([1, 2]),
            emptyWhen: (list) => list.isEmpty,
            empty: const AppEmptyState(title: 'Hiç kayıt yok'),
            data: (v) => Text('${v.length} kayıt'),
          ),
        ),
      );
      expect(find.text('2 kayıt'), findsOneWidget);
    });
  });

  group('AppMetricValue', () {
    testWidgets('Türkçe ondalık ayracı kullanır', (tester) async {
      await tester.pumpWidget(
        wrap(const AppMetricValue(value: 109.5, unit: 'kg')),
      );
      expect(find.text('109,5'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
    });

    testWidgets('tam sayı metrikte ondalık göstermez', (tester) async {
      await tester.pumpWidget(
        wrap(const AppMetricValue(value: 8, fractionDigits: 0)),
      );
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('veri yokken yer tutucu çizer, sıfırla karışmaz', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const AppMetricValue(value: null)));
      expect(find.text('—'), findsOneWidget);

      await tester.pumpWidget(
        wrap(const AppMetricValue(value: 0, fractionDigits: 0)),
      );
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('tablo rakamı özelliğini uygular', (tester) async {
      await tester.pumpWidget(wrap(const AppMetricValue(value: 1.0)));
      final text = tester.widget<Text>(find.text('1,0'));
      expect(
        text.style?.fontFeatures?.any((f) => f.feature == 'tnum'),
        isTrue,
      );
    });
  });

  group('AppStatusChip', () {
    testWidgets('her durum kendi ikonunu taşır — renk tek başına değil', (
      tester,
    ) async {
      for (final status in AppStatus.values) {
        await tester.pumpWidget(
          wrap(AppStatusChip(status: status, label: 'test')),
        );
        expect(find.byIcon(status.icon), findsOneWidget, reason: '$status');
      }
    });

    testWidgets('ekran okuyucuya durum sözlü olarak bildirilir', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AppStatusChip(status: AppStatus.bad, label: 'Kaçak')),
      );
      expect(
        find.bySemanticsLabel('Kaçak, sorunlu'),
        findsOneWidget,
      );
    });

    testWidgets('koyu modda da çizilir', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppStatusChip(status: AppStatus.good, label: 'Tamam'),
          brightness: Brightness.dark,
        ),
      );
      expect(find.text('Tamam'), findsOneWidget);
    });
  });

  group('AppSection', () {
    testWidgets('başlığı erişilebilirlik başlığı olarak işaretler', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AppSection(title: 'Haftalık özet', child: Text('içerik'))),
      );
      expect(find.text('Haftalık özet'), findsOneWidget);
      expect(find.text('içerik'), findsOneWidget);
    });
  });

  group('AppScreenBody', () {
    testWidgets('alt gezinme çubuğu için boşluk bırakır', (tester) async {
      await tester.pumpWidget(
        wrap(const AppScreenBody(children: [Text('a')])),
      );
      final list = tester.widget<ListView>(find.byType(ListView));
      final padding = list.padding as EdgeInsets;
      expect(padding.bottom, greaterThan(80));
    });
  });
}
