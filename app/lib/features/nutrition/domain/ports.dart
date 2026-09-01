/// `nutrition`'ın dışarıdan okuduğu veri için arayüzler.
///
/// **Ok tek yönlü:** tüketen feature portu tanımlar, üreten feature
/// uygular ve bağlama `nutrition/application`'da bir satırla yapılır.
/// `ai_bridge`'in `ports.dart`'ıyla aynı desen. Böylece `nutrition`
/// `workout`'un tablolarını hiç görmüyor.
library;

/// Bir günün antrenmandan gelen harcaması.
///
/// Serbest aktiviteler **buraya dahil değil**: onlar `nutrition`'ın
/// kendi tablosunda ve toplama `nutrition_providers`'da yapılıyor.
/// Antrenman tarafına "aktiviteleri de topla" demek, `workout`'un
/// `nutrition`'ın verisini okuması demek olurdu.
abstract interface class EnergySource {
  /// `yyyy-MM-dd` günündeki tahmini harcama (kcal).
  ///
  /// Seans kaydı yoksa **0** dönüyor, tahmin uydurulmuyor: setlerin
  /// toplam süresi seansın süresi değil ve aradan geçen dinlenmeyi
  /// bilmeden kalori üretmek uydurma olurdu (spec §5.5).
  Stream<double> burnedOn(String isoDate);

  /// Aralıktaki her günün harcaması; kaydı olmayan gün haritada yok.
  Stream<Map<String, double>> burnedBetween(String fromIso, String toIso);
}
