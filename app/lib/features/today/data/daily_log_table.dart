import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Günün işaretleri ve serbest notu (spec 5.3).
///
/// Sayısal ölçüm içermez — kilo ve uyku `body_metrics`'e yazılır. Ayrım
/// bilinçli: zaman serisi grafiği, ay sonu tablosu ve AI'a giden kilo
/// dizisi tek bir tablodan okunmalı; günlük kayıtla karışırsa her grafik
/// iki tabloyu birleştirmek zorunda kalır.
@DataClassName('DailyLogRow')
class DailyLogs extends Table with SyncColumns {
  /// `yyyy-MM-dd`. Gün başına tek satır.
  TextColumn get date => text().unique()();

  /// İşaretlenmiş slot id'lerinin JSON dizisi.
  ///
  /// Ayrı tablo yerine dizi: slotlar plana ait ve plan değişince eski
  /// işaretler anlamsızlaşıyor. Satır başına birkaç id için ilişkisel
  /// tablo kurmak, kazandırdığından çok karmaşıklık getirirdi.
  TextColumn get checkedSlotsJson => text().withDefault(const Constant('[]'))();

  BoolColumn get workoutDone => boolean().withDefault(const Constant(false))();
  BoolColumn get waterTargetMet =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get noAlcoholSugar =>
      boolean().withDefault(const Constant(false))();

  /// Kullanıcının kendi sözleri. M4'te `context.md`'ye düzenlenmeden
  /// aktarılır (spec 7.1, beşinci bölüm).
  TextColumn get note => text().withDefault(const Constant(''))();
}
