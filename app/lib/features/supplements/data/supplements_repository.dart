import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Takviye ve ilaç kayıtlarına erişim.
///
/// M6'nın "kullanıcı tanımlı veri" kalıbı: **yerleşik tohum yok**
/// (kimsenin varsayılan vitamini olmaz), silme yumuşak, geçmiş kayıt
/// bozulmaz.
class SupplementsRepository {
  SupplementsRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Silinmemiş takviyeler, ada göre sıralı.
  Stream<List<Supplement>> watchAll() {
    final query = _db.select(_db.supplements)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);

    return query.watch().map(
      (rows) => [for (final row in rows) _toModel(row)],
    );
  }

  Future<List<Supplement>> all() async {
    final rows =
        await (_db.select(_db.supplements)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return [for (final row in rows) _toModel(row)];
  }

  /// Ekler ya da günceller; yeni kayıtta id üretir ve onu döner.
  Future<String> upsert(Supplement supplement) async {
    final id = supplement.id.isEmpty ? _uuid.v4() : supplement.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db
        .into(_db.supplements)
        .insertOnConflictUpdate(
          SupplementsCompanion.insert(
            id: id,
            updatedAt: now,
            name: supplement.name,
            kind: Value(supplement.kind.name),
            dose: Value(supplement.dose),
            unit: Value(supplement.unit),
            timesJson: Value(jsonEncode(supplement.times)),
            weekdaysJson: Value(
              jsonEncode(supplement.weekdays.toList()..sort()),
            ),
            note: Value(supplement.note),
          ),
        );

    return id;
  }

  /// Yumuşak silme — geçmiş alım kayıtları olduğu gibi kalır.
  ///
  /// Kullanıcıya bunun söylenmesi şart: geçmişini kaybetmekten korkan
  /// kullanıcı listesini hiç toparlamıyor (M6 dersi).
  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.supplements)..where((t) => t.id.equals(id))).write(
      SupplementsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Verilen günün alım kayıtları — `"$supplementId@$time"` anahtarıyla.
  Stream<Map<String, DateTime?>> watchDay(String isoDate) {
    final query = _db.select(_db.supplementLogs)
      ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull());

    return query.watch().map(
      (rows) => {
        for (final row in rows) doseKey(row.supplementId, row.time): row.takenAt,
      },
    );
  }

  /// Aralıktaki **alınmış** dozlar — gün → doz anahtarları (v3 §7.4).
  ///
  /// Uyum şeridi son yedi günü tek sorguda okur; gün başına ayrı akış
  /// yedi canlı sorgu demek olurdu.
  Stream<Map<String, Set<String>>> watchTakenBetween(
    String fromIso,
    String toIso,
  ) {
    final query = _db.select(_db.supplementLogs)
      ..where(
        (t) =>
            t.date.isBiggerOrEqualValue(fromIso) &
            t.date.isSmallerOrEqualValue(toIso) &
            t.takenAt.isNotNull() &
            t.deletedAt.isNull(),
      );

    return query.watch().map((rows) {
      final byDate = <String, Set<String>>{};
      for (final row in rows) {
        byDate
            .putIfAbsent(row.date, () => {})
            .add(doseKey(row.supplementId, row.time));
      }
      return byDate;
    });
  }

  /// Alındı işaretini kurar ya da kaldırır.
  ///
  /// [takenAt] `null` geçilirse işaret kalkar — yanlış dokunuş geri
  /// alınabilmeli. Satır silinmiyor, damga boşaltılıyor: "hiç
  /// dokunulmadı" ile "işaretleyip geri aldım" ayrımı senkronda
  /// gerekecek.
  Future<void> markTaken({
    required String supplementId,
    required String isoDate,
    required String time,
    DateTime? takenAt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing =
        await (_db.select(_db.supplementLogs)..where(
              (t) =>
                  t.supplementId.equals(supplementId) &
                  t.date.equals(isoDate) &
                  t.time.equals(time),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.supplementLogs)
          .insert(
            SupplementLogsCompanion.insert(
              id: _uuid.v4(),
              updatedAt: now,
              supplementId: supplementId,
              date: isoDate,
              time: time,
              takenAt: Value(takenAt),
            ),
          );
      return;
    }

    await (_db.update(_db.supplementLogs)
          ..where((t) => t.id.equals(existing.id)))
        .write(
          SupplementLogsCompanion(
            takenAt: Value(takenAt),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ),
        );
  }

  /// `watchDay` haritasının anahtarı.
  ///
  /// Aynı takviye günde birden çok saatte alınabiliyor; anahtar ikisini
  /// birden taşımak zorunda.
  static String doseKey(String supplementId, String time) =>
      '$supplementId@$time';

  Supplement _toModel(SupplementRow row) => Supplement(
    id: row.id,
    kind: SupplementKind.fromName(row.kind),
    name: row.name,
    dose: row.dose,
    unit: row.unit,
    times: [
      for (final value in jsonDecode(row.timesJson) as List) value as String,
    ]..sort(),
    weekdays: {
      for (final value in jsonDecode(row.weekdaysJson) as List) value as int,
    },
    note: row.note,
  );
}
