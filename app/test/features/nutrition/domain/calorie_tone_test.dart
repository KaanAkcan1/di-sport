import 'package:disport/features/nutrition/domain/calorie_tone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveCalorieTone', () {
    test('hedef yoksa ton yok', () {
      // Plan içeri alınmamış kullanıcıya hedef uydurmak yanlış olurdu.
      expect(
        resolveCalorieTone(goalKcal: null, net: 1800),
        DayCalorieTone.none,
      );
    });

    test('o gün hiç kayıt yoksa ton yok — sıfır sayılmaz', () {
      // Kaydını girmemiş kullanıcıyı "bütçenin altında kaldın" diye
      // ödüllendirmek, uygulamayı kullanmamayı ödüllendirmek olurdu.
      expect(
        resolveCalorieTone(goalKcal: 2200, net: null),
        DayCalorieTone.none,
      );
    });

    test('hedefin altı under', () {
      expect(
        resolveCalorieTone(goalKcal: 2200, net: 1800),
        DayCalorieTone.under,
      );
    });

    test('hedefin üstü over', () {
      expect(
        resolveCalorieTone(goalKcal: 2200, net: 2600),
        DayCalorieTone.over,
      );
    });

    test('tam hedefte under sayılır', () {
      // Sınırda ceza vermek gereksiz: hedefi tam tutturmak başarı.
      expect(
        resolveCalorieTone(goalKcal: 2200, net: 2200),
        DayCalorieTone.under,
      );
    });

    test('sıfır ya da negatif hedef ton üretmez', () {
      // Bozuk bir plan yüzünden her günü kırmızıya boyamamalı.
      expect(resolveCalorieTone(goalKcal: 0, net: 100), DayCalorieTone.none);
    });
  });
}
