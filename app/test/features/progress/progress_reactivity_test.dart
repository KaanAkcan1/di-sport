import 'dart:async';

import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/progress/application/progress_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cihazda yakalanan bir kusurun nöbetçisi.
///
/// İlerleme ve Sağlık sekmeleri `IndexedStack` içinde canlı kalıyor:
/// sekme değiştirmek ekranı yeniden kurmuyor. Sağlayıcılar tek seferlik
/// okuma yaptığı sürece kullanıcı Bugün'de tartılıp İlerleme'ye
/// geçtiğinde **eski veriyi** görüyordu — sorgu bir daha çalışmıyordu.
///
/// Widget testi bunu yakalayamaz: orada ekran her testte sıfırdan
/// kurulur, yani kusurun oluştuğu koşul hiç doğmaz. Yakalayan tek şey
/// gerçek veritabanına yazıp sağlayıcının **kendiliğinden yeniden
/// yayın yapmasını** beklemek.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    return db.close();
  });

  /// Sağlayıcının değeri [until] koşulunu sağlayana kadar bekler.
  ///
  /// `.future` kullanılamaz: akış sağlayıcısında o, **ilk** değeri
  /// döner — kusurun tam da olduğu yerde, sonraki yayını beklemez.
  /// Sağlayıcı tipi (`ProviderListenable`) `flutter_riverpod`'dan dışa
  /// verilmediği için okuma bir kapanış olarak alınıyor; çağıran taraf
  /// zaten aboneliği açık tutmakla yükümlü.
  Future<T> waitFor<T>(
    AsyncValue<T> Function() read,
    bool Function(T value) until,
  ) async {
    for (var attempt = 0; attempt < 250; attempt++) {
      if (read() case AsyncData(:final value) when until(value)) return value;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw TimeoutException(
      'Sağlayıcı yeni veriyle yeniden yayın yapmadı — tek seferlik '
      'okumaya geri dönmüş olabilir.',
    );
  }

  Future<void> weigh(String isoDate, double value) =>
      BodyMetricsRepository(db).upsert(
        isoDate: isoDate,
        kind: MetricKinds.weight,
        value: value,
        unit: 'kg',
      );

  test('İlerleme yeni tartıyı ekran yeniden kurulmadan görür', () async {
    // Ekran açık ve dinliyor; abonelik test boyunca kapanmıyor.
    final open = container.listen(progressViewProvider, (_, _) {});
    addTearDown(open.close);

    final before = await waitFor<ProgressViewData>(
      () => container.read(progressViewProvider),
      (_) => true,
    );
    expect(before.weights, isEmpty);

    // Kullanıcı Bugün sekmesinde tartılıyor.
    await weigh('2026-09-01', 109.4);

    final after = await waitFor<ProgressViewData>(
      () => container.read(progressViewProvider),
      (view) => view.weights.isNotEmpty,
    );
    expect(after.weights.single.value, 109.4);
    expect(after.isEmpty, isFalse);
  });

  test('geçiş ölçütü yeni ölçümle güncellenir', () async {
    final open = container.listen(progressViewProvider, (_, _) {});
    addTearDown(open.close);

    final before = await waitFor<ProgressViewData>(
      () => container.read(progressViewProvider),
      (_) => true,
    );
    expect(before.criteria.weightOk, isFalse);

    await weigh('2026-09-01', 103.2);

    final after = await waitFor<ProgressViewData>(
      () => container.read(progressViewProvider),
      (view) => view.weights.isNotEmpty,
    );
    expect(after.criteria.weightOk, isTrue);
  });

  test('Sağlık ekranının ölçüm kartı da akışa bağlı', () async {
    final open = container.listen(latestMetricsProvider, (_, _) {});
    addTearDown(open.close);

    await BodyMetricsRepository(db).upsert(
      isoDate: '2026-09-01',
      kind: MetricKinds.pushupMax,
      value: 9,
      unit: 'tekrar',
    );

    final latest = await waitFor<Map<String, MetricSample>>(
      () => container.read(latestMetricsProvider),
      (value) => value.isNotEmpty,
    );
    expect(latest[MetricKinds.pushupMax]?.value, 9);
  });
}
