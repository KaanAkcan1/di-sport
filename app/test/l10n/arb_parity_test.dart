import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Çeviri dosyalarının sözleşmesi.
///
/// **Neden var:** çeviri unutmak sessiz bir hata. Anahtar İngilizce
/// dosyaya eklenmezse uygulama İngilizce modda Türkçe metin gösterir
/// ya da (gen_l10n'un davranışına göre) hiç göstermez — ikisi de
/// derlemede görünmez. Bu test onu görünür yapıyor.
void main() {
  Map<String, dynamic> load(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync())
          as Map<String, dynamic>;

  /// `@` ile başlayanlar üstveri (`@@locale`, `@anahtar` açıklamaları).
  Set<String> keysOf(Map<String, dynamic> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toSet();

  final tr = load('app_tr.arb');
  final en = load('app_en.arb');

  test('tr ve en anahtar kümeleri birebir aynı', () {
    final trKeys = keysOf(tr);
    final enKeys = keysOf(en);

    // Çift yönlü: eksik çeviri de, artık kalmış fazlalık anahtar da
    // hata. Fazlalık zararsız görünür ama ölü metin biriktirir.
    expect(
      trKeys.difference(enKeys),
      isEmpty,
      reason: 'çevrilmemiş anahtar var',
    );
    expect(
      enKeys.difference(trKeys),
      isEmpty,
      reason: 'en fazlalık anahtar taşıyor',
    );
  });

  test('hiçbir değer boş değil', () {
    for (final (name, arb) in [('app_tr.arb', tr), ('app_en.arb', en)]) {
      for (final entry in arb.entries) {
        if (entry.key.startsWith('@')) continue;
        expect(
          (entry.value as String).trim(),
          isNotEmpty,
          reason: '$name → ${entry.key} boş',
        );
      }
    }
  });

  test('locale damgaları doğru', () {
    expect(tr['@@locale'], 'tr');
    expect(en['@@locale'], 'en');
  });

  test('yer tutucular iki dilde de aynı', () {
    // "{count} × {reps}" gibi ICU yer tutucuları çeviride kaybolursa
    // metin çalışma zamanında patlar, derlemede değil.
    final placeholder = RegExp(r'\{(\w+)\}');

    for (final key in keysOf(tr)) {
      Set<String> namesIn(String value) =>
          placeholder.allMatches(value).map((m) => m.group(1)!).toSet();

      expect(
        namesIn(en[key] as String),
        namesIn(tr[key] as String),
        reason: '$key: yer tutucular eşleşmiyor',
      );
    }
  });
}
