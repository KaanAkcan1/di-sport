import 'package:disport/app/app.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/settings/application/settings_providers.dart';
import 'package:disport/features/settings/domain/settings_keys.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'theme_mode_test.dart' show waitFor;

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

  Future<Locale?> readLocale() async {
    final open = container.listen(appLocaleProvider, (_, _) {});
    try {
      return await container.read(appLocaleProvider.future);
    } finally {
      open.close();
    }
  }

  test('varsayılan sistem — null döner', () {
    // Tema koyu dayatılabilirdi, dil dayatılamaz: cihaz hangi dildeyse
    // uygulama da öyle açılmalı.
    expect(readLocale(), completion(isNull));
  });

  test("'en' yazılınca İngilizce", () async {
    await container
        .read(profileRepositoryProvider)
        .set(SettingsKeys.locale, 'en');

    await waitFor(
      () async => (await readLocale())?.languageCode == 'en',
    );
  });

  test("'tr' yazılınca Türkçe", () async {
    await container
        .read(profileRepositoryProvider)
        .set(SettingsKeys.locale, 'tr');

    await waitFor(
      () async => (await readLocale())?.languageCode == 'tr',
    );
  });

  test('tanınmayan değer sisteme düşer', () async {
    // Yedekten dönen eski dosya bozuk değer taşıyabilir.
    await container
        .read(profileRepositoryProvider)
        .set(SettingsKeys.locale, 'klingon');

    expect(await readLocale(), isNull);
  });

  test('dil ve tema anahtarları birbirine karışmaz', () async {
    await container
        .read(profileRepositoryProvider)
        .set(SettingsKeys.locale, 'en');

    // Dil değişmesi temayı bozmamalı; ikisi ayrı anahtar.
    final open = container.listen(themeModeProvider, (_, _) {});
    addTearDown(open.close);
    expect(
      (await container.read(themeModeProvider.future)).name,
      'dark',
    );
  });
}
