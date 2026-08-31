import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/settings/application/settings_providers.dart';
import 'package:disport/features/settings/domain/settings_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Akış sağlayıcısında `.future` **ilk** değeri döner, sonrakini
/// beklemez — "yeni değer geldi mi" sorusu yoklamayla sorulur.
Future<void> waitFor(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('koşul $timeout içinde sağlanmadı');
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Akış sağlayıcısı abone yoksa yükleme sırasında atılıyor; dinleyici
  /// onu ayakta tutuyor.
  Future<ThemeMode> readMode() async {
    final open = container.listen(themeModeProvider, (_, _) {});
    try {
      return await container.read(themeModeProvider.future);
    } finally {
      open.close();
    }
  }

  test('değer yokken varsayılan koyu', () async {
    // Mürekkep dili koyu öncelikli; sisteme bırakmak uygulamayı çoğu
    // cihazda açık modda açardı (spec §2a.1).
    expect(await readMode(), ThemeMode.dark);
  });

  test("'light' yazılınca açık moda geçer", () async {
    await container
        .read(profileRepositoryProvider)
        .set(SettingsKeys.themeMode, 'light');

    await waitFor(() async => await readMode() == ThemeMode.light);
  });

  test("'system' yazılınca cihaza bırakır", () async {
    await container
        .read(profileRepositoryProvider)
        .set(SettingsKeys.themeMode, 'system');

    await waitFor(() async => await readMode() == ThemeMode.system);
  });

  test('tanınmayan değer koyuya düşer, patlamaz', () async {
    // Yedekten dönen eski bir dosya bozuk değer taşıyabilir; uygulama
    // açılmalı, ayar ekranından düzeltilebilmeli.
    await container
        .read(profileRepositoryProvider)
        .set(SettingsKeys.themeMode, 'mor');

    expect(await readMode(), ThemeMode.dark);
  });
}
