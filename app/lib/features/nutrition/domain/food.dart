import 'package:disport/features/plan/domain/meal_kind.dart';

export 'package:disport/features/plan/domain/meal_kind.dart' show MealKind;

/// Besin türü.
///
/// **Veri kararı, arayüz kararı değil:** ekranda sekiz tür kartı öne
/// çıkıyor ama enum daha geniş — USDA kayıtları `etBalik` ve `sutUrunu`
/// olmadan bir yere sığmıyor, hepsini `diger`'e atmak arama dışındaki
/// tek gezinme yolunu kullanılamaz hâle getirirdi.
enum FoodCategory {
  yemek,
  corba,
  kahvaltilik,
  meyve,
  sebze,
  kuruyemis,
  icecek,
  tahil,
  etBalik,
  sutUrunu,
  atistirmalik,
  diger;

  static FoodCategory fromName(String name) => FoodCategory.values.firstWhere(
    (category) => category.name == name,
    orElse: () => throw ArgumentError.value(
      name,
      'category',
      // l10n-exempt: geliştiriciye giden hata metni.
      'bilinmeyen besin türü; beklenen: '
          '${FoodCategory.values.map((c) => c.name).join(' | ')}',
    ),
  );
}

/// Değerin nereden geldiği.
///
/// Kullanıcıya gösterilmiyor ama tohumlama için şart: yeniden
/// tohumlarken kullanıcının kendi girdiği besinlere dokunulmamalı.
enum FoodSource {
  /// Elle derlenmiş — Türk ev yemekleri, kahvaltılıklar.
  curated,

  /// USDA SR Legacy'den dönüştürülmüş ham besin.
  usda,

  /// Kullanıcının kendi eklediği.
  user;

  static FoodSource fromName(String name) => FoodSource.values.firstWhere(
    (source) => source.name == name,
    orElse: () => throw ArgumentError.value(
      name,
      'source',
      // l10n-exempt: geliştiriciye giden hata metni.
      'bilinmeyen kaynak; beklenen: '
          '${FoodSource.values.map((s) => s.name).join(' | ')}',
    ),
  );
}

/// Bir ev ölçüsü — "1 kase", "1 dilim".
///
/// **Neden ayrı tip:** kullanıcı gram bilmiyor. "3 porsiyon yedim"
/// diyebilmesi için porsiyonun kaç gram olduğunu uygulamanın bilmesi
/// gerekiyor; gram girişi bir kaçış yolu, ana yol değil.
class FoodPortion {
  const FoodPortion({
    required this.id,
    required this.foodId,
    required this.labelTr,
    required this.labelEn,
    required this.grams,
    this.isDefault = false,
  });

  factory FoodPortion.fromJson(String foodId, Map<String, dynamic> json) =>
      FoodPortion(
        id: json['id'] as String,
        foodId: foodId,
        labelTr: json['labelTr'] as String,
        labelEn: json['labelEn'] as String,
        grams: (json['grams'] as num).toDouble(),
        isDefault: json['isDefault'] as bool? ?? false,
      );

  final String id;
  final String foodId;
  final String labelTr;
  final String labelEn;
  final double grams;

  /// Seçici açıldığında hazır gelen porsiyon.
  final bool isDefault;

  Map<String, dynamic> toJson() => {
    'id': id,
    'labelTr': labelTr,
    'labelEn': labelEn,
    'grams': grams,
    if (isDefault) 'isDefault': true,
  };
}

/// Bir besin ve 100 gramındaki değerleri.
///
/// **Neden 100 gram:** hem USDA hem etiketler bu birimi kullanıyor.
/// Porsiyon başına saklasaydık her porsiyon değişikliği bir çarpma
/// hatası riski olurdu; şimdi tek yönde çarpılıyor.
class Food {
  const Food({
    required this.id,
    required this.nameEn,
    required this.category,
    required this.kcal100,
    this.nameTr,
    this.protein100 = 0,
    this.carb100 = 0,
    this.fat100 = 0,
    this.source = FoodSource.curated,
    this.sourceRef,
    this.portions = const [],
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

    return Food(
      id: id,
      nameEn: json['nameEn'] as String,
      nameTr: json['nameTr'] as String?,
      category: FoodCategory.fromName(json['category'] as String),
      kcal100: (json['kcal100'] as num).toDouble(),
      protein100: (json['protein100'] as num?)?.toDouble() ?? 0,
      carb100: (json['carb100'] as num?)?.toDouble() ?? 0,
      fat100: (json['fat100'] as num?)?.toDouble() ?? 0,
      source: FoodSource.fromName(json['source'] as String? ?? 'curated'),
      sourceRef: json['sourceRef'] as String?,
      portions: [
        for (final raw in (json['portions'] as List? ?? const []))
          FoodPortion.fromJson(id, raw as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String nameEn;

  /// Türkçe adı olmayabilir: USDA'da karşılığı bulunmayan bir kayıt
  /// için ad uydurmak, kullanıcının markette arayamayacağı bir sözcük
  /// üretmek olurdu (kataloğun `nameTr` kuralıyla aynı — spec §4.1).
  final String? nameTr;

  final FoodCategory category;
  final double kcal100;
  final double protein100;
  final double carb100;
  final double fat100;
  final FoodSource source;

  /// Değerin dayandığı kaynak — USDA'da NDB numarası, küratörlüde not.
  final String? sourceRef;

  final List<FoodPortion> portions;

  String get displayNameTr => nameTr ?? nameEn;

  /// Seçici açıldığında hazır gelen porsiyon; yoksa ilk porsiyon,
  /// hiç porsiyon yoksa null (100 gram varsayılır).
  FoodPortion? get defaultPortion {
    for (final portion in portions) {
      if (portion.isDefault) return portion;
    }
    return portions.isEmpty ? null : portions.first;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameEn': nameEn,
    if (nameTr != null) 'nameTr': nameTr,
    'category': category.name,
    'kcal100': kcal100,
    'protein100': protein100,
    'carb100': carb100,
    'fat100': fat100,
    'source': source.name,
    if (sourceRef != null) 'sourceRef': sourceRef,
    if (portions.isNotEmpty)
      'portions': [for (final portion in portions) portion.toJson()],
  };
}

/// Yenen bir kalem.
///
/// **Kalori ve protein kayıt anında donuyor** (`kcalSnapshot`): besin
/// tablosu güncellenince geçmiş öğün değişmemeli. Kullanıcı dün 600
/// kcal yediğini gördüyse, bugün tabloyu düzelttiğimizde dünkü sayı
/// oynarsa geçmişe güveni biter.
class MealEntry {
  const MealEntry({
    required this.id,
    required this.date,
    required this.mealKind,
    required this.foodId,
    required this.quantity,
    required this.grams,
    required this.kcal,
    required this.protein,
    this.slotId,
    this.portionId,
    this.foodName,
  });

  final String id;

  /// `yyyy-MM-dd`.
  final String date;

  final MealKind mealKind;

  /// Plan slotu — plansız kayıt serbest (spec §5.2), o zaman null.
  final String? slotId;

  final String foodId;

  /// Kaç porsiyon. "3 porsiyon yedim" burada 3.
  final double quantity;

  final String? portionId;
  final double grams;
  final double kcal;
  final double protein;

  /// Listede göstermek için besin adı — sorguda birleştirilir, tabloda
  /// tutulmaz. Besin silinse bile kalem listede kalmalı ama adı
  /// çoğaltmak iki doğruluk kaynağı yaratırdı.
  final String? foodName;
}
