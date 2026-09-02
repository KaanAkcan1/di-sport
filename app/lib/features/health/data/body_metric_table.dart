import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Tarihli sayısal ölçümler (spec 5.4).
///
/// Kilo, bel çevresi, uyku ve şınav tekrarı aynı şeydir: tarihli bir
/// sayı. Tek tablo olmaları grafik kodunun bir kez yazılmasını sağlar;
/// yeni bir ölçüm eklemek yeni tablo değil, yeni bir [kind] değeridir.
///
/// Tahliller ayrı tabloda (M5): onların referans aralığı, laboratuvar
/// adı, panel grubu ve ek dosyası var; burada tutulsalardı satırların
/// yarısı boş kalırdı.
@DataClassName('BodyMetricRow')
class BodyMetrics extends Table with SyncColumns {
  TextColumn get date => text()();
  TextColumn get kind => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  TextColumn get note => text().nullable()();

  /// Gün başına her ölçümden bir tane: aynı güne ikinci tartı girilirse
  /// yenisi eskisinin üstüne yazılır.
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {date, kind},
  ];
}

/// Ölçüm türleri.
///
/// String sabit, enum değil: değerler veritabanına yazılıyor ve M4'te
/// `context.md`'nin JSON bloğuna aynı adla giriyor. Enum adı değişse
/// veri bozulur; sabit olduğu yerde derleme zamanı güvenliğini
/// [MetricKinds] üstünden alıyoruz.
abstract final class MetricKinds {
  static const weight = 'weight';
  static const waist = 'waist';
  static const belly = 'belly';
  static const sleepHours = 'sleepHours';
  static const pushupMax = 'pushupMax';
  static const plankSec = 'plankSec';
  static const treadmillIncline = 'treadmillIncline';
  static const steps = 'steps';

  /// Ekranlarda gösterilecek Türkçe karşılıkları ve birimleri.
  static const labels = <String, (String, String)>{
    weight: ('Kilo', 'kg'),
    waist: ('Bel çevresi', 'cm'),
    belly: ('Göbek çevresi', 'cm'),
    sleepHours: ('Uyku', 'sa'),
    pushupMax: ('Şınav', 'tekrar'),
    plankSec: ('Plank', 'sn'),
    treadmillIncline: ('Bant eğimi', '%'),
    steps: ('Adım', 'adım'),
  };

  static String labelOf(String kind) => labels[kind]?.$1 ?? kind;

  static String unitOf(String kind) => labels[kind]?.$2 ?? '';
}
