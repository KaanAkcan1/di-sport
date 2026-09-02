/// Koşuya geçiş ölçütlerinin durumu (spec 5.5).
///
/// PDF'in "bunlar olmadan koşma" uyarısının kod karşılığı. Üçü de
/// eklem sağlığıyla ilgili: fazla kilo dizi yorar, itme gücü gövde
/// dayanıklılığının vekili, ağrı ise yalnız kullanıcının bilebileceği
/// tek ölçüt.
class TransitionCriteria {
  const TransitionCriteria({
    required this.weightOk,
    required this.pushupOk,
    required this.painFreeOk,
  });

  final bool weightOk;
  final bool pushupOk;
  final bool painFreeOk;

  /// Üçü birden. "İkisi tuttu, yeter" yok — ölçütler birbirinin yerine
  /// geçmez, her biri ayrı bir riski kapatıyor.
  bool get allMet => weightOk && pushupOk && painFreeOk;

  /// Kaçı sağlandı — ilerleme çubuğu için.
  int get metCount =>
      (weightOk ? 1 : 0) + (pushupOk ? 1 : 0) + (painFreeOk ? 1 : 0);
}

/// Kilo eşiği (kg). Bu değerin **altı** geçerli.
const transitionWeightMaxKg = 105.0;

/// Kesintisiz şınav eşiği. Bu değer **dahil** geçerli.
const transitionPushupMinReps = 8;

/// Ölçütleri değerlendirir.
///
/// Ölçüm yoksa sağlanmamış sayılır: "henüz bilmiyoruz" ile "sağlanmadı"
/// arasındaki fark burada kullanıcı lehine değil güvenlik lehine
/// çözülür — tartılmamış biri hafif sayılmaz.
TransitionCriteria evaluateTransition({
  required double? latestWeight,
  required double? latestPushupMax,
  required bool painFreeConfirmed,
}) => TransitionCriteria(
  weightOk: latestWeight != null && latestWeight < transitionWeightMaxKg,
  pushupOk:
      latestPushupMax != null && latestPushupMax >= transitionPushupMinReps,
  painFreeOk: painFreeConfirmed,
);
