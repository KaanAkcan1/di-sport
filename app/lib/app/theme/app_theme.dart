import 'package:disport/app/theme/app_color_schemes.dart';
import 'package:disport/app/theme/app_component_themes.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Uygulama teması — parçaları birleştiren ince katman.
///
/// Renk şemaları [AppColorSchemes], bileşen stilleri
/// [AppComponentThemes], tipografi [AppTypography], anlam renkleri
/// [AppSemanticColors] içinde. Bu dosyanın tek işi onları bir araya
/// getirmek; büyüdüğünü fark edersen parça yanlış yerde demektir.
abstract final class AppTheme {
  static ThemeData get light =>
      _build(AppColorSchemes.light, AppSemanticColors.light);

  static ThemeData get dark =>
      _build(AppColorSchemes.dark, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme c, AppSemanticColors semantic) {
    final t = AppTypography.textTheme.apply(
      fontFamily: AppTypography.fontFamily,
      bodyColor: c.onSurface,
      displayColor: c.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: c,
      fontFamily: AppTypography.fontFamily,
      textTheme: t,
      // M12: zemin artık `surface`'in kendisi. Mürekkep dilinde rampa
      // aşağıdan yukarı kuruluyor — zemin (surface) → panel
      // (surfaceContainerHigh) → ön plan (diyalog). M6'da tersiydi:
      // zemin bir ton koyu, kart beyaz. Kart kavramı kalkınca o
      // kurgunun dayanağı da kalktı.
      scaffoldBackgroundColor: c.surface,
      splashFactory: InkSparkle.splashFactory,

      // Anlam renkleri `context.semantic` ile erişilir.
      extensions: [semantic],

      // Küçük ikonlar bile 48dp dokunma alanı alır
      // (ui-ux §2 `touch-target-size`).
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppComponentThemes.appBar(c, t),
      cardTheme: AppComponentThemes.card(c),
      dividerTheme: AppComponentThemes.divider(c),
      navigationBarTheme: AppComponentThemes.navigation(c, t),
      listTileTheme: AppComponentThemes.listTile(c, t),
      checkboxTheme: AppComponentThemes.checkbox(c),
      switchTheme: AppComponentThemes.switches(c),
      inputDecorationTheme: AppComponentThemes.inputs(c, t),
      filledButtonTheme: AppComponentThemes.filledButton(t),
      outlinedButtonTheme: AppComponentThemes.outlinedButton(c, t),
      textButtonTheme: AppComponentThemes.textButton(t),
      segmentedButtonTheme: AppComponentThemes.segmentedButton(c, t),
      chipTheme: AppComponentThemes.chip(c, t),
      tabBarTheme: AppComponentThemes.tabBar(c, t),
      bottomSheetTheme: AppComponentThemes.bottomSheet(c),
      dialogTheme: AppComponentThemes.dialog(c, t),
      snackBarTheme: AppComponentThemes.snackBar(c, t),
      progressIndicatorTheme: AppComponentThemes.progress(c),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
