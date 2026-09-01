/// Check-up rehberi motoru (v3 §7.2) — saf.
///
/// Kural tablosunun kaynakları:
/// - Tam panel aralığı: MedlinePlus, "Health screenings for men/women
///   age 18 to 39 / 40 to 64"
///   (https://medlineplus.gov/ency/article/007464.htm).
/// - HbA1c 6 ay (kronik risk): ADA Standards of Care in Diabetes
///   (https://diabetesjournals.org/care).
/// - Lipit aralıkları: AHA/ACC kolesterol kılavuzu — sağlıklı erişkinde
///   4–6 yıl, sınırda/yüksek değerde yıllık
///   (https://www.heart.org/en/health-topics/cholesterol).
/// - D vitamini/B12 yıllık izlem: Endocrine Society önerileri
///   (https://www.endocrine.org).
///
/// Motor **yalnız kimlikli** kayıtları koşullarda kullanır
/// (`medical_facts.conditionId`); serbest metin yorumlanmaz. Uygulama
/// tıbbi tavsiye vermez — bölüm başında tek açıklama satırı var, karar
/// ve doktor kullanıcının.
library;

/// Rehberin önerdiği tahlil kümeleri.
enum CheckupTest {
  /// CBC + CMP + lipit + HbA1c + TSH.
  fullPanel,
  hba1c,
  lipid,
  vitaminDB12,
}

/// Tek öneri: hangi tahlil, kaç ayda bir, şimdi mi sonra mı.
class CheckupAdvice {
  const CheckupAdvice({
    required this.test,
    required this.intervalMonths,
    required this.due,
    this.monthsLeft,
  });

  final CheckupTest test;
  final int intervalMonths;

  /// Vakti geldi (hiç yapılmamış da `due` sayılır — kullanıcının
  /// bilmediği bir taban çizgisi yoktur).
  final bool due;

  /// `due` değilse kaç ay sonra.
  final int? monthsLeft;
}

/// Kronik sayılan kimlikler — HbA1c'yi 6 aya indirenler.
const _chronicForHba1c = {'insulinResistance', 'type2Diabetes'};

List<CheckupAdvice> checkupAdvice({
  required DateTime today,
  int? age,
  double? bmi,
  Set<String> conditionIds = const {},
  Map<CheckupTest, DateTime?> lastDone = const {},
  bool lastLipidBorderline = false,
}) {
  final hasChronic =
      conditionIds.intersection(_chronicForHba1c).isNotEmpty ||
      (bmi != null && bmi >= 30);

  final intervals = <CheckupTest, int>{
    // <40 sağlıklı: 2–3 yıl (30 ay orta nokta); ≥40 yıllık. Yaş
    // bilinmiyorsa temkinli taraf (yıllık) değil geniş taraf seçilir —
    // rehber öneridir, dırdır değil.
    CheckupTest.fullPanel:
        age != null && age >= 40 || conditionIds.isNotEmpty ? 12 : 30,
    if (hasChronic) CheckupTest.hba1c: 6,
    CheckupTest.lipid: lastLipidBorderline ? 12 : 60,
    CheckupTest.vitaminDB12: 12,
  };

  final advice = <CheckupAdvice>[];
  for (final entry in intervals.entries) {
    final last = lastDone[entry.key];
    if (last == null) {
      advice.add(
        CheckupAdvice(test: entry.key, intervalMonths: entry.value, due: true),
      );
      continue;
    }

    final elapsedMonths =
        (today.year - last.year) * 12 + (today.month - last.month);
    if (elapsedMonths >= entry.value) {
      advice.add(
        CheckupAdvice(test: entry.key, intervalMonths: entry.value, due: true),
      );
    } else {
      advice.add(
        CheckupAdvice(
          test: entry.key,
          intervalMonths: entry.value,
          due: false,
          monthsLeft: entry.value - elapsedMonths,
        ),
      );
    }
  }

  // Vakti gelenler önce; sonra en yakın vade.
  advice.sort((a, b) {
    if (a.due != b.due) return a.due ? -1 : 1;
    return (a.monthsLeft ?? 0).compareTo(b.monthsLeft ?? 0);
  });
  return advice;
}
