import 'package:disport/features/plan/domain/full_plan.dart';

/// Takvim hücresinin dolgu durumu.
///
/// Saf bir sınıflandırma: ekrandan bağımsız, testi doğrudan yazılıyor.
/// Renk eşlemesi sunum katmanında — burada yalnız *anlam* var.
enum DayCellFill {
  /// Günün her planlanmış işi işaretlenmiş.
  done,

  /// Bir kısmı işaretlenmiş; ya da bugün, henüz bitmedi.
  partial,

  /// Gün geçti ve hiçbir şey işaretlenmemiş — gerçek bir boşluk.
  empty,

  /// Planlanmış iş yok: serbest gün.
  free,

  /// Henüz gelmedi.
  future,
}

/// Bir günün takvimdeki dolgusunu belirler — yalnız **antrenman**
/// bilgisiyle (v3 §6.1).
///
/// v2'de dolgu slot doluluğuna bakıyordu; v3'te takvim spor sekmesinin
/// ve öğün/su işaretleri Diyet'e taşındı. Hücrenin tek sorusu kaldı:
/// "o günün antrenmanı yapıldı mı".
///
/// **Bugün asla `empty` olmaz.** Sabah 09:00'da antrenmanın yapılmamış
/// olması bir boşluk değil, günün henüz başlaması.
DayCellFill resolveWorkoutFill({
  required FullPlanDay day,
  required bool workoutDone,
  required DateTime today,
}) {
  final date = DateTime(day.date.year, day.date.month, day.date.day);
  final base = DateTime(today.year, today.month, today.day);

  if (date.isAfter(base)) return DayCellFill.future;
  if (day.type == PlanDayType.rest || !day.hasWorkout) return DayCellFill.free;
  if (workoutDone) return DayCellFill.done;

  return date.isAtSameMomentAs(base)
      ? DayCellFill.partial
      : DayCellFill.empty;
}

// Kalori tonu v3'te Diyet'e taşındı: `nutrition/domain/calorie_tone.dart`
// (T15.4); takvim artık kalori çizmiyor (T16.1).
