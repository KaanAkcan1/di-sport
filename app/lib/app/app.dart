import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/catalog/presentation/catalog_screen.dart';
import 'package:disport/features/health/presentation/health_screen.dart';
import 'package:disport/features/plan/presentation/plan_screen.dart';
import 'package:disport/features/progress/presentation/progress_screen.dart';
import 'package:disport/features/settings/presentation/onboarding_screen.dart';
import 'package:disport/features/settings/presentation/settings_screen.dart';
import 'package:disport/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Veritabanının tek örneği.
///
/// Provider olarak tanımlanması testlerde `overrideWithValue` ile bellek
/// içi bir veritabanıyla değiştirilebilmesini sağlar — ekran testleri
/// gerçek dosyaya dokunmaz.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

class DisportApp extends StatelessWidget {
  const DisportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'di@sport',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Mod seçimi cihaza bırakılır; sabah 05:45 antrenmanında koyu mod
      // gözü yormamalı, gündüz açık mod okunur olmalı.
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // Sistem yazı boyutu büyütüldüğünde arayüz bozulmadan büyümeli,
      // ama sınırsız da olmamalı: 1.6x üstünde iki satırlık etiketler
      // taşmaya başlıyor (ui-ux §1 `dynamic-type`).
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.6,
        child: child!,
      ),
      home: const _Root(),
    );
  }
}

/// İlk açılışta onboarding, sonrasında kabuk.
///
/// Ölçüt profilde boy alanının dolu olması: `context.md`'nin birinci
/// bölümü onsuz eksik kalır ve AI'ın ürettiği plan jenerikleşir.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(isOnboardedProvider);

    return AppAsyncView<bool>(
      value: onboarded,
      loading: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      onRetry: () => ref.invalidate(isOnboardedProvider),
      data: (done) => done
          ? const _Shell()
          : OnboardingScreen(
              // Form kaydedince provider yeniden okunuyor ve bu widget
              // kendiliğinden kabuğa geçiyor; ayrı bir bayrak gerekmiyor.
              onDone: () => ref.invalidate(isOnboardedProvider),
            ),
    );
  }
}

/// Alt gezinmeli kabuk: beş sekme (spec Bölüm 6).
///
/// `IndexedStack` kullanılıyor çünkü sekmeler arası geçişte ekranların
/// durumu (kaydırma konumu, yarım doldurulmuş form) korunmalı;
/// her geçişte yeniden inşa edilse antrenman sayacı sıfırlanırdı.
class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

/// Seçili ve seçili olmayan ikon ayrı: dolu ikon aktif konumu renkten
/// bağımsız olarak da belli eder (ui-ux §1 `color-not-only`,
/// §9 `nav-state-active`).
typedef _Tab = ({
  String label,
  IconData icon,
  IconData selectedIcon,
  String semanticHint,
  Widget screen,
});

class _ShellState extends State<_Shell> {
  var _index = 0;

  static const List<_Tab> _tabs = [
    (
      label: 'Bugün',
      icon: Icons.today_outlined,
      selectedIcon: Icons.today,
      semanticHint: 'Günün programı ve kayıtları',
      screen: TodayScreen(),
    ),
    (
      label: 'Plan',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      semanticHint: 'Dört haftalık program',
      screen: PlanScreen(),
    ),
    (
      label: 'İlerleme',
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      semanticHint: 'Kilo trendi ve haftalık özet',
      screen: ProgressScreen(),
    ),
    (
      label: 'Sağlık',
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      semanticHint: 'Tahliller ve ölçümler',
      screen: HealthScreen(),
    ),
    (
      label: 'Katalog',
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      semanticHint: 'Egzersiz kütüphanesi',
      screen: CatalogScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].label),
        actions: [
          IconButton(
            key: const Key('settings-button'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Profil ve yaşam tarzı',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        // Alt çubuk kendi güvenli alanını yönetiyor; gövdede yalnız
        // yanlar ve üst gerekiyor (ui-ux §5 `safe-area-awareness`).
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [for (final tab in _tabs) tab.screen],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
              tooltip: tab.semanticHint,
            ),
        ],
      ),
    );
  }
}
