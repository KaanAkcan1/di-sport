import 'dart:convert';
import 'dart:io';

import 'package:disport/features/nutrition/domain/food.dart';
import 'package:flutter_test/flutter_test.dart';

/// Besin tohumunun sözleşmesi (spec §5.1).
///
/// Bu dosya elle yazılmıyor, `tools/build_foods.py` üretiyor. Test
/// üretilen dosyanın uygulamada çalışabilir olduğunu doğruluyor —
/// boru hattının kendi `--check` modu ise dosyanın boru hattıyla
/// uyumlu kaldığını.
void main() {
  late Map<String, dynamic> doc;
  late List<Map<String, dynamic>> foods;

  setUpAll(() {
    final raw = File('assets/foods.json').readAsStringSync();
    doc = jsonDecode(raw) as Map<String, dynamic>;
    foods = (doc['foods'] as List).cast<Map<String, dynamic>>();
  });

  /// Atwater kontrolünden muaf kayıtlar ve nedenleri.
  ///
  /// **Alkol:** etanol gram başına 7 kcal veriyor ve 4/4/9 üçlüsünde
  /// karşılığı yok.
  ///
  /// **Çok lifli kayıtlar:** USDA karbonhidratı "farkla" hesaplıyor ve
  /// life de dahil ediyor; lif ise gram başına ~2 kcal veriyor, 4
  /// değil. Yulaf kepeğinin %15'i lif — denklem kaçınılmaz olarak
  /// şişiyor. Eşiği herkes için gevşetmek yerine bunları adlarıyla
  /// muaf tutmak, gerçek bir yazım hatasının elenmesini önlüyor.
  const atwaterExempt = {
    'bira',
    'sarap_kirmizi',
    'raki',
    'oat_bran_raw',
    'baobab_powder',
    'carob_flour',
  };

  test('tohum sürümü tanımlı ve pozitif', () {
    expect(doc['version'], isA<int>());
    expect(doc['version'] as int, greaterThan(0));
  });

  test('kapsama tabanı', () {
    // Sayı değil kapsamanın vekili: bunun altına düşmek bir besin
    // türünün tamamen düştüğü anlamına gelir.
    expect(foods.length, greaterThanOrEqualTo(350));
  });

  test('her kayıt modele çözülür', () {
    final parsed = [for (final food in foods) Food.fromJson(food)];
    expect(parsed, hasLength(foods.length));
  });

  test('id\'ler benzersiz ve snake_case', () {
    final ids = [for (final food in foods) food['id'] as String];
    expect(ids.toSet().length, ids.length, reason: 'yinelenen id');
    for (final id in ids) {
      expect(
        RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id),
        isTrue,
        reason: '$id snake_case değil',
      );
    }
  });

  test('besin değerleri makul aralıkta', () {
    for (final food in foods) {
      final id = food['id'];

      // Sıfır geçerli: şekersiz kola ve maden suyu gerçekten sıfır.
      // Üst sınır saf yağ (~900).
      expect(
        food['kcal100'],
        allOf(greaterThanOrEqualTo(0), lessThanOrEqualTo(900)),
        reason: '$id: kcal100 aralık dışı',
      );

      for (final field in ['protein100', 'carb100', 'fat100']) {
        expect(
          food[field],
          allOf(greaterThanOrEqualTo(0), lessThanOrEqualTo(100)),
          reason: '$id: $field aralık dışı',
        );
      }
    }
  });

  test('kalori makrolarla tutarlı — Atwater', () {
    // kJ/kcal karışmasını ve kayan virgülü yakalar: 250 kalorilik bir
    // yemeğin 25 yazılması günlük toplamı sessizce bozar.
    //
    // Ölçüt hem oransal hem mutlak: 26 kcal'lik bir sebzede 6 kcal fark
    // %23 ama kimseyi ilgilendirmez.
    for (final food in foods) {
      final id = food['id'] as String;
      if (atwaterExempt.contains(id)) continue;

      final kcal = (food['kcal100'] as num).toDouble();
      if (kcal < 10) continue;

      final estimate =
          4 * (food['protein100'] as num) +
          4 * (food['carb100'] as num) +
          9 * (food['fat100'] as num);
      final difference = (estimate - kcal).abs();

      final inconsistent = difference / kcal > 0.25 && difference > 25;
      expect(
        inconsistent,
        isFalse,
        reason: '$id: kcal=$kcal ama makrolar ${estimate.round()} diyor',
      );
    }
  });

  test('küratörlü kayıtta ev ölçüsü porsiyonu var', () {
    // "1 kase" olmadan kullanıcı gram tahmin etmek zorunda kalır ve
    // kaydı hiç girmez. USDA ham besinlerinde 100 gram varsayılanı
    // yeterli — elma zaten gramla düşünülüyor.
    for (final food in foods) {
      if (food['source'] != 'curated') continue;

      final portions = (food['portions'] as List? ?? const []);
      expect(portions, isNotEmpty, reason: '${food['id']}: porsiyon yok');
      expect(
        portions.any((p) => (p as Map)['isDefault'] == true),
        isTrue,
        reason: '${food['id']}: varsayılan porsiyon işaretlenmemiş',
      );
      for (final raw in portions) {
        final portion = raw as Map<String, dynamic>;
        expect(
          portion['grams'],
          greaterThan(0),
          reason: '${food['id']}: porsiyon gramı sıfır',
        );
      }
    }
  });

  test('her besin türünde kayıt var', () {
    final used = {for (final food in foods) food['category'] as String};
    for (final category in FoodCategory.values) {
      // `diger` boş kalabilir — bir kaçış kovası, hedef değil.
      if (category == FoodCategory.diger) continue;
      expect(
        used,
        contains(category.name),
        reason: '${category.name} türünde hiç besin yok',
      );
    }
  });

  test('Türkçe mutfak küratörlü tarafta duruyor', () {
    // Boru hattının ayrımı: ev yemekleri elle, ham besinler USDA'dan.
    final curated = foods.where((f) => f['source'] == 'curated');
    expect(curated.length, greaterThanOrEqualTo(100));
    expect(
      curated.every((f) => f['nameTr'] != null),
      isTrue,
      reason: 'küratörlü kayıtta Türkçe ad zorunlu',
    );
  });
}
