import 'dart:convert';

import 'package:disport/features/catalog/domain/exercise.dart';

/// Testlerde kullanılan hareket üreteci.
///
/// Gerçek `assets/catalog.json` yerine bunu kullanmak testleri içerik
/// değişikliklerinden bağımsız tutar: katalogdan bir hareket çıkarılınca
/// repository ya da ekran testleri kırılmamalı. İçeriğin kendisi
/// `test/assets/catalog_seed_test.dart` içinde ayrıca doğrulanıyor.
Map<String, dynamic> fixtureJson({
  required String id,
  required String nameTr,
  required String nameEn,
  List<String> muscles = const ['göğüs'],
  List<String> equipment = const ['vücut ağırlığı'],
  int difficulty = 2,
  String category = 'strength',
  String location = 'home',
  String? imagePath,
  List<String> regressions = const [],
  List<String> progressions = const [],
  bool isUserDefined = false,
}) => {
  'id': id,
  'nameTr': nameTr,
  'nameEn': nameEn,
  'category': category,
  'location': location,
  'equipment': equipment,
  'primaryMuscles': muscles,
  'secondaryMuscles': <String>[],
  'difficulty': difficulty,
  'summary': '$nameTr için kısa özet.',
  'setup': ['Başlangıç pozisyonunu al.'],
  'execution': ['Birinci adım.', 'İkinci adım.', 'Üçüncü adım.'],
  'breathing': 'İnerken al, çıkarken ver.',
  'tempo': '2 sn iniş · 1 sn çıkış',
  'cues': ['Karın sıkı'],
  'commonMistakes': [
    {'mistake': 'Kalça düşüyor', 'why': 'Bel yüklenir.', 'fix': 'Karnı sık.'},
    {'mistake': 'Yarım iniyor', 'why': 'Kas tam çalışmaz.', 'fix': 'Tam in.'},
  ],
  'safety': 'Ağrı hissedersen dur.',
  'regressions': regressions,
  'progressions': progressions,
  'imagePath': ?imagePath,
  'isUserDefined': isUserDefined,
};

Exercise fixtureExercise({
  required String id,
  required String nameTr,
  required String nameEn,
  List<String> muscles = const ['göğüs'],
  List<String> equipment = const ['vücut ağırlığı'],
  int difficulty = 2,
  ExerciseCategory category = ExerciseCategory.strength,
  ExerciseLocation location = ExerciseLocation.home,
  String? imagePath,
  List<String> regressions = const [],
  List<String> progressions = const [],
  bool isUserDefined = false,
}) => Exercise.fromJson(
  fixtureJson(
    id: id,
    nameTr: nameTr,
    nameEn: nameEn,
    muscles: muscles,
    equipment: equipment,
    difficulty: difficulty,
    category: category.name,
    location: location.name,
    imagePath: imagePath,
    regressions: regressions,
    progressions: progressions,
    isUserDefined: isUserDefined,
  ),
);

/// Repository testleri için dört hareketlik tohum belgesi.
String fixtureSeedJson() => jsonEncode({
  'version': 1,
  'exercises': [
    fixtureJson(
      id: 'incline_pushup',
      nameTr: 'Eğimli Şınav',
      nameEn: 'Incline Push-Up',
      muscles: ['göğüs'],
    ),
    fixtureJson(
      id: 'chair_squat',
      nameTr: 'Sandalyeye Squat',
      nameEn: 'Chair Squat',
      muscles: ['bacak'],
      equipment: ['sandalye'],
      difficulty: 1,
    ),
    fixtureJson(
      id: 'stationary_bike',
      nameTr: 'Kondisyon Bisikleti',
      nameEn: 'Stationary Bike',
      muscles: ['bacak'],
      equipment: ['kondisyon bisikleti'],
      difficulty: 1,
      category: 'cardio',
      location: 'gym',
    ),
    fixtureJson(
      id: 'plank',
      nameTr: 'Plank',
      nameEn: 'Plank',
      muscles: ['karın'],
      category: 'core',
      location: 'both',
    ),
  ],
});
