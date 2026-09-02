import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Tahlil sonuçları (spec 5.4).
///
/// [BodyMetrics]'ten ayrı tutulmasının nedeni referans aralığı: bir
/// tahlil değeri tek başına anlamsızdır, "30-100 arası normal" bilgisi
/// olmadan 24 ng/mL'nin iyi mi kötü mü olduğu bilinemez. Kilonun böyle
/// bir aralığı yok. İkisi aynı tabloda olsaydı satırların yarısı boş
/// kalırdı.
@DataClassName('LabResultRow')
class LabResults extends Table with SyncColumns {
  TextColumn get date => text()();
  TextColumn get marker => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();

  /// Laboratuvarın kendi referans aralığı — evrensel değil.
  ///
  /// Aynı marker için iki laboratuvar farklı aralık verebilir (cihaz ve
  /// yöntem farkı). Bu yüzden aralık sabit tabloda değil, sonuçla
  /// birlikte saklanıyor: iki yıl önceki sonucu bugünün aralığıyla
  /// yorumlamak yanlış olur.
  RealColumn get refLow => real().nullable()();
  RealColumn get refHigh => real().nullable()();

  TextColumn get panel => text()();
  TextColumn get labName => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Tahlil PDF'inin cihazdaki yolu. v1'de yalnız saklanıyor.
  TextColumn get attachmentPath => text().nullable()();
}

/// "Bu tahlili kaç ayda bir yaptır" takvimi.
@DataClassName('LabScheduleRow')
class LabSchedules extends Table with SyncColumns {
  TextColumn get marker => text()();

  /// En son ne zaman yaptırıldı. Takvim kurulmuş ama hiç sonuç
  /// girilmemişse `null` — bu durumda vade **hemen** gelmiş sayılır.
  TextColumn get lastDate => text().nullable()();

  IntColumn get intervalMonths => integer()();

  /// Marker başına tek takvim; aralık değiştirilirse üstüne yazılır.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {marker},
  ];
}

/// Panel kimlikleri (spec 5.4).
///
/// [MetricKinds] ile aynı gerekçeyle string sabit: değer veritabanına
/// yazılıyor ve `context.md`'ye aynı adla giriyor.
abstract final class LabPanels {
  static const liver = 'liver';
  static const metabolic = 'metabolic';
  static const vitamin = 'vitamin';
  static const thyroid = 'thyroid';
  static const lipid = 'lipid';
  static const other = 'other';

  /// Ekranda görünecek sıra ve Türkçe başlıklar.
  ///
  /// Sıra rastgele değil: en sık bakılan paneller üstte. "Diğer" her
  /// zaman sonda.
  static const labels = <String, String>{
    metabolic: 'Metabolizma',
    lipid: 'Lipid',
    liver: 'Karaciğer',
    thyroid: 'Tiroid',
    vitamin: 'Vitamin',
    other: 'Diğer',
  };

  static List<String> get ordered => labels.keys.toList();

  static String labelOf(String panel) => labels[panel] ?? panel;
}
