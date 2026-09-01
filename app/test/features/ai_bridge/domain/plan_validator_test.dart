import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/plan_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ai_fixtures.dart';

void main() {
  final validator = fixtureValidator();

  /// Doğrulamayı çalıştırıp hata mesajını verir; geçerse testi düşürür.
  String errorFor(Map<String, dynamic> document) {
    final result = validator.validate(jsonEncode(document));
    if (result is! Err<ValidatedPlan>) {
      fail('Belge geçersiz sayılmalıydı ama doğrulamayı geçti.');
    }
    return result.failure.message;
  }

  group('geçerli belge', () {
    test('doğrulamayı geçer ve ham JSON korunur', () {
      final raw = validPlanJson();
      final result = validator.validate(raw);

      expect(result.isOk, isTrue);
      final validated = (result as Ok<ValidatedPlan>).value;
      expect(validated.plan.meta.title, 'Eylül Planı');
      expect(validated.dayCount, 7);
      expect(validated.daysOfType('rest'), 1);
      expect(validated.rawJson, raw);
    });
  });

  group('kapı 1 — ayrıştırma', () {
    test('bozuk JSON reddedilir ve yalnız JSON istenir', () {
      final result = validator.validate('{bozuk');
      final message = (result as Err<ValidatedPlan>).failure.message;

      expect(message, contains('JSON ayrıştırılamadı'));
      expect(message, contains('yalnızca JSON'));
    });

    test('boş metin reddedilir', () {
      expect(validator.validate('').isOk, isFalse);
    });

    test('markdown çiti ile gelen yanıt reddedilir', () {
      final result = validator.validate('```json\n{}\n```');
      expect(result.isOk, isFalse);
    });
  });

  group('kapı 2 — şema', () {
    test('eksik alan, tam yolunu söyler', () {
      final document = validPlanMap();
      (document['meta'] as Map<String, dynamic>).remove('weeks');

      final message = errorFor(document);
      expect(message, contains('meta.weeks'));
      expect(message, contains('eksik'));
    });

    test('derinlemesine eksik alan da yolunu söyler', () {
      final document = validPlanMap();
      final firstDay = (document['days'] as List)[0] as Map<String, dynamic>;
      ((firstDay['exercises'] as List)[0] as Map<String, dynamic>)
          .remove('exerciseId');

      final message = errorFor(document);
      expect(message, contains('days[0].exercises[0].exerciseId'));
    });

    test('yanlış tip bildirilir', () {
      final document = validPlanMap();
      (document['meta'] as Map<String, dynamic>)['weeks'] = 'bir';

      expect(errorFor(document), contains('tam sayı olmalı'));
    });

    test('tam sayı 3.0 olarak gelirse kabul edilir', () {
      // AI sayıları bazen ondalıklı yazıyor; kayıpsızsa sorun değil.
      final document = validPlanMap();
      (document['goals'] as Map<String, dynamic>)['dailyKcal'] = 2400.0;

      expect(validator.validate(jsonEncode(document)).isOk, isTrue);
    });

    test('geçersiz gün tipi seçenekleri listeler', () {
      final document = validPlanMap();
      ((document['days'] as List)[0] as Map<String, dynamic>)['type'] = 'tatil';

      final message = errorFor(document);
      expect(message, contains('gym | home | rest'));
    });

    test('desteklenmeyen schemaVersion reddedilir', () {
      final document = validPlanMap()..['schemaVersion'] = 99;
      expect(errorFor(document), contains('schemaVersion 99'));
    });
  });

  group('kapı 3 — anlam', () {
    test('gün sayısı hafta sayısıyla tutarsız', () {
      final document = validPlanMap();
      (document['days'] as List).removeLast();

      expect(errorFor(document), contains('7 gün bekleniyordu, 6 gün'));
    });

    test('tarihler ardışık değil', () {
      final document = validPlanMap();
      ((document['days'] as List)[2] as Map<String, dynamic>)['date'] =
          '2026-09-15';

      final message = errorFor(document);
      expect(message, contains('ardışık'));
      expect(message, contains('2026-09-02'));
    });

    test('yalnız ilk tarih kopukluğu bildirilir', () {
      final document = validPlanMap();
      for (final index in [2, 3, 4]) {
        ((document['days'] as List)[index] as Map<String, dynamic>)['date'] =
            '2026-10-0$index';
      }

      final message = errorFor(document);
      expect('ardışık'.allMatches(message).length, 1);
    });

    test('makul olmayan kalori', () {
      final document = validPlanMap();
      (document['goals'] as Map<String, dynamic>)['dailyKcal'] = 800;

      expect(errorFor(document), contains('dailyKcal'));
    });

    test('makul olmayan protein ve su birlikte bildirilir', () {
      final document = validPlanMap();
      (document['goals'] as Map<String, dynamic>)
        ..['proteinG'] = 900
        ..['waterL'] = 12;

      final message = errorFor(document);
      expect(message, contains('proteinG'));
      expect(message, contains('waterL'));
    });

    test('katalogda olmayan hareket alternatif önerir', () {
      final document = validPlanMap();
      final day = (document['days'] as List)[1] as Map<String, dynamic>;
      ((day['exercises'] as List)[0] as Map<String, dynamic>)['exerciseId'] =
          'barbell_squat';

      final message = errorFor(document);
      expect(message, contains('barbell_squat'));
      expect(message, contains('katalogda yok'));
      expect(message, contains('incline_pushup'));
      expect(message, contains('newExercises'));
    });

    test('salon hareketi ev gününde reddedilir', () {
      final document = validPlanMap();
      final homeDay = (document['days'] as List)[1] as Map<String, dynamic>;
      (homeDay['exercises'] as List).add({
        'exerciseId': 'stationary_bike',
        'sets': 1,
        'durationSec': 900,
      });

      expect(errorFor(document), contains('ev günü'));
    });

    test('her ikisinde yapılabilen hareket iki gün tipinde de geçer', () {
      final document = validPlanMap();
      final homeDay = (document['days'] as List)[1] as Map<String, dynamic>;
      (homeDay['exercises'] as List).add({
        'exerciseId': 'plank',
        'sets': 3,
        'durationSec': 30,
      });

      expect(validator.validate(jsonEncode(document)).isOk, isTrue);
    });

    test('günde iki antrenman slotu reddedilir', () {
      final document = validPlanMap();
      final day = (document['days'] as List)[0] as Map<String, dynamic>;
      (day['slots'] as List).add({
        'time': '18:00',
        'kind': 'workout',
        'label': 'İkinci antrenman',
      });

      expect(errorFor(document), contains('antrenman slotu'));
    });

    test('bozuk saat biçimi reddedilir', () {
      final document = validPlanMap();
      final day = (document['days'] as List)[0] as Map<String, dynamic>;
      ((day['slots'] as List)[0] as Map<String, dynamic>)['time'] = '6:30';

      expect(errorFor(document), contains('HH:mm'));
    });

    test('dinlenme gününe egzersiz konamaz', () {
      final document = validPlanMap();
      final restDay = (document['days'] as List)[6] as Map<String, dynamic>;
      (restDay['exercises'] as List).add({
        'exerciseId': 'incline_pushup',
        'sets': 1,
        'reps': 5,
      });

      expect(errorFor(document), contains('dinlenme günü'));
    });

    test('sets ya da tekrar/süre eksikse bildirilir', () {
      final document = validPlanMap();
      final day = (document['days'] as List)[1] as Map<String, dynamic>;
      (day['exercises'] as List)[0] = {'exerciseId': 'incline_pushup'};

      final message = errorFor(document);
      expect(message, contains('sets zorunlu'));
      expect(message, contains('reps ya da durationSec'));
    });

    test('birden çok sorun tek mesajda toplanır', () {
      // AI'a her turda tek hata bildirmek döngüyü uzatır.
      final document = validPlanMap();
      (document['goals'] as Map<String, dynamic>)['dailyKcal'] = 500;
      final restDay = (document['days'] as List)[6] as Map<String, dynamic>;
      (restDay['exercises'] as List).add({
        'exerciseId': 'incline_pushup',
        'sets': 1,
        'reps': 5,
      });

      final message = errorFor(document);
      expect(message, contains('dailyKcal'));
      expect(message, contains('dinlenme günü'));
      expect('•'.allMatches(message).length, greaterThanOrEqualTo(2));
    });
  });

  group('newExercises çıtası', () {
    Map<String, dynamic> withNewExercise(
      Map<String, dynamic> Function(Map<String, dynamic>) mutate,
    ) {
      final document = validPlanMap();
      (document['newExercises'] as List).add(mutate(validNewExercise()));
      return document;
    }

    test('çıtayı geçen kayıt kabul edilir', () {
      final document = withNewExercise((e) => e);
      expect(validator.validate(jsonEncode(document)).isOk, isTrue);
    });

    test('yeni hareket aynı belgede kullanılabilir', () {
      final document = withNewExercise((e) => e);
      final day = (document['days'] as List)[1] as Map<String, dynamic>;
      (day['exercises'] as List).add({
        'exerciseId': 'custom_burpee',
        'sets': 3,
        'reps': 8,
      });

      expect(validator.validate(jsonEncode(document)).isOk, isTrue);
    });

    test('üç adımdan az anlatım reddedilir', () {
      final document = withNewExercise(
        (e) => e..['execution'] = ['tek adım'],
      );
      expect(errorFor(document), contains('execution en az 3 adım'));
    });

    test('iki hata kaydından az reddedilir', () {
      final document = withNewExercise(
        (e) => e
          ..['commonMistakes'] = [
            {'mistake': 'm', 'why': 'w', 'fix': 'f'},
          ],
      );
      expect(errorFor(document), contains('commonMistakes en az 2'));
    });

    test('eksik alanlı hata kaydı reddedilir', () {
      final document = withNewExercise(
        (e) => e
          ..['commonMistakes'] = [
            {'mistake': 'm', 'why': 'w', 'fix': ''},
            {'mistake': 'm2', 'why': 'w2', 'fix': 'f2'},
          ],
      );
      expect(errorFor(document), contains('mistake/why/fix'));
    });

    test('boş ekipman listesi yönlendirmeli hata verir', () {
      final document = withNewExercise((e) => e..['equipment'] = <String>[]);
      expect(errorFor(document), contains('equipment'));
    });

    test('boş güvenlik notu reddedilir', () {
      final document = withNewExercise((e) => e..['safety'] = '');
      expect(errorFor(document), contains('safety'));
    });

    test('katalogda zaten var olan id reddedilir', () {
      final document = withNewExercise((e) => e..['id'] = 'plank');
      expect(errorFor(document), contains('katalogda zaten var'));
    });

    test('geçersiz kategori alan adıyla bildirilir', () {
      final document = withNewExercise((e) => e..['category'] = 'yoga');
      expect(errorFor(document), contains('category'));
    });

    test('birden çok kayıttan yalnız bozuk olan bildirilir', () {
      final document = validPlanMap();
      (document['newExercises'] as List)
        ..add(validNewExercise(id: 'custom_iyi'))
        ..add(validNewExercise(id: 'custom_kotu')..['execution'] = ['bir']);

      final message = errorFor(document);
      expect(message, contains('custom_kotu'));
      expect(message, isNot(contains('custom_iyi')));
    });
  });
}
