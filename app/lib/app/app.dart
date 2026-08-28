import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/db/app_database.dart';
import 'package:disport/features/catalog/presentation/catalog_screen.dart';
import 'package:disport/features/health/presentation/health_screen.dart';
import 'package:disport/features/plan/presentation/plan_screen.dart';
import 'package:disport/features/progress/presentation/progress_screen.dart';
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
      home: const _Shell(),
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

typedef _Tab = ({String label, IconData icon, Widget screen});

class _ShellState extends State<_Shell> {
  var _index = 0;

  static const List<_Tab> _tabs = [
    (label: 'Bugün', icon: Icons.today, screen: TodayScreen()),
    (label: 'Plan', icon: Icons.calendar_month, screen: PlanScreen()),
    (label: 'İlerleme', icon: Icons.show_chart, screen: ProgressScreen()),
    (label: 'Sağlık', icon: Icons.favorite_outline, screen: HealthScreen()),
    (label: 'Katalog', icon: Icons.fitness_center, screen: CatalogScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tabs[_index].label)),
      body: IndexedStack(
        index: _index,
        children: [for (final tab in _tabs) tab.screen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
