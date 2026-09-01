import 'package:disport/features/ai_bridge/domain/json_reader.dart';

/// AI'ın döndürdüğü plan belgesi (spec 7.2).
///
/// Yalnızca taşıma katmanı: alan adları AI sözleşmesindeki adlar, tipler
/// ham. Anlam denetimi [PlanValidator]'da, domain'e çeviri
/// [PlanImporter]'da yapılır. Üçünü ayırmak, hata mesajlarının hangi
/// aşamadan geldiğini belirsizleştirmiyor.
class PlanJson {
  const PlanJson({
    required this.schemaVersion,
    required this.meta,
    required this.goals,
    required this.rules,
    required this.days,
    this.newExercises = const [],
  });

  factory PlanJson.parse(JsonReader reader) => PlanJson(
    schemaVersion: reader['schemaVersion'].asInt,
    meta: PlanMetaJson.parse(reader['meta']),
    goals: PlanGoalsJson.parse(reader['goals']),
    rules: PlanRulesJson.parse(reader['rules']),
    days: [for (final day in reader['days'].asList) PlanDayJson.parse(day)],
    newExercises: [
      for (final item in reader['newExercises'].listOrEmpty())
        NewExerciseJson(data: item.asMap, path: item.path),
    ],
  );

  final int schemaVersion;
  final PlanMetaJson meta;
  final PlanGoalsJson goals;
  final PlanRulesJson rules;
  final List<PlanDayJson> days;
  final List<NewExerciseJson> newExercises;
}

class PlanMetaJson {
  const PlanMetaJson({
    required this.title,
    required this.startDate,
    required this.weeks,
  });

  factory PlanMetaJson.parse(JsonReader reader) => PlanMetaJson(
    title: reader['title'].asString,
    startDate: reader['startDate'].asString,
    weeks: reader['weeks'].asInt,
  );

  final String title;
  final String startDate;
  final int weeks;
}

class PlanGoalsJson {
  const PlanGoalsJson({
    required this.dailyKcal,
    required this.proteinG,
    required this.waterL,
    required this.weeklyGym,
    required this.weeklyHome,
    required this.targetLossKg,
  });

  factory PlanGoalsJson.parse(JsonReader reader) => PlanGoalsJson(
    dailyKcal: reader['dailyKcal'].asInt,
    proteinG: reader['proteinG'].asInt,
    waterL: reader['waterL'].asDouble,
    weeklyGym: reader['weeklyGym'].asInt,
    weeklyHome: reader['weeklyHome'].asInt,
    targetLossKg: reader['targetLossKg'].asDouble,
  );

  final int dailyKcal;
  final int proteinG;
  final double waterL;
  final int weeklyGym;
  final int weeklyHome;
  final double targetLossKg;
}

class PlanRulesJson {
  const PlanRulesJson({required this.forbidden, required this.free});

  factory PlanRulesJson.parse(JsonReader reader) => PlanRulesJson(
    forbidden: reader['forbidden'].stringListOrEmpty(),
    free: reader['free'].stringListOrEmpty(),
  );

  final List<String> forbidden;
  final List<String> free;
}

class PlanDayJson {
  const PlanDayJson({
    required this.date,
    required this.type,
    required this.weekIndex,
    required this.path,
    this.headline = '',
    this.dinnerSuggestion = '',
    this.slots = const [],
    this.exercises = const [],
  });

  factory PlanDayJson.parse(JsonReader reader) => PlanDayJson(
    date: reader['date'].asString,
    type: reader['type'].enumValue(const {'gym', 'home', 'rest'}),
    weekIndex: reader['weekIndex'].asInt,
    headline: reader['headline'].stringOr(''),
    dinnerSuggestion: reader['dinnerSuggestion'].stringOr(''),
    slots: [
      for (final slot in reader['slots'].listOrEmpty()) PlanSlotJson.parse(slot),
    ],
    exercises: [
      for (final exercise in reader['exercises'].listOrEmpty())
        PlanExerciseJson.parse(exercise),
    ],
    path: reader.path,
  );

  final String date;
  final String type;
  final int weekIndex;
  final String headline;
  final String dinnerSuggestion;
  final List<PlanSlotJson> slots;
  final List<PlanExerciseJson> exercises;

  /// Belgedeki konumu — anlam hataları bu yolla bildiriliyor.
  final String path;
}

class PlanSlotJson {
  const PlanSlotJson({
    required this.time,
    required this.kind,
    required this.label,
    required this.path,
    this.mealKind,
    this.items = const [],
    this.note,
  });

  factory PlanSlotJson.parse(JsonReader reader) => PlanSlotJson(
    time: reader['time'].asString,
    kind: reader['kind'].enumValue(const {
      'meal',
      'workout',
      'sleep',
      'measurement',
      'lab',
      'other',
    }),
    label: reader['label'].asString,
    // v3: öğün slotu hangi öğün olduğunu ve isteğe bağlı besin
    // kalemlerini söyleyebilir (§5.0). İkisi de isteğe bağlı — eski
    // sözleşmeyle üretilmiş plan aynen çalışır.
    mealKind: reader['mealKind'].asStringOrNull == null
        ? null
        : reader['mealKind'].enumValue(const {
            'kahvalti',
            'araOgun',
            'ogle',
            'ikindi',
            'aksam',
            'gece',
          }),
    items: [
      for (final item in reader['items'].listOrEmpty())
        PlanMealItemJson.parse(item),
    ],
    note: reader['note'].asStringOrNull,
    path: reader.path,
  );

  final String time;
  final String kind;
  final String label;
  final String? mealKind;
  final List<PlanMealItemJson> items;
  final String? note;
  final String path;
}

/// Öğün slotunun bir besin kalemi (v3 §5.0).
class PlanMealItemJson {
  const PlanMealItemJson({
    required this.foodId,
    required this.path,
    this.quantity = 1,
    this.portionId,
  });

  factory PlanMealItemJson.parse(JsonReader reader) => PlanMealItemJson(
    foodId: reader['foodId'].asString,
    quantity: reader['quantity'].exists ? reader['quantity'].asDouble : 1,
    portionId: reader['portionId'].asStringOrNull,
    path: reader.path,
  );

  final String foodId;
  final double quantity;
  final String? portionId;
  final String path;
}

class PlanExerciseJson {
  const PlanExerciseJson({
    required this.exerciseId,
    required this.path,
    this.sets,
    this.reps,
    this.durationSec,
    this.restSec,
    this.intensity,
    this.note,
  });

  factory PlanExerciseJson.parse(JsonReader reader) => PlanExerciseJson(
    exerciseId: reader['exerciseId'].asString,
    sets: reader['sets'].asIntOrNull,
    reps: reader['reps'].asIntOrNull,
    durationSec: reader['durationSec'].asIntOrNull,
    restSec: reader['restSec'].asIntOrNull,
    intensity: reader['intensity'].asStringOrNull,
    note: reader['note'].asStringOrNull,
    path: reader.path,
  );

  final String exerciseId;
  final int? sets;
  final int? reps;
  final int? durationSec;
  final int? restSec;
  final String? intensity;
  final String? note;
  final String path;
}

/// AI'ın önerdiği yeni hareket.
///
/// Ham `Map` olarak taşınıyor: katalogdaki [Exercise.fromJson] zaten bu
/// şemayı çözüyor, ikinci bir tanım yazmak süreklilik hatası üretirdi.
/// Çıta denetimi [PlanValidator]'da yapılıyor.
class NewExerciseJson {
  const NewExerciseJson({required this.data, required this.path});

  final Map<String, dynamic> data;
  final String path;

  String get id => data['id'] as String? ?? '(id yok)';

  String get displayName => data['nameTr'] as String? ?? id;
}
