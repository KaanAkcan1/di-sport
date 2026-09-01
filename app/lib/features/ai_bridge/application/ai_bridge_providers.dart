import 'package:disport/app/app.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart';
import 'package:disport/features/ai_bridge/domain/plan_importer.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/application/catalog_source_adapter.dart';
import 'package:disport/features/catalog/application/environment_source_adapter.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/data/favorite_sports_repository.dart';
import 'package:disport/features/health/application/health_providers.dart';
import 'package:disport/features/health/application/health_source_adapter.dart';
import 'package:disport/features/medical/application/medical_source_adapter.dart';
import 'package:disport/features/medical/data/medical_repository.dart';
import 'package:disport/features/nutrition/application/nutrition_source_adapter.dart';
import 'package:disport/features/nutrition/data/activities_repository.dart';
import 'package:disport/features/nutrition/data/nutrition_repository.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/application/plan_source_adapter.dart';
import 'package:disport/features/settings/application/availability_source_adapter.dart';
import 'package:disport/features/settings/application/profile_source_adapter.dart';
import 'package:disport/features/settings/application/routine_source_adapter.dart';
import 'package:disport/features/settings/data/meal_behaviors_repository.dart';
import 'package:disport/features/settings/data/profile_repository.dart';
import 'package:disport/features/settings/data/weekly_windows_repository.dart';
import 'package:disport/features/supplements/application/medication_source_adapter.dart';
import 'package:disport/features/supplements/data/supplements_repository.dart';
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
  health: HealthSourceAdapter(
    metrics: ref.watch(bodyMetricsRepositoryProvider),
    labs: ref.watch(labRepositoryProvider),
  ),
  catalog: CatalogSourceAdapter(ref.watch(catalogRepositoryProvider)),
  plan: PlanSourceAdapter(ref.watch(planRepositoryProvider)),
  availability: AvailabilitySourceAdapter(
    WeeklyWindowsRepository(ref.watch(appDatabaseProvider)),
  ),
  // v3 (§9.3) kaynakları — her biri kendi feature'ının adaptörü.
  medical: MedicalSourceAdapter(MedicalRepository(ref.watch(appDatabaseProvider))),
  medications: MedicationSourceAdapter(
    SupplementsRepository(ref.watch(appDatabaseProvider)),
  ),
  environment: EnvironmentSourceAdapter(
    EquipmentRepository(ref.watch(appDatabaseProvider)),
    FavoriteSportsRepository(ref.watch(appDatabaseProvider)),
    ActivitiesRepository(ref.watch(appDatabaseProvider)),
  ),
  routine: RoutineSourceAdapter(
    MealBehaviorsRepository(ref.watch(appDatabaseProvider)),
  ),
  nutrition: NutritionSourceAdapter(
    NutritionRepository(ref.watch(appDatabaseProvider)),
    ref.watch(todayRepositoryProvider),
    SupplementsRepository(ref.watch(appDatabaseProvider)),
  ),
  rules: PlanSourceAdapter(ref.watch(planRepositoryProvider)),
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

/// Kapatılan bölümlerin profil anahtarı (v3 §9.3 — gönderilecekler).
///
/// Varsayılan hepsi açık; anahtar yalnız kapatılınca yazılır. Kapalı
/// bölüm belgeye hiç girmez.
String contextSectionOffKey(ContextSection section) =>
    'ctx.off.${section.name}';

/// Belgeye girecek bölümler — akış: ayar değişince belge de değişir.
@riverpod
Future<Set<ContextSection>> contextSections(Ref ref) async {
  final entries = await ref.watch(profileEntriesProvider.future);
  return {
    for (final section in ContextSection.values)
      if (entries[contextSectionOffKey(section)] != '1') section,
  };
}
