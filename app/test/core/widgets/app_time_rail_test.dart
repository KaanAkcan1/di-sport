import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(List<Widget> children) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: ListView(children: children)),
  );

  testWidgets('saat sıkışık ve tablo rakamıyla yazılır', (tester) async {
    // Tablo rakamı şart: saatler alt alta ve sola hizalı. Oranlı
    // rakamla "11:00" ile "06:30" farklı genişlikte olur, ray eğrilir.
    await tester.pumpWidget(
      wrap(const [
        AppTimeRailItem(
          time: '06:30',
          state: RailNodeState.done,
          isFirst: true,
          isLast: true,
          child: Text('Kahvaltı'),
        ),
      ]),
    );

    final style = tester.widget<Text>(find.text('06:30')).style!;
    expect(style.fontFamily, AppTypography.condensedFamily);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('bütün satırlar saati aynı genişlikte tutar', (tester) async {
    await tester.pumpWidget(
      wrap(const [
        AppTimeRailItem(
          time: '06:30',
          state: RailNodeState.done,
          isFirst: true,
          child: Text('Kahvaltı'),
        ),
        AppTimeRailItem(
          time: '19:00',
          state: RailNodeState.upcoming,
          isLast: true,
          child: Text('Antrenman'),
        ),
      ]),
    );

    // Omurga düz durmalı: iki satırın saat sütunu aynı x'te başlamalı.
    expect(
      tester.getTopLeft(find.text('06:30')).dx,
      tester.getTopLeft(find.text('19:00')).dx,
    );
  });

  testWidgets('sıradaki adım vurgulanır, geçmiş adım solar', (tester) async {
    await tester.pumpWidget(
      wrap(const [
        AppTimeRailItem(
          time: '06:30',
          state: RailNodeState.done,
          isFirst: true,
          child: Text('Geçmiş'),
        ),
        AppTimeRailItem(
          time: '19:00',
          state: RailNodeState.next,
          isLast: true,
          child: Text('Sıradaki'),
        ),
      ]),
    );

    final theme = AppTheme.light;
    expect(
      tester.widget<Text>(find.text('19:00')).style!.color,
      theme.colorScheme.primary,
    );
    expect(
      tester.widget<Text>(find.text('06:30')).style!.color,
      theme.colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('dokunma geri çağrısı çalışır', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap([
        AppTimeRailItem(
          time: '06:30',
          state: RailNodeState.upcoming,
          isFirst: true,
          isLast: true,
          onTap: () => tapped = true,
          child: const Text('Kahvaltı'),
        ),
      ]),
    );

    await tester.tap(find.text('Kahvaltı'));
    expect(tapped, isTrue);
  });

  testWidgets('şimdi işareti saati ve etiketi taşır', (tester) async {
    await tester.pumpWidget(wrap(const [AppNowMarker(label: '13:42')]));

    expect(find.text('13:42'), findsOneWidget);
    expect(find.text('ŞİMDİ'), findsOneWidget);
    expect(find.bySemanticsLabel('Şu an saat 13:42'), findsOneWidget);
  });
}
