import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/plan/presentation/slot_kind_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('her slot türünün kendi ikonu var', () {
    // Aynı ikonu paylaşan iki tür omurgada ayırt edilemezdi.
    final icons = SlotKind.values.map(slotKindIcon).toSet();
    expect(icons.length, SlotKind.values.length);
  });

  test('kalkış ikonu slot türlerinden ayrı', () {
    // Enum'a değer eklemek plan verisini ve AI sözleşmesini
    // değiştirirdi; kalkış yalnız görsel bir ayrım.
    expect(SlotKind.values.map(slotKindIcon), isNot(contains(wakeUpIcon)));
  });
}
