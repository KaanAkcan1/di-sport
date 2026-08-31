import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Egzersiz kataloğu tablosu.
///
/// Tasarım kararı: **yalnız filtrelenen alanlar sütun**, anlatımın
/// tamamı [detailJson] içinde taşınır.
///
/// Alternatif, yirmi küsur alanın hepsini sütun yapmaktı. Onun iki
/// bedeli olurdu: anlatım şeması her değiştiğinde veritabanı göçü
/// gerekirdi (M4'te AI'ın önerdiği hareketlerle bu şema evrilecek), ve
/// liste sorgusu hiç kullanmadığı yirmi sütunu okurdu.
///
/// Bu haliyle arama ve filtre indekslenebilir sütunlar üstünden çalışır,
/// detay ise tek satır okunup [Exercise] modeline çözülür.
@DataClassName('ExerciseRow')
class Exercises extends Table with SyncColumns {
  TextColumn get nameTr => text()();
  TextColumn get nameEn => text()();
  TextColumn get category => text()();
  TextColumn get location => text()();
  IntColumn get difficulty => integer()();
  BoolColumn get isUserDefined =>
      boolean().withDefault(const Constant(false))();

  /// Türkçe ad, İngilizce ad ve hedef kaslar; hepsi
  /// `TurkishText.fold` ile katlanmış tek metin.
  ///
  /// Ayrı sütun olmasının nedeni SQLite'ın `lower()` fonksiyonunun
  /// yalnız ASCII'yi küçültmesi: "Şınav" kaydı büyük Ş ile durduğu için
  /// sorgu tarafında küçültmek yetmez. Katlama yazma anında yapılır,
  /// arama da aynı katlamadan geçirilerek karşılaştırılır.
  TextColumn get searchText => text()();

  /// JSON dizi — ekipman filtresi için.
  TextColumn get equipmentJson => text()();
  TextColumn get primaryMusclesJson => text()();

  /// `Exercise.toJson()` çıktısının tamamı.
  TextColumn get detailJson => text()();
}
