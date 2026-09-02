import 'dart:async';

import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Açılış ekranı: tohumlama sürerken gösterilen marka animasyonu.
///
/// Davranış sözleşmesi:
/// - İşaret kendini çizer; iş bitmediyse kısa bir nefesle **baştan**
///   çizmeye devam eder (yükleniyor hissi).
/// - [ready] tamamlandığında araya sabit bekleme girmez: o anki tur
///   sonuna kadar götürülür, işaret tam hâlde bir an durur ve
///   [onFinished] çağrılır. En kötü durumda fazladan ~1 tur beklenir.
/// - "Hareketi azalt" açıksa animasyon yok: işaret tam çizili durur,
///   [ready] biter bitmez geçilir.
///
/// Yerel splash (launch_background.xml) ile aynı sahneyi kurar — zemin
/// ve işaret aynı yerde durur, geçiş kesintisiz görünür. Renkler
/// temadan gelmez: tema bu aşamada henüz kurulmadı ve logo renkleri
/// marka sabitidir (bkz. FormalityMark).
class BootSplash extends StatefulWidget {
  const BootSplash({
    super.key,
    required this.ready,
    required this.onFinished,
  });

  /// Açılış işleri (tohumlama) bittiğinde tamamlanan gelecek.
  final Future<void> ready;

  /// Animasyon zarifçe kapandığında çağrılır; gerçek uygulama bunu
  /// bekleyip devralır.
  final VoidCallback onFinished;

  /// Bir çizim turunun süresi.
  static const drawDuration = Duration(milliseconds: 1100);

  /// Tam işaretin, geçiş öncesi ekranda kaldığı kısa an.
  static const holdDuration = Duration(milliseconds: 180);

  /// Turlar arasındaki nefes payı (işaret tam, henüz silinmedi).
  static const restDuration = Duration(milliseconds: 350);

  @override
  State<BootSplash> createState() => _BootSplashState();
}

class _BootSplashState extends State<BootSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BootSplash.drawDuration,
  );
  var _ready = false;
  var _finished = false;
  var _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    widget.ready.whenComplete(() {
      if (!mounted) return;
      _ready = true;
      // Animasyon kapalıysa tur beklenecek bir şey yok: hemen geç.
      if (_reducedMotion) _finish();
      // Değilse mevcut tur status dinleyicisinde tamamlanınca geçilir.
    });
    _controller.addStatusListener((status) async {
      // Hareketi azalt açıkken döngü yok: geçiş whenComplete'te.
      if (_reducedMotion) return;
      if (status != AnimationStatus.completed || _finished) return;
      if (_ready) {
        // Tur tamam ve iş bitti: tam işareti bir an göster, geç.
        await Future<void>.delayed(BootSplash.holdDuration);
        _finish();
      } else {
        // İş sürüyor: kısa nefes, baştan çiz.
        await Future<void>.delayed(BootSplash.restDuration);
        if (!mounted || _finished) return;
        if (_ready) {
          _finish();
        } else {
          _controller.forward(from: 0);
        }
      }
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _controller.value = 1;
      if (_ready) _finish();
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: FormalityMark.brandInk,
      home: ColoredBox(
        color: FormalityMark.brandInk,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => FormalityMark(
              progress: Curves.easeInOutCubic.transform(_controller.value),
              size: 128,
            ),
          ),
        ),
      ),
    );
  }
}
