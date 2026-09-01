import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Panelin ton varyantı.
enum AppPanelTone {
  /// Yükseltilmiş ton + kıl çizgi — varsayılan.
  normal,

  /// Marka yüzeyinden zemine geçiş — kurulum, başarı vurgusu.
  accent,

  /// Amber yüzey — süresi geçmiş yedek, vadesi gelen tahlil.
  warn,
}

/// Mürekkep dilinin panel bileşeni (v3).
///
/// **Kart değil:** gölge yok, ayrım ton + kıl çizgiyle (M12 kuralı).
/// v3'e kadar her ekran bu üçlüyü (`ink800` + kenarlık + radius) elle
/// kuruyordu; bileşen tek yerde toplanınca ekranlar arası ton farkı
/// kalmıyor ve değişiklik tek dosyada yapılıyor.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.tone = AppPanelTone.normal,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final AppPanelTone tone;
  final EdgeInsetsGeometry padding;

  /// Panelin tamamı dokunulabilirse — kurulum kartı, SIRADA paneli.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final (Color background, Color border, Gradient? gradient) =
        switch (tone) {
          AppPanelTone.normal => (
            theme.colorScheme.surfaceContainerHigh,
            semantic.hairline,
            null,
          ),
          AppPanelTone.accent => (
            theme.colorScheme.surfaceContainerHigh,
            semantic.success.withValues(alpha: .45),
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // Yüzeyden zemine %70'te sönümlenen geçiş: panelin üstü
              // "önemli" der, altı içeriği ezmez.
              colors: [
                semantic.successSurface,
                theme.colorScheme.surfaceContainerHigh,
              ],
              stops: const [0, .7],
            ),
          ),
          AppPanelTone.warn => (
            semantic.warningSurface,
            semantic.warning.withValues(alpha: .6),
            null,
          ),
        };

    final content = Container(
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        border: Border.all(color: border),
        borderRadius: AppRadius.lgAll,
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: content,
      ),
    );
  }
}
