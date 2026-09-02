import 'package:disport/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Bir sevilen spor kaydı — aktivite kimliği + isteğe bağlı sıklık notu.
class FavoriteSport {
  const FavoriteSport({required this.activityId, this.note});

  final String activityId;
  final String? note;
}

/// Sevilen sporların deposu (v3 §3.3).
///
/// Ekipman ekranının üçüncü segmenti yazar, AI belgesi ve Dışarıda
/// listesi okur. Aktivitelerin kendisi `nutrition`ın tablosunda; burada
/// yalnız seçim ve not tutulur.
class FavoriteSportsRepository {
  FavoriteSportsRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<List<FavoriteSport>> watchAll() =>
      (_db.select(_db.favoriteSports)..where((t) => t.deletedAt.isNull()))
          .watch()
          .map(
            (rows) => [
              for (final row in rows)
                FavoriteSport(activityId: row.activityId, note: row.note),
            ],
          );

  /// Seçimi tersine çevirir: yoksa ekler, varsa yumuşak siler.
  ///
  /// Yumuşak silme diğer kullanıcı verileriyle aynı sebepten: geçmiş
  /// AI belgeleri bu kaydı görmüş olabilir, iz kalsın.
  Future<void> toggle(String activityId) async {
    final existing =
        await (_db.select(_db.favoriteSports)
              ..where(
                (t) => t.activityId.equals(activityId) & t.deletedAt.isNull(),
              ))
            .get();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing.isEmpty) {
      await _db
          .into(_db.favoriteSports)
          .insert(
            FavoriteSportsCompanion.insert(
              id: _uuid.v4(),
              activityId: activityId,
              updatedAt: now,
            ),
          );
      return;
    }

    for (final row in existing) {
      await (_db.update(_db.favoriteSports)..where((t) => t.id.equals(row.id)))
          .write(
            FavoriteSportsCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  /// Sıklık notunu günceller; boş metin notu temizler.
  Future<void> setNote(String activityId, String note) async {
    final trimmed = note.trim();
    await (_db.update(_db.favoriteSports)
          ..where((t) => t.activityId.equals(activityId) & t.deletedAt.isNull()))
        .write(
          FavoriteSportsCompanion(
            note: Value(trimmed.isEmpty ? null : trimmed),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }
}
