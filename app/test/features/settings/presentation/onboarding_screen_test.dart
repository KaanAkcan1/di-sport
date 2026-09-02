import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart'
    show ProfileKeys;
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/settings/data/profile_repository.dart';
import 'package:disport/features/settings/presentation/onboarding_screen.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sihirbaz veritabanına değil taklitlere yazar: burada sınanan akışın
/// kendisi — adım geçişleri, doğrulama, kaydedilen değerler. Deponun
/// gerçekten yazdığı `profile_repository_test`'te doğrulanıyor.
class _FakeProfileRepository extends Fake implements ProfileRepository {
  final saved = <String, String>{};

  @override
  Future<void> setAll(Map<String, String> values) async =>
      saved.addAll(values);
}

class _FakeBodyMetrics extends Fake implements BodyMetricsRepository {
  final upserts = <(String isoDate, String kind, double value, String unit)>[];

  @override
  Future<void> upsert({
    required String isoDate,
    required String kind,
    required double value,
    required String unit,
    String? note,
  }) async => upserts.add((isoDate, kind, value, unit));
}

void main() {
  late _FakeProfileRepository profile;
  late _FakeBodyMetrics metrics;
  var done = false;

  setUp(() {
    profile = _FakeProfileRepository();
    metrics = _FakeBodyMetrics();
    done = false;
  });

  Widget wrap() => ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profile),
      bodyMetricsRepositoryProvider.overrideWithValue(metrics),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: OnboardingScreen(onDone: () => done = true),
    ),
  );

  Future<void> enter(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
  }

  Future<void> toIdentity(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('onboarding-start')));
    await tester.pumpAndSettle();
  }

  Future<void> toMeasures(WidgetTester tester) async {
    await toIdentity(tester);
    await enter(tester, 'onboarding-first-name', 'Kaan');
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-identity-next')),
    );
    await tester.tap(find.byKey(const Key('onboarding-identity-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('hoş geldin ekranı dört alanı tanıtır ve başlatır', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    expect(find.text("Formality'ye hoş geldin"), findsOneWidget);
    await toIdentity(tester);
    expect(find.text('Seni tanıyalım'), findsOneWidget);
  });

  testWidgets('ad girilmeden ilerlenemez', (tester) async {
    await tester.pumpWidget(wrap());
    await toIdentity(tester);
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-identity-next')),
    );
    await tester.tap(find.byKey(const Key('onboarding-identity-next')));
    await tester.pumpAndSettle();
    expect(find.text('Adını yazmadan geçemeyiz.'), findsOneWidget);
    expect(find.text('Ölçülerin'), findsNothing);
  });

  testWidgets('bozuk doğum tarihi uyarı verir — 31 Şubat yoktur', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await toIdentity(tester);
    await enter(tester, 'onboarding-first-name', 'Kaan');
    await enter(tester, 'onboarding-birth-day', '31');
    await enter(tester, 'onboarding-birth-month', '2');
    await enter(tester, 'onboarding-birth-year', '1990');
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-identity-next')),
    );
    await tester.tap(find.byKey(const Key('onboarding-identity-next')));
    await tester.pumpAndSettle();
    expect(find.text('Doğum tarihi geçerli bir gün olmalı.'), findsOneWidget);
  });

  testWidgets('boy girilmeden bitirilemez', (tester) async {
    await tester.pumpWidget(wrap());
    await toMeasures(tester);
    await tester.ensureVisible(find.byKey(const Key('save-profile-button')));
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(profile.saved, isEmpty);
    expect(done, isFalse);
  });

  testWidgets('tam akış: profil yazılır, kilo ilk tartı olur', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await toIdentity(tester);
    await enter(tester, 'onboarding-first-name', 'Kaan');
    await enter(tester, 'onboarding-last-name', 'Akcan');
    await enter(tester, 'onboarding-birth-day', '17');
    await enter(tester, 'onboarding-birth-month', '4');
    await enter(tester, 'onboarding-birth-year', '1990');
    await tester.tap(find.text('Erkek'));
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-identity-next')),
    );
    await tester.tap(find.byKey(const Key('onboarding-identity-next')));
    await tester.pumpAndSettle();

    await enter(tester, 'field-heightCm', '182');
    await enter(tester, 'field-currentWeightKg', '92,5');
    await enter(tester, 'field-targetWeightKg', '85');
    await tester.ensureVisible(find.byKey(const Key('save-profile-button')));
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();

    expect(done, isTrue);
    expect(profile.saved[ProfileKeys.firstName], 'Kaan');
    expect(profile.saved[ProfileKeys.lastName], 'Akcan');
    expect(profile.saved[ProfileKeys.birthDate], '1990-04-17');
    expect(profile.saved[ProfileKeys.gender], 'male');
    expect(profile.saved[ProfileKeys.heightCm], '182');
    // Ondalık virgül noktaya çevrilir — veri katmanı nokta bekliyor.
    expect(profile.saved[ProfileKeys.currentWeightKg], '92.5');
    expect(profile.saved[ProfileKeys.targetWeightKg], '85');

    expect(metrics.upserts, hasLength(1));
    final (_, kind, value, unit) = metrics.upserts.single;
    expect(kind, MetricKinds.weight);
    expect(value, 92.5);
    expect(unit, 'kg');
  });

  testWidgets('boy ve kilo girilince canlı VKİ görünür (v3.1)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await toMeasures(tester);

    // Yalnız boy: satır çizilmez.
    await enter(tester, 'field-heightCm', '178');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding-bmi')), findsNothing);

    await enter(tester, 'field-currentWeightKg', '108,9');
    await tester.pumpAndSettle();

    // 108,9 / 1,78² = 34,4 → sınıf adıyla birlikte.
    expect(find.byKey(const Key('onboarding-bmi')), findsOneWidget);
    expect(find.text('34,4'), findsOneWidget);
    expect(find.text('Obez'), findsOneWidget);
  });

  testWidgets('doğum tarihi boş bırakılabilir', (tester) async {
    await tester.pumpWidget(wrap());
    await toMeasures(tester);
    await enter(tester, 'field-heightCm', '182');
    await tester.ensureVisible(find.byKey(const Key('save-profile-button')));
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();
    expect(done, isTrue);
    expect(profile.saved.containsKey(ProfileKeys.birthDate), isFalse);
    // Kilo girilmedi — tartı kaydı da yazılmaz (null ≠ 0).
    expect(metrics.upserts, isEmpty);
  });
}
