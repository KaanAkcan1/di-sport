import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Ekranların gördüğü ölçüm tanımı.
class MetricDefinition {
  const MetricDefinition({
    required this.kind,
    required this.label,
    required this.unit,
    required this.decimals,
    required this.isBuiltIn,
    required this.isDaily,
  });

  /// `body_metrics.kind` ile aynı değer.
  final String kind;
  final String label;
  final String unit;
  final int decimals;
  final bool isBuiltIn;

  /// Bugün ekranından günlük giriliyor (kilo, uyku).
  final bool isDaily;
}

/// Ölçüm tanımlarına erişim.
class MetricDefinitionsRepository {
  MetricDefinitionsRepository(this._db);

  final AppDatabase _db;

  /// Günlük girilen türler — Sağlık ekranının ölçüm kartında
  /// tekrarlanmasınlar diye işaretli.
  static const _dailyKinds = {MetricKinds.weight, MetricKinds.sleepHours};

  /// Tam sayı gösterilecek yerleşik türler.
  static const _wholeNumberKinds = {
    MetricKinds.pushupMax,
    MetricKinds.plankSec,
  };

  /// `MetricKinds`'teki yerleşik türleri bir kez ekler.
  ///
  /// Kural tohumlamasıyla aynı davranış: silinen tür geri gelmez.
  Future<void> seedBuiltIns() async {
    final existing = await (_db.select(
      _db.metricDefinitions,
    )..where((t) => t.isBuiltIn.equals(true))).get();
    final known = existing.map((row) => row.id).toSet();

    final now = DateTime.now().millisecondsSinceEpoch;
    var order = 0;
    for (final kind in MetricKinds.labels.keys) {
      final index = order++;
      if (known.contains(kind)) continue;

      await _db
          .into(_db.metricDefinitions)
          .insert(
            MetricDefinitionsCompanion.insert(
              id: kind,
              updatedAt: now,
              label: MetricKinds.labelOf(kind),
              unit: MetricKinds.unitOf(kind),
              sortOrder: index,
              decimals: Value(_wholeNumberKinds.contains(kind) ? 0 : 1),
              isBuiltIn: const Value(true),
              isDaily: Value(_dailyKinds.contains(kind)),
            ),
          );
    }
  }

  /// Etkin tanımlar, kullanıcının verdiği sırada.
  Stream<List<MetricDefinition>> watchAll() {
    final query = _db.select(_db.metricDefinitions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);

    return query.watch().map(
      (rows) => [for (final row in rows) _toDefinition(row)],
    );
  }

  /// Sağlık ekranının ölçüm kartındakiler — günlük girilenler hariç.
  Stream<List<MetricDefinition>> watchPeriodic() =>
      watchAll().map((all) => [for (final d in all) if (!d.isDaily) d]);

  Future<String> add({
    required String label,
    required String unit,
    int decimals = 1,
  }) async {
    final trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Ölçüm adı boş olamaz');
    }

    final id = const Uuid().v4();
    await _db
        .into(_db.metricDefinitions)
        .insert(
          MetricDefinitionsCompanion.insert(
            id: id,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            label: trimmedLabel,
            unit: unit.trim(),
            sortOrder: await _nextSortOrder(),
            decimals: Value(decimals),
          ),
        );
    return id;
  }

  Future<void> edit(
    String kind, {
    String? label,
    String? unit,
    int? decimals,
  }) async {
    final trimmed = label?.trim();
    if (trimmed != null && trimmed.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Ölçüm adı boş olamaz');
    }

    await (_db.update(_db.metricDefinitions)..where((t) => t.id.equals(kind)))
        .write(
          MetricDefinitionsCompanion(
            label: trimmed == null ? const Value.absent() : Value(trimmed),
            unit: unit == null ? const Value.absent() : Value(unit.trim()),
            decimals: decimals == null
                ? const Value.absent()
                : Value(decimals),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> reorder(List<String> orderedKinds) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      for (final (index, kind) in orderedKinds.indexed) {
        await (_db.update(_db.metricDefinitions)
              ..where((t) => t.id.equals(kind)))
            .write(
              MetricDefinitionsCompanion(
                sortOrder: Value(index),
                updatedAt: Value(now),
              ),
            );
      }
    });
  }

  /// Tanımı gizler.
  ///
  /// Ölçülmüş değerler `body_metrics`'te duruyor: geçmiş grafiği ve
  /// `context.md` bozulmuyor. Kullanıcı türü geri eklerse eski değerler
  /// yeniden görünür — id aynı kaldığı sürece.
  Future<void> remove(String kind) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.metricDefinitions)..where((t) => t.id.equals(kind)))
        .write(
          MetricDefinitionsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<int> _nextSortOrder() async {
    final rows = await _db.select(_db.metricDefinitions).get();
    if (rows.isEmpty) return 0;
    return rows.map((row) => row.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  MetricDefinition _toDefinition(MetricDefinitionRow row) => MetricDefinition(
    kind: row.id,
    label: row.label,
    unit: row.unit,
    decimals: row.decimals,
    isBuiltIn: row.isBuiltIn,
    isDaily: row.isDaily,
  );
}
