import 'package:disport/core/utils/locale_text.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tr = Locale('tr');
  const en = Locale('en');

  group('upper', () {
    test('TR: Kilo → KİLO', () {
      // ASCII kuralı "KILO" verirdi ve bu Türkçede "kılo" okunur.
      expect(LocaleText.upper(tr, 'Kilo'), 'KİLO');
    });

    test('TR: ı → I', () {
      expect(LocaleText.upper(tr, 'ısınma'), 'ISINMA');
    });

    test('EN: kilo → KILO', () {
      // İngilizcede i'nin büyüğü noktasız I; Türkçe kural burada yanlış.
      expect(LocaleText.upper(en, 'kilo'), 'KILO');
    });

    test('EN kuralı Türkçe harfleri yine de büyütür', () {
      expect(LocaleText.upper(en, 'Şınav'), 'ŞINAV');
    });
  });

  group('fold', () {
    test('TR diakritikleri indirger', () {
      expect(LocaleText.fold(tr, 'Şınav'), 'sinav');
      expect(LocaleText.fold(tr, 'GÖĞÜS'), 'gogus');
    });

    test('ayraç atılır ama boşluk korunur', () {
      // Hareket adlarının yarısı tireli ve kimse tire yazmıyor;
      // sözcük sınırı ise bilgi taşıyor.
      expect(LocaleText.fold(tr, 'Push-Up'), 'pushup');
      expect(LocaleText.fold(tr, 'Bulgarian Split Squat'),
          'bulgarian split squat');
    });

    test('EN küçültür ve ayracı atar', () {
      expect(LocaleText.fold(en, 'Push-Up'), 'pushup');
      // Türkçe harfe dokunmuyor: İngilizce arayüzde "Şınav" aranırken
      // kullanıcı zaten o harfleri yazıyor.
      expect(LocaleText.fold(en, 'Şınav'), 'şınav');
    });
  });

  group('matchesAnyLocale', () {
    test('İngilizce sorgu Türkçe kayıtta çalışır', () {
      expect(
        LocaleText.matchesAnyLocale('pushup', 'Push-Up Şınav'),
        isTrue,
      );
    });

    test('aksansız Türkçe sorgu tutar', () {
      expect(LocaleText.matchesAnyLocale('sinav', 'Şınav'), isTrue);
    });

    test('aksanlı Türkçe sorgu da tutar', () {
      expect(LocaleText.matchesAnyLocale('şınav', 'Şınav'), isTrue);
    });

    test('alakasız sorgu tutmaz', () {
      expect(LocaleText.matchesAnyLocale('zzz', 'Şınav'), isFalse);
    });

    test('boş sorgu her şeyi geçirir', () {
      // Arama kutusu boşken liste daralmamalı.
      expect(LocaleText.matchesAnyLocale('', 'herhangi'), isTrue);
      expect(LocaleText.matchesAnyLocale('   ', 'herhangi'), isTrue);
    });
  });
}
