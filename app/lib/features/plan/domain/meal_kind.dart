/// Günün öğünleri.
///
/// **Neden `plan` domain'inde, `nutrition`'da değil:** iki taraf da
/// buna ihtiyaç duyuyor — plan slotu bir öğünü işaret ediyor
/// (`plan_slots.mealKind`, M10) ve öğün kaydı hangi öğüne yazıldığını
/// söylüyor (`meal_entries.mealKind`). Ok tek yönlü olmalı: `nutrition`
/// `plan`'ı import eder, tersi olsaydı iki feature birbirine bağlanırdı.
enum MealKind {
  kahvalti,
  araOgun,
  ogle,
  ikindi,
  aksam,

  /// Gece atıştırması. Ayrı tutuluyor çünkü kullanıcının merak ettiği
  /// soru genelde "gece ne yedim" — ara öğüne karışırsa cevap kaybolur.
  gece;

  /// JSON ve veritabanındaki addan.
  ///
  /// Bilinmeyen ad **hata veriyor**: kendi yazdığımız veride tanımadığımız
  /// bir değer yazım hatasıdır, sessizce bir öğüne düşmesi onu gizlerdi.
  static MealKind fromName(String name) => MealKind.values.firstWhere(
    (kind) => kind.name == name,
    orElse: () => throw ArgumentError.value(
      name,
      'mealKind',
      // l10n-exempt: geliştiriciye giden hata metni.
      'bilinmeyen öğün; beklenen: '
          '${MealKind.values.map((k) => k.name).join(' | ')}',
    ),
  );
}
