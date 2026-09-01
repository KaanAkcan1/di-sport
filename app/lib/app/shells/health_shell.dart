import 'package:disport/app/shells/shell_header.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/health/presentation/health_screen.dart';
import 'package:disport/features/progress/presentation/progress_screen.dart';
import 'package:disport/features/supplements/presentation/supplements_screen.dart';
import 'package:flutter/material.dart';

/// Sağlık sekmesi: TAHLİL · ÖLÇÜM · İLAÇ.
///
/// Üçü bir arada çünkü doktora giderken üçü birlikte lazım. İlaç
/// Ayarlar'dan buraya taşındı — ilaç bir tercih değil, sağlık verisi.
/// Eski İlerleme sekmesi ÖLÇÜM oldu: ölçüm de bir sağlık verisi, ayrı
/// bir sekmeyi hak etmiyordu.
class HealthShell extends StatelessWidget {
  const HealthShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppSegmentedShell(
      header: ShellHeader(title: l10n.tabHealth),
      labels: [l10n.healthTabLabs, l10n.healthTabMeasure, l10n.healthTabMeds],
      children: const [
        HealthScreen(),
        ProgressScreen(),
        SupplementsScreen(embedded: true),
      ],
    );
  }
}
