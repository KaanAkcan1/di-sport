import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/medical/domain/medical_fact.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Medikal gerçeklerin deposu.
class MedicalRepository {
  MedicalRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<List<MedicalFact>> watchAll() =>
      (_db.select(_db.medicalFacts)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.label)]))
          .watch()
          .map(
            (rows) => [
              for (final row in rows)
                MedicalFact(
                  id: row.id,
                  kind: MedicalFactKind.fromName(row.kind),
                  label: row.label,
                  note: row.note,
                  conditionId: row.conditionId,
                ),
            ],
          );

  Future<String> add({
    required MedicalFactKind kind,
    required String label,
    String? note,
    String? conditionId,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      // l10n-exempt: geliştiriciye giden hata metni.
      throw ArgumentError.value(label, 'label', 'etiket boş olamaz');
    }

    final id = _uuid.v4();
    await _db
        .into(_db.medicalFacts)
        .insert(
          MedicalFactsCompanion.insert(
            id: id,
            kind: kind.name,
            label: trimmed,
            note: Value(note?.trim()),
            conditionId: Value(conditionId),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return id;
  }

  /// Yumuşak silme — AI belgesi geçmiş sürümlerde bu kaydı görmüş
  /// olabilir; iz kalsın.
  Future<void> remove(String id) =>
      (_db.update(_db.medicalFacts)..where((t) => t.id.equals(id))).write(
        MedicalFactsCompanion(
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
}
