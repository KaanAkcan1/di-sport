import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/today/data/daily_rules_repository.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DailyRulesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DailyRulesRepository(db);
  });
  tearDown(() => db.close());

  group('tohumlama', () {
    test('kâğıt çizelgenin üç kuralı sırayla gelir', () async {
      await repo.seedBuiltIns();

      final rules = await repo.watchActive().first;
      expect(rules.map((r) => r.id), [
        BuiltInRules.water,
        BuiltInRules.noAlcoholSugar,
        BuiltInRules.workout,
      ]);
      expect(rules.every((r) => r.isBuiltIn), isTrue);
    });

    test('ikinci kez tohumlamak kopya üretmez', () async {
      await repo.seedBuiltIns();
      await repo.seedBuiltIns();

      expect(await repo.watchActive().first, hasLength(3));
    });

    test('kullanıcı gizlediyse tohumlama geri getirmez', () async {
      // Aksi hâlde her açılışta silinen kural geri gelir ve kullanıcı
      // aynı şeyi tekrar tekrar siler.
      await repo.seedBuiltIns();
      await repo.remove(BuiltInRules.water);
      await repo.seedBuiltIns();

      final ids = (await repo.watchActive().first).map((r) => r.id);
      expect(ids, isNot(contains(BuiltInRules.water)));
    });
  });

  group('ekleme', () {
    test('yeni kural sona eklenir', () async {
      await repo.seedBuiltIns();
      final id = await repo.add(label: 'Kreatin aldım', iconKey: 'pill');

      final rules = await repo.watchActive().first;
      expect(rules.last.id, id);
      expect(rules.last.label, 'Kreatin aldım');
      expect(rules.last.isBuiltIn, isFalse);
    });

    test('boş etiket reddedilir', () async {
      await expectLater(
        repo.add(label: '   ', iconKey: 'check'),
        throwsArgumentError,
      );
    });
  });

  group('düzenleme', () {
    test('etiket ve ikon değiştirilebilir', () async {
      final id = await repo.add(label: 'Eski', iconKey: 'check');
      await repo.rename(id, label: 'Yeni', iconKey: 'pill');

      final rule = (await repo.watchActive().first).single;
      expect(rule.label, 'Yeni');
      expect(rule.iconKey, 'pill');
    });

    test('yerleşik kuralın etiketi de değiştirilebilir', () async {
      // Kullanıcının su hedefi 3 litre olmak zorunda değil.
      await repo.seedBuiltIns();
      await repo.rename(BuiltInRules.water, label: '4 litre su');

      final rule = (await repo.watchActive().first).first;
      expect(rule.label, '4 litre su');
      expect(rule.isBuiltIn, isTrue);
    });
  });

  group('sıralama', () {
    test('yeni sıra kalıcı olur', () async {
      await repo.seedBuiltIns();
      final id = await repo.add(label: 'Kreatin', iconKey: 'pill');

      await repo.reorder([
        id,
        BuiltInRules.workout,
        BuiltInRules.water,
        BuiltInRules.noAlcoholSugar,
      ]);

      expect((await repo.watchActive().first).map((r) => r.id), [
        id,
        BuiltInRules.workout,
        BuiltInRules.water,
        BuiltInRules.noAlcoholSugar,
      ]);
    });
  });

  group('silme', () {
    test('silinen kural listeden çıkar', () async {
      final id = await repo.add(label: 'Geçici', iconKey: 'check');
      await repo.remove(id);

      expect(await repo.watchActive().first, isEmpty);
    });

    test('geçmiş işaretler silinmez, yalnız kural gizlenir', () async {
      // Soft delete: geçmiş günlerin kaydı bozulmamalı. Kullanıcı
      // kuralı bugün silse de dünkü işaret dünün gerçeği.
      final id = await repo.add(label: 'Geçici', iconKey: 'check');
      await TodayRepository(db).toggleRule('2026-09-01', id);
      await repo.remove(id);

      final log = await TodayRepository(db).readDay('2026-09-01');
      expect(log.isRuleChecked(id), isTrue);
    });
  });

  group('günlük işaretler', () {
    test('özel kural işaretlenir ve geri alınır', () async {
      final id = await repo.add(label: 'Kreatin', iconKey: 'pill');
      final today = TodayRepository(db);

      await today.toggleRule('2026-09-01', id);
      expect((await today.readDay('2026-09-01')).isRuleChecked(id), isTrue);

      await today.toggleRule('2026-09-01', id);
      expect((await today.readDay('2026-09-01')).isRuleChecked(id), isFalse);
    });

    test('yerleşik kurallar kendi sütunlarından okunur', () async {
      // Geriye uyum: haftalık özet, kaçak serisi ve alarmlar bu
      // sütunları okuyor. Yerleşik kurallar JSON'a taşınmadı.
      final today = TodayRepository(db);
      await today.setFlags('2026-09-01', waterTargetMet: true);

      final log = await today.readDay('2026-09-01');
      expect(log.isRuleChecked(BuiltInRules.water), isTrue);
      expect(log.isRuleChecked(BuiltInRules.workout), isFalse);
    });

    test('yerleşik kural toggle ile de değişir', () async {
      final today = TodayRepository(db);
      await today.toggleRule('2026-09-01', BuiltInRules.workout);

      final log = await today.readDay('2026-09-01');
      expect(log.workoutDone, isTrue);
      expect(log.isRuleChecked(BuiltInRules.workout), isTrue);
    });
  });
}
