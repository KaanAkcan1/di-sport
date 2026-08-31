import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/features/settings/presentation/profile_form.dart';
import 'package:flutter/material.dart';

/// İlk açılış ekranı.
///
/// Uygulama boş bir ekranla karşılamıyor: kullanıcı önce kendini tanıtır,
/// sonra plan ister (spec 6, "İlk açılış").
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl2,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hoş geldin', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Önce seni tanıyalım. Bu bilgiler cihazından çıkmaz; '
                    'yalnızca sen bir yapay zekâya bağlam dosyası '
                    'gönderdiğinde kullanılır.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ProfileForm(
                onSaved: onDone,
                saveLabel: 'Kaydet ve başla',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
