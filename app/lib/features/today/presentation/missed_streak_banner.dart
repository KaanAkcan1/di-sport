import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "İki gün üst üste kaçırma — kural bu."
///
/// PDF'in bu satırı uygulamada istatistik değil **uyarı** olmalı: iki
/// gün üst üste kaçırmak, üçüncü günü de kaçırmanın en güçlü habercisi.
/// Uyarı yalnız kural çiğnendiğinde çıkar; her gün görünen bir şerit
/// kısa sürede görünmez olur.
class MissedStreakBanner extends ConsumerWidget {
  const MissedStreakBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(missedStreakProvider).value ?? 0;
    if (streak < 2) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final semantic = context.semantic;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Card(
        color: semantic.dangerSurface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: semantic.danger),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.todayMissedStreakTitle(streak),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.todayMissedStreakBody,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
