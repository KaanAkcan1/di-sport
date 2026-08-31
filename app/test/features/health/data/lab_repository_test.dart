import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

LabEntry vitD({String date = '2026-06-15', double value = 10}) => LabEntry(
  id: 'l-$date',
  date: date,
  marker: 'Vitamin D',
  value: value,
  unit: 'ng/mL',
  refLow: 30,
  refHigh: 100,
  panel: LabPanels.vitamin,
);

LabEntry alt({String date = '2026-06-15', double value = 30}) => LabEntry(
  id: 'a-$date',
  date: date,
  marker: 'ALT',
  value: value,
  unit: 'U/L',
  refLow: 0,
  refHigh: 41,
  panel: LabPanels.liver,
);

void main() {
  late AppDatabase db;
  late LabRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LabRepository(db);
  });
  tearDown(() => db.close());

  group('watchByPanel', () {
    test('gruplar ve yeniden eskiye sıralar', () async {
      await repo.add(vitD());
      await repo.add(vitD(date: '2026-09-20', value: 24));

      final map = await repo.watchByPanel().first;
      expect(map[LabPanels.vitamin]!.first.value, 24);
      expect(map[LabPanels.vitamin], hasLength(2));
    });

    test('birden çok panel ayrı anahtarlarda toplanır', () async {
      await repo.add(vitD());
      await repo.add(alt());

      final map = await repo.watchByPanel().first;
      expect(map.keys, containsAll([LabPanels.vitamin, LabPanels.liver]));
      expect(map[LabPanels.liver]!.single.marker, 'ALT');
    });

    test('silinen kayıt görünmez', () async {
      await repo.add(vitD());
      await repo.delete('l-2026-06-15');

      expect(await repo.watchByPanel().first, isEmpty);
    });
  });

  group('statusOf', () {
    test('referans aralığına göre sınıflar', () {
      expect(statusOf(vitD(value: 10)), LabStatus.low);
      expect(statusOf(vitD(value: 50)), LabStatus.normal);
      expect(statusOf(vitD(value: 120)), LabStatus.high);
    });

    test('aralık sınırları dahildir', () {
      expect(statusOf(vitD(value: 30)), LabStatus.normal);
      expect(statusOf(vitD(value: 100)), LabStatus.normal);
    });

    test('referans yoksa bilinmiyor', () {
      const noRef = LabEntry(
        id: 'x',
        date: '2026-01-01',
        marker: 'Bilinmeyen',
        value: 5,
        unit: '-',
        panel: LabPanels.other,
      );
      expect(statusOf(noRef), LabStatus.unknown);
    });
  });

  group('latestPerMarker', () {
    test('marker başına en yeni kayıt döner', () async {
      await repo.add(vitD(date: '2026-01-01', value: 8));
      await repo.add(vitD(date: '2026-09-01', value: 42));
      await repo.add(alt());

      final latest = await repo.latestPerMarker();
      expect(latest, hasLength(2));
      expect(
        latest.firstWhere((e) => e.marker == 'Vitamin D').value,
        42,
      );
    });
  });

  group('takvim', () {
    test('add takvimin lastDate alanını da günceller', () async {
      await repo.setSchedule('Vitamin D', 3);
      await repo.add(vitD(date: '2026-05-01'));

      final due = await repo.dueSchedules(DateTime(2026, 9, 1));
      expect(due.single.marker, 'Vitamin D');
      expect(due.single.nextDue, DateTime(2026, 8, 1));
    });

    test('vadesi gelmemiş takvim listelenmez', () async {
      await repo.setSchedule('Vitamin D', 3);
      await repo.add(vitD(date: '2026-05-01'));

      expect(await repo.dueSchedules(DateTime(2026, 6, 1)), isEmpty);
    });

    test('hiç kayıt girilmemiş takvim ilk günden vadeli sayılır', () async {
      await repo.setSchedule('B12', 6);

      // lastDate yok: kullanıcı takvimi kurmuş ama hiç tahlil girmemiş.
      // "Vakti gelmedi" demek yanlış olur — hiç yaptırmamış.
      final due = await repo.dueSchedules(DateTime(2026, 9, 1));
      expect(due.single.marker, 'B12');
    });

    test('aynı marker için takvim iki kez kurulmaz', () async {
      await repo.setSchedule('Vitamin D', 3);
      await repo.setSchedule('Vitamin D', 6);

      await repo.add(vitD(date: '2026-05-01'));
      // 6 aylık aralıkta 1 Eylül henüz vadeli değil (1 Kasım olurdu).
      expect(await repo.dueSchedules(DateTime(2026, 9, 1)), isEmpty);
    });

    test('ay taşması yıla normalize edilir', () async {
      await repo.setSchedule('Vitamin D', 4);
      await repo.add(vitD(date: '2026-11-15'));

      final due = await repo.dueSchedules(DateTime(2027, 4, 1));
      expect(due.single.nextDue, DateTime(2027, 3, 15));
    });
  });
}
