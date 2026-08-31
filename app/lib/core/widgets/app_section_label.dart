import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/turkish_text.dart';
import 'package:flutter/material.dart';

/// Bölüm etiketi — mürekkep dilinin başlık aracı.
///
/// [AppSectionHeader]'dan farkı: o bir *kart başlığı* (büyük punto,
/// açıklama satırı alabilir), bu bir *çizelge etiketi*. Mürekkep
/// dilinde ekran kart yığını değil tek yüzey; bölümleri ayıran şey
/// kutu değil, harf aralığı açılmış küçük büyük harf bir satır.
///
/// [trailing] sağa yaslanır ve genelde bir sayı ya da eylem taşır:
/// "GÜNÜN OMURGASI · 5/8".
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              // Dart'ın ASCII `toUpperCase()`'i değil: "Kilo" → "KILO"
              // verirdi ve bu Türkçede "kılo" okunur.
              TurkishText.upper(text),
              style: AppTypography.statCaption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.6,
              ),
            ),
          ),
          if (trailing case final w?) ...[const Spacer(), w],
        ],
      ),
    );
  }
}
