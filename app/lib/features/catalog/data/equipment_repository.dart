import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/catalog/data/equipment_table.dart';
import 'package:drift/drift.dart';

export 'package:disport/features/catalog/data/equipment_table.dart'
    show bodyweightEquipment;

/// Envanterdeki bir ekipman.
class EquipmentItem {
  const EquipmentItem({
    required this.id,
    required this.label,
    required this.isOwned,
  });

  final String id;
  final String label;
  final bool isOwned;
}

/// Ekipman envanterine erişim.
class EquipmentRepository {
  EquipmentRepository(this._db);

  final AppDatabase _db;

  /// Katalogda geçen ekipman adlarından envanteri tohumlar.
  ///
  /// Kimlik olarak katlanmış etiket kullanılıyor (`TurkishText.fold`):
  /// katalogda "Dambıl" ve "dambıl" ayrı yazılmış olabilir, envanterde
  /// iki satır olmamalı.
  Future<void> seedFrom(Iterable<String> equipmentLabels) async {
    final existing = await _db.select(_db.equipmentItems).get();
    final known = existing.map((row) => row.id).toSet();

    final now = DateTime.now().millisecondsSinceEpoch;
    var order = existing.length;

    for (final label in equipmentLabels) {
      final trimmed = label.trim();
      if (trimmed.isEmpty) continue;

      final id = TurkishText.fold(trimmed);
      if (bodyweightEquipment.contains(id) || known.contains(id)) continue;
      known.add(id);

      await _db
          .into(_db.equipmentItems)
          .insert(
            EquipmentItemsCompanion.insert(
              id: id,
              updatedAt: now,
              label: trimmed,
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
          EquipmentItem(id: row.id, label: row.label, isOwned: row.isOwned),
      ],
    );
  }

  /// Kullanıcının sahip olduğu ekipmanın katlanmış kimlikleri.
  ///
  /// Filtre bunu kullanıyor; katlanmış hâli dönmesi karşılaştırmanın
  /// büyük/küçük harf ve Türkçe karakter farkından etkilenmemesini
  /// sağlıyor.
  Stream<Set<String>> watchOwnedIds() => watchAll().map(
    (items) => {
      for (final item in items)
        if (item.isOwned) item.id,
    },
  );

  Future<void> setOwned(String id, {required bool owned}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.equipmentItems)..where((t) => t.id.equals(id)))
        .write(
          EquipmentItemsCompanion(
            isOwned: Value(owned),
            updatedAt: Value(now),
          ),
        );
  }

  /// Listede olmayan bir ekipman ekler ve sahip olarak işaretler.
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
            isOwned: const Value(true),
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

/// Hareket kullanıcının envanteriyle yapılabilir mi — saf.
///
/// Vücut ağırlığı sayılmıyor: herkeste var. Ekipman listesi boş olan
/// hareket de her zaman yapılabilir.
bool canPerform({
  required List<String> equipment,
  required Set<String> ownedIds,
}) {
  for (final item in equipment) {
    final id = TurkishText.fold(item.trim());
    if (id.isEmpty || bodyweightEquipment.contains(id)) continue;
    if (!ownedIds.contains(id)) return false;
  }
  return true;
}
