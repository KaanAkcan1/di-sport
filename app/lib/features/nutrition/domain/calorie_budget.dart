/// Bir günün enerji giriş-çıkışı.
class DayEnergy {
  const DayEnergy({this.eaten = 0, this.burned = 0});

  /// Öğünlerden gelen toplam kcal.
  final double eaten;

  /// Antrenman ve serbest aktiviteden gelen toplam kcal.
  ///
  /// **Bazal metabolizma dahil değil:** hedef kalori zaten onu içeriyor.
  /// İkisini de saymak günde 1500 kcal'lik hayali bir açık üretirdi.
  final double burned;

  /// Kahraman sayının gösterdiği net alım.
  double get net => eaten - burned;
}

/// Hedeften geriye kalan.
///
/// **Hedef yoksa `null` döner — sıfır değil.** Plan içeri alınmamış bir
/// kullanıcıya "0 kalori kaldın" demek, bütçesi olduğunu ve onu bitirdiğini
/// söylemek olur. Bütçe yokken ekran yalnız toplamı gösteriyor (spec §5.4).
double? remainingBudget({int? goalKcal, required DayEnergy day}) {
  if (goalKcal == null) return null;
  return goalKcal - day.net;
}

/// Kahramanın altındaki göstergenin doluluğu.
///
/// Kalanla aynı aritmetik: `(yenen − yakılan) / hedef`. Gösterge ile
/// rakam ayrı formüllerden gelseydi biri "bitti" derken öteki hâlâ
/// bütçe olduğunu gösterebilirdi.
///
/// 1'i aşabilir — çağıran bunu tehlike tonuna çeviriyor; burada
/// kırpmak aşımın ne kadar olduğunu gizlerdi.
double? gaugeFraction({int? goalKcal, required DayEnergy day}) {
  if (goalKcal == null || goalKcal <= 0) return null;
  return day.net / goalKcal;
}
