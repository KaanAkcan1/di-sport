import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/catalog/data/favorite_sports_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FavoriteSportsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FavoriteSportsRepository(db);
  });

  tearDown(() => db.close());

  test('boş başlar; toggle ekler, tekrar toggle kaldırır', () async {
    expect(await repo.watchAll().first, isEmpty);

    await repo.toggle('basketball');
    var favorites = await repo.watchAll().first;
    expect(favorites.single.activityId, 'basketball');

    await repo.toggle('basketball');
    expect(await repo.watchAll().first, isEmpty);

    // Kaldırma yumuşak — satır duruyor, AI belgesi izini kaybetmiyor.
    final raw = await db.select(db.favoriteSports).get();
    expect(raw.single.deletedAt, isNotNull);
  });

  test('not yazılır, boş not temizler', () async {
    await repo.toggle('running');
    await repo.setNote('running', 'haftada 1, pazar sabahı');
    expect(
      (await repo.watchAll().first).single.note,
      'haftada 1, pazar sabahı',
    );

    await repo.setNote('running', '   ');
    expect((await repo.watchAll().first).single.note, isNull);
  });

  test('kaldırıp yeniden eklemek temiz kayıt açar', () async {
    await repo.toggle('swimming');
    await repo.setNote('swimming', 'yazın');
    await repo.toggle('swimming');
    await repo.toggle('swimming');

    final favorite = (await repo.watchAll().first).single;
    expect(favorite.activityId, 'swimming');
    // Yeni kayıt eski notu taşımaz — kullanıcı silmişti.
    expect(favorite.note, isNull);
  });
}
