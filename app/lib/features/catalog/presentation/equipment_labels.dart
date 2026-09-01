import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/catalog/domain/equipment_kind.dart';
import 'package:flutter/widgets.dart';

/// Ekipman türünün kullanıcıya görünen adı.
///
/// **Neden ARB'de, veride değil:** tür bir kimlik (`dumbbell`), adı ise
/// arayüz metni ("Dambıl" / "Dumbbell"). v1'de ikisi aynı dizgiydi ve
/// dil değişince kimlik de değişirdi — envanter kayıtları kopardı.
String equipmentLabel(BuildContext context, EquipmentKind kind) {
  final l10n = context.l10n;

  return switch (kind) {
    EquipmentKind.bodyOnly => l10n.equipmentBodyOnly,
    EquipmentKind.barbell => l10n.equipmentBarbell,
    EquipmentKind.dumbbell => l10n.equipmentDumbbell,
    EquipmentKind.kettlebell => l10n.equipmentKettlebell,
    EquipmentKind.cable => l10n.equipmentCable,
    EquipmentKind.machine => l10n.equipmentMachine,
    EquipmentKind.bands => l10n.equipmentBands,
    EquipmentKind.medicineBall => l10n.equipmentMedicineBall,
    EquipmentKind.exerciseBall => l10n.equipmentExerciseBall,
    EquipmentKind.foamRoll => l10n.equipmentFoamRoll,
    EquipmentKind.ezCurlBar => l10n.equipmentEzCurlBar,
    EquipmentKind.other => l10n.equipmentOther,
    EquipmentKind.none => l10n.equipmentNone,
    EquipmentKind.pullUpBar => l10n.equipmentPullUpBar,
    EquipmentKind.dipBars => l10n.equipmentDipBars,
    EquipmentKind.bench => l10n.equipmentBench,
    EquipmentKind.jumpRope => l10n.equipmentJumpRope,
  };
}
