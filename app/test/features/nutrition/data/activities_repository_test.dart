import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/nutrition/data/activities_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ActivitiesRepository repo;

  const seed = {
    'version': 1,
    'activities': [
      {
        'id': 'basketball_game',
        'nameEn': 'Basketball, game',
        'nameTr': 'Basketbol (maç)',
        'category': 'sports',
        'met': 8.0,
      },
      {
        'id': 'gardening',
        'nameEn': 'Gardening, general',
        'nameTr': 'Bahçe İşi',
        'category': 'home',
        'met': 3.8,
      },
    ],
  };

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ActivitiesRepository(db);
    await repo.seedFromJson(jsonEncode(seed));
  });

  tearDown(() => db.close());

  test('tohum yazılır', () async {
    final all = await repo.watchAll().first;
    expect(all.map((a) => a.id), containsAll(['basketball_game', 'gardening']));
  });

  test('arama iki dilde de tutar', () async {
    expect((await repo.watchAll(query: 'bahce').first).single.id, 'gardening');
    expect(
      (await repo.watchAll(query: 'garden').first).single.id,
      'gardening',
    );
  });

  test('kayıt harcamayı dondurur', () async {
    // 8 MET × 100 kg × 1 saat = 800 kcal.
    final basketball = (await repo.byId('basketball_game'))!;
    await repo.logActivity(
      activity: basketball,
      isoDate: '2026-09-01',
      minutes: 60,
      weightKg: 100,
    );

    expect(await repo.dayKcal('2026-09-01').first, closeTo(800, 1));
  });

  test('kilo sonradan değişse geçmiş harcama değişmez', () async {
    // Kayıt anındaki kiloyla hesaplandı; o gün gerçekten o kadar
    // yakmıştı.
    final basketball = (await repo.byId('basketball_game'))!;
    await repo.logActivity(
      activity: basketball,
      isoDate: '2026-09-01',
      minutes: 60,
      weightKg: 100,
    );
    await repo.logActivity(
      activity: basketball,
      isoDate: '2026-09-02',
      minutes: 60,
      weightKg: 90,
    );

    expect(await repo.dayKcal('2026-09-01').first, closeTo(800, 1));
    expect(await repo.dayKcal('2026-09-02').first, closeTo(720, 1));
  });

  test('kayıt listesinde aktivite adı görünür', () async {
    final gardening = (await repo.byId('gardening'))!;
    await repo.logActivity(
      activity: gardening,
      isoDate: '2026-09-01',
      minutes: 45,
      weightKg: 100,
    );

    final logs = await repo.watchDay('2026-09-01').first;
    expect(logs.single.activityName, 'Bahçe İşi');
    expect(logs.single.minutes, 45);
  });

  test('silinen kayıt toplamdan düşer', () async {
    final gardening = (await repo.byId('gardening'))!;
    final id = await repo.logActivity(
      activity: gardening,
      isoDate: '2026-09-01',
      minutes: 45,
      weightKg: 100,
    );

    await repo.removeLog(id);
    expect(await repo.dayKcal('2026-09-01').first, 0);
  });

  test('kullanıcı kendi aktivitesini ekleyebilir', () async {
    await repo.add(name: 'Halı Saha', met: 7.0);

    final all = await repo.watchAll(query: 'halı').first;
    expect(all.single.source, 'user');
    expect(all.single.met, 7.0);
  });

  test('boş ad reddedilir', () {
    expect(() => repo.add(name: '   ', met: 5), throwsArgumentError);
  });

  test('aralık toplamı günlere göre gruplanır', () async {
    final gardening = (await repo.byId('gardening'))!;
    for (final date in ['2026-09-01', '2026-09-03']) {
      await repo.logActivity(
        activity: gardening,
        isoDate: date,
        minutes: 60,
        weightKg: 100,
      );
    }

    final totals = await repo
        .kcalByDayBetween('2026-09-01', '2026-09-05')
        .first;
    expect(totals.keys, containsAll(['2026-09-01', '2026-09-03']));
    expect(totals['2026-09-01'], closeTo(380, 1));
    expect(totals.containsKey('2026-09-02'), isFalse);
  });

  test('kullanıcının sildiği yerleşik geri gelmez', () async {
    await db.customStatement(
      "UPDATE activities SET deleted_at = 1 WHERE id = 'gardening'",
    );

    await repo.seedFromJson(
      jsonEncode({...seed, 'version': 2}),
      readVersion: () async => 1,
    );

    final all = await repo.watchAll().first;
    expect(all.map((a) => a.id), isNot(contains('gardening')));
  });
}
