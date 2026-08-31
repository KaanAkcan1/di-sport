import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günün üç kutucuğu: 3 L su, alkol/şeker yok, antrenman.
///
/// Kâğıt çizelgedeki üç kutunun karşılığı. Antrenman kutusu Antrenman
/// ekranındaki setler tamamlanınca da işaretlenir; buradan elle de
/// değiştirilebilir çünkü kullanıcı uygulamayı açmadan antrenman
/// yapabilir.
class DailyFlagsCard extends ConsumerWidget {
  const DailyFlagsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(todayLogProvider).value;
    final iso = ref.watch(todayIsoProvider);
    final repository = ref.watch(todayRepositoryProvider);

    return AppSection(
      title: 'Günün kuralları',
      padding: EdgeInsets.zero,
      action: log == null
          ? null
          : AppStatusChip(
              status: switch (log.flagsMet) {
                3 => AppStatus.good,
                0 => AppStatus.unknown,
                _ => AppStatus.caution,
              },
              label: '${log.flagsMet}/3',
              compact: true,
            ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              _FlagTile(
                tileKey: const Key('flag-water'),
                icon: Icons.water_drop_outlined,
                label: '3 litre su',
                value: log?.waterTargetMet ?? false,
                onChanged: (value) =>
                    repository.setFlags(iso, waterTargetMet: value),
              ),
              _FlagTile(
                tileKey: const Key('flag-no-sugar'),
                icon: Icons.no_drinks_outlined,
                label: 'Alkol ve şeker yok',
                value: log?.noAlcoholSugar ?? false,
                onChanged: (value) =>
                    repository.setFlags(iso, noAlcoholSugar: value),
              ),
              _FlagTile(
                tileKey: const Key('flag-workout'),
                icon: Icons.fitness_center,
                label: 'Antrenman yapıldı',
                value: log?.workoutDone ?? false,
                onChanged: (value) =>
                    repository.setFlags(iso, workoutDone: value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  const _FlagTile({
    required this.tileKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// Anahtar sarmalayıcıya değil `SwitchListTile`'a veriliyor.
  final Key tileKey;

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: tileKey,
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
      title: Text(label),
      dense: true,
    );
  }
}
