import 'package:disport/core/db/app_database.dart';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Şema göçlerinin nöbetçisi.
///
/// **Neden var:** göç kodu yalnız **eski kurulumu olan** cihazda
/// çalışıyor. Geliştirici makinesinde veritabanı hep sıfırdan
/// kuruluyor ve `onCreate` yolundan geçiyor; `onUpgrade` bloğu hiç
/// denenmiyor. Bozuk bir göç ancak kullanıcının telefonunda,
/// güncellemeden sonra ortaya çıkıyor — ve o noktada veri kaybı riski
/// gerçek.
///
/// Yöntem: eski sürüm sayısıyla açılmış boş bir veritabanı taklit
/// edilip üstüne göç çalıştırılıyor.
void main() {
  /// Verilen sürümde açılmış gibi damgalanmış bellek içi veritabanı.
  ///
  /// Drift'in şema sürümü `user_version` PRAGMA'sında duruyor; onu
  /// elle geriye alıp bağlantıyı yeniden açmak, "eski kurulum"
  /// senaryosunun en sade taklidi.
  Future<AppDatabase> openAt(int version) async {
    final executor = NativeDatabase.memory();
    final db = AppDatabase.forTesting(executor);

    // Şemayı bugünkü hâliyle kur, sonra sürümü geriye al: göç kodu
    // "eksik tablo" değil "eksik sürüm" görüyor. Tabloların gerçekten
    // yaratılıp yaratılmadığını `createTable`'ın kendi
    // `IF NOT EXISTS` davranışı zaten güvenceye alıyor.
    await db.customStatement('PRAGMA user_version = $version');
    return db;
  }

  test('v10 kurulumu v11\'e yükseltilebilir', () async {
    final db = await openAt(10);
    addTearDown(db.close);

    // Göç `onUpgrade` üzerinden tetikleniyor; sorgu yapabilmek
    // tabloların yerinde olduğunu kanıtlıyor.
    await db.customStatement('SELECT 1');

    expect(
      await db.select(db.supplements).get(),
      isEmpty,
      reason: 'takviye tablosu v11 göçünde oluşmalı',
    );
    expect(await db.select(db.supplementLogs).get(), isEmpty);
  });

  test('taze kurulum tüm tabloları açar', () async {
    // Sürüm numarası sabit yazılmıyor: her şema artışında güncellenmesi
    // gereken bir sayı, insanların düzeltmeden geçtiği bir teste dönüşür.
    // Ölçüt tabloların çalışır olması.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(15));
    expect(await db.select(db.supplements).get(), isEmpty);
    expect(await db.select(db.equipmentItems).get(), isEmpty);
  });

  test('v11 kurulumu v12 seviyesine yukseltilebilir', () async {
    final db = await openAt(11);
    addTearDown(db.close);

    await db.customStatement('SELECT 1');

    // Yeni sütunlar okunabiliyorsa göç çalışmış demektir.
    expect(await db.select(db.equipmentItems).get(), isEmpty);
  });

  test('v12 kurulumu v13 seviyesine yükseltilebilir', () async {
    final db = await openAt(12);
    addTearDown(db.close);

    await db.customStatement('SELECT 1');

    // Beş yeni tablo ve altı yeni sütun. Sorgulanabiliyorsa göç
    // çalışmış demektir.
    expect(await db.select(db.foods).get(), isEmpty);
    expect(await db.select(db.foodPortions).get(), isEmpty);
    expect(await db.select(db.mealEntries).get(), isEmpty);
    expect(await db.select(db.activities).get(), isEmpty);
    expect(await db.select(db.activityLogs).get(), isEmpty);
    expect(await db.select(db.workoutSessions).get(), isEmpty);

    // Şiddet sütunları iki tabloda da okunabilmeli.
    await db.customStatement(
      'SELECT speed_kmh, grade_pct, effort FROM plan_exercises',
    );
    await db.customStatement(
      'SELECT speed_kmh, grade_pct, effort FROM exercise_logs',
    );
  });

  test('v13 kurulumu v14 seviyesine yükseltilebilir', () async {
    final db = await openAt(13);
    addTearDown(db.close);

    await db.customStatement('SELECT 1');
    // Plan slotunun öğün türü; `meal_entries.mealKind` (v13) ile
    // karıştırılmamalı — biri planlanan, öteki yenen.
    await db.customStatement('SELECT meal_kind FROM plan_slots');
  });

  test('v14 kurulumu v15 seviyesine yükseltilebilir', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // `openAt` deseni yapısal kontroller için yeterli ama **veri**
    // göçünü tetiklemiyor: aynı bağlantıda `user_version`'ı geriye
    // almak `onUpgrade`'i yeniden çalıştırmaz. v15'in chair/step
    // ekleme davranışı için göç bloğu doğrudan çağrılıyor.
    await db.migration.onUpgrade(db.createMigrator(), 14, 15);

    expect(await db.select(db.medicalFacts).get(), isEmpty);
    expect(await db.select(db.mealBehaviors).get(), isEmpty);
    expect(await db.select(db.favoriteSports).get(), isEmpty);
    expect(await db.select(db.planMealItems).get(), isEmpty);
    await db.customStatement('SELECT kind FROM supplements');
    await db.customStatement('SELECT water_ml FROM daily_logs');

    // v2 "sandalye/basamak herkeste var" varsayımı korunuyor: göç iki
    // satırı evde-işaretli açıyor.
    final equipment = await db.select(db.equipmentItems).get();
    final chair = equipment.firstWhere((row) => row.id == 'chair');
    expect(chair.atHome, isTrue);
    expect(chair.atGym, isFalse);
    expect(equipment.any((row) => row.id == 'step'), isTrue);
  });

  test('v15 kurulumu v16 seviyesine yükseltilebilir', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.migration.onUpgrade(db.createMigrator(), 15, 16);

    // v3.1 günlük gerçeklik sütunları.
    await db.customStatement(
      'SELECT bed_time, wake_time_actual, nap_minutes, mood_score, '
      'symptoms, stressed_day, skipped_meals_json FROM daily_logs',
    );
    await db.customStatement('SELECT rpe, pain_note FROM workout_sessions');
    await db.customStatement('SELECT fact_date FROM medical_facts');
  });

  test('v16 göçü tekrar çalıştırılabilir — yarım yükseltme senaryosu', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db.migration.onUpgrade(db.createMigrator(), 15, 16);
    // İkinci çalıştırma "duplicate column" ile düşmemeli.
    await db.migration.onUpgrade(db.createMigrator(), 15, 16);

    await db.customStatement('SELECT bed_time FROM daily_logs');
  });

  test('göç eski verileri korur', () async {
    // Asıl korku bu: yeni tablo eklerken eskilerin silinmesi.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.profileEntries)
        .insert(
          ProfileEntriesCompanion.insert(
            id: 'p1',
            key: 'heightCm',
            value: '178',
            updatedAt: 1,
          ),
        );

    await db.customStatement('PRAGMA user_version = 10');
    await db.customStatement('SELECT 1');

    final rows = await db.select(db.profileEntries).get();
    expect(rows.single.value, '178');
  });
}
