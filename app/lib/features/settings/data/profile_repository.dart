import 'package:disport/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Anahtar-değer profil deposu.
class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  Future<Map<String, String>> all() async {
    final rows = await (_db.select(
      _db.profileEntries,
    )..where((t) => t.deletedAt.isNull())).get();
    return {for (final row in rows) row.key: row.value};
  }

  Stream<Map<String, String>> watchAll() {
    final query = _db.select(_db.profileEntries)
      ..where((t) => t.deletedAt.isNull());
    return query.watch().map(
      (rows) => {for (final row in rows) row.key: row.value},
    );
  }

  Future<String?> read(String key) async {
    final row =
        await (_db.select(_db.profileEntries)
              ..where((t) => t.key.equals(key) & t.deletedAt.isNull()))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing =
        await (_db.select(_db.profileEntries)..where((t) => t.key.equals(key)))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.profileEntries)
          .insert(
            ProfileEntriesCompanion.insert(
              id: const Uuid().v4(),
              updatedAt: now,
              key: key,
              value: value,
            ),
          );
      return;
    }

    await (_db.update(_db.profileEntries)
          ..where((t) => t.id.equals(existing.id)))
        .write(
          ProfileEntriesCompanion(
            value: Value(value),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ),
        );
  }

  /// Birden çok alanı tek seferde yazar — onboarding formu için.
  Future<void> setAll(Map<String, String> values) async {
    for (final entry in values.entries) {
      await set(entry.key, entry.value);
    }
  }

  /// Onboarding tamamlandı mı.
  ///
  /// Ölçüt boy: tek başına anlamlı, tahmin edilemez ve `context.md`'nin
  /// ilk bölümü onsuz eksik kalır.
  Future<bool> isOnboarded() async {
    final height = await read('heightCm');
    return height != null && height.trim().isNotEmpty;
  }
}
