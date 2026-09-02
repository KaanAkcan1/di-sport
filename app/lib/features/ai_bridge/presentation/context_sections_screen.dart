import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Gönderilecekler ekranı (v3 §9.3).
///
/// AI belgesine hangi bölümlerin gireceğini kullanıcı seçer; kapalı
/// bölüm belgeye **hiç** yazılmaz. "Önce belgeyi gör" önizlemesi neyin
/// paylaşılacağını paylaşmadan gösterir — mahremiyetin kontrolü
/// kullanıcıda.
class ContextSectionsScreen extends ConsumerWidget {
  const ContextSectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final enabled =
        ref.watch(contextSectionsProvider).value ??
        ContextSection.values.toSet();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ctxSectionsTitle)),
      body: AppScreenBody(
        children: [
          Text(
            l10n.ctxSectionsIntro,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final section in ContextSection.values)
            SwitchListTile(
              key: Key('ctx-section-${section.name}'),
              title: Text(_sectionLabel(l10n, section)),
              subtitle: Text(
                _sectionHint(l10n, section),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: enabled.contains(section),
              onChanged: (value) => ref
                  .read(profileRepositoryProvider)
                  .set(contextSectionOffKey(section), value ? '0' : '1'),
            ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            key: const Key('ctx-preview'),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(l10n.ctxPreviewButton),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ContextPreviewScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sectionLabel(AppLocalizations l10n, ContextSection section) =>
    switch (section) {
      ContextSection.medical => l10n.ctxSectionMedical,
      ContextSection.environment => l10n.ctxSectionEnvironment,
      ContextSection.routine => l10n.ctxSectionRoutine,
      ContextSection.forbidden => l10n.ctxSectionForbidden,
      ContextSection.recent => l10n.ctxSectionRecent,
      ContextSection.notes => l10n.ctxSectionNotes,
      ContextSection.foods => l10n.ctxSectionFoods,
    };

String _sectionHint(AppLocalizations l10n, ContextSection section) =>
    switch (section) {
      ContextSection.medical => l10n.ctxSectionMedicalHint,
      ContextSection.environment => l10n.ctxSectionEnvironmentHint,
      ContextSection.routine => l10n.ctxSectionRoutineHint,
      ContextSection.forbidden => l10n.ctxSectionForbiddenHint,
      ContextSection.recent => l10n.ctxSectionRecentHint,
      ContextSection.notes => l10n.ctxSectionNotesHint,
      ContextSection.foods => l10n.ctxSectionFoodsHint,
    };

/// Salt-okunur belge önizlemesi — eş yazı tipiyle.
class ContextPreviewScreen extends ConsumerWidget {
  const ContextPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final document = ref.watch(_previewProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ctxPreviewTitle),
        actions: [
          IconButton(
            key: const Key('ctx-copy'),
            icon: const Icon(Icons.copy, size: 20),
            tooltip: l10n.ctxCopy,
            onPressed: document.value == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final copied = l10n.labImportCopied;
                    await Clipboard.setData(
                      ClipboardData(text: document.value!),
                    );
                    messenger.showSnackBar(SnackBar(content: Text(copied)));
                  },
          ),
          IconButton(
            key: const Key('ctx-share'),
            icon: const Icon(Icons.ios_share, size: 20),
            tooltip: l10n.ctxShare,
            onPressed: document.value == null
                ? null
                : () => SharePlus.instance.share(
                      ShareParams(text: document.value!),
                    ),
          ),
        ],
      ),
      body: AppAsyncView<String>(
        value: document,
        onRetry: () => ref.invalidate(_previewProvider),
        data: (text) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
    );
  }
}

/// Önizleme belgesi — seçili bölümlerle üretilir.
final _previewProvider = FutureProvider.autoDispose<String>((ref) async {
  final sections = await ref.watch(contextSectionsProvider.future);
  return ref
      .watch(contextMdBuilderProvider)
      .build(today: DateTime.now(), sections: sections);
});
