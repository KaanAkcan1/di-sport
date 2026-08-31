import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Bir günün kayıt durumu.
///
/// Veritabanında satır olmasa da geçerli bir görünüm döner: kullanıcı
/// henüz hiçbir şey işaretlememişse "kayıt yok" değil "hepsi boş"
/// durumu doğrudur.
class DailyLogView {
  const DailyLogView({
    this.checkedSlotIds = const {},
    this.workoutDone = false,
    this.waterTargetMet = false,
    this.noAlcoholSugar = false,
    this.note = '',
  });

  final Set<String> checkedSlotIds;
  final bool workoutDone;
  final bool waterTargetMet;
  final bool noAlcoholSugar;
  final String note;

  bool isSlotChecked(String slotId) => checkedSlotIds.contains(slotId);

  /// Günün üç kutucuğundan kaçı işaretli.
  int get flagsMet =>
      (workoutDone ? 1 : 0) +
      (waterTargetMet ? 1 : 0) +
      (noAlcoholSugar ? 1 : 0);

  bool get isEmpty =>
      checkedSlotIds.isEmpty && flagsMet == 0 && note.isEmpty;
}

/// Günlük kayıtlara erişim.
class TodayRepository {
  TodayRepository(this._db);

  final AppDatabase _db;

  Stream<DailyLogView> watchDay(String isoDate) {
    final query = _db.select(_db.dailyLogs)
      ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull());

    return query.watchSingleOrNull().map(_toView);
  }

  Future<DailyLogView> readDay(String isoDate) async {
    final row =
        await (_db.select(_db.dailyLogs)
              ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull()))
            .getSingleOrNull();
    return _toView(row);
  }

  /// Belirtilen aralıktaki günlük kayıtlar.
  ///
  /// M4'te `context.md`'nin uyum bloğu ve M5'te haftalık özet bunu
  /// kullanacak; gün gün sorgu atmak yerine tek seferde okunur.
  Future<Map<String, DailyLogView>> rowsBetween(
    String fromIso,
    String toIso,
  ) async {
    final rows =
        await (_db.select(_db.dailyLogs)..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(fromIso) &
                  t.date.isSmallerOrEqualValue(toIso) &
                  t.deletedAt.isNull(),
            ))
            .get();
    return {for (final row in rows) row.date: _toView(row)};
  }

  /// Slot işaretini tersine çevirir.
  Future<void> toggleSlot(String isoDate, String slotId) async {
    final row = await _ensureRow(isoDate);
    final ids = (jsonDecode(row.checkedSlotsJson) as List)
        .cast<String>()
        .toSet();

    if (!ids.add(slotId)) ids.remove(slotId);

    await _write(
      isoDate,
      DailyLogsCompanion(checkedSlotsJson: Value(jsonEncode(ids.toList()))),
    );
  }

  /// Yalnız verilen bayrakları günceller; verilmeyenlere dokunmaz.
  Future<void> setFlags(
    String isoDate, {
    bool? workoutDone,
    bool? waterTargetMet,
    bool? noAlcoholSugar,
  }) async {
    await _ensureRow(isoDate);
    await _write(
      isoDate,
      DailyLogsCompanion(
        workoutDone: workoutDone == null
            ? const Value.absent()
            : Value(workoutDone),
        waterTargetMet: waterTargetMet == null
            ? const Value.absent()
            : Value(waterTargetMet),
        noAlcoholSugar: noAlcoholSugar == null
            ? const Value.absent()
            : Value(noAlcoholSugar),
      ),
    );
  }

  Future<void> setNote(String isoDate, String note) async {
    await _ensureRow(isoDate);
    await _write(isoDate, DailyLogsCompanion(note: Value(note)));
  }

  /// Antrenman kaçırılan ardışık gün sayısı.
  ///
  /// PDF'in "iki gün üst üste kaçırma — kural bu" satırının karşılığı.
  /// M5'te alarm bunu okuyacak; Bugün ekranı da uyarı gösterir.
  ///
  /// [planDayTypes] gün → tip eşlemesi. Dinlenme günü kaçırılmış
  /// sayılmaz; plan bilgisi olmayan gün de sayılmaz — kullanıcı henüz
  /// plan almamışsa kaçırdığı bir şey yoktur.
  Future<int> missedStreak({
    required String todayIso,
    required Map<String, String> planDayTypes,
    int lookback = 14,
  }) async {
    final today = DateTime.parse(todayIso);
    final logs = await rowsBetween(
      _iso(today.subtract(Duration(days: lookback))),
      todayIso,
    );

    var streak = 0;
    // Bugünü saymıyoruz: gün henüz bitmedi, antrenman yapılabilir.
    for (var back = 1; back <= lookback; back++) {
      final iso = _iso(today.subtract(Duration(days: back)));
      final type = planDayTypes[iso];
      if (type == null || type == 'rest') break;
      if (logs[iso]?.workoutDone ?? false) break;
      streak++;
    }
    return streak;
  }

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DailyLogView _toView(DailyLogRow? row) {
    if (row == null) return const DailyLogView();
    return DailyLogView(
      checkedSlotIds: (jsonDecode(row.checkedSlotsJson) as List)
          .cast<String>()
          .toSet(),
      workoutDone: row.workoutDone,
      waterTargetMet: row.waterTargetMet,
      noAlcoholSugar: row.noAlcoholSugar,
      note: row.note,
    );
  }

  Future<void> _write(String isoDate, DailyLogsCompanion values) =>
      (_db.update(_db.dailyLogs)..where((t) => t.date.equals(isoDate))).write(
        values.copyWith(
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  /// O güne ait satırı garanti eder. Kullanıcı bir kutucuğa dokunana
  /// kadar satır yaratılmaz; boş günler veritabanını şişirmemeli.
  Future<DailyLogRow> _ensureRow(String isoDate) async {
    final existing =
        await (_db.select(_db.dailyLogs)
              ..where((t) => t.date.equals(isoDate)))
            .getSingleOrNull();
    if (existing != null) return existing;

    await _db
        .into(_db.dailyLogs)
        .insert(
          DailyLogsCompanion.insert(
            id: const Uuid().v4(),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            date: isoDate,
          ),
        );

    return (_db.select(_db.dailyLogs)..where((t) => t.date.equals(isoDate)))
        .getSingle();
  }
}
