import 'package:disport/core/design/app_dimens.dart';
import 'package:flutter/material.dart';

/// Sekme kabuklarının ortak başlığı (v3).
///
/// Kabuğun tek `AppBar`'ı kalktı: her sekme kendi başlığını kuruyor,
/// çünkü Ana Sayfa'nın başlığı günün adı, Diyet'inki sekme adı + tarih.
/// Ortak olan yalnız düzen: sol büyük başlık + sağ eylem kutuları.
class ShellHeader extends StatelessWidget {
  const ShellHeader({
    super.key,
    required this.title,
    this.overline,
    this.actions = const [],
  });

  final String title;
  final String? overline;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline case final text?)
                  Text(
                    text,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Başlık eylem kutusu — 40dp, panelle aynı ton dili.
class ShellAction extends StatelessWidget {
  const ShellAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.mdAll,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
