import 'package:flutter/material.dart';

/// Kural ikonlarının sabit kataloğu.
///
/// Kullanıcı serbest ikon giremiyor, listeden seçiyor. İki gerekçe:
/// ikon seti tutarlı kalmalı (ui-ux §4 `icon-style-consistent`) ve
/// veritabanında saklanan şey kod noktası değil anahtar olmalı.
///
/// Sunum katmanında duruyor çünkü `IconData` bir arayüz tipi; tablo
/// dosyası Flutter'a bağımlı olmamalı.
abstract final class RuleIcons {
  static const _icons = <String, IconData>{
    'water': Icons.water_drop_outlined,
    'noDrinks': Icons.no_drinks_outlined,
    'fitness': Icons.fitness_center,
    'pill': Icons.medication_outlined,
    'walk': Icons.directions_walk,
    'run': Icons.directions_run,
    'sleep': Icons.bedtime_outlined,
    'sun': Icons.wb_sunny_outlined,
    'book': Icons.menu_book_outlined,
    'meditation': Icons.self_improvement,
    'noSmoking': Icons.smoke_free,
    'meal': Icons.restaurant_outlined,
    'scale': Icons.monitor_weight_outlined,
    'check': Icons.check_circle_outline,
  };

  /// Seçicide gösterilecek sıra.
  static List<String> get keys => _icons.keys.toList();

  /// Bilinmeyen anahtar sessizce genel bir işarete düşer — ileride bir
  /// anahtar kaldırılsa bile kayıtlı kural görünmez olmamalı.
  static IconData resolve(String key) =>
      _icons[key] ?? Icons.check_circle_outline;
}
