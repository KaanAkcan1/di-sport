import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/catalog/presentation/equipment_screen.dart';
import 'package:disport/features/settings/presentation/backup_settings.dart';
import 'package:disport/features/settings/presentation/notification_settings.dart';
import 'package:disport/features/settings/presentation/profile_form.dart';
import 'package:flutter/material.dart';

/// Ayarlar: profil, bildirimler, yedekleme.
///
/// Üçü tek kaydırma alanında; profil formu diğer bölümleri kendi
/// listesine alıyor (bkz. [ProfileForm.trailing]).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: const ProfileForm(
        trailing: [
          _EquipmentEntry(),
          NotificationSettings(),
          BackupSettings(),
        ],
      ),
    );
  }
}

/// Ekipman envanterine giriş.
///
/// Ayarlarda duruyor çünkü envanter profilin parçası: katalog filtresi
/// ve AI'a giden bağlam dosyası aynı listeyi okuyor.
class _EquipmentEntry extends StatelessWidget {
  const _EquipmentEntry();

  @override
  Widget build(BuildContext context) {
    return AppSection(
      title: 'Ekipmanım',
      description: 'İşaretlediklerin katalog filtresini ve yapay zekâya '
          'gönderilen bağlamı besliyor.',
      child: Card(
        child: ListTile(
          key: const Key('open-equipment'),
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Ekipman listesi'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EquipmentScreen()),
          ),
        ),
      ),
    );
  }
}
