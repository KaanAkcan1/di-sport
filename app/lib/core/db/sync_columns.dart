import 'package:drift/drift.dart';

/// Spec Bölüm 5: her tabloda bulunan ortak sütunlar.
///
/// v1'de işlevsizdirler; faz-2'nin (Google ile giriş, bulut senkronu,
/// çok cihaz) kapısını açık tutarlar. `userId` olmadan senkron eklemek
/// şema göçü demektir; `updatedAt`/`deletedAt` olmadan iki cihaz
/// arasında "hangisi daha yeni" sorusu cevaplanamaz.
mixin SyncColumns on Table {
  TextColumn get id => text()();

  /// v1'de sabit `'local'`. Faz-2'de gerçek kullanıcı kimliği.
  TextColumn get userId => text().withDefault(const Constant('local'))();

  /// Unix epoch milisaniye.
  IntColumn get updatedAt => integer()();

  /// Soft delete: dolu ise kayıt silinmiş sayılır ama satır durur —
  /// senkron sırasında "silindi" bilgisinin karşı tarafa taşınması için.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
