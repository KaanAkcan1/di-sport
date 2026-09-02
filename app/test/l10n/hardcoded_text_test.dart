import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Arayüzde ARB'ye taşınmamış metin kalmadığının nöbetçisi.
///
/// **Neden var:** çeviriyi unutmak sessiz bir hata. Yeni bir ekran
/// yazılırken metni doğrudan gömmek en kolay yol ve derleme buna
/// itiraz etmiyor; uygulama İngilizce moda alındığında o satır Türkçe
/// kalıyor ve bunu ancak kullanıcı fark ediyor.
///
/// Kaba bir tarama: yalnız **Türkçe özel karakter** taşıyan dizgileri
/// yakalar. "Plan", "Not", "Tamam" gibi ASCII metinler kaçar — onların
/// güvencesi `english_smoke_test.dart`.
/// Geliştiriciye giden metin üreten çağrılar.
final _developerFacing = RegExp(
  r'\bassert\(|debugPrint\(|throw\s|ArgumentError|StateError|'
  r'FormatException|UnsupportedError|reason:',
);

void main() {
  /// Tarama kökleri: kullanıcıya bir şey gösteren her yer.
  const roots = ['lib/features', 'lib/core/widgets', 'lib/app'];

  /// Bu yollar bilinçli olarak Türkçe kalıyor.
  bool isExempt(String path) {
    final normalised = path.replaceAll(r'\', '/');
    return
        // AI köprüsünün domain katmanı: `context.md` ve doğrulayıcı
        // hata mesajları AI'a gidiyor, kullanıcıya değil. Hata metni
        // "AI'a geri yapıştırılabilir" olsun diye yazıldı (spec §3.1).
        normalised.contains('/ai_bridge/domain/') ||
        // Türkçe dil kurallarını uygulayan yardımcılar: içlerindeki
        // harfler metin değil, algoritmanın kendisi.
        normalised.endsWith('turkish_text.dart') ||
        normalised.endsWith('turkish_date.dart') ||
        normalised.endsWith('turkish_number.dart') ||
        normalised.endsWith('locale_text.dart') ||
        // Tohum verisi: yerleşik kural/ölçüm/ekipman adları veritabanına
        // yazılıyor ve kullanıcı onları yeniden adlandırabiliyor. Veri,
        // arayüz metni değil (M6 "kullanıcı tanımlı veri" kalıbı).
        normalised.contains('_repository.dart') ||
        normalised.contains('/data/') ||
        normalised.contains('sample_plan.dart') ||
        // Üretilen dosyalar.
        normalised.endsWith('.g.dart');
  }

  test('arayüzde ARB\'ye taşınmamış Türkçe metin kalmadı', () {
    // Tek ya da çift tırnak içinde, Türkçe özel karakter taşıyan dizgi.
    final literal = RegExp('''['"]([^'"\\n]*[çğıöşüÇĞİÖŞÜ][^'"\\n]*)['"]''');

    final offenders = <String>[];

    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;

      for (final file in dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !isExempt(f.path))) {
        final lines = file.readAsLinesSync();

        for (final (index, line) in lines.indexed) {
          final trimmed = line.trimLeft();

          // Yalnız **satır başındaki** yorum muaf. Eskiden satırın
          // herhangi bir yerinde `//` görünce tüm satır atlanıyordu ve
          // satır sonu yorumu taşıyan gömülü metinler sessizce kaçıyordu.
          if (trimmed.startsWith('//')) continue;
          if (trimmed.startsWith('///')) continue;
          // İşaret satırın kendisinde ya da hemen üstündeki yorumda
          // olabilir; Dart'ta gerekçe yorumu üste yazılır.
          if (line.contains('l10n-exempt')) continue;
          if (index > 0 && lines[index - 1].contains('l10n-exempt')) continue;
          if (index > 1 && lines[index - 2].contains('l10n-exempt')) continue;

          // Geliştiriciye giden metinler kullanıcı arayüzü değil:
          // `assert` mesajı, `debugPrint`, fırlatılan hata. Bunları
          // çevirmek gürültü olur — kimse `ArgumentError` metnini
          // İngilizce okumak zorunda kalmaz, çünkü onu yalnız
          // geliştirici görür.
          if (_developerFacing.hasMatch(line)) continue;

          if (literal.hasMatch(line)) {
            offenders.add('${file.path}:${index + 1}  ${trimmed.trim()}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'ARB\'ye taşınmamış ${offenders.length} metin '
          '(bilinçliyse satıra `// l10n-exempt` ekle):\n'
          '${offenders.take(40).join('\n')}',
    );
  });
}
