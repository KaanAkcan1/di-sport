import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Uygulamadaki her durum ekseninin ortak dili.
///
/// Gün yapıldı mı, tahlil referans aralığında mı, hedefe ulaşıldı mı —
/// hepsi bu dörde indirgenir. Tek bir eşleme olması, aynı anlamın
/// ekrandan ekrana aynı renk ve ikonla görünmesini garanti eder.
enum AppStatus {
  /// Yapıldı, referans aralığında, hedef tuttu.
  good,

  /// Sınırda, vadesi yaklaşıyor, hedefin biraz altında.
  caution,

  /// Kaçırıldı, referans dışı, iki gün üst üste boş.
  bad,

  /// Henüz veri yok.
  unknown,
}

extension AppStatusPresentation on AppStatus {
  Color color(BuildContext context) {
    final semantic = context.semantic;
    return switch (this) {
      AppStatus.good => semantic.success,
      AppStatus.caution => semantic.warning,
      AppStatus.bad => semantic.danger,
      AppStatus.unknown => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  Color surface(BuildContext context) {
    final semantic = context.semantic;
    return switch (this) {
      AppStatus.good => semantic.successSurface,
      AppStatus.caution => semantic.warningSurface,
      AppStatus.bad => semantic.dangerSurface,
      AppStatus.unknown => Theme.of(context).colorScheme.surfaceContainer,
    };
  }

  /// Renk körlüğü ve gri tonlamalı ekranlar için: durum ikonla da
  /// ayırt edilir (ui-ux §1 `color-not-only`).
  IconData get icon => switch (this) {
    AppStatus.good => Icons.check_circle,
    AppStatus.caution => Icons.warning_amber_rounded,
    AppStatus.bad => Icons.cancel,
    AppStatus.unknown => Icons.remove_circle_outline,
  };

  /// Ekran okuyucuya okunacak karşılık.
  String get semanticLabel => switch (this) {
    AppStatus.good => 'iyi',
    AppStatus.caution => 'dikkat',
    AppStatus.bad => 'sorunlu',
    AppStatus.unknown => 'veri yok',
  };
}

/// Durumu ikon + metin ile gösteren rozet.
///
/// Renk asla tek başına anlam taşımaz: ikon her zaman var, etiket
/// isteğe bağlı ama önerilir.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.status,
    required this.label,
    this.compact = false,
  });

  final AppStatus status;
  final String label;

  /// Dar alanlarda (liste satırı sonu) daha küçük dolgu.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    final textStyle = Theme.of(context).textTheme.labelMedium;

    return Semantics(
      label: '$label, ${status.semanticLabel}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: status.surface(context),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: compact ? 14 : 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: textStyle?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Yalnız nokta — takvim hücresi gibi metnin sığmadığı yerler için.
///
/// Nokta tek başına renkle ayrışır; bu yüzden [semanticsLabel] zorunlu:
/// görsel ipucunun metin karşılığı ekran okuyucuya mutlaka ulaşmalı.
class AppStatusDot extends StatelessWidget {
  const AppStatusDot({
    super.key,
    required this.status,
    required this.semanticsLabel,
    this.size = 8,
  });

  final AppStatus status;
  final String semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticsLabel, ${status.semanticLabel}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: status.color(context),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
