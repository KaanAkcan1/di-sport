import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Kullanıcının elindeki ekipman (M6).
///
/// Katalogdaki her hareket `equipment` listesi taşıyor ama v1'de bu
/// bilgi yalnız gösteriliyordu — kullanıcı "bende dambıl var mı"
/// sorusunu uygulamaya söyleyemiyordu. Sonuç: salon hareketleri ile
/// evde yapılabilecekler aynı listede karışıktı.
///
/// Tablo katalogdaki farklı ekipman adlarından tohumlanıyor; kullanıcı
/// listeye kendi ekipmanını da ekleyebiliyor.
@DataClassName('EquipmentRow')
class EquipmentItems extends Table with SyncColumns {
  TextColumn get label => text()();

  /// [EquipmentKind] adı — tipli karşılık (M8, v12).
  ///
  /// Etiket kullanıcıya gösterilen metin, bu ise **kimlik**. Eski
  /// kayıtlar göçte `EquipmentKind.fromLegacyTr` ile dolduruluyor.
  TextColumn get kind =>
      text().withDefault(const Constant('other'))();

  /// Kullanıcıda var mı.
  ///
  /// Varsayılan `false`: envanteri boş başlatıp kullanıcının işaretlemesi,
  /// hepsini işaretli başlatıp elemesinden iyi. İkincisinde "bende yok"
  /// demeyi unutan kullanıcı yapamayacağı hareketleri öneri olarak alır.
  ///
  /// **M8'de yere bağlandı** ([atHome]/[atGym]); bu sütun göç için
  /// duruyor ve artık okunmuyor.
  BoolColumn get isOwned => boolean().withDefault(const Constant(false))();

  /// Evde var mı.
  ///
  /// **Neden iki bayrak, iki satır değil:** aynı ekipman ikisinde de
  /// olabilir ve iki kayıtla temsil etmek "dambılı sildim" dendiğinde
  /// hangisinin silineceğini belirsizleştirirdi.
  BoolColumn get atHome => boolean().withDefault(const Constant(false))();

  /// Salonda var mı.
  BoolColumn get atGym => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer()();
}

/// Ekipman gerektirmeyen hareketlerin `equipment` listesinde geçen
/// değerler — **katlanmış** hâlleriyle.
///
/// Bunlar envantere girmiyor ve filtreyi hiç etkilemiyor: vücut
/// ağırlığı herkeste var, "yok" diyebileceğin bir şey değil.
///
/// Katlanmış yazılmalarının nedeni karşılaştırmanın katlanmış kimlik
/// üzerinden yapılması. Ham hâlleriyle yazılırsa (`vücut ağırlığı`)
/// hiçbir zaman eşleşmezler ve vücut ağırlığı bir ekipman sanılır —
/// testte yakalandı.
const bodyweightEquipment = {
  'vucut agirligi',
  'yok',
  'ekipman yok',
};
