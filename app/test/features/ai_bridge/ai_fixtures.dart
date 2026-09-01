import 'dart:convert';

import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/domain/exercise.dart';

/// Doğrulama testlerinde kullanılan katalog kümesi.
PlanValidator fixtureValidator() => PlanValidator(
  catalog: {
    'incline_pushup': (
      location: ExerciseLocation.home,
      nameTr: 'Eğimli Şınav',
    ),
    'chair_squat': (
      location: ExerciseLocation.home,
      nameTr: 'Sandalyeye Squat',
    ),
    'plank': (location: ExerciseLocation.both, nameTr: 'Plank'),
    'stationary_bike': (
      location: ExerciseLocation.gym,
      nameTr: 'Kondisyon Bisikleti',
    ),
    'treadmill_incline_walk': (
      location: ExerciseLocation.gym,
      nameTr: 'Eğimli Bantta Yürüyüş',
    ),
  },
);

/// Geçerli bir haftalık plan belgesi.
///
/// 31 Ağustos 2026 Pazartesi'den başlar; Pzt salon, kalanı ev, son gün
/// dinlenme.
Map<String, dynamic> validPlanMap() => {
  'schemaVersion': 1,
  'meta': {'title': 'Eylül Planı', 'startDate': '2026-08-31', 'weeks': 1},
  // Açık tip: değerlerin hepsi int olduğu için Dart aksi halde
  // `Map<String, int>` çıkarsıyor ve testler ondalık değer atayamıyor.
  'goals': <String, dynamic>{
    'dailyKcal': 2400,
    'proteinG': 170,
    'waterL': 3,
    'weeklyGym': 3,
    'weeklyHome': 4,
    'targetLossKg': 1,
  },
  'rules': <String, dynamic>{
    'forbidden': ['Alkol'],
    'free': ['Su'],
  },
  'days': [
    for (var index = 0; index < 7; index++) _day(index),
  ],
  'newExercises': <Object>[],
};

Map<String, dynamic> _day(int index) {
  final date = DateTime(2026, 8, 31).add(Duration(days: index));
  final iso =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  final isRest = index == 6;
  final isGym = index == 0;

  return {
    'date': iso,
    'type': isRest
        ? 'rest'
        : isGym
        ? 'gym'
        : 'home',
    'weekIndex': 1,
    'headline': 'Tempoyu bul.',
    'dinnerSuggestion': 'Izgara tavuk + salata',
    'slots': [
      {'time': '06:30', 'kind': 'meal', 'label': 'Kahvaltı'},
      if (!isRest)
        {'time': '22:00', 'kind': 'workout', 'label': 'Antrenman'},
    ],
    'exercises': [
      if (isGym)
        {
          'exerciseId': 'stationary_bike',
          'sets': 1,
          'durationSec': 1500,
          'intensity': 'direnç 5',
        }
      else if (!isRest)
        {
          'exerciseId': 'incline_pushup',
          'sets': 3,
          'reps': 10,
          'restSec': 60,
        },
    ],
  };
}

String validPlanJson() => jsonEncode(validPlanMap());

/// Çıtayı geçen bir `newExercises` kaydı.
Map<String, dynamic> validNewExercise({String id = 'custom_burpee'}) => {
  'id': id,
  'nameTr': 'Burpee',
  'nameEn': 'Burpee',
  'category': 'strength',
  'location': 'home',
  'equipment': ['bodyOnly'],
  'primaryMuscles': ['tüm vücut'],
  'secondaryMuscles': <String>[],
  'difficulty': 4,
  'summary': 'Tüm vücut hareketi.',
  'setup': ['Ayakta dur.'],
  'execution': ['Çömel.', 'Plank pozisyonuna geç.', 'Ayağa kalk.'],
  'breathing': 'İnerken al, kalkarken ver.',
  'tempo': 'Akıcı',
  'cues': ['Karın sıkı'],
  'commonMistakes': [
    {'mistake': 'Bel çöküyor', 'why': 'Karın gevşiyor.', 'fix': 'Karnı sık.'},
    {'mistake': 'Hızlı iniş', 'why': 'Diz zorlanır.', 'fix': 'Kontrollü in.'},
  ],
  'safety': 'Diz ağrısında yapma.',
  'regressions': <String>[],
  'progressions': <String>[],
};
