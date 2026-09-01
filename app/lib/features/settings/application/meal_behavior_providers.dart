import 'package:disport/app/app.dart';
import 'package:disport/features/settings/data/meal_behaviors_repository.dart';
import 'package:disport/features/settings/domain/meal_behavior.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_behavior_providers.g.dart';

@riverpod
MealBehaviorsRepository mealBehaviorsRepository(Ref ref) =>
    MealBehaviorsRepository(ref.watch(appDatabaseProvider));

/// Öğün davranışları — Günlük Düzen yazar; alarm penceresi, Diyet ve
/// AI belgesi okur.
@riverpod
Stream<List<MealBehaviorEntry>> mealBehaviors(Ref ref) =>
    ref.watch(mealBehaviorsRepositoryProvider).watchAll();
