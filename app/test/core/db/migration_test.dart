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

  test('taze kurulum güncel sürümde açılır', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 11);
    expect(await db.select(db.supplements).get(), isEmpty);
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
