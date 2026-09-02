import 'package:disport/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Zaman serisindeki tek ölçüm.
///
/// `MetricSample`, `ai_bridge`'in `MetricPoint` portuyla karışmasın diye
/// ayrı adlandırıldı; port adı AI sözleşmesinin parçası.
typedef MetricSample = ({String date, double value});

/// Vücut ölçümlerine erişim.
class BodyMetricsRepository {
  BodyMetricsRepository(this._db);

  final AppDatabase _db;

  /// Aynı gün + tür için varsa günceller, yoksa ekler.
  ///
  /// Sabah tartılıp akşam tekrar tartılırsa ikinci değer geçerlidir;
  /// aynı güne iki kilo satırı grafiği bozar.
  Future<void> upsert({
    required String isoDate,
    required String kind,
    required double value,
    required String unit,
    String? note,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing =
        await (_db.select(_db.bodyMetrics)
              ..where((t) => t.date.equals(isoDate) & t.kind.equals(kind)))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.bodyMetrics)
          .insert(
            BodyMetricsCompanion.insert(
              id: const Uuid().v4(),
              updatedAt: now,
              date: isoDate,
              kind: kind,
              value: value,
              unit: unit,
              note: Value(note),
            ),
          );
      return;
    }

    await (_db.update(_db.bodyMetrics)
          ..where((t) => t.id.equals(existing.id)))
        .write(
          BodyMetricsCompanion(
            value: Value(value),
            unit: Value(unit),
            note: note == null ? const Value.absent() : Value(note),
            updatedAt: Value(now),
            // Silinmiş bir ölçümün üstüne yazılırsa geri diriltilir:
            // kullanıcı değeri yeniden girmişse silmek istememiştir.
            deletedAt: const Value(null),
          ),
        );
  }

  Stream<double?> watchValue(String isoDate, String kind) {
    final query = _db.select(_db.bodyMetrics)
      ..where(
        (t) =>
            t.date.equals(isoDate) &
            t.kind.equals(kind) &
            t.deletedAt.isNull(),
      );
    return query.watchSingleOrNull().map((row) => row?.value);
  }

  Future<double?> readValue(String isoDate, String kind) async {
    final row =
        await (_db.select(_db.bodyMetrics)..where(
              (t) =>
                  t.date.equals(isoDate) &
                  t.kind.equals(kind) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row?.value;
  }

  /// Bir ölçümün tarih sırasına göre serisi (eski → yeni).
  Future<List<MetricSample>> series(String kind, {int limit = 400}) async {
    final rows =
        await (_db.select(_db.bodyMetrics)
              ..where((t) => t.kind.equals(kind) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.date)])
              ..limit(limit))
            .get();
    return [for (final row in rows) (date: row.date, value: row.value)];
  }

  /// [series]'in akış hâli.
  ///
  /// Ayrı bir yöntem olarak duruyor çünkü İlerleme ekranı sekmeler
  /// arasında `IndexedStack` içinde canlı kalıyor: tek seferlik okuma
  /// yapsaydı, kullanıcı Bugün'de tartılıp İlerleme'ye geçtiğinde eski
  /// veriyi görürdü — ekran yeniden kurulmadığı için sorgu bir daha
  /// çalışmazdı.
  Stream<List<MetricSample>> watchSeries(String kind, {int limit = 400}) {
    final query = _db.select(_db.bodyMetrics)
      ..where((t) => t.kind.equals(kind) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.date)])
      ..limit(limit);

    return query.watch().map(
      (rows) => [for (final row in rows) (date: row.date, value: row.value)],
    );
  }

  /// [latestPerKind]'ın akış hâli — aynı gerekçeyle.
  Stream<Map<String, MetricSample>> watchLatestPerKind() {
    final query = _db.select(_db.bodyMetrics)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);

    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.kind: (date: row.date, value: row.value),
      },
    );
  }

  /// Her ölçüm türünün en güncel değeri.
  ///
  /// İlerleme ekranındaki özet kartları ve M4'teki `context.md` bunu
  /// kullanır; tür başına ayrı sorgu atmak yerine tek okuma.
  Future<Map<String, MetricSample>> latestPerKind() async {
    final rows =
        await (_db.select(_db.bodyMetrics)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();

    // Tarihe göre artan sırada okunduğu için sonraki kayıt öncekini
    // eziyor; sonuçta her tür için en yeni değer kalıyor.
    return {
      for (final row in rows)
        row.kind: (date: row.date, value: row.value),
    };
  }

  Future<void> delete(String isoDate, String kind) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.bodyMetrics)
          ..where((t) => t.date.equals(isoDate) & t.kind.equals(kind)))
        .write(
          BodyMetricsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }
}
