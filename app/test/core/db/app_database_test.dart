import 'package:disport/core/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('profile entry round-trips with sync columns defaulted', () async {
    await db
        .into(db.profileEntries)
        .insert(
          ProfileEntriesCompanion.insert(
            id: 'p1',
            updatedAt: 1000,
            key: 'heightCm',
            value: '184',
          ),
        );

    final row = await db.select(db.profileEntries).getSingle();
    expect(row.key, 'heightCm');
    expect(row.value, '184');
    expect(row.userId, 'local'); // withDefault
    expect(row.deletedAt, isNull);
    expect(row.updatedAt, 1000);
  });

  test('id is the primary key — duplicate insert fails', () async {
    Future<void> insert(String id) => db
        .into(db.profileEntries)
        .insert(
          ProfileEntriesCompanion.insert(
            id: id,
            updatedAt: 1,
            key: 'k$id',
            value: 'v',
          ),
        );

    await insert('p1');
    expect(insert('p1'), throwsA(isA<SqliteException>()));
  });
}
