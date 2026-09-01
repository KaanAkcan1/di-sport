import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/core/notifications/local_notification_service.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/catalog/presentation/catalog_screen.dart';
import 'package:disport/features/health/presentation/health_screen.dart';
import 'package:disport/features/plan/presentation/plan_screen.dart';
import 'package:disport/features/progress/presentation/progress_screen.dart';
import 'package:disport/features/reminders/domain/reminder_planner.dart';
import 'package:disport/features/settings/application/settings_providers.dart';
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

class DisportApp extends ConsumerWidget {
  const DisportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ayar okunana kadar koyu: mürekkep dili koyu öncelikli, ve bir
    // kare açık modda açılıp koyuya dönmek göz kırpması gibi durur.
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.dark;

    return MaterialApp(
      title: 'di@sport',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      // `null` = sistem dili. Flutter desteklenenler arasından en
      // yakınını seçiyor; listede olmayan bir dilde ilk sıradaki
      // (Türkçe) kullanılıyor.
      locale: ref.watch(appLocaleProvider).value,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  IconData icon,
  IconData selectedIcon,
  Widget screen,
});

class _ShellState extends State<_Shell> {
  var _index = 0;

  @override
  void initState() {
    super.initState();
    // Uygulama bildirime dokunularak açılmışsa yük zaten dolu;
    // sonradan gelenler için dinleyici kalıyor.
    pendingNotificationPayload.addListener(_openPayloadTab);
    _openPayloadTab();
  }

  @override
  void dispose() {
    pendingNotificationPayload.removeListener(_openPayloadTab);
    super.dispose();
  }

  /// Bildirim yükünü ilgili sekmeye çevirir ve yükü tüketir.
  ///
  /// Tüketmek şart: aksi halde kullanıcı elle başka sekmeye geçtiğinde
  /// bir sonraki yeniden çizimde alarmın sekmesine geri atılırdı.
  void _openPayloadTab() {
    final payload = pendingNotificationPayload.value;
    if (payload == null) return;

    pendingNotificationPayload.value = null;
    final tab = ReminderPayloads.tabIndex[payload];
    if (tab != null && mounted) setState(() => _index = tab);
  }

  /// Sekme sırası sabit; etiketler çeviriden geliyor.
  ///
  /// `ReminderPayloads.tabIndex` bu sıraya bağlı — bildirime dokunmak
  /// doğru sekmeyi açıyor. Sıra değişirse orası da değişmeli.
  static const List<_Tab> _tabs = [
    (
      icon: Icons.today_outlined,
      selectedIcon: Icons.today,
      screen: TodayScreen(),
    ),
    (
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      screen: PlanScreen(),
    ),
    (
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      screen: ProgressScreen(),
    ),
    (
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      screen: HealthScreen(),
    ),
    (
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      screen: CatalogScreen(),
    ),
  ];

  List<String> _labels(BuildContext context) => [
    context.l10n.tabToday,
    context.l10n.tabPlan,
    context.l10n.tabProgress,
    context.l10n.tabHealth,
    context.l10n.tabCatalog,
  ];

  List<String> _hints(BuildContext context) => [
    context.l10n.tabTodayHint,
    context.l10n.tabPlanHint,
    context.l10n.tabProgressHint,
    context.l10n.tabHealthHint,
    context.l10n.tabCatalogHint,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = _labels(context);
    final hints = _hints(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(labels[_index]),
        actions: [
          IconButton(
            key: const Key('settings-button'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.l10n.settingsTooltip,
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
          for (final (index, tab) in _tabs.indexed)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: labels[index],
              tooltip: hints[index],
            ),
        ],
      ),
    );
  }
}
