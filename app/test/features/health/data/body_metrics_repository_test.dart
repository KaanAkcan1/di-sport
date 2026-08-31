import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late BodyMetricsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BodyMetricsRepository(db);
  });
  tearDown(() => db.close());

  Future<void> weigh(String date, double kg) => repo.upsert(
    isoDate: date,
    kind: MetricKinds.weight,
    value: kg,
    unit: 'kg',
  );

  group('upsert', () {
    test('yeni değer ekler', () async {
      await weigh('2026-09-01', 110);
      expect(await repo.readValue('2026-09-01', MetricKinds.weight), 110);
    });

    test('aynı gün ve tür için üstüne yazar', () async {
      await weigh('2026-09-01', 110);
      await weigh('2026-09-01', 109.4);

      expect(await repo.readValue('2026-09-01', MetricKinds.weight), 109.4);
      expect(await db.select(db.bodyMetrics).get(), hasLength(1));
    });

    test('farklı türler aynı günde yan yana durur', () async {
      await weigh('2026-09-01', 110);
      await repo.upsert(
        isoDate: '2026-09-01',
        kind: MetricKinds.sleepHours,
        value: 6.5,
        unit: 'sa',
      );

      expect(await repo.readValue('2026-09-01', MetricKinds.weight), 110);
      expect(await repo.readValue('2026-09-01', MetricKinds.sleepHours), 6.5);
    });

    test('silinen ölçüm yeniden girilince geri gelir', () async {
      await weigh('2026-09-01', 110);
      await repo.delete('2026-09-01', MetricKinds.weight);
      expect(await repo.readValue('2026-09-01', MetricKinds.weight), isNull);

      await weigh('2026-09-01', 108);
      expect(await repo.readValue('2026-09-01', MetricKinds.weight), 108);
    });
  });

  group('series', () {
    test('tarihe göre artan sırada döner', () async {
      await weigh('2026-09-03', 109);
      await weigh('2026-09-01', 110);
      await weigh('2026-09-02', 109.5);

      final series = await repo.series(MetricKinds.weight);
      expect(series.map((p) => p.date), [
        '2026-09-01',
        '2026-09-02',
        '2026-09-03',
      ]);
      expect(series.map((p) => p.value), [110, 109.5, 109]);
    });

    test('yalnız istenen türü içerir', () async {
      await weigh('2026-09-01', 110);
      await repo.upsert(
        isoDate: '2026-09-01',
        kind: MetricKinds.waist,
        value: 118,
        unit: 'cm',
      );

      expect(await repo.series(MetricKinds.weight), hasLength(1));
      expect(await repo.series(MetricKinds.waist), hasLength(1));
    });

    test('silinen kayıt seride görünmez', () async {
      await weigh('2026-09-01', 110);
      await weigh('2026-09-02', 109);
      await repo.delete('2026-09-01', MetricKinds.weight);

      final series = await repo.series(MetricKinds.weight);
      expect(series.map((p) => p.date), ['2026-09-02']);
    });

    test('kayıt yoksa boş liste', () async {
      expect(await repo.series(MetricKinds.weight), isEmpty);
    });
  });

  group('latestPerKind', () {
    test('her tür için en yeni değeri verir', () async {
      await weigh('2026-09-01', 110);
      await weigh('2026-09-05', 108.2);
      await repo.upsert(
        isoDate: '2026-09-02',
        kind: MetricKinds.pushupMax,
        value: 6,
        unit: 'tekrar',
      );

      final latest = await repo.latestPerKind();
      expect(latest[MetricKinds.weight]!.value, 108.2);
      expect(latest[MetricKinds.weight]!.date, '2026-09-05');
      expect(latest[MetricKinds.pushupMax]!.value, 6);
    });
  });

  test('MetricKinds Türkçe etiket ve birim verir', () {
    expect(MetricKinds.labelOf(MetricKinds.weight), 'Kilo');
    expect(MetricKinds.unitOf(MetricKinds.weight), 'kg');
    expect(MetricKinds.labelOf(MetricKinds.plankSec), 'Plank');
    expect(MetricKinds.unitOf(MetricKinds.plankSec), 'sn');
    // Bilinmeyen tür çökmez, kendi adını döner.
    expect(MetricKinds.labelOf('bilinmeyen'), 'bilinmeyen');
  });
}
