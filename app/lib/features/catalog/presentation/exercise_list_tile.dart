import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/exercise_visuals.dart';
import 'package:flutter/material.dart';

/// Katalog listesindeki tek satır.
///
/// Ayrı dosyada, çünkü hem katalog listesinde hem M3'te antrenman
/// ekranının hareket seçiminde kullanılacak.
class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({
    super.key,
    required this.exercise,
    required this.onTap,
    this.trailing,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  /// Sağ tarafa eklenecek isteğe bağlı içerik (M3'te set × tekrar).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ExerciseThumbnail(exercise: exercise),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nameTr,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercise.primaryMuscles.join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        ExerciseLocationBadge(location: exercise.location),
                        const SizedBox(width: AppSpacing.sm),
                        ExerciseDifficultyBar(level: exercise.difficulty),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing case final widget?) ...[
                const SizedBox(width: AppSpacing.sm),
                widget,
              ] else
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
