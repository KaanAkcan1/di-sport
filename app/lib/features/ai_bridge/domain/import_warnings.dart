import 'package:disport/features/ai_bridge/domain/plan_json.dart';
import 'package:disport/features/catalog/domain/equipment_kind.dart';

/// İçe alma uyarıları (v3 §9.4) — kapı 3'ün amber eki, saf.
///
/// Uyarılar **reddettirmez**: önizlemede amber satır olarak görünür,
/// kullanıcı görür ve isterse içeri aldıktan sonra editörle düzeltir.
/// Otomatik muadil değiştirme v3-sonrası.
enum ImportWarningKind {
  /// Plandaki besin kalemi yasaklı bağıyla kesişiyor.
  forbiddenFood,

  /// Kalemdeki `foodId` besin listesinde yok.
  unknownFood,

  /// Hareket kullanıcının envanteriyle yapılamıyor.
  cannotPerform,

  /// `external` davranışlı öğüne plan yazılmış.
  externalMealPlanned,

  /// `fixed` öğün planda farklı kalemlerle gelmiş.
  fixedMealDiffers,

  /// Hareket kullanıcının kimlikli kısıtıyla eşleşiyor.
  restrictionMatch,
}

class ImportWarning {
  const ImportWarning({required this.kind, required this.subject});

  final ImportWarningKind kind;

  /// Uyarının öznesi — besin id'si, hareket id'si ya da öğün adı.
  final String subject;
}

List<ImportWarning> collectImportWarnings({
  required PlanJson plan,
  required Set<String> knownFoodIds,
  required Map<String, List<String>> forbiddenFoodIds,
  required Map<String, ({List<String> equipment, String location})>
  exerciseFacts,
  required Set<String> homeEquipment,
  required Set<String> gymEquipment,
  required Map<String, String> mealBehaviorByKind,
  required Set<String> restrictedExerciseIds,
}) {
  final warnings = <ImportWarning>[];
  void add(ImportWarningKind kind, String subject) {
    // Aynı özne için tek uyarı: 28 günde 28 kez "lahmacun yasaklı"
    // demek uyarıyı gürültüye çevirirdi.
    final warning = ImportWarning(kind: kind, subject: subject);
    if (!warnings.any((w) => w.kind == kind && w.subject == subject)) {
      warnings.add(warning);
    }
  }

  final forbiddenIds = {
    for (final ids in forbiddenFoodIds.values) ...ids,
  };

  for (final day in plan.days) {
    for (final slot in day.slots) {
      // Öğün davranışı kontrolleri.
      if (slot.kind == 'meal' && slot.mealKind != null) {
        final behavior = mealBehaviorByKind[slot.mealKind];
        if (behavior == 'external') {
          add(ImportWarningKind.externalMealPlanned, slot.mealKind!);
        }
        if (behavior == 'fixed' && slot.items.isNotEmpty) {
          add(ImportWarningKind.fixedMealDiffers, slot.mealKind!);
        }
      }

      for (final item in slot.items) {
        if (!knownFoodIds.contains(item.foodId)) {
          add(ImportWarningKind.unknownFood, item.foodId);
        }
        if (forbiddenIds.contains(item.foodId)) {
          add(ImportWarningKind.forbiddenFood, item.foodId);
        }
      }
    }

    for (final exercise in day.exercises) {
      final facts = exerciseFacts[exercise.exerciseId];
      if (facts != null && !_performable(facts, homeEquipment, gymEquipment)) {
        add(ImportWarningKind.cannotPerform, exercise.exerciseId);
      }
      if (restrictedExerciseIds.contains(exercise.exerciseId)) {
        add(ImportWarningKind.restrictionMatch, exercise.exerciseId);
      }
    }
  }

  return warnings;
}

/// Envanter kontrolü — `canPerform` ile aynı kural: envanter istemeyen
/// türler her yerde geçerli.
bool _performable(
  ({List<String> equipment, String location}) facts,
  Set<String> home,
  Set<String> gym,
) {
  final owned = switch (facts.location) {
    'gym' => gym,
    // `both` iki yerde de yapılabilir: birinde yapılabiliyorsa yeter.
    'both' => {...home, ...gym},
    _ => home,
  };

  for (final name in facts.equipment) {
    final EquipmentKind kind;
    try {
      kind = EquipmentKind.fromName(name);
    } on ArgumentError {
      continue; // bilinmeyen tür envanter kontrolüne girmez
    }
    if (!kind.needsInventory) continue;
    if (!owned.contains(name)) return false;
  }
  return true;
}
