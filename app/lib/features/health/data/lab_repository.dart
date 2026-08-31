import 'package:disport/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

export 'package:disport/features/health/data/lab_tables.dart'
    show LabPanels;

/// Tek tahlil sonucu — ekranların ve `ai_bridge`'in gördüğü hâli.
///
/// Drift satırı (`LabResultRow`) doğrudan dışarı verilmiyor: senkron
/// sütunları (`userId`, `deletedAt`) sunum katmanını ilgilendirmiyor.
class LabEntry {
  const LabEntry({
    required this.id,
    required this.date,
    required this.marker,
    required this.value,
    required this.unit,
    required this.panel,
    this.refLow,
    this.refHigh,
    this.labName,
    this.note,
  });

  final String id;
  final String date;
  final String marker;
  final double value;
  final String unit;
  final String panel;
  final double? refLow;
  final double? refHigh;
  final String? labName;
  final String? note;
}

/// Bir değerin referans aralığına göre konumu.
enum LabStatus { low, normal, high, unknown }

/// Referans aralığına göre sınıflar — saf.
///
/// Sınırlar **dahil**: laboratuvar "30-100" yazdıysa 30 normaldir.
/// Aralık verilmemişse [LabStatus.unknown]; tahmin yürütmüyoruz, bir
/// sağlık değerini uydurma aralıkla "normal" göstermek zararlı olur.
LabStatus statusOf(LabEntry entry) {
  final low = entry.refLow;
  final high = entry.refHigh;
  if (low == null || high == null) return LabStatus.unknown;
  if (entry.value < low) return LabStatus.low;
  if (entry.value > high) return LabStatus.high;
  return LabStatus.normal;
}

/// Vadesi gelmiş bir takvim satırı.
///
/// [nextDue] takvim kurulmuş ama hiç sonuç girilmemişse `null` — böyle
/// bir satırın "bir sonraki tarihi" yoktur, hiç yaptırılmamıştır.
typedef DueSchedule = ({String marker, DateTime? nextDue, int intervalMonths});

/// Tahlil sonuçlarına ve takvimine erişim.
class LabRepository {
  LabRepository(this._db);

  final AppDatabase _db;

  /// Sonucu ekler; aynı marker'ın takvimi varsa son tarihini de ilerletir.
  ///
  /// İkisi tek transaction: sonuç yazılıp takvim güncellenmezse
  /// kullanıcıya "vakti geldi" uyarısı yeni girdiği sonuca rağmen
  /// gösterilmeye devam ederdi.
  Future<void> add(LabEntry entry) {
    return _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db
          .into(_db.labResults)
          .insert(
            LabResultsCompanion.insert(
              id: entry.id,
              updatedAt: now,
              date: entry.date,
              marker: entry.marker,
              value: entry.value,
              unit: entry.unit,
              panel: entry.panel,
              refLow: Value(entry.refLow),
              refHigh: Value(entry.refHigh),
              labName: Value(entry.labName),
              note: Value(entry.note),
            ),
            mode: InsertMode.insertOrReplace,
          );

      await _touchSchedule(entry.marker, entry.date, now);
    });
  }

  /// Panel → o panelin sonuçları (yeniden eskiye).
  Stream<Map<String, List<LabEntry>>> watchByPanel() {
    final query = _db.select(_db.labResults)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    return query.watch().map((rows) {
      final grouped = <String, List<LabEntry>>{};
      for (final row in rows) {
        (grouped[row.panel] ??= []).add(_toEntry(row));
      }
      return grouped;
    });
  }

  /// Marker başına en güncel sonuç.
  ///
  /// Sağlık ekranının özet satırları ve `context.md`'nin tahlil bölümü
  /// bunu kullanır.
  Future<List<LabEntry>> latestPerMarker() async {
    final rows =
        await (_db.select(_db.labResults)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();

    // Artan sırada okunduğu için sonraki kayıt öncekini eziyor.
    final latest = <String, LabEntry>{
      for (final row in rows) row.marker: _toEntry(row),
    };
    return latest.values.toList();
  }

  /// Aynı marker'ın tarih sırasına göre geçmişi (eskiden yeniye).
  Future<List<LabEntry>> history(String marker) async {
    final rows =
        await (_db.select(_db.labResults)
              ..where((t) => t.marker.equals(marker) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.date)]))
            .get();
    return [for (final row in rows) _toEntry(row)];
  }

  Future<void> delete(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.labResults)..where((t) => t.id.equals(id))).write(
      LabResultsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Takvimi kurar ya da aralığını değiştirir. Son tarihe dokunmaz.
  Future<void> setSchedule(String marker, int intervalMonths) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _scheduleOf(marker);

    if (existing == null) {
      // Kurulurken son tarih sonuçlardan okunuyor: kullanıcı önce
      // sonucu girip sonra takvimi kurabilir, o sonuç kaybolmamalı.
      final past = await history(marker);
      await _db
          .into(_db.labSchedules)
          .insert(
            LabSchedulesCompanion.insert(
              id: const Uuid().v4(),
              updatedAt: now,
              marker: marker,
              intervalMonths: intervalMonths,
              lastDate: Value(past.isEmpty ? null : past.last.date),
            ),
          );
      return;
    }

    await (_db.update(_db.labSchedules)
          ..where((t) => t.id.equals(existing.id)))
        .write(
          LabSchedulesCompanion(
            intervalMonths: Value(intervalMonths),
            updatedAt: Value(now),
            deletedAt: const Value(null),
          ),
        );
  }

  Future<void> removeSchedule(String marker) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.labSchedules)
          ..where((t) => t.marker.equals(marker)))
        .write(
          LabSchedulesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
  }

  Future<List<DueSchedule>> allSchedules() async {
    final rows = await (_db.select(
      _db.labSchedules,
    )..where((t) => t.deletedAt.isNull())).get();

    return [
      for (final row in rows)
        (
          marker: row.marker,
          nextDue: row.lastDate == null
              ? null
              : addMonths(DateTime.parse(row.lastDate!), row.intervalMonths),
          intervalMonths: row.intervalMonths,
        ),
    ];
  }

  /// Vadesi [now] itibarıyla gelmiş takvimler, en gecikmiş önce.
  Future<List<DueSchedule>> dueSchedules(DateTime now) async {
    final due = [
      for (final schedule in await allSchedules())
        // `nextDue == null` = takvim var, sonuç yok. Vade "gelmedi"
        // demek yanlış olurdu: kullanıcı bu tahlili hiç yaptırmamış.
        if (schedule.nextDue == null || !schedule.nextDue!.isAfter(now))
          schedule,
    ];

    due.sort((a, b) {
      if (a.nextDue == null) return b.nextDue == null ? 0 : -1;
      if (b.nextDue == null) return 1;
      return a.nextDue!.compareTo(b.nextDue!);
    });
    return due;
  }

  /// Ay ekleme.
  ///
  /// Dart taşan ayı yıla normalize eder (13. ay → sonraki yılın 1'i).
  /// Gün taşması da normalize edilir: 31 Ocak + 1 ay → 3 Mart. Tahlil
  /// takviminde bu birkaç günlük kayma önemsiz; ayın son gününe
  /// kelepçelemek gereksiz karmaşıklık olurdu.
  static DateTime addMonths(DateTime from, int months) =>
      DateTime(from.year, from.month + months, from.day);

  Future<LabScheduleRow?> _scheduleOf(String marker) =>
      (_db.select(_db.labSchedules)
            ..where((t) => t.marker.equals(marker)))
          .getSingleOrNull();

  /// Takvimin son tarihini ilerletir — yalnız **ileriye**.
  ///
  /// Kullanıcı eski bir sonucu sonradan girerse takvim geri sarmamalı;
  /// o tahlil zaten daha yeni bir tarihte yaptırılmış olabilir.
  Future<void> _touchSchedule(String marker, String date, int now) async {
    final schedule = await _scheduleOf(marker);
    if (schedule == null) return;

    final current = schedule.lastDate;
    if (current != null && current.compareTo(date) >= 0) return;

    await (_db.update(_db.labSchedules)
          ..where((t) => t.id.equals(schedule.id)))
        .write(
          LabSchedulesCompanion(
            lastDate: Value(date),
            updatedAt: Value(now),
          ),
        );
  }

  LabEntry _toEntry(LabResultRow row) => LabEntry(
    id: row.id,
    date: row.date,
    marker: row.marker,
    value: row.value,
    unit: row.unit,
    panel: row.panel,
    refLow: row.refLow,
    refHigh: row.refHigh,
    labName: row.labName,
    note: row.note,
  );
}
