import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/today/presentation/mood_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> calls;

  setUp(() => calls = []);

  Widget wrap({DailyLogView log = const DailyLogView()}) => ProviderScope(
    overrides: [
      todayIsoProvider.overrideWithValue('2026-09-02'),
      dayLogProvider('2026-09-02').overrideWith((ref) => Stream.value(log)),
      wellbeingWriterProvider.overrideWithValue((
        String isoDate, {
        int? moodScore,
        bool clearMood = false,
        String? symptoms,
        bool? stressedDay,
      }) async {
        calls.add('$moodScore/$clearMood/$symptoms/$stressedDay');
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: const Scaffold(body: MoodBlock()),
    ),
  );

  testWidgets('yüz seçmek moodScore yazar', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mood-4')));
    await tester.pumpAndSettle();

    expect(calls, ['4/false/null/null']);
  });

  testWidgets('seçili yüze ikinci dokunuş seçimi kaldırır', (tester) async {
    await tester.pumpWidget(wrap(log: const DailyLogView(moodScore: 4)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mood-4')));
    await tester.pumpAndSettle();

    expect(calls, ['null/true/null/null']);
  });

  testWidgets('seçili yüzün erişilebilirlik durumu işaretli', (tester) async {
    await tester.pumpWidget(wrap(log: const DailyLogView(moodScore: 2)));
    await tester.pumpAndSettle();

    // Renk tek başına anlam taşımaz: her yüzün ekran okuyucu etiketi
    // var ve seçili olan IconButton.isSelected taşıyor.
    expect(find.bySemanticsLabel('Kötü'), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.byKey(const Key('mood-2')),
    );
    expect(button.isSelected, isTrue);
  });

  testWidgets('belirti alanı odak kaybında kaydeder', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('symptoms-field')),
      'baş ağrısı',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(calls, contains('null/false/baş ağrısı/null'));
  });

  testWidgets('stres kutucuğu yazar ve kayıtlı hâli gösterir', (tester) async {
    await tester.pumpWidget(wrap(log: const DailyLogView(stressedDay: true)));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const Key('stressed-day')),
    );
    expect(checkbox.value, isTrue);

    await tester.tap(find.byKey(const Key('stressed-day')));
    await tester.pumpAndSettle();
    expect(calls, ['null/false/null/false']);
  });
}
