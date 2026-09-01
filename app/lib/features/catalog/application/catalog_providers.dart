import 'package:disport/app/app.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/domain/recent_exercise_source.dart';
import 'package:disport/features/workout/application/recent_exercise_adapter.dart';
import 'package:disport/features/workout/application/workout_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'catalog_providers.g.dart';

@riverpod
CatalogRepository catalogRepository(Ref ref) =>
    CatalogRepository(ref.watch(appDatabaseProvider));

/// Katalog listesinin arama ve filtre durumu.
///
/// **M12'de değişen:** `location` artık bir filtre değil **bağlam** —
/// ekranın tepesindeki sekme onu taşıyor. Alan burada kalıyor çünkü
/// sorgu yine ona göre süzülüyor; değişen tek şey nasıl seçildiği.
/// Ayrıca `difficulty` eklendi: filtre alt sayfası açılınca zorluk da
/// oradan geliyor.
class CatalogFilterState {
  const CatalogFilterState({
    this.query = '',
    this.location,
    this.category,
    this.difficulty,
    this.onlyMyEquipment = false,
  });

  final String query;
  final ExerciseLocation? location;
  final ExerciseCategory? category;

  /// 1-5. Seçiliyse "bu zorluk ve altı" değil **tam eşleşme**:
  /// kullanıcı "orta seviye hareketler" arıyorsa kolayları da görmek
  /// istemez, arama kutusu zaten geniş tarama için var.
  final int? difficulty;

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
      difficulty != null ||
      onlyMyEquipment;

  /// ⚙ düğmesinin üstündeki rozet sayısı.
  ///
  /// Arama ve yer sayılmıyor: ikisi de ekranda zaten görünür (kutu ve
  /// sekme). Rozet yalnız **gizli** filtreleri sayar, yoksa kullanıcı
  /// "2" görüp alt sayfayı açtığında bir şey bulamaz.
  int get hiddenFilterCount =>
      (category != null ? 1 : 0) +
      (difficulty != null ? 1 : 0) +
      (onlyMyEquipment ? 1 : 0);

  CatalogFilterState copyWith({
    String? query,
    ExerciseLocation? location,
    ExerciseCategory? category,
    int? difficulty,
    bool? onlyMyEquipment,
    bool clearLocation = false,
    bool clearCategory = false,
    bool clearDifficulty = false,
  }) => CatalogFilterState(
    query: query ?? this.query,
    location: clearLocation ? null : (location ?? this.location),
    category: clearCategory ? null : (category ?? this.category),
    difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
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

  void toggleDifficulty(int value) => state = state.difficulty == value
      ? state.copyWith(clearDifficulty: true)
      : state.copyWith(difficulty: value);

  /// Sekmeden gelen yer seçimi — `toggle` değil, doğrudan atama.
  ///
  /// Sekme her zaman bir yer gösteriyor; aynı sekmeye tekrar dokunmak
  /// seçimi kaldırmamalı (çip davranışı sekmede yanlış olurdu).
  void setLocation(ExerciseLocation value) =>
      state = state.copyWith(location: value);

  void toggleOnlyMyEquipment() =>
      state = state.copyWith(onlyMyEquipment: !state.onlyMyEquipment);

  /// Alt sayfadaki filtreleri temizler; arama ve sekme yerinde kalır.
  void clearHidden() => state = state.copyWith(
    clearCategory: true,
    clearDifficulty: true,
    onlyMyEquipment: false,
  );

  void clear() => state = const CatalogFilterState();
}

@riverpod
EquipmentRepository equipmentRepository(Ref ref) =>
    EquipmentRepository(ref.watch(appDatabaseProvider));

/// Envanterdeki tüm ekipman — yönetim ekranı bunu listeliyor.
@riverpod
Stream<List<EquipmentItem>> equipmentItems(Ref ref) =>
    ref.watch(equipmentRepositoryProvider).watchAll();

/// Nerede neye sahip olunduğu — katalog filtresi bunu okuyor.
@riverpod
Stream<EquipmentInventory> equipmentInventory(Ref ref) =>
    ref.watch(equipmentRepositoryProvider).watchInventory();

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
  final inventory =
      ref.watch(equipmentInventoryProvider).value ??
      const EquipmentInventory.empty();

  // Yer sekmeden geliyor; filtre "burada yapabilir miyim" diye soruyor.
  final where = filter.location ?? ExerciseLocation.home;

  return base.map(
    (list) => [
      for (final exercise in list)
        if (canPerform(
          required: exercise.equipment,
          inventory: inventory,
          where: where,
        ))
          exercise,
    ],
  );
}

/// Portun bağlandığı tek nokta.
///
/// `ai_bridge`'in `ai_bridge_providers.dart`'ta yaptığının aynısı:
/// tüketen feature arayüzü tanımlar, üreten feature uygular, bağlama
/// tüketenin `application` katmanında bir satırla yapılır. Katalogun
/// geri kalanı `RecentExerciseSource`'tan başka bir şey görmüyor —
/// antrenman tabloları ona kapalı.
@riverpod
RecentExerciseSource recentExerciseSource(Ref ref) =>
    RecentExerciseAdapter(ref.watch(workoutRepositoryProvider));

/// Katalogun "son yaptıkların" bölümü.
@riverpod
Stream<List<RecentExercise>> recentExercises(Ref ref) =>
    ref.watch(recentExerciseSourceProvider).watchRecent();

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

/// Ada göre arama — plan editörünün hareket seçicisi için.
///
/// `filteredExercises`'tan ayrı çünkü o ekranın filtre **durumunu**
/// okuyor; editör seçicisi katalog ekranının sekmesinden ve
/// envanterinden bağımsız olmalı, kullanıcı plana istediği hareketi
/// koyabilmeli.
@riverpod
Stream<List<Exercise>> catalogSearch(Ref ref, String query) =>
    ref.watch(catalogRepositoryProvider).watchFiltered(query: query);
