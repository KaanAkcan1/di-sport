import 'package:disport/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark themes use Material 3 with matching brightness', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('both themes derive from the same seed colour', () {
    // Aynı tohumdan türeyen iki şemanın birincil renkleri farklı olur
    // (mod farkı) ama ikisi de üretilmiş olmalı — sabit renk atanmamalı.
    expect(AppTheme.light.colorScheme.primary, isNot(Colors.blue));
    expect(
      AppTheme.light.colorScheme.primary,
      isNot(AppTheme.dark.colorScheme.primary),
    );
  });
}
