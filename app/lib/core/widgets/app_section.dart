import 'package:disport/core/design/app_dimens.dart';
import 'package:flutter/material.dart';

/// Bölüm başlığı — isteğe bağlı açıklama ve sağda bir eylem.
///
/// Başlıkların punto, ağırlık ve boşluğunu her ekranda yeniden seçmek,
/// aynı hiyerarşi seviyesinin ekrandan ekrana farklı görünmesine yol
/// açar (ui-ux §5 `visual-hierarchy`).
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.action,
  });

  final String title;
  final String? description;

  /// Sağa hizalı ikincil eylem — "Tümünü gör", "Düzenle".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ekran okuyucuya başlık olarak bildirilir;
                // kullanıcı bölümler arasında gezinebilir
                // (ui-ux §1 `heading-hierarchy`).
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (description case final text?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Başlıklı içerik bloğu: başlık + [child], dikey ritmi standart.
///
/// `Column`'ları elle boşluklamak yerine bunu kullanmak, bölümler arası
/// mesafenin her ekranda aynı kalmasını sağlar.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.action,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.xl2),
  });

  final String title;
  final String? description;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: title,
            description: description,
            action: action,
          ),
          child,
        ],
      ),
    );
  }
}

/// Ekran gövdesi için standart kaydırılabilir yerleşim.
///
/// Alt gezinme çubuğunun arkasında içerik kalmaması için alt dolgu
/// otomatik eklenir (ui-ux §5 `fixed-element-offset`) — bu, her ekranda
/// unutulan ve son öğenin çubuk altında kaybolmasına yol açan
/// ayrıntıdır.
class AppScreenBody extends StatelessWidget {
  const AppScreenBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenH,
      vertical: AppSpacing.lg,
    ),
    this.controller,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: padding.copyWith(
        bottom: padding.bottom + AppSpacing.bottomBarClearance,
      ),
      children: children,
    );
  }
}
