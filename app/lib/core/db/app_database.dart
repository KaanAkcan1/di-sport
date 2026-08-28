import 'package:disport/features/settings/data/profile_table.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Uygulamanın tek veritabanı örneği.
///
/// Drift tüm tabloları tek şemada ister; buna karşın tablolar
/// feature'lara aittir (spec 4.4). Bu sınıf yalnızca toplayıcıdır:
/// mantık içermez, feature'ların tablo tanımlarını bir araya getirir.
@DriftDatabase(tables: [ProfileEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'disport'));

  /// Testlerde bellek içi veritabanı (spec Bölüm 11).
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}
