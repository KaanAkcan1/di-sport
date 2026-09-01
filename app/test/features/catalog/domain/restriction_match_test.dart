import 'package:disport/features/catalog/domain/equipment_kind.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/domain/restriction_match.dart';
import 'package:flutter_test/flutter_test.dart';

import '../exercise_fixtures.dart';

void main() {
  test('güvenlik metnindeki anahtar kelime kısıtla eşleşir', () {
    final squat = Exercise.fromJson(
      fixtureJson(id: 'squat', nameTr: 'Çömelme', nameEn: 'Squat')
        ..['safetyTr'] = 'Dizlerini kilitleme, DİZ hizasını koru.',
    );
    expect(exerciseMatchesRestriction(squat, 'kneeIssue'), isTrue);
    expect(exerciseMatchesRestriction(squat, 'shoulderIssue'), isFalse);
  });

  test('İngilizce ad ve kas grubu da taranır', () {
    final press = fixtureExercise(
      id: 'ohp',
      nameTr: 'Omuz Pres',
      nameEn: 'Overhead Press',
      muscles: ['shoulders'],
      equipment: [EquipmentKind.barbell],
    );
    expect(exerciseMatchesRestriction(press, 'shoulderIssue'), isTrue);
  });

  test('bilinmeyen kısıt kimliği eşleşmez — sessizce', () {
    final pushup = fixtureExercise(
      id: 'pushup',
      nameTr: 'Şınav',
      nameEn: 'Push-Up',
    );
    expect(exerciseMatchesRestriction(pushup, 'wristIssue'), isFalse);
  });

  test('matchingRestrictions yalnız eşleşenleri döner', () {
    final deadlift = Exercise.fromJson(
      fixtureJson(id: 'deadlift', nameTr: 'Ölü Kaldırış', nameEn: 'Deadlift')
        ..['safetyEn'] = 'Keep a neutral lower back.',
    );
    expect(
      matchingRestrictions(deadlift, ['kneeIssue', 'backIssue']),
      ['backIssue'],
    );
  });
}
