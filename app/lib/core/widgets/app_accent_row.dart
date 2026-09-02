import 'package:disport/core/design/app_dimens.dart';
import 'package:flutter/material.dart';

/// Sol kenarında vurgu çizgisi taşıyan satır sarmalayıcısı.
///
/// "Sıradaki" dili (v3): Ana Sayfa akışında sıradaki slot, ilaç
/// listesinde sıradaki doz aynı işaretle gösterilir — 2dp'lik alan
/// rengi çizgisi. Arka plan tonu değişmez; çizgi tek başına yeter
/// çünkü satır içeriği de (etiket, saat) durumu söylüyor.
class AppAccentRow extends StatelessWidget {
  const AppAccentRow({
    super.key,
    required this.child,
    required this.color,
    this.active = true,
  });

  final Widget child;
  final Color color;

  /// Kapalıyken çizgi çizilmez ama girinti korunur — liste hizası
  /// satırdan satıra oynamasın.
  final bool active;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          width: 2,
          color: active ? color : Colors.transparent,
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: child,
    ),
  );
}
