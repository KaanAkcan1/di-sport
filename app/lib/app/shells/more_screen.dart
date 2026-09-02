import 'package:disport/app/shells/shell_header.dart';
import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/presentation/context_sections_screen.dart';
import 'package:disport/features/catalog/presentation/equipment_screen.dart';
import 'package:disport/features/medical/presentation/medical_screen.dart';
import 'package:disport/features/nutrition/presentation/forbidden_editor_screen.dart';
import 'package:disport/features/settings/presentation/appearance_settings.dart';
import 'package:disport/features/settings/presentation/backup_settings.dart';
import 'package:disport/features/settings/presentation/language_settings.dart';
import 'package:disport/features/settings/presentation/notification_settings.dart';
import 'package:disport/features/settings/presentation/profile_form.dart';
import 'package:disport/features/settings/presentation/weekly_schedule_screen.dart';
import 'package:disport/features/today/presentation/rules_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Daha sekmesi — gruplanmış dizin (v3).
///
/// God ekranın sonu: burada hiçbir şey düzenlenmiyor, her satır kendi
/// ekranını açıyor. İki grup gerçek bir ayrımı kodluyor — ilk gruptaki
/// veriler AI belgesine girip planı etkiliyor, ikincisi yalnız
/// uygulamanın davranışı.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShellHeader(title: l10n.tabMore),
        Expanded(
          child: AppScreenBody(
            children: [
              AppSectionLabel(
                l10n.moreYourData,
                trailing: Text(
                  l10n.moreYourDataHint,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _MoreRow(
                icon: LucideIcons.user,
                area: AppArea.neutral,
                title: l10n.moreProfile,
                // ProfileForm kendi ListView'ini kuruyor; _SectionPage'in
                // SingleChildScrollView'ine sarılırsa yüksekliği sınırsız
                // kalır ve ekran hiç çizilmez (boş ekran, geri yok).
                screen: (context) => _SectionPage(
                  title: l10n.moreProfile,
                  scrollable: false,
                  child: const ProfileForm(),
                ),
              ),
              _MoreRow(
                icon: LucideIcons.wrench,
                area: AppArea.sport,
                title: l10n.moreEquipment,
                screen: (context) => const EquipmentScreen(),
              ),
              _MoreRow(
                icon: LucideIcons.heartPulse,
                area: AppArea.health,
                title: l10n.medicalTitle,
                screen: (context) => const MedicalScreen(),
              ),
              _MoreRow(
                icon: LucideIcons.clock,
                area: AppArea.energy,
                title: l10n.moreRhythm,
                screen: (context) => const WeeklyScheduleScreen(),
              ),
              _MoreRow(
                icon: LucideIcons.squareCheck,
                area: AppArea.diet,
                title: l10n.moreRules,
                screen: (context) => const RulesEditorScreen(),
              ),
              _MoreRow(
                icon: LucideIcons.ban,
                area: AppArea.diet,
                title: l10n.forbiddenTitle,
                screen: (context) => const ForbiddenEditorScreen(),
              ),
              _MoreRow(
                icon: LucideIcons.sparkles,
                area: AppArea.neutral,
                title: l10n.moreAiSections,
                screen: (context) => const ContextSectionsScreen(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppSectionLabel(l10n.moreApp),
              _MoreRow(
                icon: LucideIcons.bellRing,
                area: AppArea.neutral,
                title: l10n.moreNotifications,
                screen: (context) => _SectionPage(
                  title: l10n.moreNotifications,
                  child: const NotificationSettings(),
                ),
              ),
              _MoreRow(
                icon: LucideIcons.paintbrush,
                area: AppArea.neutral,
                title: l10n.moreAppearance,
                screen: (context) => _SectionPage(
                  title: l10n.moreAppearance,
                  child: const Column(
                    children: [AppearanceSettings(), LanguageSettings()],
                  ),
                ),
              ),
              _MoreRow(
                icon: LucideIcons.download,
                area: AppArea.neutral,
                title: l10n.moreBackup,
                screen: (context) => _SectionPage(
                  title: l10n.moreBackup,
                  child: const BackupSettings(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.icon,
    required this.area,
    required this.title,
    required this.screen,
  });

  final IconData icon;
  final AppArea area;
  final String title;
  final WidgetBuilder screen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: screen)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            AppIconTile(icon: icon, area: area, small: true),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bölüm widget'ını kendi sayfasına saran basit kabuk.
///
/// Bildirim, görünüm ve yedek bölümleri eskiden Ayarlar listesinin
/// içindeydi; ayrı ekrana taşınınca sayfa iskeletine ihtiyaç duydular.
class _SectionPage extends StatelessWidget {
  const _SectionPage({
    required this.title,
    required this.child,
    this.scrollable = true,
  });

  final String title;
  final Widget child;

  /// Çocuk kendi kaydırmasını kuruyorsa (ör. `ProfileForm`'un
  /// `ListView`'i) false geç: kaydırılabilir bir widget'ı
  /// `SingleChildScrollView`'e sarmak sınırsız yükseklik hatasıyla
  /// ekranı boş bırakır.
  final bool scrollable;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
            ),
            child: child,
          )
        : child,
  );
}
