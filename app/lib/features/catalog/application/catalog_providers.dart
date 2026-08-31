import 'package:disport/app/app.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_providers.g.dart';

@riverpod
CatalogRepository catalogRepository(Ref ref) =>
    CatalogRepository(ref.watch(appDatabaseProvider));

/// Katalog listesinin arama ve filtre durumu.
class CatalogFilterState {
  const CatalogFilterState({
    this.query = '',
    this.location,
    this.category,
    this.onlyMyEquipment = false,
  });

  final String query;
  final ExerciseLocation? location;
  final ExerciseCategory? category;

  /// Yalnız envanterdeki ekipmanla yapılabilen hareketler.
  ///
  /// Varsayılan kapalı: katalog bir kütüphane, kullanıcı yapamadığı
  /// hareketi de görüp hedef olarak belirleyebilmeli. Filtre bir
  /// daraltma aracı, gizleme değil.
  final bool onlyMyEquipment;

  bool get isActive =>
      query.isNotEmpty ||
      location != null ||
      category != null ||
      onlyMyEquipment;

  CatalogFilterState copyWith({
    String? query,
    ExerciseLocation? location,
    ExerciseCategory? category,
    bool? onlyMyEquipment,
    bool clearLocation = false,
    bool clearCategory = false,
  }) => CatalogFilterState(
    query: query ?? this.query,
    location: clearLocation ? null : (location ?? this.location),
    category: clearCategory ? null : (category ?? this.category),
    onlyMyEquipment: onlyMyEquipment ?? this.onlyMyEquipment,
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

  void toggleOnlyMyEquipment() =>
      state = state.copyWith(onlyMyEquipment: !state.onlyMyEquipment);

  void clear() => state = const CatalogFilterState();
}

@riverpod
EquipmentRepository equipmentRepository(Ref ref) =>
    EquipmentRepository(ref.watch(appDatabaseProvider));

/// Envanterdeki tüm ekipman.
@riverpod
Stream<List<EquipmentItem>> equipmentInventory(Ref ref) =>
    ref.watch(equipmentRepositoryProvider).watchAll();

/// Kullanıcıda olan ekipmanın kimlikleri.
@riverpod
Stream<Set<String>> ownedEquipmentIds(Ref ref) =>
    ref.watch(equipmentRepositoryProvider).watchOwnedIds();

@riverpod
Stream<List<Exercise>> filteredExercises(Ref ref) {
  final filter = ref.watch(catalogFilterProvider);
  final base = ref
      .watch(catalogRepositoryProvider)
      .watchFiltered(
        query: filter.query,
        location: filter.location,
        category: filter.category,
      );

  if (!filter.onlyMyEquipment) return base;

  // Ekipman süzmesi SQL'de değil Dart'ta: `equipment` bir JSON dizisi
  // ve "listenin tamamı şu kümenin alt kümesi mi" sorusu SQLite'ta
  // okunabilir biçimde yazılamıyor. Katalog birkaç düzine satır,
  // bellekte süzmek ölçülebilir bir maliyet değil.
  final owned = ref.watch(ownedEquipmentIdsProvider).value ?? const <String>{};
  return base.map(
    (list) => [
      for (final exercise in list)
        if (canPerform(equipment: exercise.equipment, ownedIds: owned))
          exercise,
    ],
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
