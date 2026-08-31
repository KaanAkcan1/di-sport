import 'package:disport/app/app.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_providers.g.dart';

@riverpod
CatalogRepository catalogRepository(Ref ref) =>
    CatalogRepository(ref.watch(appDatabaseProvider));

/// Katalog listesinin arama ve filtre durumu.
class CatalogFilterState {
  const CatalogFilterState({this.query = '', this.location, this.category});

  final String query;
  final ExerciseLocation? location;
  final ExerciseCategory? category;

  bool get isActive =>
      query.isNotEmpty || location != null || category != null;

  CatalogFilterState copyWith({
    String? query,
    ExerciseLocation? location,
    ExerciseCategory? category,
    bool clearLocation = false,
    bool clearCategory = false,
  }) => CatalogFilterState(
    query: query ?? this.query,
    location: clearLocation ? null : (location ?? this.location),
    category: clearCategory ? null : (category ?? this.category),
  );
}

@riverpod
class CatalogFilter extends _$CatalogFilter {
  @override
  CatalogFilterState build() => const CatalogFilterState();

  void setQuery(String value) => state = state.copyWith(query: value);

  /// Aynı seçeneğe tekrar dokunmak filtreyi kaldırır — kullanıcı
  /// seçimini geri almak için ayrı bir "temizle" düğmesi aramasın.
  void toggleLocation(ExerciseLocation value) => state = state.location == value
      ? state.copyWith(clearLocation: true)
      : state.copyWith(location: value);

  void toggleCategory(ExerciseCategory value) => state =
      state.category == value
      ? state.copyWith(clearCategory: true)
      : state.copyWith(category: value);

  void clear() => state = const CatalogFilterState();
}

@riverpod
Stream<List<Exercise>> filteredExercises(Ref ref) {
  final filter = ref.watch(catalogFilterProvider);
  return ref
      .watch(catalogRepositoryProvider)
      .watchFiltered(
        query: filter.query,
        location: filter.location,
        category: filter.category,
      );
}

/// Tek bir hareket — detay sayfası için.
@riverpod
Future<Exercise?> exerciseById(Ref ref, String id) =>
    ref.watch(catalogRepositoryProvider).getById(id);

/// Bir hareketin varyantları (kolay + zor), id → hareket eşlemesi olarak.
///
/// Detay sayfasında `wall_pushup` yerine "Duvar Şınavı" göstermek için.
/// Tek sorguda toplu çözülür; her varyant için ayrı sorgu N+1 olurdu.
///
/// Argüman **liste değil id**: Riverpod aile argümanlarını `==` ile
/// karşılaştırır, Dart listeleri ise kimlikle karşılaştırılır. Liste
/// geçilseydi her `build` yeni bir örnek üretir, Riverpod bunu her
/// seferinde başka bir provider sanır ve sorgu sonsuza dek yeniden
/// başlardı.
@riverpod
Future<Map<String, Exercise>> exerciseVariants(Ref ref, String exerciseId) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final exercise = await repository.getById(exerciseId);
  if (exercise == null) return const {};

  return repository.getByIds([
    ...exercise.regressions,
    ...exercise.progressions,
  ]);
}
