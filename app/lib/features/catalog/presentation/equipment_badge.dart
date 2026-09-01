import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/equipment_labels.dart';
import 'package:flutter/material.dart';

/// "Bu hareket ne gerektiriyor" rozeti (spec §4.2.2).
///
/// **Neden gizlemek yerine işaretlemek:** filtre kapalıyken eksik
/// ekipmanlı hareket listede duruyor ve rozeti neyin eksik olduğunu
/// söylüyor. Sessizce gizlense katalog küçülür ve kullanıcı bunun neden
/// olduğunu anlamaz — üstelik yapamadığı hareketi hedef olarak
/// belirleyebilmesi de gerekiyor.
class EquipmentBadge extends StatelessWidget {
  const EquipmentBadge({
    super.key,
    required this.exercise,
    required this.inventory,
    required this.where,
  });

  final Exercise exercise;
  final EquipmentInventory inventory;
  final ExerciseLocation where;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final l10n = context.l10n;

    final needed = exercise.equipment
        .where((kind) => kind.needsInventory)
        .toList();

    // Ekipman istemeyen hareket rozet taşımıyor: "hiçbir şey gerekmiyor"
    // her satırda tekrarlanınca gürültü olur.
    if (needed.isEmpty) return const SizedBox.shrink();

    final owned = inventory.at(where);
    final missing = needed.where((kind) => !owned.contains(kind)).toList();
    final names = (missing.isEmpty ? needed : missing)
        .map((kind) => equipmentLabel(context, kind))
        .join(', ');

    final (label, color) = missing.isEmpty
        ? (names, semantic.success)
        : (
            where == ExerciseLocation.gym
                ? l10n.catalogEquipmentMissingGym(names)
                : l10n.catalogEquipmentMissingHome(names),
            semantic.warning,
          );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Renk tek başına anlam taşımaz: ikon eksiği/tamamı ayrıca
          // söylüyor (spec §2a.4).
          Icon(
            missing.isEmpty ? Icons.check : Icons.info_outline,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
