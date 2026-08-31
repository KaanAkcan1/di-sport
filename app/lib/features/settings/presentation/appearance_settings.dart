import 'package:disport/core/design/app_dimens.dart';
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

    return AppSection(
      title: 'Görünüm',
      description: 'Koyu tema uygulamanın asıl hâli; salonda ve sabahın '
          'köründe de okunur.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SegmentedButton<ThemeMode>(
            key: const Key('theme-mode-selector'),
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistem'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Koyu'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Açık'),
                icon: Icon(Icons.light_mode_outlined),
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
