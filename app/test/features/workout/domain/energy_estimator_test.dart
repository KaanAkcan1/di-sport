import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/workout/domain/energy_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('metFor — sabit model', () {
    test('katalogun değerini olduğu gibi verir', () {
      expect(metFor(met: 5.0, model: MetModel.fixed), 5.0);
    });

    test('sabit modelde hız ve eğim yok sayılır', () {
      // Kaydın modeli sabitse girilen şiddet o hareket için anlamsız;
      // yine de hesaba katmak sessizce yanlış kalori üretirdi.
      expect(
        metFor(met: 5.0, model: MetModel.fixed, speedKmh: 12, gradePct: 10),
        5.0,
      );
    });
  });

  group('metFor — koşu bandı (ACSM)', () {
    test('5 km/sa düz yürüyüş ≈ 3.4 MET', () {
      // 83.3 m/dk × 0.1 + 3.5 = 11.83 ml/kg/dk → 3.38 MET
      expect(
        metFor(met: 0, model: MetModel.treadmill, speedKmh: 5, gradePct: 0),
        closeTo(3.4, 0.1),
      );
    });

    test('eğim MET\'i artırır', () {
      final flat = metFor(
        met: 0,
        model: MetModel.treadmill,
        speedKmh: 5,
        gradePct: 0,
      );
      final incline = metFor(
        met: 0,
        model: MetModel.treadmill,
        speedKmh: 5,
        gradePct: 10,
      );
      expect(incline, greaterThan(flat));
      // %10 eğim yürüyüşte MET'i iki katından fazlaya çıkarıyor: dikey
      // bileşenin katsayısı (1.8) yatayınkinin (0.1) 18 katı.
      expect(incline, closeTo(7.7, 0.2));
    });

    test('8 km/sa %8 eğimde koşu ≈ 11 MET', () {
      expect(
        metFor(met: 0, model: MetModel.treadmill, speedKmh: 8, gradePct: 8),
        closeTo(11, 1),
      );
    });

    test('yürüyüş → koşu geçişi 7 km/sa\'te süreksiz — bilinçli', () {
      // ACSM iki denklem arasında bir boşluk bırakıyor; enterpolasyonla
      // doldurmak dayanağı olmayan bir sayı üretmek olurdu. Test bu
      // kararı sabitliyor ki biri "hata var" sanıp düzeltmeye kalkmasın.
      final walk = metFor(
        met: 0,
        model: MetModel.treadmill,
        speedKmh: 6.9,
        gradePct: 0,
      );
      final run = metFor(
        met: 0,
        model: MetModel.treadmill,
        speedKmh: 7.0,
        gradePct: 0,
      );
      expect(run, greaterThan(walk * 1.4));
    });

    test('eğim yüzde olarak veriliyor — kesir sanılırsa 25 kat şişer', () {
      // Denklemler oran bekliyor (%8 → 0.08). Birim karışırsa sonuç
      // saçmalaşır; üst sınır bu hatayı yakalar.
      final met = metFor(
        met: 0,
        model: MetModel.treadmill,
        speedKmh: 6,
        gradePct: 8,
      );
      expect(met, lessThan(10));
    });

    test('hız girilmemişse katalogun sabit değerine düşer', () {
      // Sıfır döndürmek "hiç yakmadın" demek olurdu.
      expect(metFor(met: 4.5, model: MetModel.treadmill), 4.5);
    });
  });

  group('metFor — bisiklet', () {
    test('efor seviyesi MET verir', () {
      expect(
        metFor(met: 0, model: MetModel.cycling, effort: Effort.light),
        5.0,
      );
      expect(
        metFor(met: 0, model: MetModel.cycling, effort: Effort.moderate),
        7.0,
      );
      expect(
        metFor(met: 0, model: MetModel.cycling, effort: Effort.vigorous),
        10.5,
      );
    });

    test('efor girilmemişse katalogun sabit değerine düşer', () {
      expect(metFor(met: 6.8, model: MetModel.cycling), 6.8);
    });
  });

  group('kcalFor', () {
    test('8 MET × 100 kg × 1 saat = 800 kcal', () {
      expect(
        kcalFor(
          met: 8,
          weightKg: 100,
          duration: const Duration(hours: 1),
        ),
        closeTo(800, 1),
      );
    });

    test('yarım saat yarısını verir', () {
      expect(
        kcalFor(
          met: 8,
          weightKg: 100,
          duration: const Duration(minutes: 30),
        ),
        closeTo(400, 1),
      );
    });

    test('sıfır ve negatif süre sıfır verir', () {
      // Açık bir seansta `endedAt - startedAt` saat kaymasıyla eksiye
      // düşebiliyor; negatif kalori kullanıcıya bir şey kazandırmamalı.
      expect(kcalFor(met: 8, weightKg: 100, duration: Duration.zero), 0);
      expect(
        kcalFor(
          met: 8,
          weightKg: 100,
          duration: const Duration(minutes: -10),
        ),
        0,
      );
    });

    test('52 dakika kuvvet, 109 kg → ≈ 472 kcal', () {
      expect(
        kcalFor(
          met: strengthTrainingMet,
          weightKg: 109,
          duration: const Duration(minutes: 52),
        ),
        closeTo(472, 5),
      );
    });
  });
}
