import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/design/app_semantic_colors.dart';
import 'package:disport/core/design/app_typography.dart';
import 'package:flutter/material.dart';

/// Bir günün hafta şeridindeki durumu.
enum WeekDotState {
  /// Kayıt girilmiş.
  done,

  /// Geçmiş ama kayıt yok.
  missed,

  /// Seçili gün.
  today,

  /// Henüz gelmedi.
  future,
}

/// Son yedi günün doluluk şeridi.
///
/// **Neden var:** kullanıcı bir günü kaçırdığını ancak takvime gidince
/// fark ediyordu. Yedi nokta, Bugün ekranının tepesinde, kaçakları
/// bir bakışta gösteriyor — takvime gitmeye gerek kalmadan.
///
/// Her noktanın içinde **gün harfi yazılı**: renk tek başına anlam
/// taşımaz kuralı (spec §2a.4). Renk körü bir kullanıcı da hangi günün
/// boş olduğunu okuyabilmeli.
class AppWeekDots extends StatelessWidget {
  const AppWeekDots({super.key, required this.states, required this.labels});

  /// Yedi gün, en eskiden en yeniye.
  final List<WeekDotState> states;

  /// Aynı sırada gün harfleri — "P", "S", "Ç"…
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    assert(
      states.length == labels.length,
      'her nokta kendi gün harfini taşımalı',
    );

    return Row(
      children: [
        for (final (index, state) in states.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          _Dot(state: state, label: labels[index]),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.label});

  final WeekDotState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;

    final (background, foreground) = switch (state) {
      WeekDotState.done => (semantic.success, theme.colorScheme.onPrimary),
      WeekDotState.today => (
        theme.colorScheme.primary,
        theme.colorScheme.onPrimary,
      ),
      WeekDotState.missed => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
      WeekDotState.future => (
        theme.colorScheme.surfaceContainerLow,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Semantics(
      label: '$label: ${_spoken(state)}',
      excludeSemantics: true,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: state == WeekDotState.today
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: AppBorder.emphasis,
                )
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.statCaption.copyWith(
            fontSize: 9,
            color: foreground,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  String _spoken(WeekDotState state) => switch (state) {
    WeekDotState.done => 'kayıt var',
    WeekDotState.missed => 'kayıt yok',
    WeekDotState.today => 'bugün',
    WeekDotState.future => 'gelecek',
  };
}
