import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:flutter/material.dart';

/// Hareketle ilgili küçük görsel parçalar.
///
/// Liste satırı, detay sayfası ve M3'teki antrenman kartı aynı rozetleri
/// kullanacak; tek yerde durmaları aynı bilginin her ekranda aynı
/// görünmesini sağlar.

/// Küçük görsel önizleme; görseli olmayan hareketlerde kategori ikonu.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({
    super.key,
    required this.exercise,
    this.size = 64,
  });

  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: SizedBox(
        width: size,
        height: size,
        child: switch (exercise.imagePath) {
          final path? => Image.asset(
            path,
            fit: BoxFit.cover,
            // Görsel dosyası eksik ya da bozuksa ekran çökmez; yer
            // tutucuya düşer.
            errorBuilder: (context, _, _) => _Placeholder(exercise: exercise),
          ),
          _ => _Placeholder(exercise: exercise),
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Icon(
        exercise.category.icon,
        color: theme.colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}

/// Hareketin nerede yapıldığını gösteren rozet.
class ExerciseLocationBadge extends StatelessWidget {
  const ExerciseLocationBadge({super.key, required this.location});

  final ExerciseLocation location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final (icon, label) = switch (location) {
      ExerciseLocation.home => (Icons.home_outlined, l10n.catalogLocationHome),
      ExerciseLocation.gym => (Icons.fitness_center, l10n.catalogLocationGym),
      ExerciseLocation.both => (
        Icons.all_inclusive,
        l10n.catalogLocationBoth,
      ),
    };

    return Semantics(
      label: l10n.catalogLocationSemantics(label),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Zorluk göstergesi: beş çubuk, dolu olanlar seviyeyi verir.
///
/// Sayı yerine çubuk, çünkü "2/5" okumak için durup düşünmek gerekir;
/// çubuk bir bakışta okunur. Ekran okuyucuya sayı olarak bildirilir.
class ExerciseDifficultyBar extends StatelessWidget {
  const ExerciseDifficultyBar({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: context.l10n.catalogDifficultySemantics(level),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Container(
              width: 5,
              height: 10,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: i <= level
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}

extension ExerciseCategoryPresentation on ExerciseCategory {
  IconData get icon => switch (this) {
    ExerciseCategory.strength => Icons.fitness_center,
    ExerciseCategory.cardio => Icons.favorite_outline,
    ExerciseCategory.core => Icons.self_improvement,
    ExerciseCategory.mobility => Icons.accessibility_new,
  };

  /// Kategori adı çeviriden gelir; `labelTr` yerine `BuildContext` alan
  /// bir metot, çünkü metin artık dile bağlı.
  String label(BuildContext context) => switch (this) {
    ExerciseCategory.strength => context.l10n.catalogCategoryStrength,
    ExerciseCategory.cardio => context.l10n.catalogCategoryCardio,
    ExerciseCategory.core => context.l10n.catalogCategoryCore,
    ExerciseCategory.mobility => context.l10n.catalogCategoryMobility,
  };
}
