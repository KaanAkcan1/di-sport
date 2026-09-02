import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:disport/features/workout/data/workout_repository.dart';

/// `today` feature'ının `ai_bridge`'e verdiği günlük kayıt kaynağı.
///
/// Üç depoyu birleştiriyor çünkü "geçen dönem" tek bir tabloda değil:
/// işaretler `daily_logs`'ta, gün tipi ve slot sayısı planda,
/// gerçekleşen setler `exercise_logs`'ta.
class LogSourceAdapter implements LogSource {
  const LogSourceAdapter({
    required this.today,
    required this.plan,
    required this.workout,
    required this.now,
  });

  final TodayRepository today;
  final PlanRepository plan;
  final WorkoutRepository workout;

  /// Enjekte ediliyor: testte sabit bir güne kilitlenebilsin.
  final DateTime Function() now;

  ({String from, String to}) _range(int lastDays) {
    final today = now();
    return (
      from: PlanRepository.iso(today.subtract(Duration(days: lastDays))),
      to: PlanRepository.iso(today),
    );
  }

  @override
  Future<List<DayCompliance>> compliance({required int lastDays}) async {
    final range = _range(lastDays);
    final logs = await today.rowsBetween(range.from, range.to);
    final activePlan = await plan.activePlan();

    // Yalnız kayıt girilmiş günler bildiriliyor. Hiç dokunulmamış günü
    // "hepsi kaçırıldı" diye raporlamak yanıltıcı olur: kullanıcı
    // uygulamayı o gün hiç açmamış olabilir.
    final dates = logs.keys.toList()..sort();

    return [
      for (final date in dates)
        () {
          final log = logs[date]!;
          final day = activePlan?.days
              .where((d) => PlanRepository.iso(d.date) == date)
              .firstOrNull;

          return DayCompliance(
            date: date,
            dayType: day?.type.name ?? 'unknown',
            workoutDone: log.workoutDone,
            waterTargetMet: log.waterTargetMet,
            noAlcoholSugar: log.noAlcoholSugar,
            checkedSlots: log.checkedSlotIds.length,
            totalSlots: day?.slots.length ?? 0,
          );
        }(),
    ];
  }

  @override
  Future<List<({String date, String text})>> userNotes({
    required int lastDays,
  }) async {
    final range = _range(lastDays);
    final logs = await today.rowsBetween(range.from, range.to);

    final dates = logs.keys.toList()..sort();
    return [
      for (final date in dates)
        if (logs[date]!.note.trim().isNotEmpty)
          (date: date, text: logs[date]!.note.trim()),
    ];
  }

  @override
  Future<List<DayRealityDump>> reality({required int lastDays}) async {
    final range = _range(lastDays);
    final logs = await today.rowsBetween(range.from, range.to);

    final dates = logs.keys.toList()..sort();
    return [
      for (final date in dates)
        () {
          final log = logs[date]!;
          return DayRealityDump(
            date: date,
            bedTime: log.bedTime,
            wakeTime: log.wakeTimeActual,
            napMinutes: log.napMinutes,
            moodScore: log.moodScore,
            symptoms: log.symptoms.trim(),
            stressedDay: log.stressedDay,
            skippedMeals: log.skippedMeals,
          );
        }(),
    ].where((dump) => !dump.isEmpty).toList();
  }

  @override
  Future<List<SessionDump>> sessions({required int lastDays}) async {
    final range = _range(lastDays);
    final rows = await workout.listSessionsBetween(range.from, range.to);
    return [
      for (final row in rows)
        SessionDump(
          date: row.date,
          minutes: row.minutes,
          rpe: row.rpe,
          painNote: row.painNote,
        ),
    ];
  }

  @override
  Future<List<SetActualDump>> actuals({required int lastDays}) async {
    final range = _range(lastDays);
    final logs = await workout.logsBetween(range.from, range.to);

    return [
      for (final log in logs)
        SetActualDump(
          date: log.date,
          exerciseId: log.exerciseId,
          setIndex: log.actual.setIndex,
          reps: log.actual.reps,
          durationSec: log.actual.durationSec,
        ),
    ];
  }
}
