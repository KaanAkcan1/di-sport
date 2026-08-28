import 'package:flutter/material.dart';

/// Uygulama teması.
///
/// Tek tohum renkten iki mod türetilir (spec Bölüm 6). Renkleri tek tek
/// elle atamak yerine `ColorScheme.fromSeed` kullanmak, açık ve koyu
/// modun kontrast kurallarını Material'a bırakır — okunabilirlik
/// bizim tahminimize değil, üretilen palete bağlı olur.
abstract final class AppTheme {
  /// Koyu yeşil — sağlık ve spor bağlamı.
  static const _seed = Color(0xFF2E7D32);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  );
}
