import 'package:disport/features/catalog/domain/equipment_kind.dart';

/// MET'in nasıl hesaplanacağı (spec §4.4).
///
/// Kardiyoda tek bir MET değeri yetmiyor: koşu bandında 5 km/h düz
/// yürüyüş ~4 MET, 8 km/h %8 eğimde ~11 MET — aynı harekete tek sayı
/// vermek üç kat hata demek.
enum MetModel {
  /// Sabit değer — kuvvet ve gövde hareketleri.
  fixed,

  /// ACSM denklemi, hız + eğim girdisiyle.
  treadmill,

  /// Direnç kademesi → MET tablosu. ACSM'in bisiklet denklemi watt
  /// istiyor ve ev/salon bisikletlerindeki kademe watt'a güvenilir
  /// şekilde çevrilemiyor.
  cycling,
}

/// Kardiyo ve kuvvette şiddet kademesi.
///
/// Burada tanımlı çünkü MET modeliyle birlikte kullanılıyor; M9'un
/// enerji hesabı ve M10'un plan editörü ikisini de buradan alıyor —
/// çifte tanım riski böyle kapanıyor.
enum Effort { light, moderate, vigorous }

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
    required this.nameEn,
    required this.category,
    required this.location,
    required this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.difficulty,
    required this.execution,
    required this.isUserDefined,
    this.nameTr,
    this.summary,
    this.setup = const [],
    this.breathing,
    this.tempo,
    this.cues = const [],
    this.commonMistakes = const [],
    this.safety,
    this.regressions = const [],
    this.progressions = const [],
    this.met,
    this.metModel = MetModel.fixed,
    this.imagePath,
    this.videoQuery,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    nameTr: json['nameTr'] as String?,
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
    equipment: [
      for (final raw in _strings(json['equipment']))
        EquipmentKind.fromName(raw),
    ],
    primaryMuscles: _strings(json['primaryMuscles']),
    secondaryMuscles: _strings(json['secondaryMuscles']),
    difficulty: json['difficulty'] as int,
    summary: json['summary'] as String?,
    setup: _strings(json['setup']),
    execution: _strings(json['execution']),
    breathing: json['breathing'] as String?,
    tempo: json['tempo'] as String?,
    cues: _strings(json['cues']),
    commonMistakes: [
      for (final m in json['commonMistakes'] as List? ?? const [])
        CommonMistake.fromJson(m as Map<String, dynamic>),
    ],
    safety: json['safety'] as String?,
    regressions: _strings(json['regressions']),
    progressions: _strings(json['progressions']),
    met: (json['met'] as num?)?.toDouble(),
    metModel: json['metModel'] == null
        ? MetModel.fixed
        : _enumByName(MetModel.values, json['metModel'] as String, 'metModel'),
    imagePath: json['imagePath'] as String?,
    videoQuery: json['videoQuery'] as String?,
    isUserDefined: json['isUserDefined'] as bool? ?? false,
  );

  final String id;

  /// Türkçe ad — **boş olabilir**.
  ///
  /// Katalog ~120 harekete çıkarken kaynakta yalnız İngilizce ad var;
  /// çevrilebilenler çevrildi, özel ad taşıyanlar boş bırakıldı.
  /// Uydurma bir Türkçe ad hem aramayı hem internette aratmayı
  /// zorlaştırırdı (spec §4.1, §4.3).
  final String? nameTr;

  final String nameEn;
  final ExerciseCategory category;
  final ExerciseLocation location;

  /// Gereken ekipman — tipli.
  ///
  /// Boş dizi değil `[EquipmentKind.none]` yazılır: "ekipman
  /// gerekmiyor" bilgisi de bir bilgidir ve rozette görünmesi gerekir.
  final List<EquipmentKind> equipment;

  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  /// 1 (en kolay) – 5 (en zor).
  final int difficulty;

  /// Bir-iki cümle: ne işe yarar, neden bu programda.
  ///
  /// Zenginlik alanları (`summary`, `setup`, `breathing`, `tempo`,
  /// `cues`, `safety`) **boş olabilir**: kaynakta yoklar ve araştırmayla
  /// bulunamadıysa uydurulmuyor. Boş alan ekranda hiç çizilmiyor
  /// (spec §4.3). Çekirdek listede zorunlular —
  /// `catalog_seed_test.dart` orayı denetliyor.
  final String? summary;

  /// Başlangıç pozisyonu, adım adım.
  final List<String> setup;

  /// Hareketin kendisi, numaralandırılacak adımlar.
  final List<String> execution;

  final String? breathing;
  final String? tempo;

  /// Antrenman sırasında kartta görünen kısa hatırlatmalar. Set arasında
  /// paragraf okunmaz; bunlar bir bakışta okunur.
  final List<String> cues;

  final List<CommonMistake> commonMistakes;
  final String? safety;

  /// Kolaylaştırılmış varyantların id'leri.
  final List<String> regressions;

  /// Zorlaştırılmış varyantların id'leri.
  final List<String> progressions;

  /// Metabolik eşdeğer — enerji hesabının temeli (spec §4.4).
  ///
  /// `null` ise bu hareket için kalori tahmini üretilmiyor; uydurma bir
  /// sayı olmayan bir hassasiyet iddia etmek olurdu.
  final double? met;

  final MetModel metModel;

  final String? imagePath;
  final String? videoQuery;

  /// AI önerisiyle sonradan eklendiyse true (M4).
  final bool isUserDefined;

  bool get hasImage => imagePath != null;

  /// Ekipman gerektirmiyor mu.
  bool get isBodyweight => equipment.every((kind) => !kind.needsInventory);

  /// Gösterim ve arama için Türkçe ad — yoksa İngilizcesi.
  String get displayNameTr => nameTr ?? nameEn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameTr': nameTr,
    'nameEn': nameEn,
    'category': category.name,
    'location': location.name,
    'equipment': [for (final kind in equipment) kind.name],
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'difficulty': difficulty,
    'summary': summary,
    'setup': setup,
    'execution': execution,
    'breathing': breathing,
    'tempo': tempo,
    'met': met,
    'metModel': metModel.name,
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
