import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Setler arası dinlenme geri sayımı.
///
/// Alt çubukta duruyor: kullanıcı listeyi kaydırırken de görünür kalmalı,
/// çünkü dinlenme süresi antrenmanın parçası — "60 sn" yazan bir kart
/// ekrandan çıkınca sayaç işlevini yitirir.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({
    super.key,
    required this.remaining,
    required this.onSkip,
  });

  final int remaining;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        color: theme.colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Semantics(
                liveRegion: true,
                label: context.l10n.workoutRestSemantics(remaining),
                excludeSemantics: true,
                child: Text(
                  context.l10n.workoutRestLabel(remaining),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onSkip,
              child: Text(
                context.l10n.workoutRestSkip,
                style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
