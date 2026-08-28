import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Widget wrap() => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const DisportApp(),
  );

  testWidgets('shows five tabs and starts on Today', (tester) async {
    await tester.pumpWidget(wrap());

    // 'Bugün' hem sekme etiketi hem AppBar başlığı olarak görünür.
    expect(find.text('Bugün'), findsWidgets);
    for (final label in ['Plan', 'İlerleme', 'Sağlık', 'Katalog']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Bugün ekranı — M3'), findsOneWidget);
  });

  testWidgets('tapping a tab switches screen and title', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();

    expect(find.text('Katalog ekranı — M2'), findsOneWidget);
    // Başlangıçta 'Bugün' iki yerde: AppBar başlığı + sekme etiketi.
    // Katalog'a geçince başlık değişir, geriye yalnız sekme etiketi kalır.
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Katalog'), findsNWidgets(2)); // başlık + sekme
  });

  testWidgets('IndexedStack keeps all five screens alive', (tester) async {
    await tester.pumpWidget(wrap());

    final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack.children, hasLength(5));
    expect(stack.index, 0);
  });
}
