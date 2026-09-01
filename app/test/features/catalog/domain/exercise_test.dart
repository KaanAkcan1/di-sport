import 'dart:convert';
import 'dart:io';

import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> sampleJson() => {
  'id': 'incline_pushup',
  'nameTr': 'Eğimli Şınav',
  'nameEn': 'Incline Push-up',
  'category': 'strength',
  'location': 'home',
  'equipment': <String>['bodyOnly'],
  'primaryMuscles': ['göğüs'],
  'secondaryMuscles': ['triceps', 'ön omuz'],
  'difficulty': 2,
  'summary': 'Şınavın kolaylaştırılmış hali; eller yükseltide.',
  'setup': ['Ellerini sağlam bir yükseltiye omuz genişliğinde koy.'],
  'execution': [
    'Gövdeni düz bir çizgide tut.',
    'Dirsekleri 45 derece açıyla bükerek in.',
    'Göğsün yükseltiye yaklaşınca it.',
  ],
  'breathing': 'İnerken nefes al, iterken ver.',
  'tempo': '2 sn iniş · 1 sn duraklama · 1 sn çıkış',
  'cues': ['Karın sıkı', 'Bel çukurlaşmasın'],
  'commonMistakes': [
    {
      'mistake': 'Kalça düşüyor',
      'why': 'Karın gevşeyince yük bele biner.',
      'fix': 'Kalçayı hafif içeri al, kaburgayı aşağı çek.',
    },
  ],
  'safety': 'Omuz ağrısında yüksekliği artır.',
  'regressions': ['wall_pushup'],
  'progressions': ['knee_pushup', 'pushup'],
  'imagePath': 'assets/exercises/incline_pushup.webp',
  'videoQuery': 'incline push up form',
  'isUserDefined': false,
};

void main() {
  test('fromJson tüm alanları çözer', () {
    final e = Exercise.fromJson(sampleJson());

    expect(e.id, 'incline_pushup');
    expect(e.nameTr, 'Eğimli Şınav');
    expect(e.category, ExerciseCategory.strength);
    expect(e.location, ExerciseLocation.home);
    expect(e.difficulty, 2);
    expect(e.execution, hasLength(3));
    expect(e.commonMistakes.single.fix, contains('kaburga'));
    expect(e.progressions, ['knee_pushup', 'pushup']);
    expect(e.imagePath, 'assets/exercises/incline_pushup.webp');
  });

  test('toJson/fromJson gidiş dönüşü kayıpsız', () {
    final e = Exercise.fromJson(sampleJson());
    final again = Exercise.fromJson(e.toJson());
    expect(again.toJson(), e.toJson());
  });

  test('isteğe bağlı alanlar yoksa null kalır', () {
    final json = sampleJson()
      ..remove('imagePath')
      ..remove('videoQuery');
    final e = Exercise.fromJson(json);
    expect(e.imagePath, isNull);
    expect(e.videoQuery, isNull);
  });

  test('isUserDefined verilmezse false', () {
    final e = Exercise.fromJson(sampleJson()..remove('isUserDefined'));
    expect(e.isUserDefined, isFalse);
  });

  test('bilinmeyen kategori hata verir — sessizce varsayılana düşmez', () {
    expect(
      () => Exercise.fromJson(sampleJson()..['category'] = 'yoga'),
      throwsArgumentError,
    );
  });

  test('hasImage yalnız görsel varken doğru', () {
    expect(Exercise.fromJson(sampleJson()).hasImage, isTrue);
    expect(
      Exercise.fromJson(sampleJson()..remove('imagePath')).hasImage,
      isFalse,
    );
  });

  test('gerçek tohum dosyasındaki kayıtların hepsi çözülür', () {
    // Model ile elle yazılmış veri arasındaki uyum, ancak gerçek dosya
    // okunarak doğrulanabilir; uydurma örnek bunu yakalamaz.
    final raw = File('assets/catalog.json').readAsStringSync();
    final list = (jsonDecode(raw) as Map<String, dynamic>)['exercises'] as List;

    final parsed = [
      for (final e in list) Exercise.fromJson(e as Map<String, dynamic>),
    ];

    // Ölçüt sabit sayı değil "hepsi çözüldü": katalog büyüdükçe bu
    // test her seferinde güncellenmek zorunda kalmamalı. Asıl aranan
    // şey ayrıştırılamayan kayıt olmaması.
    expect(parsed, hasLength(list.length));

    // Yine de bir taban var: katalog kazara boşalırsa ya da tek kayda
    // düşerse bu test düşmeli.
    expect(parsed.length, greaterThanOrEqualTo(17));

    expect(parsed.where((e) => e.hasImage), isNotEmpty);
    expect(
      parsed.map((e) => e.id),
      contains('treadmill_incline_walk'),
    );
  });
}
