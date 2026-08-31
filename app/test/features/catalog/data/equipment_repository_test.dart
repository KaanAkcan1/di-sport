import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late EquipmentRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = EquipmentRepository(db);
  });
  tearDown(() => db.close());

  group('tohumlama', () {
    test('katalogdaki adlardan liste kurulur', () async {
      await repo.seedFrom(['dambıl', 'bar', 'sehpa']);

      final all = await repo.watchAll().first;
      expect(all.map((e) => e.label), ['dambıl', 'bar', 'sehpa']);
      // Varsayılan işaretsiz: "bende yok" demeyi unutan kullanıcı
      // yapamayacağı hareketleri öneri olarak almasın.
      expect(all.every((e) => !e.isOwned), isTrue);
    });

    test('vücut ağırlığı envantere girmez', () async {
      // "Yok" diyebileceğin bir şey değil; filtreyi de etkilememeli.
      await repo.seedFrom(['vücut ağırlığı', 'dambıl', 'yok']);

      final labels = (await repo.watchAll().first).map((e) => e.label);
      expect(labels, ['dambıl']);
    });

    test('büyük/küçük harf farkı kopya üretmez', () async {
      // Katalogda "Dambıl" ve "dambıl" ayrı yazılmış olabilir.
      await repo.seedFrom(['Dambıl', 'dambıl', 'DAMBIL']);

      expect(await repo.watchAll().first, hasLength(1));
    });

    test('ikinci tohumlama işaretleri bozmaz', () async {
      await repo.seedFrom(['dambıl']);
      final id = (await repo.watchAll().first).single.id;
      await repo.setOwned(id, owned: true);

      await repo.seedFrom(['dambıl', 'bar']);

      final all = await repo.watchAll().first;
      expect(all, hasLength(2));
      expect(all.firstWhere((e) => e.id == id).isOwned, isTrue);
    });
  });

  group('işaretleme', () {
    test('sahip olunanlar ayrı akışta gelir', () async {
      await repo.seedFrom(['dambıl', 'bar']);
      final all = await repo.watchAll().first;
      await repo.setOwned(all.first.id, owned: true);

      expect(await repo.watchOwnedIds().first, {all.first.id});
    });

    test('elle eklenen ekipman sahip olarak gelir', () async {
      final id = await repo.add('Kettlebell');

      final item = (await repo.watchAll().first).single;
      expect(item.id, id);
      expect(item.label, 'Kettlebell');
      expect(item.isOwned, isTrue);
    });

    test('silinen ekipman aynı adla eklenince canlanır', () async {
      // İkinci bir satır açmak envanteri kirletirdi.
      final id = await repo.add('Kettlebell');
      await repo.remove(id);
      expect(await repo.watchAll().first, isEmpty);

      await repo.add('kettlebell');
      expect(await repo.watchAll().first, hasLength(1));
    });

    test('boş ad reddedilir', () async {
      await expectLater(repo.add('  '), throwsArgumentError);
    });
  });

  group('canPerform', () {
    test('vücut ağırlığı her zaman yapılabilir', () {
      expect(
        canPerform(equipment: ['vücut ağırlığı'], ownedIds: const {}),
        isTrue,
      );
      expect(canPerform(equipment: const [], ownedIds: const {}), isTrue);
    });

    test('eksik ekipman hareketi eler', () {
      expect(
        canPerform(equipment: ['dambıl'], ownedIds: const {}),
        isFalse,
      );
    });

    test('tüm ekipman varsa yapılabilir', () {
      expect(
        canPerform(
          equipment: ['dambıl', 'sehpa'],
          ownedIds: const {'dambil', 'sehpa'},
        ),
        isTrue,
      );
    });

    test('bir tanesi bile eksikse yapılamaz', () {
      expect(
        canPerform(
          equipment: ['dambıl', 'sehpa'],
          ownedIds: const {'dambil'},
        ),
        isFalse,
      );
    });

    test('karşılaştırma Türkçe karakterden etkilenmez', () {
      // Envanterdeki kimlik katlanmış; hareketin listesi ham. İkisi
      // aynı katlamadan geçmezse "Dambıl" ile "dambıl" farklı sayılır.
      expect(
        canPerform(equipment: ['DAMBIL'], ownedIds: const {'dambil'}),
        isTrue,
      );
    });
  });
}
