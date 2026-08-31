import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/today/data/daily_rule_table.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

export 'package:disport/features/today/data/daily_rule_table.dart'
    show BuiltInRules;

/// Ekranların gördüğü kural.
class DailyRule {
  const DailyRule({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.isBuiltIn,
  });

  final String id;
  final String label;
  final String iconKey;
  final bool isBuiltIn;
}

/// Günlük kurallara erişim.
class DailyRulesRepository {
  DailyRulesRepository(this._db);

  final AppDatabase _db;

  /// Kâğıt çizelgenin üç kuralını bir kez ekler.
  ///
  /// Her açılışta çağrılıyor ama **silinmiş kuralı geri getirmiyor**:
  /// aksi hâlde kullanıcının sildiği kural her açılışta yeniden belirir
  /// ve aynı şeyi tekrar tekrar silmek zorunda kalır. Ölçüt satırın
  /// varlığı, `deletedAt`'in boşluğu değil.
  Future<void> seedBuiltIns() async {
    final existing = await (_db.select(
      _db.dailyRules,
    )..where((t) => t.isBuiltIn.equals(true))).get();
    final known = existing.map((row) => row.id).toSet();

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final (index, seed) in BuiltInRules.seeds.indexed) {
      if (known.contains(seed.id)) continue;

      await _db
          .into(_db.dailyRules)
          .insert(
            DailyRulesCompanion.insert(
              id: seed.id,
              updatedAt: now,
              label: seed.label,
              iconKey: seed.iconKey,
              sortOrder: index,
              isBuiltIn: const Value(true),
            ),
          );
    }
  }

  /// Etkin kurallar, kullanıcının verdiği sırada.
  Stream<List<DailyRule>> watchActive() {
    final query = _db.select(_db.dailyRules)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);

    return query.watch().map(
      (rows) => [for (final row in rows) _toRule(row)],
    );
  }

  Future<List<DailyRule>> active() async {
    final rows =
        await (_db.select(_db.dailyRules)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return [for (final row in rows) _toRule(row)];
  }

  /// Yeni kural ekler ve id'sini döner. Kural listenin sonuna gelir.
  Future<String> add({required String label, required String iconKey}) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Kural adı boş olamaz');
    }

    final id = const Uuid().v4();
    await _db
        .into(_db.dailyRules)
        .insert(
          DailyRulesCompanion.insert(
            id: id,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            label: trimmed,
            iconKey: iconKey,
            sortOrder: await _nextSortOrder(),
          ),
        );
    return id;
  }

  /// Etiketi ve/veya ikonu değiştirir.
  ///
  /// Yerleşik kurallar da yeniden adlandırılabilir: kullanıcının su
  /// hedefi 3 litre olmak zorunda değil. Kimlik sabit kaldığı için
  /// geçmiş kayıtlar bozulmuyor.
  Future<void> rename(String id, {String? label, String? iconKey}) async {
    final trimmed = label?.trim();
    if (trimmed != null && trimmed.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Kural adı boş olamaz');
    }

    await (_db.update(_db.dailyRules)..where((t) => t.id.equals(id))).write(
      DailyRulesCompanion(
        label: trimmed == null ? const Value.absent() : Value(trimmed),
        iconKey: iconKey == null ? const Value.absent() : Value(iconKey),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Verilen sırayı kaydeder.
  Future<void> reorder(List<String> orderedIds) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      for (final (index, id) in orderedIds.indexed) {
        await (_db.update(_db.dailyRules)..where((t) => t.id.equals(id))).write(
          DailyRulesCompanion(
            sortOrder: Value(index),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Kuralı gizler.
  ///
  /// Soft delete: geçmiş günlerin işaretleri duruyor. Kullanıcı kuralı
  /// bugün silse de dünkü işaret dünün gerçeği ve `context.md`'ye öyle
  /// gitmeli.
  Future<void> remove(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.dailyRules)..where((t) => t.id.equals(id))).write(
      DailyRulesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<int> _nextSortOrder() async {
    final rows = await _db.select(_db.dailyRules).get();
    if (rows.isEmpty) return 0;
    return rows.map((row) => row.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  DailyRule _toRule(DailyRuleRow row) => DailyRule(
    id: row.id,
    label: row.label,
    iconKey: row.iconKey,
    isBuiltIn: row.isBuiltIn,
  );
}
