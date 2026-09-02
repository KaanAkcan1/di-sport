import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Haftalık zaman pencereleri: mesai ve yasaklı saatler (M6).
///
/// İkisi tek tabloda çünkü aynı şey: haftanın bir gününde bir saat
/// aralığı. Ayrı tablo kurmak aynı CRUD'u, aynı çakışma kontrolünü ve
/// aynı düzenleme ekranını iki kez yazmak olurdu.
///
/// **Neden gerekli:** v1'de AI'a "sabah 06:30 kahvaltı" diyebiliyorduk
/// ama kullanıcının 08:00-18:00 arası fabrikada olduğunu
/// söyleyemiyorduk. Plan bu yüzden mesai saatine antrenman koyabiliyordu.
@DataClassName('WeeklyWindowRow')
class WeeklyWindows extends Table with SyncColumns {
  /// 1 = Pazartesi … 7 = Pazar (`DateTime.weekday` ile aynı).
  IntColumn get weekday => integer()();

  /// `HH:mm`, gün içi.
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();

  /// [WindowKinds] değeri.
  TextColumn get kind => text()();

  /// İsteğe bağlı açıklama — "Fabrika", "Çocuk yatırma".
  TextColumn get label => text().withDefault(const Constant(''))();
}

/// Pencere türleri.
abstract final class WindowKinds {
  /// Mesai: kullanıcı işte. Plan bu saatlere antrenman koymamalı ama
  /// öğün koyabilir — insan işte de yemek yiyor.
  static const work = 'work';

  /// Yasaklı: bu aralıkta hiçbir şey planlanmamalı ve bildirim
  /// çalmamalı. Uyku, toplantı, çocuk saati.
  static const blocked = 'blocked';

  static const labels = <String, String>{
    work: 'Mesai',
    blocked: 'Uygun değil',
  };

  static String labelOf(String kind) => labels[kind] ?? kind;
}
