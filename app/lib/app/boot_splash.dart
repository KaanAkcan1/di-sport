import 'dart:async';

import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Açılış ekranı: tohumlama sürerken gösterilen marka animasyonu.
///
/// Davranış sözleşmesi:
/// - Bekleme sırasında işaret bir EKG monitörü gibi yaşar: kuyruğu
///   silinen bir vuruş hat boyunca akar, uçtan çıkar, kısa bir
///   sessizlikten sonra yeniden gelir (kalp atışı ritmi).
/// - [ready] tamamlandığında araya sabit bekleme girmez: o anki
///   süpürme biter bitmez **final çizim** oynar — çizgi sıfırdan
///   sonuna çizilir, onay işareti tamamlanır, bir an durur ve
///   [onFinished] çağrılır. Bitti gitti.
/// - "Hareketi azalt" açıksa animasyon yok: işaret tam çizili durur,
///   [ready] biter bitmez geçilir.
///
/// Yerel splash (launch_background.xml) yalnız zemin rengidir — sabit
/// işaret bilerek yok: kullanıcının gördüğü ilk işaret animasyonun
/// kendisi olmalı, yoksa "resim hazır geldi" hissi doğuyor. Renkler
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

  /// Bir EKG süpürmesinin süresi (vuruşun hattı kat edişi).
  static const sweepDuration = Duration(milliseconds: 850);

  /// Süpürmeler arasındaki sessizlik — kalp atışının "lup-dup" arası.
  static const restDuration = Duration(milliseconds: 400);

  /// Final çizimin süresi (sıfırdan tam onay işaretine).
  static const drawDuration = Duration(milliseconds: 1100);

  /// Tam işaretin, geçiş öncesi ekranda kaldığı kısa an.
  static const holdDuration = Duration(milliseconds: 180);

  /// Süpürme kuyruğunun uzunluğu (yol oranı).
  static const sweepTrail = 0.45;

  @override
  State<BootSplash> createState() => _BootSplashState();
}

enum _Phase { sweeping, finishing }

class _BootSplashState extends State<BootSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this);
  var _phase = _Phase.sweeping;
  var _ready = false;
  var _finished = false;
  var _reducedMotion = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    widget.ready.whenComplete(() {
      if (!mounted) return;
      _ready = true;
      // Animasyon kapalıysa beklenecek tur yok: hemen geç. Değilse
      // döngü, süren süpürmenin sonunda final çizime geçer.
      if (_reducedMotion) _finish();
    });
  }

  /// Animasyon akışı, durum dinleyicisi yerine düz bir döngü:
  /// süpürme → sessizlik → (iş bittiyse) final çizim → an → geçiş.
  Future<void> _run() async {
    try {
      while (mounted && !_finished) {
        if (_ready) {
          setState(() => _phase = _Phase.finishing);
          _controller.duration = BootSplash.drawDuration;
          await _controller.forward(from: 0).orCancel;
          await Future<void>.delayed(BootSplash.holdDuration);
          _finish();
          return;
        }
        _controller.duration = BootSplash.sweepDuration;
        await _controller.forward(from: 0).orCancel;
        // İş bittiyse sessizlik atlanır: final çizime hemen geçilir.
        if (!_ready) {
          await Future<void>.delayed(BootSplash.restDuration);
        }
      }
    } on TickerCanceled {
      // Widget söküldü; yapılacak bir şey yok.
    }
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
      _controller.stop();
      _controller.value = 1;
      _phase = _Phase.finishing;
      if (_ready) _finish();
    } else if (!_started) {
      _started = true;
      _run();
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
            builder: (context, _) {
              final v = _controller.value;
              if (_phase == _Phase.finishing || _reducedMotion) {
                return FormalityMark(
                  progress: Curves.easeInOutCubic.transform(v),
                  size: 128,
                );
              }
              // Süpürme: vuruşun başı yolu 0→1 kat eder, kuyruk onu
              // `sweepTrail` geriden izler ve uçtan tamamen çıkar.
              const trail = BootSplash.sweepTrail;
              final t = Curves.easeInOut.transform(v) * (1 + trail);
              final head = t.clamp(0.0, 1.0);
              final tailStart = (t - trail).clamp(0.0, 1.0);
              return FormalityMark(
                progress: head,
                trail: head - tailStart,
                size: 128,
              );
            },
          ),
        ),
      ),
    );
  }
}
