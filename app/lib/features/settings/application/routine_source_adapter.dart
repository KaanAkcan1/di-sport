import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/settings/data/meal_behaviors_repository.dart';

/// Öğün davranışı kaynağı (v3 §9.3/4).
class RoutineSourceAdapter implements RoutineSource {
  const RoutineSourceAdapter(this._repository);

  final MealBehaviorsRepository _repository;

  @override
  Future<List<MealBehaviorDump>> mealBehaviors() async {
    final entries = await _repository.watchAll().first;
    return [
      for (final entry in entries)
        MealBehaviorDump(
          meal: entry.meal.name,
          behavior: entry.behavior.name,
          time: entry.time,
          fixedNote: entry.fixedNote,
        ),
    ];
  }
}
