import 'package:disport/features/nutrition/domain/food.dart';
import 'package:disport/features/nutrition/domain/forbidden_match.dart';
import 'package:flutter_test/flutter_test.dart';

Food food(String id, {String? nameTr, String nameEn = ''}) => Food.fromJson({
  'id': id,
  'nameEn': nameEn.isEmpty ? id : nameEn,
  'nameTr': nameTr,
  'category': 'yemek',
  'kcal100': 100.0,
  'source': 'curated',
});

void main() {
  test('etiket besin adında çift dilli katlamayla aranır', () {
    final baklava = food('baklava', nameTr: 'Baklava', nameEn: 'Baklava');
    expect(
      isForbiddenFood(food: baklava, labels: ['BAKLAVA']),
      isTrue,
      reason: 'katlama büyük/küçük harfe takılmamalı',
    );
    expect(
      isForbiddenFood(food: baklava, labels: ['şeker']),
      isFalse,
      reason: 'eşleşme ad düzeyinde — içerik bilgisi yok (kabul edilen sınır)',
    );
  });

  test('İngilizce ad da aranır — kullanıcı iki dilde de yazabilir', () {
    final cola = food('cola', nameTr: null, nameEn: 'Cola');
    expect(isForbiddenFood(food: cola, labels: ['cola']), isTrue);
  });

  test('besin id bağı ad eşleşmese de yakalar', () {
    final lahmacun = food('lahmacun', nameTr: 'Lahmacun');
    expect(
      isForbiddenFood(
        food: lahmacun,
        labels: ['hamur işi'],
        foodIds: {
          'hamur işi': ['lahmacun'],
        },
      ),
      isTrue,
    );
    // Bağ olmadan "hamur işi" lahmacunu bulamaz.
    expect(
      isForbiddenFood(food: lahmacun, labels: ['hamur işi']),
      isFalse,
    );
  });

  test('boş etiket hiçbir şeyi yasaklamaz', () {
    expect(
      isForbiddenFood(food: food('elma', nameTr: 'Elma'), labels: ['  ']),
      isFalse,
    );
  });
}
