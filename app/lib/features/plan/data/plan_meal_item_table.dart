import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Plan öğün kalemleri (spec v3 §5.0).
///
/// v2'de plan slotu öğünü yalnız etiketle tanıyordu ("Öğle yemeği").
/// "Plandaki gibi yedim" tek dokunuşu ve yasaklı/besin kontrolleri,
/// planın besin **id'siyle** konuşmasını gerektiriyor — AI belgeye
/// giden 368 besinin id'lerinden seçiyor, dönen plan aynı id'lerle
/// dönüyor ve içe alma uydurma besin kabul etmiyor.
///
/// `items` olmayan öğün slotu eski davranışta kalır (yalnız etiket) —
/// eski planlar ve elle kurulan iskeletler bozulmaz.
@DataClassName('PlanMealItemRow')
class PlanMealItems extends Table with SyncColumns {
  TextColumn get planSlotId => text()();

  /// Katalogdaki besin. Yabancı anahtar kısıtı bilinçli olarak yok:
  /// besin silinse (yumuşak) geçmiş plan okunabilir kalmalı.
  TextColumn get foodId => text()();

  /// Porsiyon çarpanı — "1,5 kase".
  RealColumn get quantity => real().withDefault(const Constant(1))();

  /// Ev ölçüsü; null = 100 g tabanı.
  TextColumn get portionId => text().nullable()();
}
