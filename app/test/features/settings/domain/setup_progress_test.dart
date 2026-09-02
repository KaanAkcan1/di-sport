import 'package:disport/features/settings/domain/setup_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SetupProgress build({
    bool identity = true,
    bool equipment = false,
    bool equipmentSkipped = false,
    bool medical = false,
    bool medicalSkipped = false,
    bool wake = false,
    bool rhythmSkipped = false,
  }) => buildSetupProgress(
    hasIdentity: identity,
    hasAnyEquipmentChecked: equipment,
    equipmentSkipped: equipmentSkipped,
    hasAnyMedicalFact: medical,
    medicalSkipped: medicalSkipped,
    hasWakeTime: wake,
    rhythmSkipped: rhythmSkipped,
  );

  test('sihirbaz bitti, gerisi bekliyor: 1/4', () {
    final progress = build();
    expect(progress.done, 1);
    expect(progress.total, 4);
    expect(progress.complete, isFalse);
    expect(progress.pending, [
      SetupStep.equipment,
      SetupStep.medical,
      SetupStep.rhythm,
    ]);
  });

  test('veri girmek adımı tamamlar', () {
    final progress = build(equipment: true, medical: true, wake: true);
    expect(progress.complete, isTrue);
    expect(progress.pending, isEmpty);
  });

  test('geçmek de adımı tamamlar — kart her açılışta geri gelmesin', () {
    final progress = build(
      equipmentSkipped: true,
      medicalSkipped: true,
      rhythmSkipped: true,
    );
    expect(progress.complete, isTrue);
  });

  test('geçilen adım sonradan veri girilirse durum değişmez', () {
    final progress = build(equipment: true, equipmentSkipped: true);
    expect(progress.equipmentDone, isTrue);
  });

  test('pending sihirbazı asla içermez', () {
    final progress = build(identity: false);
    expect(progress.pending, isNot(contains(SetupStep.wizard)));
    expect(progress.wizardDone, isFalse);
    expect(progress.done, 0);
  });
}
