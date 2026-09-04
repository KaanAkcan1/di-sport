import 'package:flutter/material.dart';

/// Formality marka işareti — V2a "nabız onayı".
///
/// EKG hattı gibi düz başlayan çizgi küçük bir vuruş yapar, derin inişi
/// onay işaretinin kendisine dönüşür. Geometri `tools/build_brand_assets.py`
/// ile birebir aynıdır; ikisi birlikte değişir.
///
/// Renkler tema üzerinden **gelmez**: bu bir logo, arayüz bileşeni değil.
/// Logonun renkleri marka sabitidir ve temayla değişmez
/// (docs/superpowers/specs/2026-09-02-formality-gorsel-kimlik.md).
class FormalityMark extends StatelessWidget {
  const FormalityMark({
    super.key,
    this.progress = 1.0,
    this.size = 120,
    this.color = brandGreen,
    this.trail = 1.0,
  });

  /// Çizimin tamamlanma oranı: 0 = boş, 1 = işaret tamam.
  ///
  /// Yol tek parça olduğu için animasyon doğal biter: son çizilen
  /// bölüm onay işaretini tamamlayan uzun yükseliştir.
  final double progress;

  /// Görünen kuyruğun uzunluğu, yol uzunluğunun oranı olarak.
  ///
  /// 1.0 = baştan itibaren her şey görünür (çizim animasyonu).
  /// Küçük değerler EKG süpürmesi verir: hat boyunca akan, arkası
  /// silinen bir vuruş. Açılış döngüsü bunu kullanır.
  final double trail;

  /// İşaretin genişliği; yükseklik orandan türetilir.
  final double size;

  final Color color;

  /// Vue yeşili — markanın tek dokunulmaz rengi.
  static const brandGreen = Color(0xFF42B883);

  /// Gece Grafiti zemini; açılış ekranı bunun üstüne çizer.
  static const brandInk = Color(0xFF0F1B16);

  @override
  Widget build(BuildContext context) {
    // 460'lık ızgarada içerik kutusu 306x194: yükseklik oranı korunur.
    return CustomPaint(
      size: Size(size, size * _MarkPainter.contentHeight / _MarkPainter.contentWidth),
      painter: _MarkPainter(
        progress: progress.clamp(0.0, 1.0),
        color: color,
        trail: trail.clamp(0.0, 1.0),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.progress,
    required this.color,
    required this.trail,
  });

  final double progress;
  final Color color;
  final double trail;

  /// V2a geometrisi, 460'lık marka ızgarasında.
  static const points = <Offset>[
    Offset(66, 252),
    Offset(138, 252),
    Offset(162, 218),
    Offset(196, 252),
    Offset(238, 342),
    Offset(372, 148),
  ];
  static const strokeOnGrid = 30.0;
  static const contentWidth = 306.0; // x: 66..372
  static const contentHeight = 194.0; // y: 148..342

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final scale = size.width / contentWidth;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(
        (points[i].dx - 66) * scale,
        (points[i].dy - 148) * scale,
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }

    // İlerleme, yol uzunluğu üzerinden kesilir: çizgi gerçekten
    // "çiziliyor" hissi verir, parça parça belirmez. Kuyruk 1'den
    // kısaysa vuruşun arkası silinir (EKG süpürmesi).
    final metric = path.computeMetrics().first;
    final head = metric.length * progress;
    final tailStart = trail >= 1 ? 0.0 : (head - metric.length * trail);
    if (head - tailStart <= 0) return;
    final visible = metric.extractPath(tailStart < 0 ? 0 : tailStart, head);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeOnGrid * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(visible, paint);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trail != trail;
}

/// İşareti kendi kendine çizen sürüm — açılış ve yükleme durumları için.
///
/// Bir kez 0→1 çizer ve tamamlanmış hâlde kalır; dönen bir yükleme
/// simgesi değildir. "Hareketi azalt" açıksa animasyonu atlayıp
/// doğrudan tam işareti gösterir (ui-ux `reduced-motion`).
class AnimatedFormalityMark extends StatefulWidget {
  const AnimatedFormalityMark({
    super.key,
    this.size = 120,
    this.duration = const Duration(milliseconds: 1100),
    this.color = FormalityMark.brandGreen,
  });

  final double size;
  final Duration duration;
  final Color color;

  @override
  State<AnimatedFormalityMark> createState() => _AnimatedFormalityMarkState();
}

class _AnimatedFormalityMarkState extends State<AnimatedFormalityMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery bağımlılığı build öncesi burada okunur; ayar açıksa
    // animasyon kurulmaz, işaret ilk kareden tam çizilir.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => FormalityMark(
        progress: Curves.easeInOutCubic.transform(_controller.value),
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
