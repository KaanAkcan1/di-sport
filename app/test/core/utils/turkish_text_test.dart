import 'package:disport/core/utils/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurkishText.fold', () {
    test('Türkçe harfleri ASCII karşılığına indirger', () {
      expect(TurkishText.fold('Eğimli Şınav'), 'egimli sinav');
      expect(TurkishText.fold('Kuş–Köpek'), 'kus–kopek');
      expect(TurkishText.fold('Göğüs'), 'gogus');
      expect(TurkishText.fold('Sağlık'), 'saglik');
    });

    test('noktalı ve noktasız i aynı harfe düşer', () {
      // Asıl mesele bu: Dart'ın toLowerCase()'i 'I'yı 'i' yapar,
      // Türkçede ise 'ı' olmalıdır. İkisini de 'i'de birleştirerek
      // hangi yönden yazılırsa yazılsın eşleşme sağlanır.
      expect(TurkishText.fold('ŞINAV'), TurkishText.fold('Şınav'));
      expect(TurkishText.fold('İLERLEME'), TurkishText.fold('ilerleme'));
      expect(TurkishText.fold('IĞDIR'), 'igdir');
    });

    test('aksansız yazım da eşleşir', () {
      // Kullanıcı klavye düzeniyle uğraşmadan arayabilmeli.
      expect(TurkishText.fold('sinav'), TurkishText.fold('Şınav'));
      expect(TurkishText.fold('kalca'), TurkishText.fold('Kalça'));
    });

    test('ASCII metni bozmaz', () {
      expect(TurkishText.fold('Incline Push-Up'), 'incline push-up');
      expect(TurkishText.fold('Plank'), 'plank');
    });

    test('boş metin ve rakamlar', () {
      expect(TurkishText.fold(''), '');
      expect(TurkishText.fold('3 × 10'), '3 × 10');
    });
  });

  group('upper', () {
    test('i büyürken noktasını korur', () {
      // Dart'ın toUpperCase()'i "KILO" verir; Türkçede bu "kılo"
      // okunur, başka bir sözcük. İstatistik etiketlerinde görüldü.
      expect(TurkishText.upper('Kilo'), 'KİLO');
      expect(TurkishText.upper('ilerleme'), 'İLERLEME');
    });

    test('ı büyürken noktasız kalır', () {
      expect(TurkishText.upper('ışık'), 'IŞIK');
      expect(TurkishText.upper('sağlık'), 'SAĞLIK');
    });

    test('diğer Türkçe harfler doğru büyür', () {
      expect(TurkishText.upper('çğöşü'), 'ÇĞÖŞÜ');
    });

    test('zaten büyük olan metni bozmaz', () {
      expect(TurkishText.upper('KİLO'), 'KİLO');
    });

    test('boş metin boş döner', () {
      expect(TurkishText.upper(''), '');
    });
  });
}
