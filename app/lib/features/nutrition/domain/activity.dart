/// Serbest bir aktivite — 2024 Adult Compendium of Physical Activities.
///
/// **Katalog hareketinden farkı:** bu bir plana konulacak şey değil,
/// olmuş bitmiş bir şey. "Basketbol maçı" için set/tekrar yok, ipucu
/// yok, ilerleme zinciri yok; tek bilinmesi gereken ne kadar sürdüğü ve
/// MET'i. Katalogla aynı tabloya koymak filtreleri ve plan editörünü
/// kirletirdi.
class Activity {
  const Activity({
    required this.id,
    required this.nameEn,
    required this.met,
    this.nameTr,
    this.category = 'diger',
    this.source = 'compendium',
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    nameEn: json['nameEn'] as String,
    nameTr: json['nameTr'] as String?,
    met: (json['met'] as num).toDouble(),
    category: json['category'] as String? ?? 'diger',
    source: json['source'] as String? ?? 'compendium',
  );

  final String id;
  final String nameEn;

  /// Türkçe karşılığı olmayabilir; arayüz o zaman İngilizcesini
  /// gösterir (katalog ve besinle aynı kural).
  final String? nameTr;

  final double met;

  /// Compendium ana başlığı — "sports", "walking", "home activity".
  final String category;

  /// `compendium` ya da `user`.
  final String source;

  String get displayNameTr => nameTr ?? nameEn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameEn': nameEn,
    if (nameTr != null) 'nameTr': nameTr,
    'category': category,
    'met': met,
    'source': source,
  };
}

/// Yapılmış bir aktivitenin kaydı.
///
/// [kcal] kayıt anında donmuş: kullanıcı üç ay sonra 10 kilo
/// verdiğinde geçmiş harcamalar değişmemeli, o gün gerçekten o kadar
/// yakmıştı.
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.date,
    required this.activityId,
    required this.minutes,
    required this.kcal,
    this.activityName,
  });

  final String id;

  /// `yyyy-MM-dd`.
  final String date;

  final String activityId;
  final int minutes;
  final double kcal;

  /// Listede göstermek için — sorguda birleştiriliyor, tabloda
  /// tutulmuyor.
  final String? activityName;
}
