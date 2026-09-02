import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Yedekleme işlemi başarısız oldu.
///
/// Ayrı bir tip: ekran bunu kullanıcıya okunabilir bir mesaj olarak
/// gösteriyor, `FileSystemException`'ın ham metnini değil.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Veritabanı dosyasının kopyalanmasıyla yedek alma ve geri yükleme.
///
/// **Neden dosya kopyası, JSON dışa aktarma değil:** yedeğin amacı
/// cihaz değiştiğinde ya da veri bozulduğunda **tam** geri dönüş.
/// JSON'a çevirmek her yeni tablo eklendiğinde güncellenmesi gereken
/// ikinci bir şema demek olurdu; unutulan bir tablo sessizce kaybolurdu.
/// Dosya kopyası şemadan bağımsız ve eksiksiz.
///
/// Karşılığında dosya taşınabilir değil (yalnız bu uygulama okur) —
/// kabul edilen bir ödünç, çünkü yedeğin okuyucusu zaten uygulama.
class BackupService {
  const BackupService({Future<File> Function()? databaseFile})
    : _databaseFile = databaseFile ?? _defaultDatabaseFile;

  /// Testlerde geçici bir dosyayla değiştirilebilsin diye enjekte
  /// ediliyor; üretimde `getApplicationDocumentsDirectory` altındaki
  /// Drift dosyası.
  final Future<File> Function() _databaseFile;

  static Future<File> _defaultDatabaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'disport.sqlite'));
  }

  Future<File> databaseFile() => _databaseFile();

  /// Veritabanının kopyasını [directory] altına yazar.
  ///
  /// Ad tarihli: kullanıcı klasöründe hangi yedeğin ne zaman
  /// alındığını dosya adından görmeli. Aynı gün ikinci yedek numaralı
  /// bir sonek alıyor — eskisinin üstüne yazmak, yeni yedek bozuksa
  /// geri dönüşü de yok ederdi.
  Future<File> exportTo(Directory directory, {DateTime? now}) async {
    final source = await _databaseFile();
    if (!source.existsSync()) {
      throw const BackupException('Veritabanı dosyası bulunamadı.');
    }

    final stamp = _stamp(now ?? DateTime.now());
    var target = File(p.join(directory.path, 'disport-yedek-$stamp.db'));
    for (var index = 2; target.existsSync(); index++) {
      target = File(p.join(directory.path, 'disport-yedek-$stamp-$index.db'));
    }

    return source.copy(target.path);
  }

  /// Yedeği veritabanının üstüne yazar.
  ///
  /// Üstüne yazmadan önce mevcut hâl `.pre-import` olarak saklanıyor:
  /// kullanıcı yanlış dosyayı seçtiyse geri dönüşü olmalı. Bu kopya
  /// olmadan işlem tek yönlü ve veri kaybı kalıcı olurdu.
  ///
  /// **Çağıran taraf onay diyaloğu göstermekle yükümlü** — bu yöntem
  /// sorgusuz üzerine yazar.
  Future<void> importFrom(File backup) async {
    if (!backup.existsSync()) {
      throw const BackupException('Seçilen dosya bulunamadı.');
    }
    // Sıfır bayt geçerli SQLite değil; üstüne yazmak tüm veriyi
    // sessizce silmek olurdu.
    if (await backup.length() == 0) {
      throw const BackupException('Seçilen dosya boş, yedek değil.');
    }

    final target = await _databaseFile();
    if (target.existsSync()) {
      await target.copy('${target.path}.pre-import');
    }

    await backup.copy(target.path);
  }

  /// İçe aktarma öncesi güvenlik kopyası varsa geri alır.
  Future<bool> undoImport() async {
    final target = await _databaseFile();
    final safety = File('${target.path}.pre-import');
    if (!safety.existsSync()) return false;

    await safety.copy(target.path);
    return true;
  }

  static String _stamp(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';
}
