/// Bir günün kalori tonu.
///
/// M12'de plan takvimindeydi (`day_cell_state.dart`); v3'te kalori
/// geçmişi Diyet'e taşınınca fonksiyon da veri sahibinin yanına geldi
/// (T15.4). Takvim hâlâ eski yolu kullanıyorsa `day_cell_state`
/// yeniden dışa veriyor.
enum DayCalorieTone {
  /// Bütçenin altında kalınmış.
  under,

  /// Bütçe aşılmış.
  over,

  /// Hedef yok ya da o gün hiç yemek girilmemiş.
  none,
}

/// Bir günün kalori dengesini tona çevirir.
///
/// [net] `null` ise o gün **hiç kayıt yok** — sıfır kalori yemiş gibi
/// davranmak, kaydını girmemiş kullanıcıyı "bütçenin altında kaldın"
/// diye ödüllendirmek olurdu.
DayCalorieTone resolveCalorieTone({int? goalKcal, double? net}) {
  if (goalKcal == null || goalKcal <= 0 || net == null) {
    return DayCalorieTone.none;
  }
  return net > goalKcal ? DayCalorieTone.over : DayCalorieTone.under;
}
