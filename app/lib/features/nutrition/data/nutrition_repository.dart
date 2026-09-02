import 'dart:async';
import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/utils/locale_text.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/domain/meal_math.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Besin ve öğün verisine erişimin tek kapısı.
class NutritionRepository {
  NutritionRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  // --- Tohumlama ---

  Future<int> countFoods() async {
    final count = _db.foods.id.count();
    final query = _db.selectOnly(_db.foods)..addColumns([count]);
    return (await query.getSingle()).read(count)!;
  }

  /// Besin tohumunu yükler, güncellenmişse yeniden uygular.
  ///
  /// Katalogun `seedFromJson`'ıyla aynı mekanizma ve aynı gerekçeler:
  /// sürüm damgası olmadan besin düzeltmeleri mevcut kurulumlara hiç
  /// ulaşmaz; kullanıcının **sildiği** yerleşik geri gelmez; kendi
  /// eklediği (`user`) kayda dokunulmaz.
  Future<void> seedFromJson(
    String jsonString, {
    Future<int> Function()? readVersion,
    Future<void> Function(int version)? writeVersion,
  }) async {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final fileVersion = decoded['version'] as int? ?? 1;
    final applied = await readVersion?.call() ?? 0;

    final isEmpty = await countFoods() == 0;
    if (!isEmpty && fileVersion <= applied) return;

    final items = [
      for (final raw in decoded['foods'] as List)
        Food.fromJson(raw as Map<String, dynamic>),
    ];

    final existing = await _db.select(_db.foods).get();
    final known = {for (final row in existing) row.id};
    final deleted = {
      for (final row in existing)
        if (row.deletedAt != null) row.id,
    };

    await _db.batch((batch) {
      for (final food in items) {
        if (deleted.contains(food.id)) continue;

        if (known.contains(food.id)) {
          batch.replace(_db.foods, _foodRow(food));
        } else {
          batch.insert(_db.foods, _foodRow(food));
        }

        // Porsiyonlar tohumla birlikte tazeleniyor: gram düzeltmesi
        // besin değerinden bağımsız gelebiliyor. Kullanıcının kendi
        // porsiyonu yok (v1'de eklenemiyor), silip yazmak güvenli.
        batch.deleteWhere(_db.foodPortions, (t) => t.foodId.equals(food.id));
        batch.insertAll(_db.foodPortions, [
          for (final portion in food.portions) _portionRow(portion),
        ]);
      }
    });

    await writeVersion?.call(fileVersion);
  }

  // --- Okuma ---

  /// Tüm besinler; arama ve tür süzmesi bellekte yapılıyor.
  ///
  /// **Neden SQL'de değil:** arama iki dilin katlamasını birlikte
  /// deniyor (`matchesAnyLocale`) ve porsiyonlar ayrı tabloda. Besin
  /// tablosu birkaç yüz satır; bellekte süzmek ölçülebilir bir maliyet
  /// değil ve sorguyu okunur tutuyor.
  Stream<List<Food>> watchFoods({String? query, FoodCategory? category}) {
    final foods = (_db.select(_db.foods)..where((t) => t.deletedAt.isNull()))
        .watch();
    final portions = _db.select(_db.foodPortions).watch();

    return foods.combine(portions, (rows, portionRows) {
      final byFood = <String, List<FoodPortion>>{};
      for (final row in portionRows) {
        byFood.putIfAbsent(row.foodId, () => []).add(_toPortion(row));
      }

      final result = [
        for (final row in rows)
          if (category == null || row.category == category.name)
            _toFood(row, byFood[row.id] ?? const []),
      ];

      final needle = query?.trim() ?? '';
      if (needle.isEmpty) {
        result.sort((a, b) => a.displayNameTr.compareTo(b.displayNameTr));
        return result;
      }

      final matched = [
        for (final food in result)
          if (LocaleText.matchesAnyLocale(needle, food.nameEn) ||
              LocaleText.matchesAnyLocale(needle, food.nameTr ?? ''))
            food,
      ];
      matched.sort((a, b) => a.displayNameTr.compareTo(b.displayNameTr));
      return matched;
    });
  }

  Future<Food?> foodById(String id) async {
    // Silinmiş besin dönmüyor: kullanıcı onu listeden kaldırdıysa
    // "sık yediklerin" bölümünde geri belirmesi kafa karıştırırdı.
    final row =
        await (_db.select(_db.foods)
              ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
            .getSingleOrNull();
    if (row == null) return null;

    final portions = await (_db.select(
      _db.foodPortions,
    )..where((t) => t.foodId.equals(id))).get();

    return _toFood(row, [for (final p in portions) _toPortion(p)]);
  }

  /// Bir günün öğün kalemleri, öğün sırasına göre.
  Stream<List<MealEntry>> watchDay(String isoDate) {
    final entries =
        (_db.select(_db.mealEntries)
              ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull()))
            .watch();
    final foods = _db.select(_db.foods).watch();

    return entries.combine(foods, (rows, foodRows) {
      final names = {for (final row in foodRows) row.id: row};
      final result = [
        for (final row in rows) _toEntry(row, names[row.foodId]),
      ];
      result.sort((a, b) {
        final byMeal = a.mealKind.index.compareTo(b.mealKind.index);
        return byMeal != 0 ? byMeal : a.id.compareTo(b.id);
      });
      return result;
    });
  }

  Stream<double> dayKcal(String isoDate) =>
      watchDay(isoDate).map(_sumKcal);

  Stream<double> dayProtein(String isoDate) => watchDay(
    isoDate,
  ).map((entries) => entries.fold(0.0, (sum, e) => sum + e.protein));

  /// Aralıktaki her günün toplamı.
  ///
  /// **Neden tek sorgu:** takvim 28 gün gösteriyor ve her gün için ayrı
  /// akış açmak 28 canlı sorgu demek olurdu. Gün anahtarı olmayan
  /// günler haritada **yok** — sıfır ile "hiç girilmemiş" ayrı şeyler.
  Stream<Map<String, double>> kcalByDayBetween(String fromIso, String toIso) =>
      (_db.select(_db.mealEntries)..where(
            (t) =>
                t.date.isBiggerOrEqualValue(fromIso) &
                t.date.isSmallerOrEqualValue(toIso) &
                t.deletedAt.isNull(),
          ))
          .watch()
          .map((rows) {
            final totals = <String, double>{};
            for (final row in rows) {
              totals[row.date] = (totals[row.date] ?? 0) + row.kcalSnapshot;
            }
            return totals;
          });

  /// Son 30 günde en sık girilen besinler.
  ///
  /// Seçici boş bir arama kutusuyla açılmıyor: kullanıcının yediği şey
  /// büyük ölçüde tekrar ediyor ve bu bölüm çoğu kaydı tek dokunuşa
  /// indiriyor.
  Stream<List<Food>> frequent({int limit = 8, DateTime? now}) {
    final since = _isoDate(
      (now ?? DateTime.now()).subtract(const Duration(days: 30)),
    );

    final entries =
        (_db.select(_db.mealEntries)..where(
              (t) => t.date.isBiggerOrEqualValue(since) & t.deletedAt.isNull(),
            ))
            .watch();

    return entries.asyncMap((rows) async {
      final counts = <String, int>{};
      for (final row in rows) {
        counts[row.foodId] = (counts[row.foodId] ?? 0) + 1;
      }

      final ranked = counts.keys.toList()
        ..sort((a, b) {
          final byCount = counts[b]!.compareTo(counts[a]!);
          // Eşitlikte id'ye göre: sıralamanın çalıştırmadan
          // çalıştırmaya değişmesi listeyi huzursuz gösterirdi.
          return byCount != 0 ? byCount : a.compareTo(b);
        });

      final result = <Food>[];
      for (final id in ranked.take(limit)) {
        final food = await foodById(id);
        if (food != null) result.add(food);
      }
      return result;
    });
  }

  // --- Yazma ---

  /// Bir kalem ekler ve **değerleri dondurur**.
  ///
  /// Kalori ve protein burada hesaplanıp satıra yazılıyor. Besin
  /// tablosu sonradan düzeltilirse geçmiş öğün değişmiyor — dün 600
  /// kcal gördüyse bugün de 600 görmeli.
  Future<String> addEntry({
    required Food food,
    required MealKind mealKind,
    required String isoDate,
    required double quantity,
    String? slotId,
    FoodPortion? portion,
    double? customGrams,
  }) async {
    final values = mealValues(
      food: food,
      quantity: quantity,
      portion: portion,
      customGrams: customGrams,
    );

    final id = _uuid.v4();
    await _db
        .into(_db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            id: id,
            date: isoDate,
            mealKind: mealKind.name,
            foodId: food.id,
            grams: values.grams,
            kcalSnapshot: values.kcal,
            proteinSnapshot: values.protein,
            quantity: Value(quantity),
            slotId: Value(slotId),
            portionId: Value(portion?.id),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return id;
  }

  /// Yumuşak silme: geçmiş toplamlar bozulmasın diye satır duruyor.
  Future<void> removeEntry(String id) =>
      (_db.update(_db.mealEntries)..where((t) => t.id.equals(id))).write(
        MealEntriesCompanion(
          deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  /// Kalem listesini besinlere çözüp snapshot'la yazar (v3 §5.1).
  ///
  /// "Plandaki gibi yedim" ve "Her zamanki" tek dokunuşları bunu
  /// kullanıyor. Snapshot **o anki** besin değerinden — plan yazıldığı
  /// andaki değil; snapshot ilkesi kayıt anına bakar. Bilinmeyen
  /// `foodId` sessizce atlanır ve dönen sayıya girmez: plan eski bir
  /// katalogdan geliyor olabilir, tek bozuk kalem tümünü engellememeli.
  Future<int> addResolvedItems({
    required String isoDate,
    required MealKind mealKind,
    required List<({String foodId, double quantity, String? portionId})>
    items,
    String? slotId,
  }) async {
    var added = 0;
    for (final item in items) {
      final food = await foodById(item.foodId);
      if (food == null) continue;

      FoodPortion? portion;
      for (final candidate in food.portions) {
        if (candidate.id == item.portionId) portion = candidate;
      }

      await addEntry(
        food: food,
        mealKind: mealKind,
        isoDate: isoDate,
        quantity: item.quantity,
        portion: portion,
        slotId: slotId,
      );
      added++;
    }
    return added;
  }

  /// Bir öğünü, o öğünde kayıt bulunan **en son günden** kopyalar.
  ///
  /// "Dünü kopyala" değil: kullanıcı dün kahvaltı girmemiş olabilir ve
  /// boş bir kopya hiçbir işe yaramaz. Şablon tablosu açmak yerine bu
  /// seçildi — kullanıcının kahvaltısı zaten tekrar ediyor ve gerçek
  /// şablon özelliği istenirse sonra eklenir (M9 review notu 10).
  ///
  /// Kopya da **donuk**: snapshot yeniden hesaplanmıyor. Kaynağı
  /// kopyalıyoruz, besini değil.
  Future<int> copyMeal({
    required MealKind mealKind,
    required String toIsoDate,
  }) async {
    final source =
        await (_db.select(_db.mealEntries)
              ..where(
                (t) =>
                    t.mealKind.equals(mealKind.name) &
                    t.date.isSmallerThanValue(toIsoDate) &
                    t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(1))
            .getSingleOrNull();

    if (source == null) return 0;

    final rows =
        await (_db.select(_db.mealEntries)..where(
              (t) =>
                  t.date.equals(source.date) &
                  t.mealKind.equals(mealKind.name) &
                  t.deletedAt.isNull(),
            ))
            .get();

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.batch((batch) {
      batch.insertAll(_db.mealEntries, [
        for (final row in rows)
          MealEntriesCompanion.insert(
            id: _uuid.v4(),
            date: toIsoDate,
            mealKind: row.mealKind,
            foodId: row.foodId,
            grams: row.grams,
            kcalSnapshot: row.kcalSnapshot,
            proteinSnapshot: row.proteinSnapshot,
            quantity: Value(row.quantity),
            slotId: const Value(null),
            portionId: Value(row.portionId),
            updatedAt: now,
          ),
      ]);
    });

    return rows.length;
  }

  // --- Dönüştürücüler ---

  static double _sumKcal(List<MealEntry> entries) =>
      entries.fold(0.0, (sum, entry) => sum + entry.kcal);

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  FoodsCompanion _foodRow(Food food) => FoodsCompanion.insert(
    id: food.id,
    nameEn: food.nameEn,
    nameTr: Value(food.nameTr),
    category: food.category.name,
    kcal100: food.kcal100,
    protein100: Value(food.protein100),
    carb100: Value(food.carb100),
    fat100: Value(food.fat100),
    source: Value(food.source.name),
    sourceRef: Value(food.sourceRef),
    searchText: Value(_searchBlob(food)),
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );

  /// İki dilin katlanmış hâli tek blobda.
  ///
  /// Katalogun `searchText`iyle aynı çözüm: sorgu tarafında iki
  /// katlamayı denemek yerine **yazım** tarafında ikisini de saklamak.
  static String _searchBlob(Food food) {
    final parts = [food.nameEn, if (food.nameTr != null) food.nameTr!];
    return [
      for (final part in parts) ...[
        TurkishText.fold(part),
        part.toLowerCase(),
      ],
    ].join(' ');
  }

  FoodPortionsCompanion _portionRow(FoodPortion portion) =>
      FoodPortionsCompanion.insert(
        id: portion.id,
        foodId: portion.foodId,
        labelTr: portion.labelTr,
        labelEn: portion.labelEn,
        grams: portion.grams,
        isDefault: Value(portion.isDefault),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

  static Food _toFood(FoodRow row, List<FoodPortion> portions) => Food(
    id: row.id,
    nameEn: row.nameEn,
    nameTr: row.nameTr,
    category: FoodCategory.fromName(row.category),
    kcal100: row.kcal100,
    protein100: row.protein100,
    carb100: row.carb100,
    fat100: row.fat100,
    source: FoodSource.fromName(row.source),
    sourceRef: row.sourceRef,
    portions: portions,
  );

  static FoodPortion _toPortion(FoodPortionRow row) => FoodPortion(
    id: row.id,
    foodId: row.foodId,
    labelTr: row.labelTr,
    labelEn: row.labelEn,
    grams: row.grams,
    isDefault: row.isDefault,
  );

  static MealEntry _toEntry(MealEntryRow row, FoodRow? food) => MealEntry(
    id: row.id,
    date: row.date,
    mealKind: MealKind.fromName(row.mealKind),
    slotId: row.slotId,
    foodId: row.foodId,
    quantity: row.quantity,
    portionId: row.portionId,
    grams: row.grams,
    kcal: row.kcalSnapshot,
    protein: row.proteinSnapshot,
    foodName: food == null ? null : (food.nameTr ?? food.nameEn),
  );
}

/// İki akışı birleştirir.
///
/// Drift'in `watch()`'u tek tabloya bakıyor; besin ve porsiyon ayrı
/// tablolarda ve ekranın ikisini birden görmesi gerekiyor.
extension _Combine<T> on Stream<T> {
  Stream<R> combine<U, R>(Stream<U> other, R Function(T, U) merge) {
    T? latestSelf;
    U? latestOther;
    var hasSelf = false;
    var hasOther = false;

    late final controller = StreamController<R>.broadcast();

    void emit() {
      if (hasSelf && hasOther) {
        controller.add(merge(latestSelf as T, latestOther as U));
      }
    }

    controller.onListen = () {
      final a = listen((value) {
        latestSelf = value;
        hasSelf = true;
        emit();
      }, onError: controller.addError);
      final b = other.listen((value) {
        latestOther = value;
        hasOther = true;
        emit();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await a.cancel();
        await b.cancel();
      };
    };

    return controller.stream;
  }
}
