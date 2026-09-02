import 'package:disport/features/nutrition/domain/ports.dart';
import 'package:disport/features/workout/data/workout_repository.dart';
import 'package:disport/features/workout/domain/energy_estimator.dart';

/// `workout`'un `nutrition`'a verdiği enerji kaynağı.
///
/// Katalog `RecentExerciseSource`'u nasıl uyguluyorsa aynısı: arayüzü
/// tüketen tanımladı, uygulaması burada, bağlama tüketenin
/// `application`'ında.
class EnergySourceAdapter implements EnergySource {
  const EnergySourceAdapter(this._repository, {required this.weightKg});

  final WorkoutRepository _repository;

  /// Kullanıcının güncel kilosu.
  ///
  /// **Geçmişe uygulanıyor** ve bu bilinçli bir sınır: seans kaydında
  /// donmuş kalori yok, hesap her okumada yapılıyor. Aktivite kaydının
  /// aksine burada snapshot tutulmadı çünkü seansın MET'i de sabit
  /// (kuvvet antrenmanı) ve tek değişken kilo — üç ay önceki
  /// antrenmanın kalorisi %5 kayabilir, kabul edilmiş bir hata payı.
  final double weightKg;

  @override
  Stream<double> burnedOn(String isoDate) => _repository
      .watchSessionDurations(isoDate)
      .map(
        (durations) => durations.fold(
          0.0,
          (sum, duration) =>
              sum +
              kcalFor(
                met: strengthTrainingMet,
                weightKg: weightKg,
                duration: duration,
              ),
        ),
      );

  @override
  Stream<Map<String, double>> burnedBetween(String fromIso, String toIso) =>
      _repository.sessionsBetween(fromIso, toIso).map(
        (byDay) => {
          for (final entry in byDay.entries)
            entry.key: kcalFor(
              met: strengthTrainingMet,
              weightKg: weightKg,
              duration: entry.value,
            ),
        },
      );
}
