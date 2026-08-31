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
        trailing: [NotificationSettings(), BackupSettings()],
      ),
    );
  }
}
