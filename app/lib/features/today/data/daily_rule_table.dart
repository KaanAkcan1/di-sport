import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Kullanıcının günlük kuralları (spec 5.3, M6'da genişletildi).
///
/// v1'de üç kural koda gömülüydü: 3 litre su, alkol/şeker yok,
/// antrenman. Bunlar kâğıt çizelgeden geliyordu ama kullanıcının
/// hayatı çizelgede yazandan geniş — kreatin, D vitamini, adım hedefi,
/// erken yatma… Bu tablo kuralı veriye çeviriyor.
@DataClassName('DailyRuleRow')
class DailyRules extends Table with SyncColumns {
  TextColumn get label => text()();

  /// `RuleIcons` anahtarı (sunum katmanında çözülür). `IconData`
  /// veritabanına yazılmıyor: yazılabilse bile Flutter sürümleri
  /// arasında kod noktaları değişebilir ve kayıtlı ikonlar bozulurdu.
  TextColumn get iconKey => text()();

  IntColumn get sortOrder => integer()();

  /// Kâğıt çizelgeden gelen üç kural.
  ///
  /// Silinebilir ve yeniden adlandırılabilirler ama işaretleri
  /// `daily_logs`'un kendi sütunlarında tutulur: haftalık özet, kaçak
  /// serisi ve alarmlar o sütunları okuyor.
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
}

/// Yerleşik kuralların kimlikleri.
///
/// Sabit string: `daily_logs`'taki sütunlarla eşleşmeleri gerekiyor ve
/// bu eşleşme veritabanına yazılan değerlere dayanıyor.
abstract final class BuiltInRules {
  static const water = 'water';
  static const noAlcoholSugar = 'no_alcohol_sugar';
  static const workout = 'workout';

  /// Tohumlama sırası ve varsayılan içerikleri.
  static const seeds = <({String id, String label, String iconKey})>[
    (id: water, label: '3 litre su', iconKey: 'water'),
    (id: noAlcoholSugar, label: 'Alkol ve şeker yok', iconKey: 'noDrinks'),
    (id: workout, label: 'Antrenman yapıldı', iconKey: 'fitness'),
  ];

  static const ids = {water, noAlcoholSugar, workout};
}
