import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Ölçüm türlerinin tanımları (M6).
///
/// **Değerleri tutmuyor** — onlar `body_metrics`'te, `kind` sütununda
/// bu tablonun id'siyle. Ayrım önemli: `body_metrics` zaten serbest bir
/// `kind` stringi kabul ediyordu, yani özel ölçümler veri katmanında
/// baştan beri mümkündü. Eksik olan tek şey **tanım**dı: etiket, birim
/// ve kaç ondalıkla gösterileceği.
///
/// v1'de bunlar `MetricKinds` içinde koda gömülüydü. Kullanıcının
/// ölçmek isteyebileceği şey listede olmayabilir — kol çevresi, kalça,
/// istirahat nabzı, VKİ.
@DataClassName('MetricDefinitionRow')
class MetricDefinitions extends Table with SyncColumns {
  TextColumn get label => text()();

  /// "cm", "kg", "tekrar", "sn", "atım/dk".
  TextColumn get unit => text()();

  /// Gösterimde kaç ondalık. Tekrar sayısı 0, çevre ölçüsü 1.
  ///
  /// "6,0 tekrar" diye bir şey yok; bunu kullanıcının seçebilmesi
  /// gerekiyor çünkü hangi ölçümün tam sayı olduğunu biz bilemeyiz.
  IntColumn get decimals => integer().withDefault(const Constant(1))();

  IntColumn get sortOrder => integer()();

  /// Kâğıt çizelgeden gelenler. Silinebilirler ama id'leri sabittir:
  /// `MetricKinds` sabitleriyle eşleşmeleri gerekiyor, geçiş kriteri
  /// ve `context.md` onları adıyla okuyor.
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  /// Bugün ekranında günlük girilenler (kilo, uyku) Sağlık ekranının
  /// ölçüm kartında tekrar gösterilmiyor.
  BoolColumn get isDaily => boolean().withDefault(const Constant(false))();
}
