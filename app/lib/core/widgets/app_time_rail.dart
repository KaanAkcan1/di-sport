import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:flutter/material.dart';

/// Rayın bir düğümünün durumu.
enum RailNodeState {
  /// Saati geçmiş ve işaretlenmiş.
  done,

  /// Saati geçmiş, işaretlenmemiş.
  missed,

  /// Sırada — günün şu an içinde bulunulan ya da en yakın gelecek adımı.
  next,

  /// Henüz vakti gelmemiş.
  upcoming,
}

/// Zaman rayındaki tek satır.
class AppTimeRailItem extends StatelessWidget {
  const AppTimeRailItem({
    super.key,
    required this.time,
    required this.state,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  /// `06:30` — sıkışık, tablo rakamıyla yazılır.
  final String time;
  final RailNodeState state;
  final Widget child;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  /// Saat sütununun genişliği. Sabit: raya asılan çizgi tüm satırlarda
  /// aynı x'te olmalı, yoksa omurga eğrilir.
  static const railColumnWidth = 62.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _colorsFor(context, state);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: railColumnWidth,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  time,
                  style: AppTypography.timeRail.copyWith(
                    color: colors.time,
                  ),
                ),
                // Kalan yüksekliği çizgi dolduruyor: satır ne kadar
                // uzarsa ray da o kadar uzuyor, boşluk kalmıyor.
                // Çizgi saatin **altındaki** aralığı dolduruyor; son
                // satırda altta bir şey olmadığı için çizilmiyor,
                // yoksa ray boşluğa uzanıp yarım kalmış görünüyor.
                Expanded(child: _RailLine(color: colors.line, draw: !isLast)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: AppRadius.mdAll,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: DefaultTextStyle.merge(
                      style: theme.textTheme.bodyLarge!,
                      child: child,
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

  ({Color time, Color line}) _colorsFor(
    BuildContext context,
    RailNodeState state,
  ) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return switch (state) {
      // Yapılmış adım soluklaşıyor: bitmiş iş dikkat çekmemeli.
      RailNodeState.done => (time: muted, line: theme.colorScheme.primary),
      RailNodeState.missed => (
        time: muted,
        line: theme.colorScheme.outlineVariant,
      ),
      RailNodeState.next => (
        time: theme.colorScheme.primary,
        line: theme.colorScheme.primary,
      ),
      RailNodeState.upcoming => (
        time: theme.colorScheme.onSurface,
        line: theme.colorScheme.outlineVariant,
      ),
    };
  }
}

class _RailLine extends StatelessWidget {
  const _RailLine({required this.color, required this.draw});

  final Color color;
  final bool draw;

  @override
  Widget build(BuildContext context) {
    if (!draw) return const SizedBox.shrink();

    return Center(
      child: SizedBox(
        width: AppBorder.rail,
        child: ColoredBox(color: color, child: const SizedBox.expand()),
      ),
    );
  }
}

/// Rayı bölen "şimdi" işareti.
///
/// **Neden var:** sabah 05:45'te uygulamayı açan kullanıcının tek
/// sorusu "sırada ne var". v1'de slotlar düz bir listeydi — geçmişle
/// gelecek arasında hiçbir görsel fark yoktu ve bu bilgi atılıyordu.
/// Bu satır listeyi ikiye bölerek soruyu cevaplıyor.
class AppNowMarker extends StatelessWidget {
  const AppNowMarker({super.key, required this.label});

  /// `13:42` — geçerli saat.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Semantics(
      label: context.l10n.commonNowAt(label),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: AppTimeRailItem.railColumnWidth,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.timeRail.copyWith(
                  color: color,
                  fontSize: 15,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: AppBorder.rail,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.fullAll,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.fullAll,
              ),
              child: Text(
                context.l10n.commonNowLabel,
                style: AppTypography.statCaption.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
