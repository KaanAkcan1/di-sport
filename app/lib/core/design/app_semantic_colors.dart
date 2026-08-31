import 'package:disport/core/design/app_palette.dart';
import 'package:flutter/material.dart';

/// Material'ın `ColorScheme`'i marka ve hata renklerini tanımlar ama
/// bu uygulamanın ihtiyaç duyduğu durum eksenlerini kapsamaz:
/// gün yapıldı/kaçırıldı, tahlil referans aralığında mı, seri kaç gün.
///
/// Bunları `ThemeExtension` olarak eklemek üç şey kazandırır:
/// açık/koyu mod otomatik çözülür, widget'lar ham hex görmez
/// (ui-ux §6 `color-semantic`), ve yeni bir durum ekseni gerektiğinde
/// tek dosya değişir.
///
/// Kullanım: `context.semantic.success`
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successSurface,
    required this.warning,
    required this.onWarning,
    required this.warningSurface,
    required this.danger,
    required this.onDanger,
    required this.dangerSurface,
    required this.info,
    required this.hairline,
    required this.chartSeries,
    required this.chartGrid,
    required this.chartMuted,
  });

  /// Yapıldı, referans aralığında, hedefe ulaşıldı.
  final Color success;
  final Color onSuccess;
  final Color successSurface;

  /// Sınırda, vadesi yaklaşan tahlil, hedefin altında ama kritik değil.
  final Color warning;
  final Color onWarning;
  final Color warningSurface;

  /// Kaçak gün, referans dışı değer, iki gün üst üste kaçırma.
  final Color danger;
  final Color onDanger;
  final Color dangerSurface;

  /// Bilgilendirme — eylem gerektirmeyen bildirimler.
  final Color info;

  /// Liste içi bölme çizgisi — mürekkep dilinin ayırma aracı (M12).
  ///
  /// `outlineVariant`'tan ayrı: o bir *kenarlık* rengi (kart çerçevesi,
  /// input alanı), bu bir *ayraç*. Mürekkep dilinde kart ve gölge
  /// olmadığı için satırları ayıran tek şey bu çizgi; kenarlıkla aynı
  /// tonda olursa liste ızgaraya döner.
  final Color hairline;

  /// Grafik serileri, sırayla kullanılır. Okabe-Ito paleti: renk
  /// körlüğünde ayırt edilebilir. Yine de renk tek başına yeterli
  /// sayılmaz; çizgi deseni ve etiketle desteklenir.
  final List<Color> chartSeries;

  /// Grafik ızgarası — veriyle yarışmayacak kadar soluk
  /// (ui-ux §10 `gridline-subtle`).
  final Color chartGrid;

  /// Ham günlük veri noktaları — vurgulanan trend çizgisinin gerisinde
  /// kalması gereken ikincil seri.
  final Color chartMuted;

  static const light = AppSemanticColors(
    success: AppPalette.successLight,
    onSuccess: AppPalette.neutral0,
    successSurface: AppPalette.successSurfaceLight,
    warning: AppPalette.warningLight,
    onWarning: AppPalette.neutral0,
    warningSurface: AppPalette.warningSurfaceLight,
    danger: AppPalette.dangerLight,
    onDanger: AppPalette.neutral0,
    dangerSurface: AppPalette.dangerSurfaceLight,
    info: AppPalette.infoLight,
    hairline: AppPalette.ivoryHairline,
    chartSeries: [
      AppPalette.chartBlue,
      AppPalette.chartOrangeOnLight,
      AppPalette.chartGreen,
      AppPalette.chartPinkOnLight,
      AppPalette.chartVermillion,
    ],
    chartGrid: AppPalette.ivory200,
    chartMuted: AppPalette.neutral400,
  );

  static const dark = AppSemanticColors(
    success: AppPalette.successDark,
    onSuccess: AppPalette.ink950,
    successSurface: AppPalette.successSurfaceDark,
    warning: AppPalette.warningDark,
    onWarning: AppPalette.ink950,
    warningSurface: AppPalette.warningSurfaceDark,
    danger: AppPalette.dangerDark,
    onDanger: AppPalette.ink950,
    dangerSurface: AppPalette.dangerSurfaceDark,
    info: AppPalette.infoDark,
    hairline: AppPalette.ink750,
    chartSeries: [
      AppPalette.chartSky,
      AppPalette.chartOrange,
      AppPalette.chartGreen,
      AppPalette.chartPink,
      AppPalette.chartYellow,
    ],
    chartGrid: AppPalette.ink750,
    chartMuted: AppPalette.mist500,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successSurface,
    Color? warning,
    Color? onWarning,
    Color? warningSurface,
    Color? danger,
    Color? onDanger,
    Color? dangerSurface,
    Color? info,
    Color? hairline,
    List<Color>? chartSeries,
    Color? chartGrid,
    Color? chartMuted,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successSurface: successSurface ?? this.successSurface,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningSurface: warningSurface ?? this.warningSurface,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      info: info ?? this.info,
      hairline: hairline ?? this.hairline,
      chartSeries: chartSeries ?? this.chartSeries,
      chartGrid: chartGrid ?? this.chartGrid,
      chartMuted: chartMuted ?? this.chartMuted,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      info: Color.lerp(info, other.info, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      chartSeries: t < 0.5 ? chartSeries : other.chartSeries,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartMuted: Color.lerp(chartMuted, other.chartMuted, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  /// Anlamsal renklere kısa erişim: `context.semantic.success`
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
