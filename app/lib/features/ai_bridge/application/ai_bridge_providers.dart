import 'package:disport/app/app.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart';
import 'package:disport/features/ai_bridge/domain/plan_importer.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/application/catalog_source_adapter.dart';
import 'package:disport/features/health/application/health_source_adapter.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/application/plan_source_adapter.dart';
import 'package:disport/features/settings/application/profile_source_adapter.dart';
import 'package:disport/features/settings/data/profile_repository.dart';
import 'package:disport/features/today/application/log_source_adapter.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_bridge_providers.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepository(ref.watch(appDatabaseProvider));

/// Profil alanları; onboarding ve ayarlar bunu dinler.
@riverpod
Stream<Map<String, String>> profileEntries(Ref ref) =>
    ref.watch(profileRepositoryProvider).watchAll();

/// Onboarding tamamlandı mı.
@riverpod
Future<bool> isOnboarded(Ref ref) async {
  final entries = await ref.watch(profileEntriesProvider.future);
  final height = entries['heightCm'];
  return height != null && height.trim().isNotEmpty;
}

/// `context.md` üreteci — dört adaptörü bir araya getirir.
@riverpod
ContextMdBuilder contextMdBuilder(Ref ref) => ContextMdBuilder(
  profile: ProfileSourceAdapter(ref.watch(profileRepositoryProvider)),
  logs: LogSourceAdapter(
    today: ref.watch(todayRepositoryProvider),
    plan: ref.watch(planRepositoryProvider),
    workout: ref.watch(workoutRepositoryProvider),
    now: DateTime.now,
  ),
  health: HealthSourceAdapter(ref.watch(bodyMetricsRepositoryProvider)),
  catalog: CatalogSourceAdapter(ref.watch(catalogRepositoryProvider)),
  plan: PlanSourceAdapter(ref.watch(planRepositoryProvider)),
);

/// Doğrulayıcı; katalogdaki güncel hareketlerle kurulur.
@riverpod
Future<PlanValidator> planValidator(Ref ref) async {
  final entries = await CatalogSourceAdapter(
    ref.watch(catalogRepositoryProvider),
  ).catalogEntries();

  return PlanValidator(catalog: entries);
}

/// Importer; kayıt kapıları depo yöntemlerine bağlanır.
@riverpod
PlanImporter planImporter(Ref ref) => PlanImporter(
  insertPlan: ref.watch(planRepositoryProvider).insertFullPlan,
  addExercise: ref.watch(catalogRepositoryProvider).upsertUserDefined,
);
