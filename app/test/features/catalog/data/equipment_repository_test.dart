import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/domain/equipment_kind.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
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
    test('yalnız envanter sorusu anlamlı olan türler girer', () async {
      await repo.seedFrom([
        EquipmentKind.dumbbell,
        EquipmentKind.bands,
        // Bunların üçü de envantere girmemeli: herkeste var sayılıyor.
        EquipmentKind.bodyOnly,
        EquipmentKind.none,
        EquipmentKind.other,
      ]);

      final items = await repo.watchAll().first;
      expect(
        items.map((e) => e.kind),
        containsAll([EquipmentKind.dumbbell, EquipmentKind.bands]),
      );
      expect(items.map((e) => e.kind), isNot(contains(EquipmentKind.bodyOnly)));
      expect(items, hasLength(2));
    });

    test('ikinci tohumlama kopya üretmez', () async {
      await repo.seedFrom([EquipmentKind.dumbbell]);
      await repo.seedFrom([EquipmentKind.dumbbell, EquipmentKind.cable]);

      final items = await repo.watchAll().first;
      expect(items, hasLength(2));
    });

    test('yeni tohumlanan ekipman hiçbir yerde işaretli değil', () async {
      // Sahip olunmayan bir şeyi varsaymak filtrenin ilk günden yanlış
      // çalışması demek (spec §4.2.1).
      await repo.seedFrom([EquipmentKind.dumbbell]);

      final item = (await repo.watchAll().first).single;
      expect(item.atHome, isFalse);
      expect(item.atGym, isFalse);
    });
  });

  group('yere bağlı işaretleme', () {
    setUp(() => repo.seedFrom([EquipmentKind.dumbbell, EquipmentKind.cable]));

    test('ev ve salon ayrı ayrı işaretlenir', () async {
      await repo.setOwnedAt(EquipmentKind.dumbbell.name, atHome: true);
      await repo.setOwnedAt(EquipmentKind.cable.name, atGym: true);

      final inventory = await repo.watchInventory().first;
      expect(inventory.atHome, {EquipmentKind.dumbbell});
      expect(inventory.atGym, {EquipmentKind.cable});
    });

    test('bir yeri değiştirmek diğerini bozmaz', () async {
      await repo.setOwnedAt(
        EquipmentKind.dumbbell.name,
        atHome: true,
        atGym: true,
      );
      await repo.setOwnedAt(EquipmentKind.dumbbell.name, atHome: false);

      final inventory = await repo.watchInventory().first;
      expect(inventory.atHome, isEmpty);
      expect(inventory.atGym, {EquipmentKind.dumbbell});
    });
  });

  group('elle ekleme', () {
    test('eklenen ekipman iki yerde de işaretli gelir', () async {
      // Kullanıcı onu eklerken zaten "bende var" diyor; nerede olduğunu
      // ayrıca sormak fazladan bir adım olurdu.
      await repo.add('Kettlebell');

      final inventory = await repo.watchInventory().first;
      expect(inventory.atHome, contains(EquipmentKind.kettlebell));
      expect(inventory.atGym, contains(EquipmentKind.kettlebell));
    });

    test('boş ad reddedilir', () {
      expect(() => repo.add('   '), throwsArgumentError);
    });
  });

  group('canPerform', () {
    const dumbbellAtHome = EquipmentInventory(
      atHome: {EquipmentKind.dumbbell},
      atGym: {EquipmentKind.cable},
    );

    test('evde olan ekipmanla ev hareketi yapılır', () {
      expect(
        canPerform(
          required: const [EquipmentKind.dumbbell],
          inventory: dumbbellAtHome,
          where: ExerciseLocation.home,
        ),
        isTrue,
      );
    });

    test('aynı ekipman salonda yoksa salon hareketi yapılamaz', () {
      // Asıl kazanç bu: tek listeyle bu soru cevaplanamıyordu.
      expect(
        canPerform(
          required: const [EquipmentKind.dumbbell],
          inventory: dumbbellAtHome,
          where: ExerciseLocation.gym,
        ),
        isFalse,
      );
    });

    test('vücut ağırlığı her yerde geçerli', () {
      expect(
        canPerform(
          required: const [EquipmentKind.bodyOnly],
          inventory: const EquipmentInventory.empty(),
          where: ExerciseLocation.gym,
        ),
        isTrue,
      );
    });

    test('ev eşyası envantere bakmadan geçer', () {
      // Kullanıcıdan "sandalyem var" demesini beklemek gereksiz.
      expect(
        canPerform(
          required: const [EquipmentKind.other],
          inventory: const EquipmentInventory.empty(),
          where: ExerciseLocation.home,
        ),
        isTrue,
      );
    });

    test('birden çok ekipmanda hepsi gerekli', () {
      expect(
        canPerform(
          required: const [EquipmentKind.dumbbell, EquipmentKind.cable],
          inventory: dumbbellAtHome,
          where: ExerciseLocation.home,
        ),
        isFalse,
      );
    });

    test('"both" hareketi ev envanterine bakar', () {
      // Sekme ev ya da salon; `both` kaydı ikisinde de görünüyor ve
      // sorulan soru "bu sekmede yapabilir miyim".
      expect(
        canPerform(
          required: const [EquipmentKind.dumbbell],
          inventory: dumbbellAtHome,
          where: ExerciseLocation.both,
        ),
        isTrue,
      );
    });
  });

  group('EquipmentKind eşlemesi', () {
    test('free-exercise-db değerleri çözülür', () {
      expect(EquipmentKind.fromSource('body only'), EquipmentKind.bodyOnly);
      expect(EquipmentKind.fromSource('dumbbell'), EquipmentKind.dumbbell);
      expect(EquipmentKind.fromSource('kettlebells'), EquipmentKind.kettlebell);
      expect(EquipmentKind.fromSource('e-z curl bar'), EquipmentKind.ezCurlBar);
    });

    test('bilinmeyen kaynak değeri other, null ise none', () {
      // Kaynak güncellenip yeni tür eklendiğinde içe aktarma durmamalı.
      expect(EquipmentKind.fromSource('jetpack'), EquipmentKind.other);
      expect(EquipmentKind.fromSource(null), EquipmentKind.none);
    });

    test('eski Türkçe etiketler göç için çözülür', () {
      expect(
        EquipmentKind.fromLegacyTr('vücut ağırlığı'),
        EquipmentKind.bodyOnly,
      );
      expect(EquipmentKind.fromLegacyTr('Dambıl'), EquipmentKind.dumbbell);
      expect(EquipmentKind.fromLegacyTr('direnç bandı'), EquipmentKind.bands);
      expect(EquipmentKind.fromLegacyTr('koşu bandı'), EquipmentKind.machine);
      // Ev eşyaları envanter kontrolünden muaf bir türe düşüyor.
      expect(EquipmentKind.fromLegacyTr('sandalye'), EquipmentKind.other);
      expect(EquipmentKind.fromLegacyTr('duvar'), EquipmentKind.other);
    });

    test('bilinmeyen enum adı hata verir — sessiz düşüş yok', () {
      // Kendi ürettiğimiz dosyada tanımadığımız değer bir yazım hatası;
      // `other`'a düşmesi onu gizlerdi.
      expect(() => EquipmentKind.fromName('jetpack'), throwsArgumentError);
    });

    test('needsInventory yalnız gerçek ekipmanda', () {
      expect(EquipmentKind.dumbbell.needsInventory, isTrue);
      expect(EquipmentKind.bodyOnly.needsInventory, isFalse);
      expect(EquipmentKind.none.needsInventory, isFalse);
      expect(EquipmentKind.other.needsInventory, isFalse);
    });
  });
}
