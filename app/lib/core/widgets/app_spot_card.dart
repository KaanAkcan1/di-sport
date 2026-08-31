import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:flutter/material.dart';

/// "SIRADA" kartı — sıradaki işi listeden çıkarıp öne alan vurgu.
///
/// **Neden var:** omurga listesinde her satır eşit ağırlıktaydı ve
/// sıradaki iş yalnız bir renk çubuğuyla ayrışıyordu. Whoop'un
/// "her kutu bir kapıdır" fikri: kullanıcının şimdi yapacağı tek şey
/// varsa o bir satır değil bir hedef olmalı, tek dokunuşla açılmalı.
///
/// Yeşil kıl çerçeve + %7 dolgu: mürekkep dilinde vurgu gölgeyle değil
/// marka renginin kısık bir katmanıyla kuruluyor.
class AppSpotCard extends StatelessWidget {
  const AppSpotCard({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
  });

  /// Üstteki küçük büyük harf satır — "SIRADA · 18:00".
  final String eyebrow;

  final String title;
  final String? subtitle;

  /// Başlığın solundaki ikon — slot türü.
  final IconData? leading;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Semantics(
      button: onTap != null,
      label: '$eyebrow. $title${subtitle == null ? '' : '. $subtitle'}',
      excludeSemantics: true,
      child: Material(
        color: accent.withValues(alpha: 0.07),
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Container(
            // 48dp dokunma hedefi dolguyla garantileniyor.
            constraints: const BoxConstraints(minHeight: AppTouch.minSize),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              border: Border.all(
                color: accent.withValues(alpha: 0.45),
                width: AppBorder.hairline,
              ),
            ),
            child: Row(
              children: [
                if (leading case final icon?) ...[
                  Icon(icon, color: accent, size: 22),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TurkishText.upper(eyebrow),
                        style: AppTypography.statCaption.copyWith(
                          color: theme.colorScheme.tertiary,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle case final s?) ...[
                        const SizedBox(height: 2),
                        Text(
                          s,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
