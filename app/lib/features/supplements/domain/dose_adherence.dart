import 'package:disport/features/supplements/domain/supplement.dart';

/// Bir günün doz uyumu (v3 §7.4).
class DayDoseAdherence {
  const DayDoseAdherence({
    required this.date,
    required this.planned,
    required this.taken,
  });

  /// `yyyy-MM-dd`.
  final String date;

  final int planned;
  final int taken;

  /// Tam gün: planlanan her doz alınmış (planlı doz varken).
  bool get full => planned > 0 && taken >= planned;

  /// Eksik: bir şey alınmış ama hepsi değil, ya da hiçbiri.
  bool get partial => planned > 0 && taken > 0 && taken < planned;

  /// O gün planlı doz yok — nötr, ceza değil.
  bool get unscheduled => planned == 0;
}

/// Son [days] günün uyumu, bugünden geriye — saf.
///
/// [takenByDate] gün → alınmış doz anahtarları
/// (`SupplementsRepository.watchTakenBetween`). Planlanan sayı tanımın
/// **bugünkü** hâlinden türetilir; geçmişte saat değiştiyse küçük bir
/// kayma olabilir — kabul edilmiş sınır, tanım geçmişi tutulmuyor.
List<DayDoseAdherence> doseAdherence({
  required List<Supplement> supplements,
  required Map<String, Set<String>> takenByDate,
  required DateTime today,
  int days = 7,
}) {
  String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  final result = <DayDoseAdherence>[];
  for (var back = days - 1; back >= 0; back--) {
    final day = DateTime(today.year, today.month, today.day - back);
    final date = iso(day);
    final taken = takenByDate[date] ?? const <String>{};

    var planned = 0;
    var takenCount = 0;
    for (final supplement in supplements) {
      if (!supplement.activeOn(day)) continue;
      for (final time in supplement.times) {
        planned++;
        if (taken.contains('${supplement.id}@$time')) takenCount++;
      }
    }

    result.add(
      DayDoseAdherence(date: date, planned: planned, taken: takenCount),
    );
  }
  return result;
}
