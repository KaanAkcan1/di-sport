import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/settings/application/settings_providers.dart';
import 'package:disport/features/settings/domain/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arayüz dili — Sistem · Türkçe · English.
///
/// Varsayılan **sistem**: tema bir tasarım kararıydı ve koyu
/// dayatılabilirdi, dil ise erişim meselesi — cihazı hangi dildeyse
/// uygulama da öyle açılmalı.
///
/// Dil adları çevrilmiyor: "Türkçe" ve "English" kendi dillerinde
/// yazılır. Bir kullanıcı yanlış dile düşmüşse listede kendi dilini
/// tanıyabilmeli.
class LanguageSettings extends ConsumerWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider).value;
    final l10n = context.l10n;

    return AppSection(
      title: l10n.languageTitle,
      description: l10n.languageDescription,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SegmentedButton<String>(
            key: const Key('language-selector'),
            segments: [
              ButtonSegment(
                value: 'system',
                label: Text(l10n.languageSystem),
              ),
              ButtonSegment(value: 'tr', label: Text(l10n.languageTurkish)),
              ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
            ],
            selected: {locale?.languageCode ?? 'system'},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(profileRepositoryProvider)
                .set(SettingsKeys.locale, selection.first),
          ),
        ),
      ),
    );
  }
}
