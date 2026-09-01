import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/supplements/data/supplements_repository.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SupplementsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SupplementsRepository(db);
  });

  tearDown(() => db.close());

  const vitaminD = Supplement(
    id: '',
    name: 'D Vitamini',
    dose: '1000',
    unit: 'IU',
    times: ['08:00', '21:30'],
  );

  group('tanım', () {
    test('yerleşik tohum yok — liste boş başlar', () async {
      // Kimsenin varsayılan vitamini olmaz; uydurma bir kayıt
      // kullanıcıyı ilk açılışta silmeye zorlardı.
      expect(await repo.all(), isEmpty);
    });

    test('ekleme id üretir ve geri okunur', () async {
      final id = await repo.upsert(vitaminD);
      expect(id, isNotEmpty);

      final saved = (await repo.all()).single;
      expect(saved.name, 'D Vitamini');
      expect(saved.dose, '1000');
      expect(saved.unit, 'IU');
      expect(saved.times, ['08:00', '21:30']);
    });

    test('güncelleme yeni kayıt açmaz', () async {
      final id = await repo.upsert(vitaminD);
      await repo.upsert(
        Supplement(id: id, name: 'D3', dose: '2000', unit: 'IU'),
      );

      final all = await repo.all();
      expect(all, hasLength(1));
      expect(all.single.name, 'D3');
    });

    test('saatler sıralı okunur', () async {
      await repo.upsert(
        const Supplement(id: '', name: 'X', times: ['21:30', '08:00']),
      );
      expect((await repo.all()).single.times, ['08:00', '21:30']);
    });

    test('hafta günleri korunur', () async {
      await repo.upsert(
        const Supplement(id: '', name: 'X', weekdays: {1, 3, 5}),
      );
      expect((await repo.all()).single.weekdays, {1, 3, 5});
    });
  });

  group('yumuşak silme', () {
    test('listeden düşer ama alım kaydı durur', () async {
      final id = await repo.upsert(vitaminD);
      await repo.markTaken(
        supplementId: id,
        isoDate: '2026-09-01',
        time: '08:00',
        takenAt: DateTime(2026, 9, 1, 8, 5),
      );

      await repo.softDelete(id);

      expect(await repo.all(), isEmpty, reason: 'tanım listeden kalkmalı');

      // Geçmiş bozulmamalı: kullanıcıya "kayıtların duruyor" diye söz
      // veriyoruz, o söz burada tutuluyor.
      final day = await repo.watchDay('2026-09-01').first;
      expect(day, hasLength(1));
    });
  });

  group('alım işareti', () {
    test('işaretleme ve okuma', () async {
      final id = await repo.upsert(vitaminD);
      final at = DateTime(2026, 9, 1, 8, 5);

      await repo.markTaken(
        supplementId: id,
        isoDate: '2026-09-01',
        time: '08:00',
        takenAt: at,
      );

      final day = await repo.watchDay('2026-09-01').first;
      expect(day[SupplementsRepository.doseKey(id, '08:00')], at);
    });

    test('aynı saat iki kez işaretlenince tek satır kalır', () async {
      final id = await repo.upsert(vitaminD);

      for (var i = 0; i < 3; i++) {
        await repo.markTaken(
          supplementId: id,
          isoDate: '2026-09-01',
          time: '08:00',
          takenAt: DateTime(2026, 9, 1, 8, i),
        );
      }

      expect(await repo.watchDay('2026-09-01').first, hasLength(1));
    });

    test('işaret geri alınabilir — satır durur, damga boşalır', () async {
      final id = await repo.upsert(vitaminD);
      await repo.markTaken(
        supplementId: id,
        isoDate: '2026-09-01',
        time: '08:00',
        takenAt: DateTime(2026, 9, 1, 8, 5),
      );

      await repo.markTaken(
        supplementId: id,
        isoDate: '2026-09-01',
        time: '08:00',
      );

      final day = await repo.watchDay('2026-09-01').first;
      expect(day[SupplementsRepository.doseKey(id, '08:00')], isNull);
    });

    test('aynı gün iki farklı saat ayrı kayıt', () async {
      final id = await repo.upsert(vitaminD);
      final at = DateTime(2026, 9, 1, 8);

      await repo.markTaken(
        supplementId: id,
        isoDate: '2026-09-01',
        time: '08:00',
        takenAt: at,
      );
      await repo.markTaken(
        supplementId: id,
        isoDate: '2026-09-01',
        time: '21:30',
        takenAt: at,
      );

      expect(await repo.watchDay('2026-09-01').first, hasLength(2));
    });

    test('başka günün kaydı sızmaz', () async {
      final id = await repo.upsert(vitaminD);
      await repo.markTaken(
        supplementId: id,
        isoDate: '2026-08-31',
        time: '08:00',
        takenAt: DateTime(2026, 8, 31, 8),
      );

      expect(await repo.watchDay('2026-09-01').first, isEmpty);
    });
  });

  group('activeOn', () {
    test('boş hafta günü kümesi her gün demek', () {
      const daily = Supplement(id: 'x', name: 'X');
      for (var day = 1; day <= 7; day++) {
        expect(daily.activeOn(DateTime(2026, 8, 30 + day)), isTrue);
      }
    });

    test('seçili günler dışında pasif', () {
      // 2026-09-01 Salı (ISO 2).
      const weekdaysOnly = Supplement(id: 'x', name: 'X', weekdays: {2});
      expect(weekdaysOnly.activeOn(DateTime(2026, 9, 1)), isTrue);
      expect(weekdaysOnly.activeOn(DateTime(2026, 9, 2)), isFalse);
    });
  });

  test('doseLabel boş alanları atlar', () {
    expect(const Supplement(id: 'x', name: 'X').doseLabel, '');
    expect(
      const Supplement(id: 'x', name: 'X', dose: '2', unit: 'tablet').doseLabel,
      '2 tablet',
    );
  });
}
