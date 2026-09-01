import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/settings/application/settings_providers.dart';
import 'package:disport/features/settings/domain/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Görünüm tercihi — Sistem · Koyu · Açık.
///
/// Varsayılan koyu: uygulamanın görsel dili mürekkep zemin üstünde
/// kuruldu. "Sistem" seçilebilir ama varsayılan değil, çünkü çoğu
/// cihazda açık moda düşerdi ve tasarımın asıl hâli hiç görülmezdi.
class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.dark;

    final l10n = context.l10n;

    return AppSection(
      title: l10n.appearanceTitle,
      description: l10n.appearanceDescription,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SegmentedButton<ThemeMode>(
            key: const Key('theme-mode-selector'),
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.appearanceSystem),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.appearanceDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.appearanceLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => _save(ref, selection.first),
          ),
        ),
      ),
    );
  }

  Future<void> _save(WidgetRef ref, ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };
    return ref
        .read(profileRepositoryProvider)
        .set(SettingsKeys.themeMode, value);
  }
}
