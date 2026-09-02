import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/catalog/presentation/equipment_screen.dart';
import 'package:disport/features/medical/presentation/medical_screen.dart';
import 'package:disport/features/settings/application/setup_providers.dart';
import 'package:disport/features/settings/domain/setup_progress.dart';
import 'package:disport/features/settings/presentation/weekly_schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Kurulum paneli (v3 §3.2).
///
/// İlk açılışta kahraman kalorinin yerini alır: kayıt yokken kahraman
/// sayı anlamsız. Bekleyen adımlar kart olarak listelenir; her kartın
/// GEÇ yolu var (geçilen kart düşer, ekran Daha'dan hep erişilebilir).
/// 4/4'te panel kendini kaldırır — kaldırma kararı [SetupProgress]'te,
/// burada yalnız çizim var.
class SetupPanel extends ConsumerWidget {
  const SetupPanel({super.key, required this.progress});

  final SetupProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  TurkishText.upper(l10n.setupPanelTitle),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                l10n.setupPanelProgress(progress.done, progress.total),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.setupPanelBody, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          for (final step in progress.pending)
            _SetupCard(step: step, key: Key('setup-card-${step.name}')),
        ],
      ),
    );
  }
}

class _SetupCard extends ConsumerWidget {
  const _SetupCard({super.key, required this.step});

  final SetupStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final (icon, area, title, minutes) = switch (step) {
      SetupStep.equipment => (
        LucideIcons.dumbbell,
        AppArea.sport,
        l10n.setupCardEquipment,
        2,
      ),
      SetupStep.medical => (
        LucideIcons.heartPulse,
        AppArea.health,
        l10n.setupCardMedical,
        3,
      ),
      SetupStep.rhythm => (
        LucideIcons.clock,
        AppArea.neutral,
        l10n.setupCardRhythm,
        1,
      ),
      // Sihirbaz `pending`e hiç girmiyor; panel görünürken bitmiştir.
      SetupStep.wizard => (
        LucideIcons.user,
        AppArea.neutral,
        '',
        0,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              AppIconTile(icon: icon, area: area, small: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyMedium),
                    Text(
                      l10n.setupCardMinutes(minutes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: Key('setup-skip-${step.name}'),
                onPressed: () => skipSetupStep(
                  ref.read(profileRepositoryProvider),
                  step,
                ),
                child: Text(l10n.setupCardSkip),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final screen = switch (step) {
      SetupStep.equipment => const EquipmentScreen(),
      SetupStep.medical => const MedicalScreen(),
      SetupStep.rhythm => const WeeklyScheduleScreen(),
      SetupStep.wizard => null,
    };
    if (screen == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}
