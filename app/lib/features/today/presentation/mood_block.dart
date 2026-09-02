import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/today/application/day_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// His + belirti + stres bloğu (v3.1 §3).
///
/// Üç giriş de isteğe bağlı; hepsi `daily_logs`'a yazılır ve AI
/// belgesinin "Geçen dönem" bölümüne gün gün akar. Yüz ikonları renkle
/// değil seçim durumu + erişilebilirlik etiketiyle konuşur — renk tek
/// başına anlam taşımaz kuralı.
class MoodBlock extends ConsumerWidget {
  const MoodBlock({super.key});

  static const _icons = [
    LucideIcons.angry,
    LucideIcons.frown,
    LucideIcons.meh,
    LucideIcons.smile,
    LucideIcons.laugh,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final iso = ref.watch(viewedDateProvider);
    final log = ref.watch(dayLogProvider(iso)).value;
    final write = ref.watch(wellbeingWriterProvider);

    final mood = log?.moodScore;
    final labels = [
      l10n.moodLevel1,
      l10n.moodLevel2,
      l10n.moodLevel3,
      l10n.moodLevel4,
      l10n.moodLevel5,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.moodBlockTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var score = 1; score <= 5; score++)
              Semantics(
                button: true,
                selected: mood == score,
                label: labels[score - 1],
                child: IconButton(
                  key: Key('mood-$score'),
                  icon: Icon(_icons[score - 1]),
                  isSelected: mood == score,
                  tooltip: labels[score - 1],
                  color: mood == score
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  // Aynı yüze ikinci dokunuş seçimi kaldırır — "yanlış
                  // bastım" geri alınabilir olmalı.
                  onPressed: () => mood == score
                      ? write(iso, clearMood: true)
                      : write(iso, moodScore: score),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SymptomsField(
          value: log?.symptoms ?? '',
          onSubmitted: (text) => write(iso, symptoms: text.trim()),
        ),
        CheckboxListTile(
          key: const Key('stressed-day'),
          value: log?.stressedDay ?? false,
          onChanged: (checked) => write(iso, stressedDay: checked ?? false),
          title: Text(
            l10n.moodStressedLabel,
            style: theme.textTheme.bodyMedium,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }
}

/// Odak kaybında da kaydeden metin alanı (ölçüm alanı kalıbı).
class _SymptomsField extends StatefulWidget {
  const _SymptomsField({required this.value, required this.onSubmitted});

  final String value;
  final void Function(String text) onSubmitted;

  @override
  State<_SymptomsField> createState() => _SymptomsFieldState();
}

class _SymptomsFieldState extends State<_SymptomsField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onSubmitted(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_focusNode.hasFocus && _controller.text != widget.value) {
      _controller.text = widget.value;
    }

    return TextField(
      key: const Key('symptoms-field'),
      controller: _controller,
      focusNode: _focusNode,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: context.l10n.moodSymptomsLabel,
        hintText: context.l10n.moodSymptomsHint,
        isDense: true,
      ),
      onSubmitted: widget.onSubmitted,
    );
  }
}
