import 'package:disport/core/design/app_dimens.dart';
import 'package:flutter/material.dart';

/// Bileşen temaları, sorumluluk gruplarına ayrılmış hâlde.
///
/// Hepsi tek bir `ThemeData(...)` çağrısının içinde durduğunda o çağrı
/// üç yüz satırlık, okunamaz ve değiştirilmesi riskli bir bloğa dönüşür.
/// Burada her grup kendi metodunda: giriş alanlarını değiştirmek isteyen
/// yalnız [inputs] metoduna bakar, gezinmeyi değiştiren yalnız
/// [navigation] metoduna.
///
/// Metotlar `ColorScheme` ve `TextTheme` alır, ham renk sabiti bilmez —
/// böylece açık/koyu mod için ayrı kod yazılmaz, aynı metot iki şemayla
/// iki kez çağrılır.
abstract final class AppComponentThemes {
  // -------------------------------------------------------------------
  // Yüzeyler: uygulama çubuğu, kart, ayraç
  // -------------------------------------------------------------------

  static AppBarTheme appBar(ColorScheme c, TextTheme t) => AppBarTheme(
    // Zeminle aynı: çubuk ayrı bir şerit gibi durmasın, ekran tek
    // yüzey olarak başlasın. Kaydırınca `scrolledUnderElevation`
    // ayrımı kendiliğinden getiriyor.
    backgroundColor: c.surfaceContainer,
    foregroundColor: c.onSurface,
    elevation: AppElevation.none,
    // İçerik altına kaydığında ince bir ayrım belirir; sabit gölge
    // yerine bu, "kaydırılıyor" bilgisini taşır.
    scrolledUnderElevation: 1,
    surfaceTintColor: c.surfaceTint,
    centerTitle: false,
    titleTextStyle: t.titleLarge,
  );

  static CardThemeData card(ColorScheme c) => CardThemeData(
    color: c.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: c.shadow,
    // Kenarlık **ve** yumuşak gölge. v1'de yalnız kenarlık vardı ve
    // beyaz üstünde beyaz kart görünmüyordu; gölge kartı zeminden
    // koparıyor, kenarlık kenarı tanımlıyor.
    elevation: AppElevation.card,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.lgAll,
      side: BorderSide(color: c.outlineVariant, width: AppBorder.hairline),
    ),
  );

  static DividerThemeData divider(ColorScheme c) => DividerThemeData(
    color: c.outlineVariant,
    thickness: 1,
    space: AppSpacing.xl2,
  );

  // -------------------------------------------------------------------
  // Gezinme
  // -------------------------------------------------------------------

  static NavigationBarThemeData navigation(ColorScheme c, TextTheme t) =>
      NavigationBarThemeData(
        // Beyaz: alt çubuk zeminden ayrışıp ekranı aşağıdan
        // çapalıyor.
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.raised,
        shadowColor: c.shadow,
        height: 68,
        indicatorColor: c.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.fullAll,
        ),
        // Etiketler her zaman görünür: yalnız ikonlu gezinme
        // keşfedilebilirliği düşürür (ui-ux §9 `nav-label-icon`).
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return t.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? c.onSurface : c.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? c.onPrimaryContainer : c.onSurfaceVariant,
          );
        }),
      );

  // -------------------------------------------------------------------
  // Listeler ve seçim denetimleri
  // -------------------------------------------------------------------

  static ListTileThemeData listTile(ColorScheme c, TextTheme t) =>
      ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        minVerticalPadding: AppSpacing.md,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        titleTextStyle: t.bodyLarge,
        subtitleTextStyle: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
        iconColor: c.onSurfaceVariant,
      );

  static CheckboxThemeData checkbox(ColorScheme c) => CheckboxThemeData(
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
    side: BorderSide(color: c.outline, width: 1.5),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return c.onSurface.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.selected)) return c.primary;
      return Colors.transparent;
    }),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );

  static SwitchThemeData switches(ColorScheme c) => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.selected) ? c.onPrimary : c.outline,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? c.primary
          : c.surfaceContainerHigh,
    ),
  );

  // -------------------------------------------------------------------
  // Girişler
  // -------------------------------------------------------------------

  static InputDecorationTheme inputs(ColorScheme c, TextTheme t) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecorationTheme(
      filled: true,
      // Zemin tonu: alanlar beyaz kart üstünde girilebilir olduklarını
      // belli etmeli. Beyaz dolgu beyaz kartta kaybolurdu.
      fillColor: c.surfaceContainer,
      // Dikey dolgu asgari 48dp yüksekliği garantiler
      // (ui-ux §8 `touch-friendly-input`).
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: const OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide.none,
      ),
      enabledBorder: border(c.outlineVariant, 1),
      focusedBorder: border(c.primary, 2),
      errorBorder: border(c.error, 1.5),
      focusedErrorBorder: border(c.error, 2),
      labelStyle: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
      helperStyle: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
      errorStyle: t.bodySmall?.copyWith(color: c.error),
    );
  }

  // -------------------------------------------------------------------
  // Eylemler
  // -------------------------------------------------------------------

  static FilledButtonThemeData filledButton(TextTheme t) =>
      FilledButtonThemeData(style: _buttonBase(t));

  static OutlinedButtonThemeData outlinedButton(ColorScheme c, TextTheme t) =>
      OutlinedButtonThemeData(
        style: _buttonBase(t).copyWith(
          side: WidgetStatePropertyAll(BorderSide(color: c.outline)),
        ),
      );

  static TextButtonThemeData textButton(TextTheme t) => TextButtonThemeData(
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, AppTouch.minSize)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      textStyle: WidgetStatePropertyAll(t.labelLarge),
    ),
  );

  static SegmentedButtonThemeData segmentedButton(
    ColorScheme c,
    TextTheme t,
  ) => SegmentedButtonThemeData(
    style: SegmentedButton.styleFrom(
      minimumSize: const Size(0, AppTouch.minSize),
      textStyle: t.labelLarge,
      selectedBackgroundColor: c.primaryContainer,
      selectedForegroundColor: c.onPrimaryContainer,
    ),
  );

  static ChipThemeData chip(ColorScheme c, TextTheme t) => ChipThemeData(
    backgroundColor: c.surfaceContainer,
    side: BorderSide(color: c.outlineVariant),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
    labelStyle: t.labelMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  );

  /// Dolgulu ve çerçeveli düğmelerin ortak tabanı — dokunma hedefi,
  /// köşe yarıçapı, tipografi tek yerde tanımlı.
  static ButtonStyle _buttonBase(TextTheme t) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(0, AppTouch.minSize)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
    ),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    ),
    textStyle: WidgetStatePropertyAll(t.labelLarge),
  );

  // -------------------------------------------------------------------
  // Katmanlar: alt sayfa, diyalog, bildirim şeridi
  // -------------------------------------------------------------------

  static BottomSheetThemeData bottomSheet(ColorScheme c) =>
      BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.overlay,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      );

  static DialogThemeData dialog(ColorScheme c, TextTheme t) => DialogThemeData(
    backgroundColor: c.surface,
    surfaceTintColor: Colors.transparent,
    elevation: AppElevation.overlay,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
    titleTextStyle: t.titleLarge,
    contentTextStyle: t.bodyMedium,
  );

  static SnackBarThemeData snackBar(ColorScheme c, TextTheme t) =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: t.bodyMedium?.copyWith(color: c.onInverseSurface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      );

  static ProgressIndicatorThemeData progress(ColorScheme c) =>
      ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceContainerHigh,
      );
}
