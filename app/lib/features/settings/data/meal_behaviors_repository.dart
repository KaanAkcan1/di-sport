import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:disport/features/settings/domain/meal_behavior.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Öğün saatleri ve davranışlarının deposu (v3 §3.4).
///
/// Öğün başına en fazla bir canlı satır: `upsert` önce var olanı arar.
/// Tablo şemasında bunu zorlamadık (id PK, SyncColumns kalıbı) —
/// tekillik burada korunuyor.
class MealBehaviorsRepository {
  MealBehaviorsRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<List<MealBehaviorEntry>> watchAll() =>
      (_db.select(_db.mealBehaviors)..where((t) => t.deletedAt.isNull()))
          .watch()
          .map(
            (rows) => [
              for (final row in rows)
                MealBehaviorEntry(
                  meal: MealKind.fromName(row.mealKind),
                  time: row.time,
                  behavior: MealBehavior.fromName(row.behavior),
                  fixedNote: row.fixedNote,
                  fixedItemsJson: row.fixedItemsJson,
                ),
            ],
          );

  Future<void> upsert(MealBehaviorEntry entry) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing =
        await (_db.select(_db.mealBehaviors)
              ..where(
                (t) =>
                    t.mealKind.equals(entry.meal.name) & t.deletedAt.isNull(),
              ))
            .get();

    if (existing.isEmpty) {
      await _db
          .into(_db.mealBehaviors)
          .insert(
            MealBehaviorsCompanion.insert(
              id: _uuid.v4(),
              mealKind: entry.meal.name,
              time: Value(entry.time),
              behavior: Value(entry.behavior.name),
              fixedNote: Value(entry.fixedNote),
              fixedItemsJson: Value(entry.fixedItemsJson),
              updatedAt: now,
            ),
          );
      return;
    }

    await (_db.update(_db.mealBehaviors)
          ..where((t) => t.id.equals(existing.first.id)))
        .write(
          MealBehaviorsCompanion(
            time: Value(entry.time),
            behavior: Value(entry.behavior.name),
            fixedNote: Value(entry.fixedNote),
            fixedItemsJson: Value(entry.fixedItemsJson),
            updatedAt: Value(now),
          ),
        );
  }
}
