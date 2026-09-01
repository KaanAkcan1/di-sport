import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/catalog/domain/equipment_kind.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:drift/drift.dart';

export 'package:disport/features/catalog/data/equipment_table.dart'
    show bodyweightEquipment;

/// Envanterdeki bir ekipman.
class EquipmentItem {
  const EquipmentItem({
    required this.id,
    required this.label,
    required this.kind,
    required this.atHome,
    required this.atGym,
  });

  final String id;
  final String label;
  final EquipmentKind kind;
  final bool atHome;
  final bool atGym;

  /// Onay kutusu gösterilsin mi.
  ///
  /// Vücut ağırlığı ve ev eşyası için etkisiz bir kutu göstermek
  /// kullanıcıya karar veriyormuş hissi verirdi; oysa `canPerform`
  /// onları zaten her yerde geçerli sayıyor.
  bool get isSelectable => kind.needsInventory;
}

/// Kullanıcının nerede neye sahip olduğu.
class EquipmentInventory {
  const EquipmentInventory({required this.atHome, required this.atGym});

  const EquipmentInventory.empty() : atHome = const {}, atGym = const {};

  final Set<EquipmentKind> atHome;
  final Set<EquipmentKind> atGym;

  Set<EquipmentKind> at(ExerciseLocation where) => switch (where) {
    ExerciseLocation.gym => atGym,
    // `both` hareketi iki yerde de yapılabiliyor; envanter sorusu
    // "hangi sekmedeyim" ile geliyor ve o sekme ev ya da salon.
    ExerciseLocation.home || ExerciseLocation.both => atHome,
  };
}

/// Ekipman envanterine erişim.
class EquipmentRepository {
  EquipmentRepository(this._db);

  final AppDatabase _db;

  /// Katalogda geçen ekipman türlerinden envanteri tohumlar.
  ///
  /// Kimlik artık enum adı — katlanmış etiket değil. Etiket dile bağlı
  /// ve M7'de çevrildi; kimliğin çeviriden etkilenmemesi gerekiyor.
  ///
  /// Envanter sorusu anlamsız olan türler (`bodyOnly`, `none`, `other`)
  /// hiç girmiyor: kullanıcıdan "vücut ağırlığım var" ya da
  /// "sandalyem var" demesini beklemek gereksiz sürtünme.
  Future<void> seedFrom(Iterable<EquipmentKind> kinds) async {
    final existing = await _db.select(_db.equipmentItems).get();
    final known = existing.map((row) => row.id).toSet();

    final now = DateTime.now().millisecondsSinceEpoch;
    var order = existing.length;

    for (final kind in kinds) {
      if (!kind.needsInventory) continue;
      final id = kind.name;
      if (known.contains(id)) continue;
      known.add(id);

      await _db
          .into(_db.equipmentItems)
          .insert(
            EquipmentItemsCompanion.insert(
              id: id,
              updatedAt: now,
              // Etiket arayüzde çeviriden geliyor; buradaki değer yalnız
              // yedek (eski kayıtlarla aynı sütun).
              label: id,
              kind: Value(id),
              sortOrder: order++,
            ),
          );
    }
  }

  Stream<List<EquipmentItem>> watchAll() {
    final query = _db.select(_db.equipmentItems)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          EquipmentItem(
            id: row.id,
            label: row.label,
            kind: EquipmentKind.fromName(row.kind),
            atHome: row.atHome,
            atGym: row.atGym,
          ),
      ],
    );
  }

  /// Nerede neye sahip olunduğu — filtrenin kaynağı.
  Stream<EquipmentInventory> watchInventory() => watchAll().map(
    (items) => EquipmentInventory(
      atHome: {
        for (final item in items)
          if (item.atHome) item.kind,
      },
      atGym: {
        for (final item in items)
          if (item.atGym) item.kind,
      },
    ),
  );

  /// Bir ekipmanın belirli bir yerdeki durumunu değiştirir.
  Future<void> setOwnedAt(
    String id, {
    bool? atHome,
    bool? atGym,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.equipmentItems)..where((t) => t.id.equals(id)))
        .write(
          EquipmentItemsCompanion(
            atHome: atHome == null ? const Value.absent() : Value(atHome),
            atGym: atGym == null ? const Value.absent() : Value(atGym),
            updatedAt: Value(now),
          ),
        );
  }

  /// Listede olmayan bir ekipman ekler ve sahip olarak işaretler.
  ///
  /// Serbest metin: kullanıcı enum'da karşılığı olmayan bir şey
  /// ekleyebilmeli. Karşılığı varsa ona eşleniyor, yoksa `other`.
  Future<String> add(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Ekipman adı boş olamaz');
    }

    final id = TurkishText.fold(trimmed);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Aynı ad zaten varsa (kullanıcı silmiş olabilir) yeniden
    // canlandırılıyor: ikinci bir satır açmak envanteri kirletir.
    await _db
        .into(_db.equipmentItems)
        .insertOnConflictUpdate(
          EquipmentItemsCompanion.insert(
            id: id,
            updatedAt: now,
            label: trimmed,
            sortOrder: await _nextSortOrder(),
            kind: Value(EquipmentKind.fromLegacyTr(trimmed).name),
            // Elle eklenen ekipman ikisinde de işaretli başlıyor:
            // kullanıcı onu eklerken zaten "bende var" diyor, nerede
            // olduğunu ayrıca sormak fazladan bir adım olurdu.
            atHome: const Value(true),
            atGym: const Value(true),
            deletedAt: const Value(null),
          ),
        );
    return id;
  }

  Future<void> remove(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.equipmentItems)..where((t) => t.id.equals(id)))
        .write(
          EquipmentItemsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<int> _nextSortOrder() async {
    final rows = await _db.select(_db.equipmentItems).get();
    if (rows.isEmpty) return 0;
    return rows.map((row) => row.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }
}

/// Hareket bu **yerde** yapılabilir mi — saf.
///
/// **Neden yere bağlı:** bu ürünün ayrımı ev ile salon. Evde dambıl
/// var, salonda kablo makinesi var; "bu hareketi yapabilir miyim"
/// sorusunun cevabı nerede antrenman yaptığına göre değişiyor ve tek
/// bir "sahip olduklarım" listesi bunu cevaplayamıyordu.
///
/// [EquipmentKind.bodyOnly], [EquipmentKind.none] ve
/// [EquipmentKind.other] her yerde geçerli: ilk ikisi ekipman
/// gerektirmiyor, üçüncüsü ev eşyası (sandalye, duvar) ve kullanıcıyı
/// onun için envanter doldurmaya zorlamak gereksiz sürtünme.
bool canPerform({
  required List<EquipmentKind> required,
  required EquipmentInventory inventory,
  required ExerciseLocation where,
}) {
  final owned = inventory.at(where);
  for (final kind in required) {
    if (!kind.needsInventory) continue;
    if (!owned.contains(kind)) return false;
  }
  return true;
}
