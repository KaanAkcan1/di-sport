import 'package:disport/core/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// İngilizce arayüzün duman testi.
///
/// **Neden var:** `hardcoded_text_test` yalnız Türkçe özel karakter
/// taşıyan dizgileri yakalıyor. "Plan", "Not", "Tamam" gibi ASCII
/// metinler o taramadan kaçar ve İngilizce modda Türkçe olarak kalır.
/// Buradaki ölçüt farklı: çeviri gerçekten yüklendi mi ve İngilizce
/// karşılıklar Türkçesinden farklı mı.
void main() {
  Future<AppLocalizations> loadFor(WidgetTester tester, Locale locale) async {
    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = context.l10n;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return l10n;
  }

  testWidgets('İngilizce çeviri yükleniyor', (tester) async {
    final en = await loadFor(tester, const Locale('en'));
    expect(en.tabToday, 'Today');
    expect(en.tabProgress, 'Progress');
    expect(en.settingsTitle, 'Settings');
  });

  testWidgets('Türkçe çeviri yükleniyor', (tester) async {
    final tr = await loadFor(tester, const Locale('tr'));
    expect(tr.tabToday, 'Bugün');
    expect(tr.tabProgress, 'İlerleme');
    expect(tr.settingsTitle, 'Ayarlar');
  });

  testWidgets('desteklenmeyen dil İngilizceye düşer', (tester) async {
    // Flutter eşleşme bulamayınca `supportedLocales`'in ilkini seçiyor
    // ve o İngilizce. Türkçe konuşmayan birine Türkçe göstermektense
    // İngilizce göstermek daha evrensel bir yedek — davranış bilinçli
    // olarak böyle bırakıldı, test onu sabitliyor.
    final other = await loadFor(tester, const Locale('de'));
    expect(other.tabToday, 'Today');
  });

  testWidgets('iki dil aynı metni vermiyor — çeviri gerçekten yapılmış', (
    tester,
  ) async {
    // Kopyala-yapıştır bir çeviri dosyası bu testi düşürür.
    final tr = await loadFor(tester, const Locale('tr'));
    final en = await loadFor(tester, const Locale('en'));

    final differing = [
      tr.tabToday != en.tabToday,
      tr.tabProgress != en.tabProgress,
      tr.tabHealth != en.tabHealth,
      tr.settingsTitle != en.settingsTitle,
      tr.commonSave != en.commonSave,
    ];

    expect(differing.every((d) => d), isTrue);
  });
}
