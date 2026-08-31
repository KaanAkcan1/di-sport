import 'package:disport/app/app.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_providers.g.dart';

@riverpod
PlanRepository planRepository(Ref ref) =>
    PlanRepository(ref.watch(appDatabaseProvider));

/// Etkin plan. Plan yoksa null.
@riverpod
Future<FullPlan?> activePlan(Ref ref) =>
    ref.watch(planRepositoryProvider).activePlan();
