import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/today/presentation/sleep_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yazımları kaydeden sahte — Drift'e bağlanılmaz.
class _RecordingSleepWriter implements SleepWriter {
  final calls = <String>[];

  @override
  TodayRepository get today => throw UnimplementedError();

  @override
  BodyMetricsRepository get metrics => throw UnimplementedError();

  @override
  Future<void> saveTimes(
    String isoDate, {
    required String? bedTime,
    required String? wakeTime,
    required int? napMinutes,
  }) async {
    calls.add('times:$bedTime/$wakeTime/$napMinutes');
  }

  @override
  Future<void> saveHoursOnly(String isoDate, double hours) async {
    calls.add('hours:$hours');
  }
}

void main() {
  late _RecordingSleepWriter writer;

  setUp(() => writer = _RecordingSleepWriter());

  Widget wrap({DailyLogView log = const DailyLogView(), double? sleep}) =>
      ProviderScope(
        overrides: [
          todayIsoProvider.overrideWithValue('2026-09-02'),
          dayLogProvider(
            '2026-09-02',
          ).overrideWith((ref) => Stream.value(log)),
          daySleepProvider(
            '2026-09-02',
          ).overrideWith((ref) => Stream.value(sleep)),
          sleepWriterProvider.overrideWithValue(writer),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: const Scaffold(body: SleepBlock()),
        ),
      );

  testWidgets('saatler görünür ve türetilen süre başlıkta', (tester) async {
    await tester.pumpWidget(
      wrap(
        log: const DailyLogView(
          bedTime: '23:45',
          wakeTimeActual: '06:11',
          napMinutes: 30,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('23:45'), findsOneWidget);
    expect(find.text('06:11'), findsOneWidget);
    // 23:45→06:11 = 6 sa 26 dk, +30 dk kestirme = 6 sa 56 dk.
    expect(find.text('6 sa 56 dk uyku'), findsOneWidget);
  });

  testWidgets('saat yokken kayıtlı süre başlıkta görünür', (tester) async {
    await tester.pumpWidget(wrap(sleep: 7.5));
    await tester.pumpAndSettle();

    expect(find.text('7 sa 30 dk uyku'), findsOneWidget);
    // Yalnız-süre alanı kayıtlı değeri gösterir.
    final field = tester.widget<TextField>(
      find.byKey(const Key('sleep-hours-only')),
    );
    expect(field.controller?.text, '7,5');
  });

  testWidgets('yalnız süre girmek saveHoursOnly çağırır', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('sleep-hours-only')), '6,5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(writer.calls, contains('hours:6.5'));
  });

  testWidgets('temizle düğmesi saatleri null yazar', (tester) async {
    await tester.pumpWidget(
      wrap(
        log: const DailyLogView(bedTime: '23:00', wakeTimeActual: '06:00'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sleep-clear')));
    await tester.pumpAndSettle();

    expect(writer.calls, contains('times:null/null/null'));
  });

  testWidgets('kestirme alanı diğer saatleri koruyarak yazar', (tester) async {
    await tester.pumpWidget(
      wrap(
        log: const DailyLogView(bedTime: '23:00', wakeTimeActual: '06:00'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('sleep-nap')), '45');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(writer.calls, contains('times:23:00/06:00/45'));
  });
}
