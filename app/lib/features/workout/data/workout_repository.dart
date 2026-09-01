import 'package:disport/core/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Gerçekleşen tek set.
class SetActual {
  const SetActual({
    required this.setIndex,
    this.reps,
    this.weightKg,
    this.durationSec,
  });

  final int setIndex;
  final int? reps;
  final double? weightKg;
  final int? durationSec;

  /// Kısa gösterim: "10" ya da "30 sn".
  String get shortLabel {
    if (reps != null) return '$reps';
    if (durationSec != null) return '$durationSec sn';
    return '—';
  }
}

/// Antrenman kayıtlarına erişim.
class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  Future<void> logSet({
    required String isoDate,
    required String exerciseId,
    required int setIndex,
    String? planExerciseId,
    int? reps,
    double? weightKg,
    int? durationSec,
  }) => _db
      .into(_db.exerciseLogs)
      .insert(
        ExerciseLogsCompanion.insert(
          id: const Uuid().v4(),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          date: isoDate,
          planExerciseId: Value(planExerciseId),
          exerciseId: exerciseId,
          setIndex: setIndex,
          reps: Value(reps),
          weightKg: Value(weightKg),
          durationSec: Value(durationSec),
        ),
      );

  /// Son kaydedilen seti geri alır.
  ///
  /// Yanlışlıkla iki kez dokunmak sık; geri alma olmadan kullanıcı
  /// veriyi düzeltemez.
  Future<void> undoLastSet(String isoDate, String exerciseId) async {
    final last =
        await (_db.select(_db.exerciseLogs)
              ..where(
                (t) =>
                    t.date.equals(isoDate) &
                    t.exerciseId.equals(exerciseId) &
                    t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.setIndex)])
              ..limit(1))
            .getSingleOrNull();
    if (last == null) return;

    await (_db.delete(_db.exerciseLogs)..where((t) => t.id.equals(last.id)))
        .go();
  }

  /// Gün içinde hareket başına tamamlanan set sayısı.
  Stream<Map<String, int>> watchDoneSetCounts(String isoDate) {
    final query = _db.select(_db.exerciseLogs)
      ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull());

    return query.watch().map((rows) {
      final counts = <String, int>{};
      for (final row in rows) {
        counts[row.exerciseId] = (counts[row.exerciseId] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Bu hareketin **bir önceki** seansındaki gerçekleşmeleri.
  ///
  /// Antrenman ekranında hedefin yanında gri olarak gösterilir: geçen
  /// sefer ne yaptığını bilmeden bugün ne hedefleyeceğini bilemezsin.
  Future<List<SetActual>> lastActuals(
    String exerciseId, {
    required String beforeIso,
  }) async {
    final maxDate = _db.exerciseLogs.date.max();
    final dateQuery = _db.selectOnly(_db.exerciseLogs)
      ..addColumns([maxDate])
      ..where(
        _db.exerciseLogs.exerciseId.equals(exerciseId) &
            _db.exerciseLogs.date.isSmallerThanValue(beforeIso) &
            _db.exerciseLogs.deletedAt.isNull(),
      );

    final lastDate = (await dateQuery.getSingle()).read(maxDate);
    if (lastDate == null) return const [];

    final rows =
        await (_db.select(_db.exerciseLogs)
              ..where(
                (t) =>
                    t.exerciseId.equals(exerciseId) &
                    t.date.equals(lastDate) &
                    t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.setIndex)]))
            .get();

    return [
      for (final row in rows)
        SetActual(
          setIndex: row.setIndex,
          reps: row.reps,
          weightKg: row.weightKg,
          durationSec: row.durationSec,
        ),
    ];
  }

  /// Son çalışılan hareketler — katalogun "son yaptıkların" bölümü.
  ///
  /// Hareket başına **en son gün** alınıyor; aynı hareket iki kez
  /// listelenmiyor. Katalog bu veriyi bir port üzerinden okuyor
  /// (`RecentExerciseSource`), doğrudan buraya bakmıyor.
  ///
  /// Akış: kullanıcı antrenmanı bitirip Katalog sekmesine geçtiğinde
  /// liste güncel olmalı (`IndexedStack` kuralı).
  Stream<List<({String exerciseId, String date, List<SetActual> sets})>>
  watchRecentSessions({int limit = 5}) {
    final query = _db.select(_db.exerciseLogs)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.asc(t.setIndex),
      ]);

    return query.watch().map((rows) {
      // Hareket başına yalnız en son günü topluyoruz. Satırlar tarihe
      // göre azalan geldiği için ilk görülen gün en sonuncusu.
      final latestDate = <String, String>{};
      final sets = <String, List<SetActual>>{};
      final order = <String>[];

      for (final row in rows) {
        final seen = latestDate[row.exerciseId];
        if (seen == null) {
          latestDate[row.exerciseId] = row.date;
          order.add(row.exerciseId);
        } else if (seen != row.date) {
          continue; // daha eski bir seans — atlanıyor
        }

        (sets[row.exerciseId] ??= []).add(
          SetActual(
            setIndex: row.setIndex,
            reps: row.reps,
            weightKg: row.weightKg,
            durationSec: row.durationSec,
          ),
        );
      }

      return [
        for (final id in order.take(limit))
          (exerciseId: id, date: latestDate[id]!, sets: sets[id]!),
      ];
    });
  }

  /// Aralıktaki tüm kayıtlar — M4'ün `context.md` bloğu için.
  Future<List<({String date, String exerciseId, SetActual actual})>>
  logsBetween(String fromIso, String toIso) async {
    final rows =
        await (_db.select(_db.exerciseLogs)
              ..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(fromIso) &
                    t.date.isSmallerOrEqualValue(toIso) &
                    t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.date),
                (t) => OrderingTerm.asc(t.setIndex),
              ]))
            .get();

    return [
      for (final row in rows)
        (
          date: row.date,
          exerciseId: row.exerciseId,
          actual: SetActual(
            setIndex: row.setIndex,
            reps: row.reps,
            weightKg: row.weightKg,
            durationSec: row.durationSec,
          ),
        ),
    ];
  }
}
