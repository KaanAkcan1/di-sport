import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Besin tanımı — 100 gramındaki değerler (spec §5.2).
@DataClassName('FoodRow')
class Foods extends Table with SyncColumns {
  TextColumn get nameEn => text()();

  /// Boş olabilir: USDA'da Türkçe karşılığı bulunmayan kayıt için ad
  /// uydurulmuyor, arayüz İngilizcesini gösteriyor.
  TextColumn get nameTr => text().nullable()();

  /// `FoodCategory` enum adı.
  TextColumn get category => text()();

  RealColumn get kcal100 => real()();
  RealColumn get protein100 => real().withDefault(const Constant(0))();
  RealColumn get carb100 => real().withDefault(const Constant(0))();
  RealColumn get fat100 => real().withDefault(const Constant(0))();

  /// `FoodSource` enum adı — yeniden tohumlarken `user` kayıtlara
  /// dokunulmaması için.
  TextColumn get source => text().withDefault(const Constant('curated'))();

  TextColumn get sourceRef => text().nullable()();

  /// İki dilin katlanmış hâli, aramada tek `LIKE` ile taransın diye.
  /// Katalogdaki `searchText` ile aynı desen.
  TextColumn get searchText => text().withDefault(const Constant(''))();
}

/// Bir besinin ev ölçüsü — "1 kase = 250 g".
@DataClassName('FoodPortionRow')
class FoodPortions extends Table with SyncColumns {
  TextColumn get foodId => text()();
  TextColumn get labelTr => text()();
  TextColumn get labelEn => text()();
  RealColumn get grams => real()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

/// Yenen bir kalem.
///
/// `kcalSnapshot`/`proteinSnapshot` **kayıt anında donuyor**: besin
/// tablosu güncellenince geçmiş öğün değişmemeli.
@DataClassName('MealEntryRow')
class MealEntries extends Table with SyncColumns {
  /// `yyyy-MM-dd`.
  TextColumn get date => text()();

  /// `MealKind` enum adı.
  TextColumn get mealKind => text()();

  /// Plan slotu; plansız kayıt serbest.
  TextColumn get slotId => text().nullable()();

  TextColumn get foodId => text()();

  /// Kaç porsiyon — "3 porsiyon yedim" burada 3.
  RealColumn get quantity => real().withDefault(const Constant(1))();

  /// Hangi ev ölçüsü seçildi; gram doğrudan girildiyse null.
  TextColumn get portionId => text().nullable()();

  RealColumn get grams => real()();
  RealColumn get kcalSnapshot => real()();
  RealColumn get proteinSnapshot => real()();
}

/// Serbest aktivite tanımı — 2024 Adult Compendium (spec §5.6).
///
/// Katalog hareketlerinden ayrı: "basketbol maçı" bir antrenman planına
/// konulacak bir hareket değil, olan bitmiş bir şey. Katalogla aynı
/// tabloya koymak filtreleri ve plan editörünü kirletirdi.
@DataClassName('ActivityRow')
class Activities extends Table with SyncColumns {
  TextColumn get nameEn => text()();
  TextColumn get nameTr => text().nullable()();

  /// Compendium ana kategorisi — "sports", "walking", "home activity".
  TextColumn get category => text().withDefault(const Constant('diger'))();

  RealColumn get met => real()();

  /// `compendium` ya da `user`.
  TextColumn get source => text().withDefault(const Constant('compendium'))();

  TextColumn get searchText => text().withDefault(const Constant(''))();
}

/// Yapılan bir aktivitenin kaydı.
@DataClassName('ActivityLogRow')
class ActivityLogs extends Table with SyncColumns {
  /// `yyyy-MM-dd`.
  TextColumn get date => text()();

  TextColumn get activityId => text()();
  IntColumn get minutes => integer()();

  /// Kilo değişince geçmiş harcama değişmemeli — kayıtta donuyor.
  RealColumn get kcalSnapshot => real()();
}
