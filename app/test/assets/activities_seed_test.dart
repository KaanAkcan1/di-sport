import 'dart:convert';
import 'dart:io';

import 'package:disport/features/nutrition/domain/activity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serbest aktivite tohumunun sözleşmesi (spec §5.6).
void main() {
  late Map<String, dynamic> doc;
  late List<Map<String, dynamic>> activities;

  setUpAll(() {
    final raw = File('assets/activities.json').readAsStringSync();
    doc = jsonDecode(raw) as Map<String, dynamic>;
    activities = (doc['activities'] as List).cast<Map<String, dynamic>>();
  });

  test('tohum sürümü tanımlı ve pozitif', () {
    expect(doc['version'], isA<int>());
    expect(doc['version'] as int, greaterThan(0));
  });

  test('kapsama tabanı', () {
    expect(activities.length, greaterThanOrEqualTo(60));
  });

  test('her kayıt modele çözülür', () {
    final parsed = [for (final raw in activities) Activity.fromJson(raw)];
    expect(parsed, hasLength(activities.length));
  });

  test('id\'ler benzersiz ve snake_case', () {
    final ids = [for (final activity in activities) activity['id'] as String];
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id), isTrue, reason: id);
    }
  });

  test('MET değerleri makul aralıkta', () {
    // Dinlenme 1.0, ring boksu ~12.8. Bu aralığın dışı bir yazım
    // hatasıdır ve kalori hesabını sessizce bozar.
    for (final activity in activities) {
      expect(
        activity['met'],
        allOf(greaterThanOrEqualTo(1.0), lessThanOrEqualTo(15.0)),
        reason: '${activity['id']}: met=${activity['met']}',
      );
    }
  });

  test('her kayıtta iki dilde ad var', () {
    // Katalog ve besinden farklı olarak burada Türkçe ad **zorunlu**:
    // liste elle derlendi ve 72 aktivitenin hepsinin karşılığı var.
    for (final activity in activities) {
      expect((activity['nameEn'] as String).trim(), isNotEmpty);
      expect((activity['nameTr'] as String?)?.trim(), isNotEmpty,
          reason: '${activity['id']}: Türkçe ad yok');
    }
  });

  test('kategoriler kapsamlı', () {
    final used = {
      for (final activity in activities) activity['category'] as String,
    };
    // Ev işi ve masa başı çalışma da listede: kullanıcının günü
    // yalnız spordan ibaret değil ve iki saat bahçe işi gerçek bir
    // harcama.
    expect(used, containsAll({'walking', 'running', 'sports', 'gym', 'home'}));
  });
}
