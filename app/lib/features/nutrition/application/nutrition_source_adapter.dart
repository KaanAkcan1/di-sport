import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/nutrition/data/nutrition_repository.dart';
import 'package:disport/features/supplements/data/supplements_repository.dart';
import 'package:disport/features/supplements/domain/dose_adherence.dart';
import 'package:disport/features/today/data/today_repository.dart';

/// `nutrition`'ın `ai_bridge`'e verdiği kaynak (v3 §9.3/6 ve /9).
///
/// Günlük alım özeti üç depodan derleniyor (öğün kalorisi, su, ilaç
/// uyumu) — kullanıcının isteği: "geçmiş su ve ilaç alımı da AI ile
/// paylaşılsın".
class NutritionSourceAdapter implements NutritionSource {
  const NutritionSourceAdapter(this._nutrition, this._today, this._supplements);

  final NutritionRepository _nutrition;
  final TodayRepository _today;
  final SupplementsRepository _supplements;

  @override
  Future<List<FoodDump>> foods() async {
    final all = await _nutrition.watchFoods().first;
    return [
      for (final food in all)
        FoodDump(
          id: food.id,
          name: food.nameTr ?? food.nameEn,
          kcal100: food.kcal100,
          defaultPortion: food.defaultPortion == null
              ? null
              : '${food.defaultPortion!.labelTr} = '
                    '${food.defaultPortion!.grams.round()} g',
        ),
    ];
  }

  @override
  Future<List<DayIntakeDump>> dailyIntake({required int lastDays}) async {
    final today = DateTime.now();
    final from = today.subtract(Duration(days: lastDays - 1));
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final kcalByDay = await _nutrition
        .kcalByDayBetween(iso(from), iso(today))
        .first;
    final logs = await _today.rowsBetween(iso(from), iso(today));
    final taken = await _supplements
        .watchTakenBetween(iso(from), iso(today))
        .first;
    final supplements = await _supplements.all();
    final adherence = {
      for (final day in doseAdherence(
        supplements: supplements,
        takenByDate: taken,
        today: today,
        days: lastDays,
      ))
        day.date: day,
    };

    return [
      for (var back = lastDays - 1; back >= 0; back--)
        () {
          final date = iso(
            DateTime(today.year, today.month, today.day - back),
          );
          final doses = adherence[date];
          return DayIntakeDump(
            date: date,
            kcalEaten: kcalByDay[date] ?? 0,
            waterMl: logs[date]?.waterMl,
            dosesTaken: doses == null || doses.unscheduled
                ? null
                : doses.taken,
            dosesPlanned: doses == null || doses.unscheduled
                ? null
                : doses.planned,
          );
        }(),
    ];
  }
}
