import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// İkonun ait olduğu alan — rengin kaynağı.
///
/// Renk burada dekor değil harita: kullanıcı yeşilin diyet, göğün spor
/// olduğunu alt çubuktan öğreniyor ve aynı eşleme her ikon kutusunda
/// tekrarlanıyor. Renk yine de tek başına anlam taşımaz — kutu her zaman
/// bir etiketin yanında durur.
enum AppArea { diet, sport, health, med, energy, neutral, danger }

/// Alan renkli ikon kutusu (v3 duotone dili).
///
/// 40dp yuvarlatılmış kare: alanın yüzey rengi zemin, alanın kendisi
/// ikon. Liste satırlarında `small` (34dp) kullanılır.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    required this.area,
    this.small = false,
  });

  final IconData icon;
  final AppArea area;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final (Color foreground, Color background) = switch (area) {
      AppArea.diet => (semantic.areaDiet, semantic.areaDietSurface),
      AppArea.sport => (semantic.areaSport, semantic.areaSportSurface),
      AppArea.health => (semantic.areaHealth, semantic.areaHealthSurface),
      AppArea.med => (semantic.areaMed, semantic.areaMedSurface),
      AppArea.energy => (semantic.areaEnergy, semantic.areaEnergySurface),
      AppArea.neutral => (
        theme.colorScheme.onSurfaceVariant,
        theme.colorScheme.surfaceContainerHighest,
      ),
      AppArea.danger => (semantic.danger, semantic.dangerSurface),
    };

    final size = small ? 34.0 : 40.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: small ? AppRadius.smAll : AppRadius.mdAll,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: small ? 18 : 22, color: foreground),
    );
  }
}
