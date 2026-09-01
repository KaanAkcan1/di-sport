import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/catalog/domain/exercise.dart';

/// `catalog` feature'ının `ai_bridge`'e verdiği hareket kaynağı.
class CatalogSourceAdapter implements CatalogSource {
  const CatalogSourceAdapter(this._repository);

  final CatalogRepository _repository;

  @override
  Future<List<ExerciseRef>> selectable() async {
    final exercises = await _repository.watchFiltered().first;

    return [
      for (final exercise in exercises)
        ExerciseRef(
          id: exercise.id,
          name: exercise.nameEn,
          location: exercise.location.name,
          equipment: [for (final kind in exercise.equipment) kind.name],
          primaryMuscles: exercise.primaryMuscles,
        ),
    ];
  }

  @override
  Future<List<ExerciseRef>> all() => selectable();

  /// Doğrulayıcının ihtiyaç duyduğu id → (yer, ad) eşlemesi.
  Future<Map<String, ({ExerciseLocation location, String nameTr})>>
  catalogEntries() async {
    final exercises = await _repository.watchFiltered().first;
    return {
      for (final exercise in exercises)
        exercise.id: (location: exercise.location, nameTr: exercise.displayNameTr),
    };
  }
}
