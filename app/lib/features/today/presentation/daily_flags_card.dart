import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/daily_rules_repository.dart';
import 'package:disport/features/today/presentation/rule_icons.dart';
import 'package:disport/features/today/presentation/rules_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Günün kuralları.
///
/// v1'de üç sabit kutucuktu; M6'da kullanıcının kendi listesi oldu.
/// Kâğıt çizelgenin üçü hâlâ varsayılan ama silinebilir, yeniden
/// adlandırılabilir ve aralarına yenileri girebilir.
///
/// Antrenman kuralı Antrenman ekranındaki setler tamamlanınca da
/// işaretlenir; buradan elle de değiştirilebilir çünkü kullanıcı
/// uygulamayı açmadan antrenman yapabilir.
class DailyFlagsCard extends ConsumerWidget {
  const DailyFlagsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(todayLogProvider).value;
    final iso = ref.watch(todayIsoProvider);
    final repository = ref.watch(todayRepositoryProvider);
    final rules = ref.watch(dailyRulesProvider);

    return AppAsyncView<List<DailyRule>>(
      value: rules,
      onRetry: () => ref.invalidate(dailyRulesProvider),
      loading: const SizedBox.shrink(),
      data: (list) {
        final met = log?.metAmong(list.map((r) => r.id)) ?? 0;

        return AppSection(
          title: 'Günün kuralları',
          padding: EdgeInsets.zero,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (list.isNotEmpty)
                AppStatusChip(
                  status: switch (met) {
                    _ when met == list.length => AppStatus.good,
                    0 => AppStatus.unknown,
                    _ => AppStatus.caution,
                  },
                  label: '$met/${list.length}',
                  compact: true,
                ),
              IconButton(
                key: const Key('edit-rules-button'),
                icon: const Icon(Icons.tune),
                tooltip: 'Kuralları düzenle',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RulesEditorScreen(),
                  ),
                ),
              ),
            ],
          ),
          child: list.isEmpty
              ? const _NoRules()
              : Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        for (final rule in list)
                          _RuleTile(
                            // Anahtar sarmalayıcıya değil
                            // `SwitchListTile`'a veriliyor.
                            tileKey: Key('flag-${rule.id}'),
                            rule: rule,
                            value: log?.isRuleChecked(rule.id) ?? false,
                            onChanged: (_) =>
                                repository.toggleRule(iso, rule.id),
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _NoRules extends StatelessWidget {
  const _NoRules();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: AppEmptyState(
          icon: Icons.rule,
          title: 'Kural yok',
          description: 'Her gün takip etmek istediğin şeyleri ekle — su, '
              'takviye, erken yatma. Sağ üstteki ayar düğmesinden.',
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.tileKey,
    required this.rule,
    required this.value,
    required this.onChanged,
  });

  final Key tileKey;
  final DailyRule rule;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: tileKey,
      value: value,
      onChanged: onChanged,
      secondary: Icon(RuleIcons.resolve(rule.iconKey)),
      title: Text(rule.label),
      dense: true,
    );
  }
}
