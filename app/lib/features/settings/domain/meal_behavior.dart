import 'package:disport/features/plan/domain/meal_kind.dart';

/// Bir öğünün planlanma biçimi (v3 §3.4).
///
/// AI belgesi bunu okuyup öğünü ona göre ele alır: `planned` normal
/// önerilir, `fixed` "bu öğün sabit — kalorisini hesaba kat, değiştirme"
/// satırı alır, `external` hiç planlanmaz ve kalan öğünler dengelenir.
enum MealBehavior {
  /// Plan bu öğünü doldurur.
  planned,

  /// Hep aynı şey yenir ("menemen + çay").
  fixed,

  /// Yemekhane/dışarıda — kontrol dışı.
  external;

  static MealBehavior fromName(String name) => MealBehavior.values.firstWhere(
    (behavior) => behavior.name == name,
    orElse: () => throw ArgumentError.value(
      name,
      'behavior',
      // l10n-exempt: geliştiriciye giden hata metni.
      'bilinmeyen davranış; beklenen: '
          '${MealBehavior.values.map((b) => b.name).join(' | ')}',
    ),
  );
}

/// Bir öğünün saati ve davranışı.
///
/// Kayıt yoksa varsayılan geçerlidir: saat esnek, davranış `planned`.
/// Bu yüzden "kayıt sil" diye bir kavram yok — varsayılana dönmek
/// kaydı varsayılan değerlerle yazmakla aynı sonucu verir ve ekran
/// ikisini ayırt etmek zorunda kalmaz.
class MealBehaviorEntry {
  const MealBehaviorEntry({
    required this.meal,
    this.time,
    this.behavior = MealBehavior.planned,
    this.fixedNote,
    this.fixedItemsJson,
  });

  final MealKind meal;

  /// `HH:mm`; null ise saat esnek — alarm kurulmaz.
  final String? time;

  final MealBehavior behavior;

  /// `fixed`: ne yendiğinin serbest tarifi.
  final String? fixedNote;

  /// `fixed`: tarif besinlere bağlandıysa `[{foodId, quantity,
  /// portionId?}]`. Bağlama M15'te (Diyet); burada yalnız taşınır.
  final String? fixedItemsJson;
}
