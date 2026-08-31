import 'package:disport/features/settings/presentation/profile_form.dart';
import 'package:flutter/material.dart';

/// Ayarlar — şimdilik profil ve yaşam tarzı.
///
/// M5'te bildirim tercihleri ve yedekleme buraya eklenecek.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil ve yaşam tarzı')),
      body: const ProfileForm(),
    );
  }
}
