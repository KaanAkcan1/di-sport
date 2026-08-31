import 'dart:io';

import 'package:disport/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// M12 — bileşen katmanının mürekkep sözleşmesi.
void main() {
  for (final (mode, theme) in [
    ('Açık', AppTheme.light),
    ('Koyu', AppTheme.dark),
  ]) {
    group('$mode mod', () {
      test('kart gölgesiz ve kıl çizgili', () {
        final card = theme.cardTheme;
        expect(card.elevation, 0);
        expect(card.shadowColor, Colors.transparent);
        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.side.color, theme.colorScheme.outlineVariant);
      });

      test('kart zeminden bir ton yukarıda', () {
        // Gölge yoksa ayrımın tek kaynağı bu. Eşit olurlarsa kart
        // yeniden görünmez olur — M6'nın düzelttiği kusur geri gelir.
        expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerHigh);
        expect(
          theme.cardTheme.color,
          isNot(theme.scaffoldBackgroundColor),
        );
      });

      test('gezinme çubuğu gölgesiz, zeminden ayrı tonda', () {
        final nav = theme.navigationBarTheme;
        expect(nav.elevation, 0);
        expect(nav.shadowColor, Colors.transparent);
        expect(nav.backgroundColor, theme.colorScheme.surfaceContainerLow);
      });

      test('ön plan katmanları gölge yerine kenarlıkla ayrışır', () {
        // Tek istisna: perde arkayı karartınca ton farkı yetmiyor.
        // Çözüm gölge değil, belirgin kenarlık.
        final sheet = theme.bottomSheetTheme;
        expect(sheet.elevation, 0);
        expect(
          (sheet.shape! as RoundedRectangleBorder).side.color,
          theme.colorScheme.outline,
        );

        final dialog = theme.dialogTheme;
        expect(dialog.elevation, 0);
        expect(
          (dialog.shape! as RoundedRectangleBorder).side.color,
          theme.colorScheme.outline,
        );
      });

      test('sekme göstergesi marka yeşili', () {
        expect(theme.tabBarTheme.indicatorColor, theme.colorScheme.primary);
        expect(theme.tabBarTheme.labelColor, theme.colorScheme.tertiary);
      });
    });
  }

  test('lib altında AppElevation kullanımı kalmadı', () {
    // Nöbetçi: mürekkep dilinde gölge yok. Bir gölge geri sızarsa
    // burası düşer ve karar yeniden tartışılır.
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('app_dimens.dart'))
        .where((f) => f.readAsStringSync().contains('AppElevation.'))
        .map((f) => f.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason: 'Mürekkep dilinde gölge yok:\n${offenders.join('\n')}',
    );
  });
}
