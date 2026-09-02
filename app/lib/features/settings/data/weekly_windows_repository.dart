import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/settings/domain/weekly_window.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

export 'package:disport/features/settings/data/weekly_window_table.dart'
    show WindowKinds;

/// Haftalık mesai ve yasaklı saat pencerelerine erişim.
class WeeklyWindowsRepository {
  WeeklyWindowsRepository(this._db);

  final AppDatabase _db;

  Stream<List<WeeklyWindow>> watchAll() {
    final query = _db.select(_db.weeklyWindows)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.asc(t.weekday),
        (t) => OrderingTerm.asc(t.startTime),
      ]);

    return query.watch().map(
      (rows) => [for (final row in rows) _toWindow(row)],
    );
  }

  Future<List<WeeklyWindow>> all() async {
    final rows =
        await (_db.select(_db.weeklyWindows)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.weekday),
                (t) => OrderingTerm.asc(t.startTime),
              ]))
            .get();
    return [for (final row in rows) _toWindow(row)];
  }

  /// Pencere ekler.
  ///
  /// Aynı günde çakışan pencereye izin veriliyor: kullanıcı mesaisinin
  /// içine bir toplantı saati koymak isteyebilir ve bunu engellemek
  /// gerçek bir günü modellemeyi zorlaştırırdı. Çakışma zararsız —
  /// sorgular "herhangi biri kapsıyor mu" diye bakıyor.
  Future<String> add({
    required int weekday,
    required String startTime,
    required String endTime,
    required String kind,
    String label = '',
  }) async {
    if (weekday < 1 || weekday > 7) {
      throw ArgumentError.value(weekday, 'weekday', '1-7 arasında olmalı');
    }
    if (WeeklyWindow.minutesOf(startTime) < 0 ||
        WeeklyWindow.minutesOf(endTime) < 0) {
      throw ArgumentError('Saatler HH:mm biçiminde olmalı');
    }

    final id = const Uuid().v4();
    await _db
        .into(_db.weeklyWindows)
        .insert(
          WeeklyWindowsCompanion.insert(
            id: id,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            weekday: weekday,
            startTime: startTime,
            endTime: endTime,
            kind: kind,
            label: Value(label.trim()),
          ),
        );
    return id;
  }

  /// Aynı pencereyi birden çok güne kopyalar.
  ///
  /// Mesai genelde hafta içi aynı; beş kez elle girmek yerine tek
  /// seferde kurulabilmeli.
  Future<void> addForDays({
    required List<int> weekdays,
    required String startTime,
    required String endTime,
    required String kind,
    String label = '',
  }) async {
    for (final weekday in weekdays) {
      await add(
        weekday: weekday,
        startTime: startTime,
        endTime: endTime,
        kind: kind,
        label: label,
      );
    }
  }

  Future<void> remove(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (_db.update(_db.weeklyWindows)..where((t) => t.id.equals(id)))
        .write(
          WeeklyWindowsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  WeeklyWindow _toWindow(WeeklyWindowRow row) => WeeklyWindow(
    id: row.id,
    weekday: row.weekday,
    startTime: row.startTime,
    endTime: row.endTime,
    kind: row.kind,
    label: row.label,
  );
}
