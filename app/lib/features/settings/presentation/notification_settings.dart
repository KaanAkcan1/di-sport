import 'package:disport/core/design/app_dimens.dart';
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

  /// Slot türlerinin Türkçe karşılıkları ve açıklamaları.
  static const _labels = <String, (String, String)>{
    'workout': ('Antrenman', 'Programdaki antrenman saatinde'),
    'meal': ('Öğün', 'Programdaki öğün saatlerinde'),
    'walk': ('Yürüyüş', 'Programdaki yürüyüş saatinde'),
    'supplement': ('Takviye', 'Vitamin ve takviye saatlerinde'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileEntriesProvider);
    final theme = Theme.of(context);

    return AppAsyncView<Map<String, String>>(
      value: profile,
      onRetry: () => ref.invalidate(profileEntriesProvider),
      data: (settings) => AppSection(
        title: 'Bildirimler',
        description: 'Sabah tartısı hatırlatması uyanma saatine bağlı; '
            'profilde uyanma saatini gir.',
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
                  title: Text(_labels[kind]?.$1 ?? kind),
                  subtitle: Text(
                    _labels[kind]?.$2 ?? '',
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
    await ref.read(reminderSchedulerProvider).reschedule(DateTime.now());
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
      title: const Text('Tam zamanlı alarm izni'),
      subtitle: Text(
        switch (_exact) {
          true => 'Verildi — bildirimler tam saatinde çalar.',
          false => 'Verilmedi. Bildirimler yine çalar ama pil tasarrufu '
              'kipinde birkaç dakika gecikebilir.',
          null => 'Durumu görmek için dokun.',
        },
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () async {
        final granted = await ref
            .read(notificationServiceProvider)
            .canScheduleExact();
        if (mounted) setState(() => _exact = granted);
      },
    );
  }
}
