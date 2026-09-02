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
    required this.areaDiet,
    required this.areaDietSurface,
    required this.areaSport,
    required this.areaSportSurface,
    required this.areaHealth,
    required this.areaHealthSurface,
    required this.areaMed,
    required this.areaMedSurface,
    required this.areaEnergy,
    required this.areaEnergySurface,
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

  /// Alan renkleri (v3): beş sekmenin kimliği. Açık modda koyulaştırılmış
  /// varyantlar döner (`areaSportOnLight`…) — eşik düşmez, renk koyulaşır.
  /// Diyet marka yeşilini paylaşır.
  final Color areaDiet;
  final Color areaDietSurface;
  final Color areaSport;
  final Color areaSportSurface;
  final Color areaHealth;
  final Color areaHealthSurface;
  final Color areaMed;
  final Color areaMedSurface;
  final Color areaEnergy;
  final Color areaEnergySurface;

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
    areaDiet: AppPalette.brand700,
    areaDietSurface: AppPalette.brand50,
    areaSport: AppPalette.areaSportOnLight,
    areaSportSurface: AppPalette.areaSportSurfaceLight,
    areaHealth: AppPalette.areaHealthOnLight,
    areaHealthSurface: AppPalette.areaHealthSurfaceLight,
    areaMed: AppPalette.areaMedOnLight,
    areaMedSurface: AppPalette.areaMedSurfaceLight,
    areaEnergy: AppPalette.areaEnergyOnLight,
    areaEnergySurface: AppPalette.areaEnergySurfaceLight,
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
    areaDiet: AppPalette.brand400,
    areaDietSurface: AppPalette.successSurfaceDark,
    areaSport: AppPalette.areaSport,
    areaSportSurface: AppPalette.areaSportSurfaceDark,
    areaHealth: AppPalette.areaHealth,
    areaHealthSurface: AppPalette.areaHealthSurfaceDark,
    areaMed: AppPalette.areaMed,
    areaMedSurface: AppPalette.areaMedSurfaceDark,
    areaEnergy: AppPalette.areaEnergy,
    areaEnergySurface: AppPalette.areaEnergySurfaceDark,
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
    Color? areaDiet,
    Color? areaDietSurface,
    Color? areaSport,
    Color? areaSportSurface,
    Color? areaHealth,
    Color? areaHealthSurface,
    Color? areaMed,
    Color? areaMedSurface,
    Color? areaEnergy,
    Color? areaEnergySurface,
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
      areaDiet: areaDiet ?? this.areaDiet,
      areaDietSurface: areaDietSurface ?? this.areaDietSurface,
      areaSport: areaSport ?? this.areaSport,
      areaSportSurface: areaSportSurface ?? this.areaSportSurface,
      areaHealth: areaHealth ?? this.areaHealth,
      areaHealthSurface: areaHealthSurface ?? this.areaHealthSurface,
      areaMed: areaMed ?? this.areaMed,
      areaMedSurface: areaMedSurface ?? this.areaMedSurface,
      areaEnergy: areaEnergy ?? this.areaEnergy,
      areaEnergySurface: areaEnergySurface ?? this.areaEnergySurface,
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
      areaDiet: Color.lerp(areaDiet, other.areaDiet, t)!,
      areaDietSurface: Color.lerp(areaDietSurface, other.areaDietSurface, t)!,
      areaSport: Color.lerp(areaSport, other.areaSport, t)!,
      areaSportSurface:
          Color.lerp(areaSportSurface, other.areaSportSurface, t)!,
      areaHealth: Color.lerp(areaHealth, other.areaHealth, t)!,
      areaHealthSurface:
          Color.lerp(areaHealthSurface, other.areaHealthSurface, t)!,
      areaMed: Color.lerp(areaMed, other.areaMed, t)!,
      areaMedSurface: Color.lerp(areaMedSurface, other.areaMedSurface, t)!,
      areaEnergy: Color.lerp(areaEnergy, other.areaEnergy, t)!,
      areaEnergySurface:
          Color.lerp(areaEnergySurface, other.areaEnergySurface, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  /// Anlamsal renklere kısa erişim: `context.semantic.success`
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
