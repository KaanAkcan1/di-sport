import 'package:disport/core/utils/turkish_number.dart';
import 'package:disport/features/catalog/domain/recent_exercise_source.dart';
import 'package:disport/features/workout/data/workout_repository.dart';

/// [RecentExerciseSource]'un antrenman tarafındaki uygulaması.
///
/// Katalog portu tanımlar, burası doldurur — `ai_bridge`'deki desenin
/// aynısı. Özet metni burada kuruluyor çünkü setlerin nasıl özetleneceği
/// antrenman alanının bilgisi; katalog "3×12 · 12,5 kg" ifadesinin
/// nasıl doğduğunu bilmek zorunda değil.
class RecentExerciseAdapter implements RecentExerciseSource {
  const RecentExerciseAdapter(this._repository);

  final WorkoutRepository _repository;

  @override
  Stream<List<RecentExercise>> watchRecent({int limit = 5}) {
    return _repository.watchRecentSessions(limit: limit).map(
      (sessions) => [
        for (final session in sessions)
          RecentExercise(
            exerciseId: session.exerciseId,
            date: session.date,
            summary: summarise(session.sets),
          ),
      ],
    );
  }

  /// Setleri tek satıra indirger.
  ///
  /// Ağırlıklar aynıysa tek değer yazılıyor ("3×12 · 12,5 kg");
  /// farklıysa ağırlık hiç yazılmıyor — "12,5/15/15 kg" bir satıra
  /// sığmıyor ve ortalama almak yanlış bilgi üretirdi.
  static String summarise(List<SetActual> sets) {
    if (sets.isEmpty) return '—';

    final reps = sets.map((s) => s.shortLabel).toSet();
    final counts = reps.length == 1
        ? '${sets.length}×${reps.first}'
        : sets.map((s) => s.shortLabel).join('/');

    final weights = sets
        .map((s) => s.weightKg)
        .whereType<double>()
        .toSet();

    if (weights.length != 1) return counts;

    return '$counts · ${TurkishNumber.format(weights.first, fractionDigits: 1)} kg';
  }
}
