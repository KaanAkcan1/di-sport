/// Enerji harcaması tahmini — **saf**, veritabanı ve arayüz görmez.
///
/// Kaynak: ACSM metabolik denklemleri (Guidelines for Exercise Testing
/// and Prescription) ve 2024 Adult Compendium of Physical Activities.
///
/// **Her sonuç bir tahmindir** ve arayüzde `≈` ile gösterilir. Kesin
/// rakam vaat etmek kullanıcının kalori dengesini gerçek sanmasına yol
/// açar; bu hesabın hata payı kolayca %20'dir.
library;

import 'package:disport/features/catalog/domain/exercise.dart';

/// Dinlenme metabolizmasının oksijen tüketimi (ml/kg/dk).
///
/// MET tanımının paydası: 1 MET = 3.5 ml/kg/dk.
const _restingVo2 = 3.5;

/// Yürüyüş ve koşu denklemlerinin ayrım hızı (km/sa).
///
/// ACSM yürüyüş denklemini 1.9–6.4 km/sa, koşu denklemini ≥8 km/sa için
/// geçerli sayıyor; arada bir boşluk var çünkü insanlar orada yürümekle
/// koşmak arasında geçiş yapıyor. **7 km/sa'i sınır seçtik** ve iki
/// denklem bu noktada süreksiz: 7 km/sa yürüyüş ≈ 5.1 MET, koşu ≈ 7.7
/// MET. Süreklilik uğruna aradaki değeri enterpolasyonla uydurmak,
/// dayanağı olmayan bir sayı üretmek olurdu.
const _runningThresholdKmh = 7.0;

/// Bisiklette efor seviyesinin MET karşılığı (Compendium 01010-01030).
const _cyclingMet = {
  Effort.light: 5.0,
  Effort.moderate: 7.0,
  Effort.vigorous: 10.5,
};

/// Kuvvet antrenmanının MET'i (Compendium 02054, vigorous effort).
///
/// Set başına değil **seans süresine** uygulanıyor: aradaki dinlenme de
/// harcama üretiyor ve setlerin toplam süresi seansın süresi değil.
const strengthTrainingMet = 5.0;

/// Bir hareketin o andaki MET değeri.
///
/// [met] kataloğun taşıdığı sabit değer; [model] `fixed` ise doğrudan
/// o dönüyor. Diğer iki model girdiye bakıyor ve girdi eksikse
/// **katalogun sabit değerine düşüyor** — hesap yapamayınca sıfır
/// döndürmek "hiç yakmadın" demek olurdu.
double metFor({
  required double met,
  required MetModel model,
  double? speedKmh,
  double? gradePct,
  Effort? effort,
}) => switch (model) {
  MetModel.fixed => met,
  MetModel.cycling => _cyclingMet[effort] ?? met,
  MetModel.treadmill => speedKmh == null
      ? met
      : _treadmillMet(speedKmh: speedKmh, gradePct: gradePct ?? 0),
};

/// ACSM yürüyüş/koşu denklemleri.
///
/// Hız m/dk'ya çevriliyor, eğim **kesire** (`%8 → 0.08`). Bu birim
/// dönüşümü atlanırsa sonuç 25 kat şişer — denklemler yüzde değil oran
/// bekliyor.
double _treadmillMet({required double speedKmh, required double gradePct}) {
  final metersPerMinute = speedKmh * 1000 / 60;
  final grade = gradePct / 100;

  final vo2 = speedKmh < _runningThresholdKmh
      // Yürüyüş: 0.1 × hız + 1.8 × hız × eğim + dinlenme
      ? 0.1 * metersPerMinute + 1.8 * metersPerMinute * grade + _restingVo2
      // Koşu: dikey bileşenin katsayısı yarıya iner (sıçrama fazında
      // ayak yerden kesiliyor).
      : 0.2 * metersPerMinute + 0.9 * metersPerMinute * grade + _restingVo2;

  return vo2 / _restingVo2;
}

/// MET × kilo × saat.
///
/// Negatif ya da sıfır süre 0 veriyor; çağıranın elinde açık bir seans
/// olabiliyor ve `endedAt - startedAt` saat farkıyla eksiye düşebilir.
double kcalFor({
  required double met,
  required double weightKg,
  required Duration duration,
}) {
  final hours = duration.inSeconds / 3600;
  if (hours <= 0) return 0;
  return met * weightKg * hours;
}
