import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/health/data/body_metrics_repository.dart';
import 'package:disport/features/health/data/metric_definitions_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MetricDefinitionsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MetricDefinitionsRepository(db);
  });
  tearDown(() => db.close());

  group('tohumlama', () {
    test('yerleşik türler MetricKinds ile birebir gelir', () async {
      await repo.seedBuiltIns();

      final all = await repo.watchAll().first;
      expect(all.map((d) => d.kind), MetricKinds.labels.keys);
      expect(all.every((d) => d.isBuiltIn), isTrue);
    });

    test('tekrar tohumlamak kopya üretmez', () async {
      await repo.seedBuiltIns();
      await repo.seedBuiltIns();

      expect(
        await repo.watchAll().first,
        hasLength(MetricKinds.labels.length),
      );
    });

    test('silinen tür geri gelmez', () async {
      await repo.seedBuiltIns();
      await repo.remove(MetricKinds.treadmillIncline);
      await repo.seedBuiltIns();

      final kinds = (await repo.watchAll().first).map((d) => d.kind);
      expect(kinds, isNot(contains(MetricKinds.treadmillIncline)));
    });

    test('tam sayı türler sıfır ondalıkla gelir', () async {
      await repo.seedBuiltIns();
      final all = await repo.watchAll().first;

      final pushup = all.firstWhere((d) => d.kind == MetricKinds.pushupMax);
      final waist = all.firstWhere((d) => d.kind == MetricKinds.waist);
      // "6,0 tekrar" diye bir şey yok.
      expect(pushup.decimals, 0);
      expect(waist.decimals, 1);
    });
  });

  group('günlük ve dönemsel ayrımı', () {
    test('kilo ve uyku günlük işaretlenir', () async {
      await repo.seedBuiltIns();
      final all = await repo.watchAll().first;

      expect(
        all.firstWhere((d) => d.kind == MetricKinds.weight).isDaily,
        isTrue,
      );
      expect(
        all.firstWhere((d) => d.kind == MetricKinds.sleepHours).isDaily,
        isTrue,
      );
    });

    test('dönemsel liste günlükleri dışarıda bırakır', () async {
      // Sağlık ekranının ölçüm kartı bunları göstermiyor: kilo ve uyku
      // Bugün ekranından her gün giriliyor, iki yerde tekrar etmeleri
      // gereksiz.
      await repo.seedBuiltIns();

      final kinds = (await repo.watchPeriodic().first).map((d) => d.kind);
      expect(kinds, isNot(contains(MetricKinds.weight)));
      expect(kinds, isNot(contains(MetricKinds.sleepHours)));
      expect(kinds, contains(MetricKinds.waist));
    });
  });

  group('ekleme', () {
    test('özel ölçüm sona eklenir', () async {
      await repo.seedBuiltIns();
      final kind = await repo.add(label: 'Kol çevresi', unit: 'cm');

      final all = await repo.watchAll().first;
      expect(all.last.kind, kind);
      expect(all.last.label, 'Kol çevresi');
      expect(all.last.isBuiltIn, isFalse);
      expect(all.last.isDaily, isFalse);
    });

    test('boş etiket reddedilir', () async {
      await expectLater(
        repo.add(label: '  ', unit: 'cm'),
        throwsArgumentError,
      );
    });

    test('özel ölçüme değer yazılabilir ve okunabilir', () async {
      // Asıl mesele bu: `body_metrics` zaten serbest bir `kind`
      // kabul ediyordu, eksik olan yalnız tanımdı.
      final kind = await repo.add(label: 'İstirahat nabzı', unit: 'atım/dk');

      await BodyMetricsRepository(db).upsert(
        isoDate: '2026-09-01',
        kind: kind,
        value: 58,
        unit: 'atım/dk',
      );

      final latest = await BodyMetricsRepository(db).latestPerKind();
      expect(latest[kind]?.value, 58);
    });
  });

  group('düzenleme', () {
    test('etiket, birim ve ondalık değiştirilebilir', () async {
      final kind = await repo.add(label: 'Nabız', unit: 'bpm');
      await repo.edit(kind, label: 'İstirahat nabzı', unit: 'atım/dk',
          decimals: 0);

      final def = (await repo.watchAll().first).single;
      expect(def.label, 'İstirahat nabzı');
      expect(def.unit, 'atım/dk');
      expect(def.decimals, 0);
    });

    test('yerleşik türün etiketi de değiştirilebilir', () async {
      await repo.seedBuiltIns();
      await repo.edit(MetricKinds.waist, label: 'Bel (göbek hizası)');

      final def = (await repo.watchAll().first)
          .firstWhere((d) => d.kind == MetricKinds.waist);
      expect(def.label, 'Bel (göbek hizası)');
      expect(def.isBuiltIn, isTrue);
    });
  });

  test('sıralama kalıcı olur', () async {
    final a = await repo.add(label: 'A', unit: 'cm');
    final b = await repo.add(label: 'B', unit: 'cm');

    await repo.reorder([b, a]);

    expect((await repo.watchAll().first).map((d) => d.kind), [b, a]);
  });

  test('silinen tanımın ölçüm geçmişi korunur', () async {
    final kind = await repo.add(label: 'Kalça', unit: 'cm');
    await BodyMetricsRepository(db).upsert(
      isoDate: '2026-09-01',
      kind: kind,
      value: 104,
      unit: 'cm',
    );

    await repo.remove(kind);

    expect(await repo.watchAll().first, isEmpty);
    // Değer duruyor: grafik ve context.md bozulmuyor.
    final latest = await BodyMetricsRepository(db).latestPerKind();
    expect(latest[kind]?.value, 104);
  });
}
