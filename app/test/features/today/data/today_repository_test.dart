import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/today/data/daily_rule_table.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TodayRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TodayRepository(db);
  });
  tearDown(() => db.close());

  const today = '2026-09-01';

  group('boş gün', () {
    test('kayıt yokken geçerli boş görünüm döner', () async {
      final view = await repo.watchDay(today).first;

      expect(view.checkedSlotIds, isEmpty);
      expect(view.workoutDone, isFalse);
      expect(view.waterTargetMet, isFalse);
      expect(view.noAlcoholSugar, isFalse);
      expect(view.note, '');
      expect(view.isEmpty, isTrue);
    });

    test('dokunulmayan gün için satır yaratılmaz', () async {
      await repo.watchDay(today).first;
      expect(await db.select(db.dailyLogs).get(), isEmpty);
    });
  });

  group('slot işaretleme', () {
    test('ekler, ikinci dokunuşta kaldırır', () async {
      await repo.toggleSlot(today, 's1');
      expect((await repo.readDay(today)).checkedSlotIds, {'s1'});

      await repo.toggleSlot(today, 's1');
      expect((await repo.readDay(today)).checkedSlotIds, isEmpty);
    });

    test('birden çok slot bağımsız tutulur', () async {
      await repo.toggleSlot(today, 's1');
      await repo.toggleSlot(today, 's2');
      await repo.toggleSlot(today, 's1');

      expect((await repo.readDay(today)).checkedSlotIds, {'s2'});
    });

    test('isSlotChecked doğru cevap verir', () async {
      await repo.toggleSlot(today, 's1');
      final view = await repo.readDay(today);

      expect(view.isSlotChecked('s1'), isTrue);
      expect(view.isSlotChecked('s2'), isFalse);
    });
  });

  group('bayraklar', () {
    test('yalnız verilen bayrak değişir', () async {
      await repo.setFlags(today, workoutDone: true);
      await repo.setFlags(today, waterTargetMet: true);

      final view = await repo.readDay(today);
      expect(view.workoutDone, isTrue);
      expect(view.waterTargetMet, isTrue);
      expect(view.noAlcoholSugar, isFalse);
    });

    test('geri alınabilir', () async {
      await repo.setFlags(today, workoutDone: true);
      await repo.setFlags(today, workoutDone: false);
      expect((await repo.readDay(today)).workoutDone, isFalse);
    });

    test('flagsMet işaretli kutucuk sayısını verir', () async {
      await repo.setFlags(today, workoutDone: true, waterTargetMet: true);
      expect((await repo.readDay(today)).flagsMet, 2);
    });
  });

  test('not kaydedilir ve güncellenir', () async {
    await repo.setNote(today, 'Şınavda zorlandım.');
    expect((await repo.readDay(today)).note, 'Şınavda zorlandım.');

    await repo.setNote(today, 'Akşam bir dilim baklava yedim.');
    expect(
      (await repo.readDay(today)).note,
      'Akşam bir dilim baklava yedim.',
    );
  });

  test('gün başına tek satır tutulur', () async {
    await repo.toggleSlot(today, 's1');
    await repo.setFlags(today, workoutDone: true);
    await repo.setNote(today, 'not');

    expect(await db.select(db.dailyLogs).get(), hasLength(1));
  });

  group('su miktarı (v3 §5.1)', () {
    test('yazım kutucuğu miktardan türetir — iki yönde', () async {
      await repo.setWaterMl(today, 2750, targetMl: 3000);
      var view = await repo.readDay(today);
      expect(view.waterMl, 2750);
      expect(view.waterTargetMet, isFalse);

      await repo.setWaterMl(today, 3000, targetMl: 3000);
      view = await repo.readDay(today);
      expect(view.waterTargetMet, isTrue);

      // Geri almak kutucuğu da geri alır — iki kaynak çelişmez.
      await repo.setWaterMl(today, 2500, targetMl: 3000);
      view = await repo.readDay(today);
      expect(view.waterTargetMet, isFalse);
    });

    test('kutucuğu elle işaretlemek miktarı hedefe eşitler', () async {
      await repo.toggleRule(today, BuiltInRules.water, waterTargetMl: 3000);
      var view = await repo.readDay(today);
      expect(view.waterTargetMet, isTrue);
      expect(view.waterMl, 3000);

      // Kaldırmak miktarı sıfırlamaz, bilinmeze döndürür: "bugün takip
      // etmedim" ile "hiç içmedim" aynı şey değil.
      await repo.toggleRule(today, BuiltInRules.water, waterTargetMl: 3000);
      view = await repo.readDay(today);
      expect(view.waterTargetMet, isFalse);
      expect(view.waterMl, isNull);
    });
  });

  group('rowsBetween', () {
    test('aralıktaki günleri döner, dışındakileri değil', () async {
      await repo.setFlags('2026-08-30', workoutDone: true);
      await repo.setFlags('2026-09-01', workoutDone: true);
      await repo.setFlags('2026-09-05', workoutDone: true);

      final rows = await repo.rowsBetween('2026-09-01', '2026-09-03');
      expect(rows.keys, ['2026-09-01']);
    });
  });

  group('missedStreak', () {
    // Plan: 28 Ağustos - 1 Eylül, hepsi ev günü.
    final planDays = {
      for (var day = 25; day <= 31; day++) '2026-08-$day': 'home',
      '2026-09-01': 'home',
    };

    test('kaçırılan gün yoksa sıfır', () async {
      await repo.setFlags('2026-08-31', workoutDone: true);
      expect(
        await repo.missedStreak(todayIso: today, planDayTypes: planDays),
        0,
      );
    });

    test('ardışık kaçırılan günleri sayar', () async {
      // 30 ve 31 Ağustos kaçırıldı, 29'unda yapıldı.
      await repo.setFlags('2026-08-29', workoutDone: true);
      expect(
        await repo.missedStreak(todayIso: today, planDayTypes: planDays),
        2,
      );
    });

    test('bugünü saymaz — gün henüz bitmedi', () async {
      await repo.setFlags('2026-08-31', workoutDone: true);
      // Bugün (1 Eylül) işaretlenmemiş ama seri sıfır olmalı.
      expect(
        await repo.missedStreak(todayIso: today, planDayTypes: planDays),
        0,
      );
    });

    test('dinlenme günü seriyi bozar, kaçırılmış sayılmaz', () async {
      final withRest = {...planDays, '2026-08-31': 'rest'};
      expect(
        await repo.missedStreak(todayIso: today, planDayTypes: withRest),
        0,
      );
    });

    test('plan kapsamayan gün sayılmaz', () async {
      // Plan bilgisi olmayan günde kaçırılan bir şey yoktur.
      expect(
        await repo.missedStreak(todayIso: today, planDayTypes: const {}),
        0,
      );
    });
  });

  group('uyku saatleri (v3.1)', () {
    test('üç alan yazılır ve okunur', () async {
      await repo.setSleepTimes(
        today,
        bedTime: '23:45',
        wakeTimeActual: '06:11',
        napMinutes: 30,
      );

      final view = await repo.readDay(today);
      expect(view.bedTime, '23:45');
      expect(view.wakeTimeActual, '06:11');
      expect(view.napMinutes, 30);
    });

    test('null yazmak alanları temizler — son yazan kazanır', () async {
      await repo.setSleepTimes(
        today,
        bedTime: '23:45',
        wakeTimeActual: '06:11',
        napMinutes: null,
      );
      await repo.setSleepTimes(
        today,
        bedTime: null,
        wakeTimeActual: null,
        napMinutes: null,
      );

      final view = await repo.readDay(today);
      expect(view.bedTime, isNull);
      expect(view.wakeTimeActual, isNull);
    });
  });

  group('his bloğu (v3.1)', () {
    test('his, belirti ve stres ayrı ayrı güncellenir', () async {
      await repo.setWellbeing(today, moodScore: 2);
      await repo.setWellbeing(today, symptoms: 'baş ağrısı');
      await repo.setWellbeing(today, stressedDay: true);

      final view = await repo.readDay(today);
      expect(view.moodScore, 2);
      expect(view.symptoms, 'baş ağrısı');
      expect(view.stressedDay, isTrue);
    });

    test('clearMood hissi bilinmeze döndürür', () async {
      await repo.setWellbeing(today, moodScore: 4);
      await repo.setWellbeing(today, clearMood: true);

      expect((await repo.readDay(today)).moodScore, isNull);
    });
  });

  group('öğün atlama (v3.1)', () {
    test('neden yazılır, null silme demektir', () async {
      await repo.setMealSkipped(
        today,
        mealKindName: 'kahvalti',
        reason: 'mesai',
      );
      await repo.setMealSkipped(today, mealKindName: 'ogle', reason: 'dışarıdaydım');

      var view = await repo.readDay(today);
      expect(view.skippedMeals, {'kahvalti': 'mesai', 'ogle': 'dışarıdaydım'});

      await repo.setMealSkipped(today, mealKindName: 'kahvalti', reason: null);
      view = await repo.readDay(today);
      expect(view.skippedMeals, {'ogle': 'dışarıdaydım'});
    });
  });
}
