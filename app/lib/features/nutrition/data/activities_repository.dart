import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/utils/locale_text.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:disport/features/workout/domain/energy_estimator.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Serbest aktivitelerin ve kayıtlarının deposu.
///
/// **Neden `nutrition` içinde:** aktivite kaydının tek işlevi enerji
/// hattını beslemek — "basketbol oynadım" bilgisi kalori dengesine
/// girmek için var. Ayrı bir feature açmak, tek tüketicisi nutrition
/// olan bir katman daha eklemek olurdu.
class ActivitiesRepository {
  ActivitiesRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<int> countAll() async {
    final count = _db.activities.id.count();
    final query = _db.selectOnly(_db.activities)..addColumns([count]);
    return (await query.getSingle()).read(count)!;
  }

  /// Tohumu yükler; katalog ve besinle aynı sürüm damgası deseni.
  Future<void> seedFromJson(
    String jsonString, {
    Future<int> Function()? readVersion,
    Future<void> Function(int version)? writeVersion,
  }) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final fileVersion = decoded['version'] as int? ?? 1;
    final applied = await readVersion?.call() ?? 0;

    final isEmpty = await countAll() == 0;
    if (!isEmpty && fileVersion <= applied) return;

    final items = [
      for (final raw in decoded['activities'] as List)
        Activity.fromJson(raw as Map<String, dynamic>),
    ];

    final existing = await _db.select(_db.activities).get();
    final known = {for (final row in existing) row.id};
    final deleted = {
      for (final row in existing)
        if (row.deletedAt != null) row.id,
    };

    await _db.batch((batch) {
      for (final activity in items) {
        if (deleted.contains(activity.id)) continue;
        if (known.contains(activity.id)) {
          batch.replace(_db.activities, _row(activity));
        } else {
          batch.insert(_db.activities, _row(activity));
        }
      }
    });

    await writeVersion?.call(fileVersion);
  }

  Stream<List<Activity>> watchAll({String? query}) =>
      (_db.select(_db.activities)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.nameEn)]))
          .watch()
          .map((rows) {
            final all = [for (final row in rows) _toActivity(row)];
            final needle = query?.trim() ?? '';
            if (needle.isEmpty) return all;
            return [
              for (final activity in all)
                if (LocaleText.matchesAnyLocale(needle, activity.nameEn) ||
                    LocaleText.matchesAnyLocale(needle, activity.nameTr ?? ''))
                  activity,
            ];
          });

  Future<Activity?> byId(String id) async {
    final row =
        await (_db.select(_db.activities)
              ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
            .getSingleOrNull();
    return row == null ? null : _toActivity(row);
  }

  /// Kullanıcının kendi aktivitesi (M6 kalıbı).
  Future<String> add({required String name, required double met}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      // l10n-exempt: geliştiriciye giden hata metni.
      throw ArgumentError.value(name, 'name', 'aktivite adı boş olamaz');
    }

    final id = _uuid.v4();
    await _db
        .into(_db.activities)
        .insert(
          ActivitiesCompanion.insert(
            id: id,
            nameEn: trimmed,
            nameTr: Value(trimmed),
            met: met,
            source: const Value('user'),
            searchText: Value(TurkishText.fold(trimmed)),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return id;
  }

  /// Yapılan aktiviteyi kaydeder ve harcamayı **dondurur**.
  ///
  /// Kilo kayıt anındaki kilo: kullanıcı üç ay sonra 10 kilo verdiğinde
  /// geçmiş harcamalar değişmemeli, o gün gerçekten o kadar yakmıştı.
  Future<String> logActivity({
    required Activity activity,
    required String isoDate,
    required int minutes,
    required double weightKg,
  }) async {
    final id = _uuid.v4();
    await _db
        .into(_db.activityLogs)
        .insert(
          ActivityLogsCompanion.insert(
            id: id,
            date: isoDate,
            activityId: activity.id,
            minutes: minutes,
            kcalSnapshot: kcalFor(
              met: activity.met,
              weightKg: weightKg,
              duration: Duration(minutes: minutes),
            ),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return id;
  }

  Future<void> removeLog(String id) =>
      (_db.update(_db.activityLogs)..where((t) => t.id.equals(id))).write(
        ActivityLogsCompanion(
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Stream<List<ActivityLog>> watchDay(String isoDate) {
    final logs =
        (_db.select(_db.activityLogs)
              ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull()))
            .watch();

    return logs.asyncMap((rows) async {
      final activities = await _db.select(_db.activities).get();
      final names = {for (final row in activities) row.id: row};
      return [
        for (final row in rows)
          ActivityLog(
            id: row.id,
            date: row.date,
            activityId: row.activityId,
            minutes: row.minutes,
            kcal: row.kcalSnapshot,
            activityName: switch (names[row.activityId]) {
              final activity? => activity.nameTr ?? activity.nameEn,
              null => null,
            },
          ),
      ];
    });
  }

  Stream<double> dayKcal(String isoDate) => watchDay(
    isoDate,
  ).map((logs) => logs.fold(0.0, (sum, log) => sum + log.kcal));

  Stream<Map<String, double>> kcalByDayBetween(String fromIso, String toIso) =>
      (_db.select(_db.activityLogs)..where(
            (t) =>
                t.date.isBiggerOrEqualValue(fromIso) &
                t.date.isSmallerOrEqualValue(toIso) &
                t.deletedAt.isNull(),
          ))
          .watch()
          .map((rows) {
            final totals = <String, double>{};
            for (final row in rows) {
              totals[row.date] = (totals[row.date] ?? 0) + row.kcalSnapshot;
            }
            return totals;
          });

  ActivitiesCompanion _row(Activity activity) => ActivitiesCompanion.insert(
    id: activity.id,
    nameEn: activity.nameEn,
    nameTr: Value(activity.nameTr),
    category: Value(activity.category),
    met: activity.met,
    source: Value(activity.source),
    searchText: Value(
      [
        TurkishText.fold(activity.nameEn),
        activity.nameEn.toLowerCase(),
        if (activity.nameTr != null) TurkishText.fold(activity.nameTr!),
      ].join(' '),
    ),
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );

  static Activity _toActivity(ActivityRow row) => Activity(
    id: row.id,
    nameEn: row.nameEn,
    nameTr: row.nameTr,
    category: row.category,
    met: row.met,
    source: row.source,
  );
}
