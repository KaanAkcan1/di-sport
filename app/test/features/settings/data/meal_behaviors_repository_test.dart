import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/plan/domain/meal_kind.dart';
import 'package:disport/features/settings/data/meal_behaviors_repository.dart';
import 'package:disport/features/settings/domain/meal_behavior.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MealBehaviorsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MealBehaviorsRepository(db);
  });

  tearDown(() => db.close());

  test('boş başlar — kayıt yoksa varsayılan (planned, esnek) geçerli', () async {
    expect(await repo.watchAll().first, isEmpty);
  });

  test('upsert yazar ve öğün başına tek satır tutar', () async {
    await repo.upsert(
      const MealBehaviorEntry(meal: MealKind.ogle, time: '12:30'),
    );
    await repo.upsert(
      const MealBehaviorEntry(
        meal: MealKind.ogle,
        time: '12:00',
        behavior: MealBehavior.external,
      ),
    );

    final entries = await repo.watchAll().first;
    expect(entries, hasLength(1));
    expect(entries.single.time, '12:00');
    expect(entries.single.behavior, MealBehavior.external);

    final raw = await db.select(db.mealBehaviors).get();
    expect(raw, hasLength(1));
  });

  test('fixed davranış tarif ve besin bağı taşır', () async {
    await repo.upsert(
      const MealBehaviorEntry(
        meal: MealKind.kahvalti,
        time: '07:00',
        behavior: MealBehavior.fixed,
        fixedNote: 'menemen + çay',
        fixedItemsJson: '[{"foodId":"egg","quantity":2}]',
      ),
    );

    final entry = (await repo.watchAll().first).single;
    expect(entry.behavior, MealBehavior.fixed);
    expect(entry.fixedNote, 'menemen + çay');
    expect(entry.fixedItemsJson, '[{"foodId":"egg","quantity":2}]');
  });

  test('bilinmeyen davranış adı okuma sırasında hata verir', () {
    expect(() => MealBehavior.fromName('canteen'), throwsArgumentError);
  });
}
