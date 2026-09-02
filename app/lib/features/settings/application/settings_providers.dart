import 'package:disport/app/app.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/settings/data/weekly_windows_repository.dart';
import 'package:disport/features/settings/domain/settings_keys.dart';
import 'package:disport/features/settings/domain/weekly_window.dart';
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

@riverpod
WeeklyWindowsRepository weeklyWindowsRepository(Ref ref) =>
    WeeklyWindowsRepository(ref.watch(appDatabaseProvider));

/// Haftalık mesai ve yasaklı saat pencereleri.
@riverpod
Stream<List<WeeklyWindow>> weeklyWindows(Ref ref) =>
    ref.watch(weeklyWindowsRepositoryProvider).watchAll();

/// Görünüm modu — **varsayılan koyu**.
///
/// M12'de mürekkep dili koyu öncelikli tasarlandı; sistem tercihine
/// bırakmak çoğu cihazda uygulamayı açık modda açar ve kullanıcı
/// tasarımın asıl hâlini hiç görmez. "Sistem" bilinçli seçilebilir bir
/// seçenek, varsayılan değil.
///
/// Akış olarak okunuyor: ayar değişince tema anında dönmeli, uygulamayı
/// yeniden başlatmayı beklememeli.
@riverpod
Stream<ThemeMode> themeMode(Ref ref) {
  return ref.watch(profileRepositoryProvider).watchAll().map((values) {
    return switch (values[SettingsKeys.themeMode]) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };
  });
}

/// Arayüz dili — `null` ise cihazın dili kullanılır.
///
/// Tema modundan farklı olarak varsayılan **sistem**: kullanıcının
/// cihazı hangi dildeyse uygulama da o dilde açılmalı. Tema bir tasarım
/// kararıydı, dil bir erişim meselesi.
@riverpod
Stream<Locale?> appLocale(Ref ref) {
  return ref.watch(profileRepositoryProvider).watchAll().map((values) {
    return switch (values[SettingsKeys.locale]) {
      'tr' => const Locale('tr'),
      'en' => const Locale('en'),
      _ => null,
    };
  });
}
