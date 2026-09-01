import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/locale_text.dart';
import 'package:flutter/material.dart';

/// Alt sekme segmenti (v3).
///
/// **Neden `TabBar` değil:** her ana sekmenin içinde alt sekmeler var ve
/// bazı ekranlar (katalog yer seçimi gibi) ayrıca çip sırası taşıyor.
/// İki ayrı "alt çizgili sekme" sırası üst üste gelince hangisinin
/// gezinme olduğu okunmuyordu. Segment görsel olarak farklı bir tür:
/// kapalı bir kutu içinde dolgulu seçim — gezinme olduğu belli.
class AppSegmented extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  /// Etiketler — çağıran ARB'den verir; burada yalnız büyük harfe
  /// çevrilir (Türkçe kurallarıyla).
  final List<String> labels;

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          for (final (i, label) in labels.indexed)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: label,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.transparent,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      LocaleText.upper(locale, label),
                      style: AppTypography.statCaption.copyWith(
                        fontSize: 13,
                        letterSpacing: .6,
                        fontWeight: i == index
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: i == index
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Segment + `IndexedStack` birleşimi — shell'lerin gövdesi.
///
/// Alt sekmeler de canlı kalır (ana sekmelerle aynı gerekçe): GÜNLÜK'te
/// yarım kalan giriş, BESİNLER'e bakıp dönünce durmalı.
class AppSegmentedShell extends StatefulWidget {
  const AppSegmentedShell({
    super.key,
    required this.labels,
    required this.children,
    this.initialIndex = 0,
    this.header,
  });

  final List<String> labels;
  final List<Widget> children;
  final int initialIndex;

  /// Segmentin üstünde duran başlık bölümü (ekrana özgü).
  final Widget? header;

  @override
  State<AppSegmentedShell> createState() => _AppSegmentedShellState();
}

class _AppSegmentedShellState extends State<AppSegmentedShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ?widget.header,
      AppSegmented(
        labels: widget.labels,
        index: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
      const SizedBox(height: AppSpacing.sm),
      Expanded(
        child: IndexedStack(
          index: _index,
          children: widget.children,
        ),
      ),
    ],
  );
}
