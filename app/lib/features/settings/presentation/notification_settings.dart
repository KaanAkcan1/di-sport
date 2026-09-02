import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/reminders/application/reminder_providers.dart';
import 'package:disport/features/reminders/application/reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bildirim tercihleri.
///
/// Tür başına ayrı anahtar: kullanıcı antrenman alarmını isteyip öğün
/// alarmını istemeyebilir. Hepsi tek anahtara bağlansaydı, rahatsız
/// eden tek bildirim yüzünden hepsi kapatılırdı.
class NotificationSettings extends ConsumerWidget {
  const NotificationSettings({super.key});

  /// Slot türlerinin ad ve açıklamaları.
  ///
  /// Sabit harita olamaz: çeviri `BuildContext` ister. Bilinmeyen bir
  /// tür gelirse `null` dönüyor, çağrı yeri ham anahtarı gösteriyor.
  static (String, String)? _labelFor(AppLocalizations l10n, String kind) =>
      switch (kind) {
        'workout' => (
          l10n.settingsNotifWorkout,
          l10n.settingsNotifWorkoutDescription,
        ),
        'meal' => (l10n.settingsNotifMeal, l10n.settingsNotifMealDescription),
        'walk' => (l10n.settingsNotifWalk, l10n.settingsNotifWalkDescription),
        'supplement' => (
          l10n.settingsNotifSupplement,
          l10n.settingsNotifSupplementDescription,
        ),
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileEntriesProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AppAsyncView<Map<String, String>>(
      value: profile,
      onRetry: () => ref.invalidate(profileEntriesProvider),
      data: (settings) => AppSection(
        title: l10n.settingsNotificationsTitle,
        description: l10n.settingsNotificationsDescription,
        child: Card(
          child: Column(
            children: [
              for (final (index, kind) in notifiableKinds.indexed) ...[
                if (index > 0)
                  const Divider(height: 1, indent: AppSpacing.lg),
                SwitchListTile(
                  key: Key('notif-$kind'),
                  value: settings[notifKindKey(kind)] == 'true',
                  onChanged: (value) => _toggle(ref, kind, value),
                  title: Text(_labelFor(l10n, kind)?.$1 ?? kind),
                  subtitle: Text(
                    _labelFor(l10n, kind)?.$2 ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const Divider(height: 1, indent: AppSpacing.lg),
              _ExactAlarmTile(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, String kind, bool value) async {
    await ref
        .read(profileRepositoryProvider)
        .set(notifKindKey(kind), value.toString());

    // Anahtar değişince pencere hemen yeniden kuruluyor; bir sonraki
    // açılışı beklemek kullanıcıya "çalışmadı" hissi verirdi.
    await rescheduleQuietly(ref.read(reminderSchedulerProvider));
  }
}

/// Tam zamanlı alarm izni satırı.
///
/// Ayrı bir satır çünkü Android bunu bildirim izninden ayrı soruyor ve
/// reddedilmesi bildirimleri tümden kapatmıyor — yalnız geciktiriyor.
class _ExactAlarmTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ExactAlarmTile> createState() => _ExactAlarmTileState();
}

class _ExactAlarmTileState extends ConsumerState<_ExactAlarmTile> {
  bool? _exact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      key: const Key('exact-alarm-tile'),
      leading: Icon(
        _exact == true ? Icons.alarm_on : Icons.alarm_outlined,
        color: _exact == true
            ? AppStatus.good.color(context)
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(context.l10n.settingsExactAlarmTitle),
      subtitle: Text(
        switch (_exact) {
          true => context.l10n.settingsExactAlarmGranted,
          false => context.l10n.settingsExactAlarmDenied,
          null => context.l10n.settingsExactAlarmLoading,
        },
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      // Dokunmak sistem ayarları sayfasını açar; kullanıcı geri
      // döndüğünde durum yeniden okunuyor.
      onTap: _exact == true ? null : _request,
    );
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .canScheduleExact();
    if (mounted) setState(() => _exact = granted);
  }

  Future<void> _request() async {
    final granted = await ref
        .read(notificationServiceProvider)
        .requestExactPermission();
    if (mounted) setState(() => _exact = granted);
  }
}
