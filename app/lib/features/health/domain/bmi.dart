/// Vücut kitle indeksi (v3 §7.1, v3.1 §1) — saf.
///
/// v3 "ilk ekranda obez damgası kötü karşılama" diye değerlendirmeyi
/// yalnız Sağlık'a koymuştu; kullanıcı kararı ters yönde (v3.1 §1.2):
/// BMI hem onboarding'de hem Sağlık'ta görünür, yumuşatma damgayı
/// silerek değil bağlam cümlesiyle yapılır.
library;

/// VKİ; kilo ya da boy yoksa null — uydurma değer üretilmez.
double? bodyMassIndex({double? weightKg, double? heightCm}) {
  if (weightKg == null || heightCm == null) return null;
  if (weightKg <= 0 || heightCm <= 0) return null;
  final meters = heightCm / 100;
  return weightKg / (meters * meters);
}

/// DSÖ erişkin eşikleri.
///
/// Kaynak: WHO — Obesity and overweight fact sheet
/// (https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight).
enum BmiClass {
  underweight,
  normal,
  overweight,
  obese;

  static BmiClass of(double bmi) {
    if (bmi < 18.5) return BmiClass.underweight;
    if (bmi < 25) return BmiClass.normal;
    if (bmi < 30) return BmiClass.overweight;
    return BmiClass.obese;
  }
}
