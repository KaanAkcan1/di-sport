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

/// Kimlikli set kaydı — Planlanan/Yapılan ekranı düzenleme için
/// satırın kimliğine muhtaç (v3 §6.2); [SetActual] onu taşımıyor.
class LoggedSet {
  const LoggedSet({
    required this.id,
    required this.exerciseId,
    required this.setIndex,
    this.reps,
    this.weightKg,
    this.durationSec,
  });

  final String id;
  final String exerciseId;
  final int setIndex;
  final int? reps;
  final double? weightKg;
  final int? durationSec;
}

/// Bir seans satırı — süre ve saat aralığı düzenlenebilir.
class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.rpe,
    this.painNote = '',
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Seans sonu zorlanma 1-10 (v3.1 §6); girilmediyse null.
  final int? rpe;

  /// "Hangi hareket rahatsız etti" notu; boş = yok.
  final String painNote;

  Duration? get duration => endedAt?.difference(startedAt);
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
    double? speedKmh,
    double? gradePct,
    String? effort,
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
          speedKmh: Value(speedKmh),
          gradePct: Value(gradePct),
          effort: Value(effort),
        ),
      );

  /// Bir seansı başlatır ya da o gün açık olanı döndürür.
  ///
  /// **Neden idempotent:** kullanıcı antrenman ekranına gün içinde
  /// birkaç kez giriyor (bir hareketi yap, çık, dön). Her girişte yeni
  /// seans açmak süreyi ve dolayısıyla kaloriyi katlardı.
  Future<String> startSession(String isoDate, {DateTime? now}) async {
    final open =
        await (_db.select(_db.workoutSessions)
              ..where(
                (t) =>
                    t.date.equals(isoDate) &
                    t.endedAt.isNull() &
                    t.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (open != null) return open.id;

    final id = const Uuid().v4();
    await _db
        .into(_db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            date: isoDate,
            startedAt: now ?? DateTime.now(),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return id;
  }

  /// O günün açık seansını kapatır.
  ///
  /// Açık seans yoksa hiçbir şey yapmıyor — "bitir"e iki kez basmak
  /// süreyi uzatmamalı.
  Future<void> endSession(String isoDate, {DateTime? now}) =>
      (_db.update(_db.workoutSessions)..where(
            (t) =>
                t.date.equals(isoDate) &
                t.endedAt.isNull() &
                t.deletedAt.isNull(),
          ))
          .write(
            WorkoutSessionsCompanion(
              endedAt: Value(now ?? DateTime.now()),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );

  /// Bir günün tamamlanmış seans süreleri.
  ///
  /// Açık seanslar **dışarıda**: bitmemiş bir antrenmanın süresi
  /// bilinmiyor ve "şu ana kadar" saymak, uygulamayı açık unutan
  /// kullanıcıya 9 saatlik antrenman yazardı.
  Stream<List<Duration>> watchSessionDurations(String isoDate) =>
      (_db.select(_db.workoutSessions)..where(
            (t) =>
                t.date.equals(isoDate) &
                t.endedAt.isNotNull() &
                t.deletedAt.isNull(),
          ))
          .watch()
          .map(
            (rows) => [
              for (final row in rows) row.endedAt!.difference(row.startedAt),
            ],
          );

  /// Aralıktaki kapalı seanslar, değerlendirmeleriyle (v3.1 §8).
  ///
  /// AI belgesinin seans satırları buradan: süre + RPE + ağrı notu.
  Future<List<({String date, int minutes, int? rpe, String painNote})>>
  listSessionsBetween(String fromIso, String toIso) async {
    final rows =
        await (_db.select(_db.workoutSessions)
              ..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(fromIso) &
                    t.date.isSmallerOrEqualValue(toIso) &
                    t.endedAt.isNotNull() &
                    t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
            .get();
    return [
      for (final row in rows)
        (
          date: row.date,
          minutes: row.endedAt!.difference(row.startedAt).inMinutes,
          rpe: row.rpe,
          painNote: row.painNote,
        ),
    ];
  }

  Stream<Map<String, Duration>> sessionsBetween(
    String fromIso,
    String toIso,
  ) =>
      (_db.select(_db.workoutSessions)..where(
            (t) =>
                t.date.isBiggerOrEqualValue(fromIso) &
                t.date.isSmallerOrEqualValue(toIso) &
                t.endedAt.isNotNull() &
                t.deletedAt.isNull(),
          ))
          .watch()
          .map((rows) {
            final totals = <String, Duration>{};
            for (final row in rows) {
              totals[row.date] =
                  (totals[row.date] ?? Duration.zero) +
                  row.endedAt!.difference(row.startedAt);
            }
            return totals;
          });

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

  // --- Planlanan/Yapılan (v3 §6.2) ---

  /// Günün kimlikli set kayıtları — düzenleme ekranı akışla okur.
  Stream<List<LoggedSet>> watchDayLogs(String isoDate) =>
      (_db.select(_db.exerciseLogs)
            ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.setIndex)]))
          .watch()
          .map(
            (rows) => [
              for (final row in rows)
                LoggedSet(
                  id: row.id,
                  exerciseId: row.exerciseId,
                  setIndex: row.setIndex,
                  reps: row.reps,
                  weightKg: row.weightKg,
                  durationSec: row.durationSec,
                ),
            ],
          );

  /// Var olan bir seti düzeltir. Verilmeyen alanlar dokunulmadan kalır.
  Future<void> updateSet(
    String id, {
    int? reps,
    double? weightKg,
    int? durationSec,
  }) =>
      (_db.update(_db.exerciseLogs)..where((t) => t.id.equals(id))).write(
        ExerciseLogsCompanion(
          reps: reps == null ? const Value.absent() : Value(reps),
          weightKg: weightKg == null ? const Value.absent() : Value(weightKg),
          durationSec: durationSec == null
              ? const Value.absent()
              : Value(durationSec),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  /// Seti siler — `undoLastSet` ile aynı sebepten kalıcı: set kaydı
  /// bir sayaç, geçmiş belge değil.
  Future<void> deleteSet(String id) =>
      (_db.delete(_db.exerciseLogs)..where((t) => t.id.equals(id))).go();

  /// Günün seansları, kimlikleriyle — düzenleme için.
  Stream<List<SessionInfo>> watchSessions(String isoDate) =>
      (_db.select(_db.workoutSessions)
            ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .watch()
          .map(
            (rows) => [
              for (final row in rows)
                SessionInfo(
                  id: row.id,
                  startedAt: row.startedAt,
                  endedAt: row.endedAt,
                  rpe: row.rpe,
                  painNote: row.painNote,
                ),
            ],
          );

  /// Antrenman geçmişi: seans ya da set kaydı olan günler, en yeni
  /// önce (v3 §6.3). İki tabloyu da dinler — geçmişe elle eklenen
  /// seans da, düzeltilen set de listeyi tazeler.
  Stream<List<({String date, Duration total, int exerciseCount})>>
  watchHistoryDays({int limit = 60}) => _db
      .customSelect(
        '''
        SELECT dates.date AS date,
          COALESCE((SELECT COUNT(DISTINCT e.exercise_id)
            FROM exercise_logs e
            WHERE e.date = dates.date AND e.deleted_at IS NULL), 0)
            AS exercise_count,
          COALESCE((SELECT SUM(s.ended_at - s.started_at)
            FROM workout_sessions s
            WHERE s.date = dates.date AND s.ended_at IS NOT NULL
              AND s.deleted_at IS NULL), 0) AS total_seconds
        FROM (
          SELECT date FROM workout_sessions WHERE deleted_at IS NULL
          UNION
          SELECT date FROM exercise_logs WHERE deleted_at IS NULL
        ) AS dates
        ORDER BY dates.date DESC
        LIMIT ?
        ''',
        variables: [Variable.withInt(limit)],
        readsFrom: {_db.workoutSessions, _db.exerciseLogs},
      )
      .watch()
      .map(
        (rows) => [
          for (final row in rows)
            (
              date: row.read<String>('date'),
              total: Duration(seconds: row.read<int>('total_seconds')),
              exerciseCount: row.read<int>('exercise_count'),
            ),
        ],
      );

  /// Seans saatlerini elle yazar (geçmiş gün için seans girişi).
  ///
  /// [sessionId] verilirse o satır güncellenir; verilmezse kapalı bir
  /// seans açılır — geçmiş güne "18:00–18:45 çalıştım" demek için canlı
  /// sayaç gerekmiyor.
  /// Seansı yazar, kimliğini döner (yeni açıldıysa da) — değerlendirme
  /// yazımı kimliğe ihtiyaç duyuyor (v3.1 §6).
  Future<String> setSessionTimes({
    required String isoDate,
    String? sessionId,
    required DateTime start,
    required DateTime end,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (sessionId != null) {
      await (_db.update(_db.workoutSessions)
            ..where((t) => t.id.equals(sessionId)))
          .write(
            WorkoutSessionsCompanion(
              startedAt: Value(start),
              endedAt: Value(end),
              updatedAt: Value(now),
            ),
          );
      return sessionId;
    }

    final id = const Uuid().v4();
    await _db
        .into(_db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            date: isoDate,
            startedAt: start,
            endedAt: Value(end),
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Seans sonu değerlendirmesi (v3.1 §6) — RPE ve ağrı notu.
  ///
  /// İkisi de isteğe bağlı; null RPE "girilmedi" demek, silme değil.
  Future<void> setSessionDebrief({
    required String sessionId,
    int? rpe,
    String? painNote,
  }) => (_db.update(_db.workoutSessions)
        ..where((t) => t.id.equals(sessionId)))
      .write(
        WorkoutSessionsCompanion(
          rpe: Value(rpe),
          painNote: painNote == null ? const Value.absent() : Value(painNote),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
}
