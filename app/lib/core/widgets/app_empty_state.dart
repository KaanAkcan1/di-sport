import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Boş durumun tonu — ikon ve rengi belirler.
enum AppEmptyStateTone {
  /// Beklenen boşluk: henüz kayıt girilmemiş.
  neutral,

  /// Dikkat gerektiren boşluk: eksik veri bir şeyi engelliyor.
  warning,

  /// Hata sonucu boşluk.
  danger,
}

/// Veri olmadığında gösterilecek görünüm.
///
/// Boş ekran bırakmak kullanıcıyı "bozuk mu?" diye düşündürür. Boş
/// durum üç şey söylemeli: ne yok, neden yok, ne yapılabilir
/// (ui-ux §8 `empty-states`).
///
/// Renk tek başına ton taşımaz; her tonun kendi ikonu var
/// (ui-ux §1 `color-not-only`).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.tone = AppEmptyStateTone.neutral,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel ve onAction birlikte verilmeli',
       );

  final String title;
  final String? description;
  final IconData? icon;
  final AppEmptyStateTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final (color, defaultIcon) = switch (tone) {
      AppEmptyStateTone.neutral => (
        theme.colorScheme.onSurfaceVariant,
        Icons.inbox_outlined,
      ),
      AppEmptyStateTone.warning => (semantic.warning, Icons.info_outline),
      AppEmptyStateTone.danger => (semantic.danger, Icons.error_outline),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // İkon dekoratif: metin zaten aynı bilgiyi taşıyor, ekran
            // okuyucu iki kez okumasın.
            ExcludeSemantics(child: Icon(icon ?? defaultIcon, size: 40, color: color)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (description case final text?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel case final label?) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
