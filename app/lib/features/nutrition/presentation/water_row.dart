import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/nutrition/application/nutrition_providers.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Su satırı (v3 §5.1): kutucuk değil miktar.
///
/// Bardak dokunuşu +250 ml; hedef plan hedefinden. Ana Sayfa akışı ve
/// Diyet GÜNLÜK aynı satırı kullanıyor — iki ayrı su arayüzü iki ayrı
/// davranış demek olurdu.
class WaterRow extends ConsumerWidget {
  const WaterRow({super.key});

  static const glassMl = 250;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final iso = ref.watch(viewedDateProvider);
    final log = ref.watch(dayLogProvider(iso)).value;
    final target = ref.watch(waterTargetMlProvider).value ?? 3000;
    final current = log?.waterMl ?? 0;
    final met = current >= target;

    return Row(
      children: [
        AppIconTile(
          icon: LucideIcons.glassWater,
          area: met ? AppArea.diet : AppArea.neutral,
          small: true,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.waterRowTitle, style: theme.textTheme.bodyMedium),
              Text(
                l10n.waterRowAmount(current, target),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: met
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  // Sayı hedefe ulaşınca yalnız renk değişmiyor; metin
                  // zaten "3000/3000" diyor — renk destek, anlam değil.
                  fontWeight: met ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
        if (current > 0)
          IconButton(
            key: const Key('water-minus'),
            icon: const Icon(Icons.remove, size: 20),
            tooltip: l10n.waterRowRemoveGlass,
            onPressed: () => _add(ref, iso, current, -glassMl, target),
          ),
        FilledButton.tonalIcon(
          key: const Key('water-plus'),
          onPressed: () => _add(ref, iso, current, glassMl, target),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.waterRowAddGlass),
        ),
      ],
    );
  }

  void _add(WidgetRef ref, String iso, int current, int delta, int target) {
    final next = (current + delta).clamp(0, 20000);
    ref.read(todayRepositoryProvider).setWaterMl(iso, next, targetMl: target);
  }
}
