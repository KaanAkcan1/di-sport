import 'package:disport/features/progress/domain/weight_trend.dart';

export 'package:disport/features/progress/domain/weight_trend.dart'
    show WeightPoint;

/// Bir günün özet için gereken kadarı.
///
/// `FullPlanDay` ya da `DailyLogView` yerine yalın kayıt: bu katman saf
/// kalmalı (spec 4.1) ve iki farklı feature'ın modelini birleştirmek
/// zorunda. Çağıran taraf eşlemeyi yapar.
typedef DayFact = ({
  String date,
  String dayType,
  bool workoutDone,
  bool noAlcoholSugar,
});

/// Bir haftanın özeti.
class WeekSummary {
  const WeekSummary({
    required this.weekIndex,
    required this.dayCount,
    required this.avgWeight,
    required this.deltaFromPrevWeek,
    required this.gymDone,
    required this.gymTarget,
    required this.homeDone,
    required this.homeTarget,
    required this.restDays,
    required this.slipDays,
  });

  /// 1'den başlar — ekranda "Hafta 1" yazacak.
  final int weekIndex;
  final int dayCount;

  /// O haftanın ortalama kilosu; hiç tartılmamışsa `null`.
  ///
  /// `null` ile `0` farkı önemli: sıfır kilo diye bir şey yok.
  final double? avgWeight;

  /// Bir önceki haftaya göre değişim. İlk haftada ve iki haftadan
  /// birinde tartı yoksa `null`.
  final double? deltaFromPrevWeek;

  final int gymDone;
  final int gymTarget;
  final int homeDone;
  final int homeTarget;
  final int restDays;

  /// "Kaçak" gün sayısı — alkol/şeker kutucuğu işaretlenmemiş günler
  /// (spec 5.5).
  final int slipDays;

  /// Yedi günü dolmamış hafta. İçinde bulunulan hafta hep böyledir;
  /// ekran "3 / 3" yazarken bunu bilmeli — yarım haftada hedefe
  /// ulaşılamamış olması başarısızlık değil.
  bool get isPartial => dayCount < 7;

  int get workoutsDone => gymDone + homeDone;
  int get workoutsTarget => gymTarget + homeTarget;
}

/// Günleri 7'şerli dilimleyip haftalık özet üretir.
///
/// Hafta sınırı **plandaki `weekIndex` değil, listenin sırası**: kullanıcı
/// planı ayın ortasında da başlatabilir, o zaman "hafta" onun 1. gününden
/// itibaren sayılır. Takvim haftasına hizalamak, üç günlük ilk haftayı
/// tam hafta gibi gösterip Δ'yı anlamsızlaştırırdı.
///
/// Son dilim 7 günden kısa olabilir; atılmaz — kullanıcı içinde
/// bulunduğu haftayı da görmeli ([WeekSummary.isPartial]).
List<WeekSummary> summarizeWeeks({
  required List<DayFact> days,
  required List<WeightPoint> weights,
  required int gymTarget,
  required int homeTarget,
}) {
  if (days.isEmpty) return const [];

  final weightByDate = {for (final point in weights) point.date: point.value};
  final summaries = <WeekSummary>[];
  double? previousAvg;

  for (var start = 0; start < days.length; start += 7) {
    final slice = days.sublist(
      start,
      start + 7 > days.length ? days.length : start + 7,
    );

    final sliceWeights = [
      for (final day in slice) ?weightByDate[day.date],
    ];
    final avg = sliceWeights.isEmpty
        ? null
        : sliceWeights.reduce((a, b) => a + b) / sliceWeights.length;

    summaries.add(
      WeekSummary(
        weekIndex: summaries.length + 1,
        dayCount: slice.length,
        avgWeight: avg,
        // İki haftadan birinde tartı yoksa fark hesaplanamaz; sıfır
        // yazmak "değişmedi" demek olurdu ki bu bir iddia.
        deltaFromPrevWeek: (avg != null && previousAvg != null)
            ? avg - previousAvg
            : null,
        gymDone: slice.where((d) => d.dayType == 'gym' && d.workoutDone).length,
        gymTarget: gymTarget,
        homeDone: slice
            .where((d) => d.dayType == 'home' && d.workoutDone)
            .length,
        homeTarget: homeTarget,
        restDays: slice.where((d) => d.dayType == 'rest').length,
        slipDays: slice.where((d) => !d.noAlcoholSugar).length,
      ),
    );

    // Tartısız hafta zinciri koparmaz: bir sonraki hafta en son bilinen
    // ortalamayla karşılaştırılır.
    previousAvg = avg ?? previousAvg;
  }

  return summaries;
}
