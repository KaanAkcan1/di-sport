/// Türkçe sayı giriş ve gösterimi.
///
/// Türkçe klavyenin sayı tuş takımı ondalık ayracı olarak **virgül**
/// üretir. Yalnız nokta kabul eden bir alan, kullanıcının yazdığı
/// `2,45`'i sessizce reddeder — kullanıcı hatayı kendinde arar.
abstract final class TurkishNumber {
  /// Hem `2,45` hem `2.45` kabul eder; ayrıştırılamazsa `null`.
  static double? tryParse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  /// Ondalık ayracı virgül olan gösterim.
  static String format(double value, {int fractionDigits = 1}) =>
      value.toStringAsFixed(fractionDigits).replaceAll('.', ',');

  /// İşaretli gösterim: `+1,4` / `-0,7`.
  ///
  /// İlerleme ekranındaki haftalık fark ve tahlil değişimi için — artı
  /// işareti olmadan "1,4" arttı mı azaldı mı belli olmaz.
  static String formatDelta(double value, {int fractionDigits = 1}) {
    final text = format(value.abs(), fractionDigits: fractionDigits);
    if (value > 0) return '+$text';
    if (value < 0) return '-$text';
    return text;
  }
}
