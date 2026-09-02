/// Tarihli tek tartı.
typedef WeightPoint = ({String date, double value});

/// Hareketli ortalamanın tek noktası.
typedef TrendPoint = ({String date, double avg});

/// Kayan pencere ortalaması.
///
/// İlerleme ekranının ana çizgisi budur, ham tartı değil. Gerekçe spec
/// 6'da: günlük kilo tuz, su ve bağırsak içeriğiyle ±1 kg oynar; bu
/// gürültüye tepki veren kullanıcı iki günde bir moral bozar. Ortalama
/// yönü gösterir, günü değil.
///
/// **Eksik günler doldurulmaz.** Girdi noktaları neyse pencere onları
/// sayar; tartılmayan gün "aynı kilo" varsayılmaz. Kullanıcı üç gün
/// tartılmadıysa bilinen tek şey üç ölçüm eksik olduğudur — araya
/// uydurulan değer, olmayan bir eğilim çizer.
///
/// Baştaki noktalarda pencere henüz dolmadığı için eldeki kadarıyla
/// ortalanır; çıktı her zaman girdiyle aynı uzunlukta ve aynı tarihlerde.
List<TrendPoint> movingAverage(
  List<WeightPoint> points, {
  int window = 7,
}) {
  assert(window > 0, 'Pencere en az bir nokta olmalı.');
  if (points.isEmpty) return const [];

  final result = <TrendPoint>[];
  for (var index = 0; index < points.length; index++) {
    final from = index - window + 1;
    final slice = points.sublist(from < 0 ? 0 : from, index + 1);
    final sum = slice.fold<double>(0, (total, p) => total + p.value);
    result.add((date: points[index].date, avg: sum / slice.length));
  }
  return result;
}
