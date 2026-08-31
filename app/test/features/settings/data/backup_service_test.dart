import 'dart:io';

import 'package:disport/features/settings/data/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late File database;
  late BackupService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('disport-backup-test');
    database = File(p.join(root.path, 'disport.sqlite'))
      ..writeAsStringSync('ORİJİNAL');
    service = BackupService(databaseFile: () async => database);
  });

  tearDown(() => root.delete(recursive: true));

  group('dışa aktarma', () {
    test('veritabanının kopyasını tarihli adla yazar', () async {
      final backup = await service.exportTo(root, now: DateTime(2026, 9, 3));

      expect(p.basename(backup.path), 'disport-yedek-20260903.db');
      expect(backup.readAsStringSync(), 'ORİJİNAL');
    });

    test('aynı gün ikinci yedek öncekini ezmez', () async {
      final first = await service.exportTo(root, now: DateTime(2026, 9, 3));
      database.writeAsStringSync('DEĞİŞTİ');
      final second = await service.exportTo(root, now: DateTime(2026, 9, 3));

      expect(second.path, isNot(first.path));
      expect(first.readAsStringSync(), 'ORİJİNAL');
      expect(second.readAsStringSync(), 'DEĞİŞTİ');
    });
  });

  group('içe aktarma', () {
    test('yedek geri yüklenir ve öncesi saklanır', () async {
      final backup = await service.exportTo(root, now: DateTime(2026, 9, 3));
      database.writeAsStringSync('BOZULDU');

      await service.importFrom(backup);

      expect(database.readAsStringSync(), 'ORİJİNAL');

      // Geri dönüş yolu: içe aktarma öncesi hâl yanına kopyalanmış.
      final safety = File('${database.path}.pre-import');
      expect(safety.existsSync(), isTrue);
      expect(safety.readAsStringSync(), 'BOZULDU');
    });

    test('ikinci içe aktarma güvenlik kopyasını tazeler', () async {
      final backup = await service.exportTo(root, now: DateTime(2026, 9, 3));

      database.writeAsStringSync('BİRİNCİ');
      await service.importFrom(backup);
      database.writeAsStringSync('İKİNCİ');
      await service.importFrom(backup);

      expect(
        File('${database.path}.pre-import').readAsStringSync(),
        'İKİNCİ',
      );
    });

    test('var olmayan dosya reddedilir, veritabanına dokunulmaz', () async {
      final missing = File(p.join(root.path, 'yok.db'));

      await expectLater(
        service.importFrom(missing),
        throwsA(isA<BackupException>()),
      );
      expect(database.readAsStringSync(), 'ORİJİNAL');
    });

    test('boş dosya reddedilir', () async {
      // Sıfır baytlık bir dosya geçerli SQLite değildir; üstüne
      // yazmak kullanıcının tüm verisini sessizce siler.
      final empty = File(p.join(root.path, 'bos.db'))..writeAsStringSync('');

      await expectLater(
        service.importFrom(empty),
        throwsA(isA<BackupException>()),
      );
      expect(database.readAsStringSync(), 'ORİJİNAL');
    });
  });
}
