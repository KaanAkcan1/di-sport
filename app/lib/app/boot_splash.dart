import 'package:disport/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Açılış ekranı: tohumlama sürerken gösterilen marka animasyonu.
///
/// Yerel splash (launch_background.xml) ile aynı sahneyi kurar — zemin
/// ve işaret aynı yerde durur, geçiş kesintisiz görünür; fark yalnız
/// çizginin kendini çizmesidir. Tohumlama animasyondan önce biterse
/// gerçek uygulama devralır; işaret yarım kalmış görünmez çünkü ilk
/// kare zaten dolu veriyle gelir.
///
/// Renkler temadan gelmez: tema bu aşamada henüz kurulmadı ve logo
/// renkleri marka sabitidir (bkz. FormalityMark).
class BootSplash extends StatelessWidget {
  const BootSplash({super.key});

  /// Açılışın en az bekleyeceği süre: çizim (1100 ms) + kısa nefes.
  ///
  /// Tohumlama genelde bundan hızlı biter; beklenmezse işaret yarıda
  /// kesilir ve animasyonun anlamı kaybolur. Marka anı için bilinçli
  /// ödenen gecikme budur — daha fazlası açılışı hantallaştırır.
  static const minimumDuration = Duration(milliseconds: 1350);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: FormalityMark.brandInk,
      home: const ColoredBox(
        color: FormalityMark.brandInk,
        child: Center(
          child: AnimatedFormalityMark(size: 128),
        ),
      ),
    );
  }
}
