import 'package:disport/features/plan/domain/full_plan.dart';

/// Antrenman uyumu (v3 §6.1) — saf.
///
/// Uyum % = tamamlanan antrenman günü / **geçen** planlı antrenman
/// günü. Bugün paydaya yalnız antrenman yapıldıysa girer: sabah 09:00'da
/// "bugün daha yapmadın" diye oranı düşürmek haksızlık olurdu; akşam
/// yapılan antrenman ise oranı hemen yükseltmeli.
({int done, int planned}) workoutAdherence({
  required Iterable<FullPlanDay> days,
  required Set<String> workoutDoneDates,
  required DateTime today,
}) {
  final base = DateTime(today.year, today.month, today.day);
  var done = 0;
  var planned = 0;

  for (final day in days) {
    if (day.type == PlanDayType.rest || !day.hasWorkout) continue;
    final date = DateTime(day.date.year, day.date.month, day.date.day);
    if (date.isAfter(base)) continue;

    final iso = _iso(date);
    final isDone = workoutDoneDates.contains(iso);
    if (date.isAtSameMomentAs(base) && !isDone) continue;

    planned++;
    if (isDone) done++;
  }
  return (done: done, planned: planned);
}

String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
