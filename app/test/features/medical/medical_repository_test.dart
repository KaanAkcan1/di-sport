import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/medical/data/medical_repository.dart';
import 'package:disport/features/medical/domain/medical_fact.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MedicalRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MedicalRepository(db);
  });

  tearDown(() => db.close());

  test('liste boş başlar — kimseye durum atfedilmez', () async {
    expect(await repo.watchAll().first, isEmpty);
  });

  test('ekleme ve geri okuma — tür, etiket, kimlik korunur', () async {
    await repo.add(
      kind: MedicalFactKind.condition,
      label: 'İnsülin direnci',
      conditionId: 'insulinResistance',
    );
    await repo.add(kind: MedicalFactKind.allergy, label: 'Laktoz');

    final facts = await repo.watchAll().first;
    expect(facts, hasLength(2));
    final condition = facts.singleWhere(
      (f) => f.kind == MedicalFactKind.condition,
    );
    expect(condition.label, 'İnsülin direnci');
    expect(condition.conditionId, 'insulinResistance');
    final allergy = facts.singleWhere((f) => f.kind == MedicalFactKind.allergy);
    expect(allergy.conditionId, isNull);
  });

  test('boş etiket reddedilir', () {
    expect(
      () => repo.add(kind: MedicalFactKind.condition, label: '   '),
      throwsArgumentError,
    );
  });

  test('silme yumuşak — listeden düşer, satır durur', () async {
    final id = await repo.add(
      kind: MedicalFactKind.restriction,
      label: 'Diz sorunu',
    );
    await repo.remove(id);

    expect(await repo.watchAll().first, isEmpty);
    final raw = await db.select(db.medicalFacts).get();
    expect(raw, hasLength(1));
    expect(raw.single.deletedAt, isNotNull);
  });

  test('bilinmeyen tür adı okuma sırasında hata verir — sessiz düşüş yok', () {
    expect(() => MedicalFactKind.fromName('surgery'), throwsArgumentError);
  });
}
