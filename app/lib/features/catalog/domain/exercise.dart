/// Hareketin türü.
enum ExerciseCategory { strength, cardio, mobility, core }

/// Hareketin nerede yapılabildiği.
enum ExerciseLocation { home, gym, both }

/// Sık yapılan bir hata ve düzeltmesi.
///
/// Üç alanın da zorunlu olması bilinçli: "beli çukurlaştırma" demek işe
/// yaramaz. Hatanın neden kötü olduğu bilinmeden düzeltme akılda kalmaz,
/// düzeltme verilmeden uyarı işe yaramaz.
class CommonMistake {
  const CommonMistake({
    required this.mistake,
    required this.why,
    required this.fix,
  });

  factory CommonMistake.fromJson(Map<String, dynamic> json) => CommonMistake(
    mistake: json['mistake'] as String,
    why: json['why'] as String,
    fix: json['fix'] as String,
  );

  /// Ne yanlış yapılıyor.
  final String mistake;

  /// Neden sorun — hangi eklem ya da kas zarar görüyor.
  final String why;

  /// Nasıl düzeltilir.
  final String fix;

  Map<String, dynamic> toJson() => {'mistake': mistake, 'why': why, 'fix': fix};
}

/// Katalogdaki bir hareket.
///
/// Saf veri sınıfı: veritabanını da arayüzü de bilmez (spec 4.1). Hem
/// `assets/catalog.json` tohumundan hem Drift satırından, hem de M4'te
/// AI'ın önerdiği `newExercises` bloğundan aynı şemayla üretilir —
/// şemanın tek tanımı burasıdır.
class Exercise {
  const Exercise({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.category,
    required this.location,
    required this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.difficulty,
    required this.summary,
    required this.setup,
    required this.execution,
    required this.breathing,
    required this.tempo,
    required this.cues,
    required this.commonMistakes,
    required this.safety,
    required this.regressions,
    required this.progressions,
    required this.isUserDefined,
    this.imagePath,
    this.videoQuery,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    nameTr: json['nameTr'] as String,
    nameEn: json['nameEn'] as String,
    category: _enumByName(
      ExerciseCategory.values,
      json['category'] as String,
      'category',
    ),
    location: _enumByName(
      ExerciseLocation.values,
      json['location'] as String,
      'location',
    ),
    equipment: _strings(json['equipment']),
    primaryMuscles: _strings(json['primaryMuscles']),
    secondaryMuscles: _strings(json['secondaryMuscles']),
    difficulty: json['difficulty'] as int,
    summary: json['summary'] as String,
    setup: _strings(json['setup']),
    execution: _strings(json['execution']),
    breathing: json['breathing'] as String,
    tempo: json['tempo'] as String,
    cues: _strings(json['cues']),
    commonMistakes: [
      for (final m in json['commonMistakes'] as List? ?? const [])
        CommonMistake.fromJson(m as Map<String, dynamic>),
    ],
    safety: json['safety'] as String,
    regressions: _strings(json['regressions']),
    progressions: _strings(json['progressions']),
    imagePath: json['imagePath'] as String?,
    videoQuery: json['videoQuery'] as String?,
    isUserDefined: json['isUserDefined'] as bool? ?? false,
  );

  final String id;
  final String nameTr;
  final String nameEn;
  final ExerciseCategory category;
  final ExerciseLocation location;

  /// Boş dizi değil, `['vücut ağırlığı']` yazılır — "ekipman gerekmiyor"
  /// bilgisi de bir bilgidir ve filtrede görünmesi gerekir.
  final List<String> equipment;

  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  /// 1 (en kolay) – 5 (en zor).
  final int difficulty;

  /// Bir-iki cümle: ne işe yarar, neden bu programda.
  final String summary;

  /// Başlangıç pozisyonu, adım adım.
  final List<String> setup;

  /// Hareketin kendisi, numaralandırılacak adımlar.
  final List<String> execution;

  final String breathing;
  final String tempo;

  /// Antrenman sırasında kartta görünen kısa hatırlatmalar. Set arasında
  /// paragraf okunmaz; bunlar bir bakışta okunur.
  final List<String> cues;

  final List<CommonMistake> commonMistakes;
  final String safety;

  /// Kolaylaştırılmış varyantların id'leri.
  final List<String> regressions;

  /// Zorlaştırılmış varyantların id'leri.
  final List<String> progressions;

  final String? imagePath;
  final String? videoQuery;

  /// AI önerisiyle sonradan eklendiyse true (M4).
  final bool isUserDefined;

  bool get hasImage => imagePath != null;

  /// Ekipman gerektirmiyor mu — filtrede "evde yapılabilir" ayrımı için.
  bool get isBodyweight =>
      equipment.isEmpty ||
      // l10n-exempt: katalog verisi, arayüz metni değil. M8'de
      // `EquipmentKind.bodyOnly` karşılaştırmasına dönüyor.
      (equipment.length == 1 && equipment.first == 'vücut ağırlığı');

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameTr': nameTr,
    'nameEn': nameEn,
    'category': category.name,
    'location': location.name,
    'equipment': equipment,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'difficulty': difficulty,
    'summary': summary,
    'setup': setup,
    'execution': execution,
    'breathing': breathing,
    'tempo': tempo,
    'cues': cues,
    'commonMistakes': [for (final m in commonMistakes) m.toJson()],
    'safety': safety,
    'regressions': regressions,
    'progressions': progressions,
    if (imagePath != null) 'imagePath': imagePath,
    if (videoQuery != null) 'videoQuery': videoQuery,
    'isUserDefined': isUserDefined,
  };

  static List<String> _strings(Object? value) =>
      (value as List? ?? const []).cast<String>();

  /// `values.byName` bilinmeyen ad için `ArgumentError` atar ama mesajı
  /// hangi alanın hatalı olduğunu söylemez. M4'te bu hata AI'a geri
  /// yapıştırılacağı için alan adı mesajda geçmeli.
  static T _enumByName<T extends Enum>(
    List<T> values,
    String name,
    String field,
  ) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw ArgumentError.value(
      name,
      field,
      // l10n-exempt: geliştiriciye giden `ArgumentError` metni.
      'geçersiz değer; beklenen: ${values.map((v) => v.name).join(' | ')}',
    );
  }
}
