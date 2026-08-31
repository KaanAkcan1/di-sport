import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/catalog/data/catalog_repository.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../exercise_fixtures.dart';

void main() {
  late AppDatabase db;
  late CatalogRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CatalogRepository(db);
  });
  tearDown(() => db.close());

  group('tohumlama', () {
    test('seedFromJson kayıtları yükler', () async {
      await repo.seedFromJson(fixtureSeedJson());
      expect(await repo.countAll(), 4);
    });

    test('ikinci çağrı hiçbir şey yapmaz — açılışta tekrar tekrar çalışır',
        () async {
      await repo.seedFromJson(fixtureSeedJson());
      await repo.seedFromJson(fixtureSeedJson());
      expect(await repo.countAll(), 4);
    });
  });

  group('okuma', () {
    setUp(() => repo.seedFromJson(fixtureSeedJson()));

    test('getById tam modeli geri kurar', () async {
      final e = await repo.getById('incline_pushup');
      expect(e!.nameTr, 'Eğimli Şınav');
      expect(e.execution, hasLength(3));
      expect(e.commonMistakes, hasLength(2));
      expect(e.commonMistakes.first.why, 'Bel yüklenir.');
    });

    test('getById bilinmeyen id için null', () async {
      expect(await repo.getById('yok'), isNull);
    });

    test('varsayılan sıralama Türkçe ada göre', () async {
      final list = await repo.watchFiltered().first;
      expect(list.map((e) => e.nameTr), [
        'Eğimli Şınav',
        'Kondisyon Bisikleti',
        'Plank',
        'Sandalyeye Squat',
      ]);
    });
  });

  group('filtreleme', () {
    setUp(() => repo.seedFromJson(fixtureSeedJson()));

    test('arama Türkçe adda, büyük/küçük harf duyarsız', () async {
      final list = await repo.watchFiltered(query: 'şınav').first;
      expect(list.map((e) => e.id), ['incline_pushup']);
    });

    test('arama İngilizce adda da çalışır', () async {
      final list = await repo.watchFiltered(query: 'CHAIR').first;
      expect(list.map((e) => e.id), ['chair_squat']);
    });

    test('arama kas grubunda da çalışır', () async {
      final list = await repo.watchFiltered(query: 'karın').first;
      expect(list.map((e) => e.id), ['plank']);
    });

    test('ev filtresi both olanları da içerir', () async {
      final list = await repo
          .watchFiltered(location: ExerciseLocation.home)
          .first;
      expect(list.map((e) => e.id), containsAll(['incline_pushup', 'plank']));
      expect(list.map((e) => e.id), isNot(contains('stationary_bike')));
    });

    test('salon filtresi both olanları da içerir', () async {
      final list = await repo
          .watchFiltered(location: ExerciseLocation.gym)
          .first;
      expect(list.map((e) => e.id), containsAll(['stationary_bike', 'plank']));
      expect(list.map((e) => e.id), isNot(contains('chair_squat')));
    });

    test('kategori filtresi', () async {
      final list = await repo
          .watchFiltered(category: ExerciseCategory.cardio)
          .first;
      expect(list.map((e) => e.id), ['stationary_bike']);
    });

    test('filtreler birlikte uygulanır', () async {
      final list = await repo
          .watchFiltered(location: ExerciseLocation.home, query: 'squat')
          .first;
      expect(list.map((e) => e.id), ['chair_squat']);
    });

    test('eşleşme yoksa boş liste — hata değil', () async {
      expect(await repo.watchFiltered(query: 'zzz').first, isEmpty);
    });
  });

  group('kullanıcı tanımlı hareket', () {
    setUp(() => repo.seedFromJson(fixtureSeedJson()));

    test('eklenir ve işaretli kalır', () async {
      final base = (await repo.getById('plank'))!;
      final custom = Exercise.fromJson(
        base.toJson()
          ..['id'] = 'custom_burpee'
          ..['nameTr'] = 'Burpee'
          ..['isUserDefined'] = true,
      );

      await repo.upsertUserDefined(custom);

      final saved = await repo.getById('custom_burpee');
      expect(saved!.isUserDefined, isTrue);
      expect(saved.nameTr, 'Burpee');
      expect(await repo.countAll(), 5);
    });

    test('aynı id ikinci kez eklenirse üzerine yazar', () async {
      final base = (await repo.getById('plank'))!;
      Exercise variant(String name) => Exercise.fromJson(
        base.toJson()
          ..['id'] = 'custom_x'
          ..['nameTr'] = name
          ..['isUserDefined'] = true,
      );

      await repo.upsertUserDefined(variant('İlk'));
      await repo.upsertUserDefined(variant('İkinci'));

      expect((await repo.getById('custom_x'))!.nameTr, 'İkinci');
      expect(await repo.countAll(), 5);
    });
  });

  test('silinmiş kayıt listede görünmez', () async {
    await repo.seedFromJson(fixtureSeedJson());
    await repo.softDelete('plank');

    final list = await repo.watchFiltered().first;
    expect(list.map((e) => e.id), isNot(contains('plank')));
    expect(await repo.getById('plank'), isNull);
  });
}
