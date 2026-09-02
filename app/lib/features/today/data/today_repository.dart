import 'dart:convert';

import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/today/data/daily_rule_table.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Bir günün kayıt durumu.
///
/// Veritabanında satır olmasa da geçerli bir görünüm döner: kullanıcı
/// henüz hiçbir şey işaretlememişse "kayıt yok" değil "hepsi boş"
/// durumu doğrudur.
class DailyLogView {
  const DailyLogView({
    this.checkedSlotIds = const {},
    this.checkedRuleIds = const {},
    this.workoutDone = false,
    this.waterTargetMet = false,
    this.noAlcoholSugar = false,
    this.waterMl,
    this.note = '',
    this.bedTime,
    this.wakeTimeActual,
    this.napMinutes,
    this.moodScore,
    this.symptoms = '',
    this.stressedDay = false,
    this.skippedMeals = const {},
  });

  final Set<String> checkedSlotIds;

  /// Kullanıcının kendi eklediği kurallardan işaretli olanlar.
  /// Yerleşik üçü burada değil, aşağıdaki bayraklarda.
  final Set<String> checkedRuleIds;

  final bool workoutDone;
  final bool waterTargetMet;
  final bool noAlcoholSugar;

  /// İçilen su (v3 §5.1). null = hiç girilmemiş; 0'dan farklı bir şey
  /// söyler ("bugün takip etmedim" ≠ "hiç içmedim").
  final int? waterMl;

  final String note;

  /// Uyku gerçeği (v3.1 §2): önceki gece yatış, sabah kalkış, kestirme.
  final String? bedTime;
  final String? wakeTimeActual;
  final int? napMinutes;

  /// His bloğu (v3.1 §3): 1-5 his, belirti notu, yoğun gün işareti.
  final int? moodScore;
  final String symptoms;
  final bool stressedDay;

  /// Atlanan öğünler: `MealKind.name` → neden (v3.1 §5).
  final Map<String, String> skippedMeals;

  bool isSlotChecked(String slotId) => checkedSlotIds.contains(slotId);

  /// Kural işaretli mi — yerleşik ve özel kurallar için tek soru.
  ///
  /// Yerleşiklerin işaretleri kendi sütunlarında duruyor (haftalık
  /// özet ve alarmlar onları okuyor); özel kurallar JSON dizisinde.
  /// Çağıran tarafın bu ayrımı bilmesi gerekmiyor.
  bool isRuleChecked(String ruleId) => switch (ruleId) {
    BuiltInRules.water => waterTargetMet,
    BuiltInRules.noAlcoholSugar => noAlcoholSugar,
    BuiltInRules.workout => workoutDone,
    _ => checkedRuleIds.contains(ruleId),
  };

  /// Günün üç yerleşik kutucuğundan kaçı işaretli.
  int get flagsMet =>
      (workoutDone ? 1 : 0) +
      (waterTargetMet ? 1 : 0) +
      (noAlcoholSugar ? 1 : 0);

  /// Verilen kural listesinden kaçı işaretli — kart başlığındaki sayaç.
  int metAmong(Iterable<String> ruleIds) =>
      ruleIds.where(isRuleChecked).length;

  bool get isEmpty =>
      checkedSlotIds.isEmpty &&
      checkedRuleIds.isEmpty &&
      flagsMet == 0 &&
      note.isEmpty;
}

/// Günlük kayıtlara erişim.
class TodayRepository {
  TodayRepository(this._db);

  final AppDatabase _db;

  Stream<DailyLogView> watchDay(String isoDate) {
    final query = _db.select(_db.dailyLogs)
      ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull());

    return query.watchSingleOrNull().map(_toView);
  }

  Future<DailyLogView> readDay(String isoDate) async {
    final row =
        await (_db.select(_db.dailyLogs)
              ..where((t) => t.date.equals(isoDate) & t.deletedAt.isNull()))
            .getSingleOrNull();
    return _toView(row);
  }

  /// Belirtilen aralıktaki günlük kayıtlar.
  ///
  /// M4'te `context.md`'nin uyum bloğu ve M5'te haftalık özet bunu
  /// kullanacak; gün gün sorgu atmak yerine tek seferde okunur.
  Future<Map<String, DailyLogView>> rowsBetween(
    String fromIso,
    String toIso,
  ) async {
    final rows =
        await (_db.select(_db.dailyLogs)..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(fromIso) &
                  t.date.isSmallerOrEqualValue(toIso) &
                  t.deletedAt.isNull(),
            ))
            .get();
    return {for (final row in rows) row.date: _toView(row)};
  }

  /// [rowsBetween]'in akış hâli.
  ///
  /// İlerleme ekranının haftalık kartları bunu dinliyor: kullanıcı
  /// Bugün'de "antrenman yapıldı" kutucuğunu işaretlediğinde sayaç
  /// beklemeden güncellenmeli.
  Stream<Map<String, DailyLogView>> watchBetween(String fromIso, String toIso) {
    final query = _db.select(_db.dailyLogs)
      ..where(
        (t) =>
            t.date.isBiggerOrEqualValue(fromIso) &
            t.date.isSmallerOrEqualValue(toIso) &
            t.deletedAt.isNull(),
      );

    return query.watch().map(
      (rows) => {for (final row in rows) row.date: _toView(row)},
    );
  }

  /// Slot işaretini tersine çevirir.
  Future<void> toggleSlot(String isoDate, String slotId) async {
    final row = await _ensureRow(isoDate);
    final ids = (jsonDecode(row.checkedSlotsJson) as List)
        .cast<String>()
        .toSet();

    if (!ids.add(slotId)) ids.remove(slotId);

    await _write(
      isoDate,
      DailyLogsCompanion(checkedSlotsJson: Value(jsonEncode(ids.toList()))),
    );
  }

  /// Suyu miktar olarak yazar; kutucuğu miktardan türetir (v3 §5.1).
  ///
  /// `waterTargetMet` sütunu kalıyor — kaçak serisi ve eski okuyucular
  /// bozulmasın — ama artık her yazımda `waterMl >= hedef`ten
  /// güncelleniyor. İki kaynak çelişemez.
  Future<void> setWaterMl(
    String isoDate,
    int? ml, {
    required int targetMl,
  }) async {
    await _ensureRow(isoDate);
    await _write(
      isoDate,
      DailyLogsCompanion(
        waterMl: Value(ml),
        waterTargetMet: Value(ml != null && ml >= targetMl),
      ),
    );
  }

  /// Kural işaretini tersine çevirir — yerleşik ya da özel.
  ///
  /// Çağıran taraf ayrımı bilmiyor: yerleşik kurallar kendi sütununa,
  /// özel kurallar JSON dizisine yazılıyor.
  ///
  /// [waterTargetMl] yalnız su kuralında anlamlı: kutucuk elle
  /// işaretlenirse miktar hedefe eşitlenir (eski alışkanlık bozulmaz),
  /// işaret kaldırılırsa miktar sıfırlanmaz, bilinmeze döner.
  Future<void> toggleRule(
    String isoDate,
    String ruleId, {
    int waterTargetMl = 3000,
  }) async {
    final row = await _ensureRow(isoDate);

    switch (ruleId) {
      case BuiltInRules.water:
        if (row.waterTargetMet) {
          await setWaterMl(isoDate, null, targetMl: waterTargetMl);
        } else {
          await setWaterMl(isoDate, waterTargetMl, targetMl: waterTargetMl);
        }
      case BuiltInRules.noAlcoholSugar:
        await setFlags(isoDate, noAlcoholSugar: !row.noAlcoholSugar);
      case BuiltInRules.workout:
        await setFlags(isoDate, workoutDone: !row.workoutDone);
      default:
        final ids = (jsonDecode(row.checkedRulesJson) as List)
            .cast<String>()
            .toSet();
        if (!ids.add(ruleId)) ids.remove(ruleId);

        await _write(
          isoDate,
          DailyLogsCompanion(checkedRulesJson: Value(jsonEncode(ids.toList()))),
        );
    }
  }

  /// Yalnız verilen bayrakları günceller; verilmeyenlere dokunmaz.
  Future<void> setFlags(
    String isoDate, {
    bool? workoutDone,
    bool? waterTargetMet,
    bool? noAlcoholSugar,
  }) async {
    await _ensureRow(isoDate);
    await _write(
      isoDate,
      DailyLogsCompanion(
        workoutDone: workoutDone == null
            ? const Value.absent()
            : Value(workoutDone),
        waterTargetMet: waterTargetMet == null
            ? const Value.absent()
            : Value(waterTargetMet),
        noAlcoholSugar: noAlcoholSugar == null
            ? const Value.absent()
            : Value(noAlcoholSugar),
      ),
    );
  }

  Future<void> setNote(String isoDate, String note) async {
    await _ensureRow(isoDate);
    await _write(isoDate, DailyLogsCompanion(note: Value(note)));
  }

  /// Uyku saatlerini yazar — üçü birden, kısmi değil.
  ///
  /// "Son yazan kazanır" kuralının (spec v3.1 §2.2) yazım yarısı:
  /// çağıran taraf alanların son hâlini verir, silme null ile yazılır.
  /// Türetilmiş `sleepHours` kaydını `body_metrics`'e yazmak çağıranın
  /// (uygulama katmanındaki tek koordinatörün) işi — iki depo tek
  /// metottan güncellenirse `today`, `health`'in data katmanına bağlanır.
  Future<void> setSleepTimes(
    String isoDate, {
    required String? bedTime,
    required String? wakeTimeActual,
    required int? napMinutes,
  }) async {
    await _ensureRow(isoDate);
    await _write(
      isoDate,
      DailyLogsCompanion(
        bedTime: Value(bedTime),
        wakeTimeActual: Value(wakeTimeActual),
        napMinutes: Value(napMinutes),
      ),
    );
  }

  /// His bloğu — yalnız verilen alanlar güncellenir ([setFlags] kalıbı).
  Future<void> setWellbeing(
    String isoDate, {
    int? moodScore,
    bool clearMood = false,
    String? symptoms,
    bool? stressedDay,
  }) async {
    await _ensureRow(isoDate);
    await _write(
      isoDate,
      DailyLogsCompanion(
        moodScore: clearMood
            ? const Value(null)
            : (moodScore == null ? const Value.absent() : Value(moodScore)),
        symptoms: symptoms == null ? const Value.absent() : Value(symptoms),
        stressedDay: stressedDay == null
            ? const Value.absent()
            : Value(stressedDay),
      ),
    );
  }

  /// Öğün atlama işareti — [reason] null ise işaret silinir.
  ///
  /// Sahibi `today` ama çağıranı `nutrition` (v3.1 §5): atlamayı koyan
  /// da kaldıran da öğün akışı.
  Future<void> setMealSkipped(
    String isoDate, {
    required String mealKindName,
    required String? reason,
  }) async {
    final row = await _ensureRow(isoDate);
    final skipped = (jsonDecode(row.skippedMealsJson) as Map)
        .cast<String, String>();

    if (reason == null) {
      skipped.remove(mealKindName);
    } else {
      skipped[mealKindName] = reason;
    }

    await _write(
      isoDate,
      DailyLogsCompanion(skippedMealsJson: Value(jsonEncode(skipped))),
    );
  }

  /// Antrenman kaçırılan ardışık gün sayısı.
  ///
  /// PDF'in "iki gün üst üste kaçırma — kural bu" satırının karşılığı.
  /// M5'te alarm bunu okuyacak; Bugün ekranı da uyarı gösterir.
  ///
  /// [planDayTypes] gün → tip eşlemesi. Dinlenme günü kaçırılmış
  /// sayılmaz; plan bilgisi olmayan gün de sayılmaz — kullanıcı henüz
  /// plan almamışsa kaçırdığı bir şey yoktur.
  Future<int> missedStreak({
    required String todayIso,
    required Map<String, String> planDayTypes,
    int lookback = 14,
  }) async {
    final today = DateTime.parse(todayIso);
    final logs = await rowsBetween(
      _iso(today.subtract(Duration(days: lookback))),
      todayIso,
    );

    var streak = 0;
    // Bugünü saymıyoruz: gün henüz bitmedi, antrenman yapılabilir.
    for (var back = 1; back <= lookback; back++) {
      final iso = _iso(today.subtract(Duration(days: back)));
      final type = planDayTypes[iso];
      if (type == null || type == 'rest') break;
      if (logs[iso]?.workoutDone ?? false) break;
      streak++;
    }
    return streak;
  }

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DailyLogView _toView(DailyLogRow? row) {
    if (row == null) return const DailyLogView();
    return DailyLogView(
      checkedSlotIds: (jsonDecode(row.checkedSlotsJson) as List)
          .cast<String>()
          .toSet(),
      checkedRuleIds: (jsonDecode(row.checkedRulesJson) as List)
          .cast<String>()
          .toSet(),
      workoutDone: row.workoutDone,
      waterTargetMet: row.waterTargetMet,
      noAlcoholSugar: row.noAlcoholSugar,
      waterMl: row.waterMl,
      note: row.note,
      bedTime: row.bedTime,
      wakeTimeActual: row.wakeTimeActual,
      napMinutes: row.napMinutes,
      moodScore: row.moodScore,
      symptoms: row.symptoms,
      stressedDay: row.stressedDay,
      skippedMeals: (jsonDecode(row.skippedMealsJson) as Map)
          .cast<String, String>(),
    );
  }

  Future<void> _write(String isoDate, DailyLogsCompanion values) =>
      (_db.update(_db.dailyLogs)..where((t) => t.date.equals(isoDate))).write(
        values.copyWith(
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  /// O güne ait satırı garanti eder. Kullanıcı bir kutucuğa dokunana
  /// kadar satır yaratılmaz; boş günler veritabanını şişirmemeli.
  Future<DailyLogRow> _ensureRow(String isoDate) async {
    final existing =
        await (_db.select(_db.dailyLogs)
              ..where((t) => t.date.equals(isoDate)))
            .getSingleOrNull();
    if (existing != null) return existing;

    await _db
        .into(_db.dailyLogs)
        .insert(
          DailyLogsCompanion.insert(
            id: const Uuid().v4(),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            date: isoDate,
          ),
        );

    return (_db.select(_db.dailyLogs)..where((t) => t.date.equals(isoDate)))
        .getSingle();
  }
}
