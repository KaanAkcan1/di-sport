import 'package:disport/core/db/sync_columns.dart';
import 'package:drift/drift.dart';

/// Anahtar-değer profil deposu (spec 5.4): boy, doğum yılı, hedef kilo,
/// yaşam tarzı alanları, AI sağlayıcı tercihi.
///
/// Tablo `core/db` altında değil, sahibi olan feature'ın içinde yaşar
/// (spec 4.4). `core/db/app_database.dart` yalnızca toplayıcıdır.
@DataClassName('ProfileEntryRow')
class ProfileEntries extends Table with SyncColumns {
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}
