import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart'
    show ProfileKeys;
import 'package:disport/features/health/data/body_metric_table.dart'
    show MetricKinds;
import 'package:disport/features/plan/data/plan_repository.dart'
    show PlanRepository;
import 'package:disport/features/today/application/today_providers.dart'
    show bodyMetricsRepositoryProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// İlk açılış sihirbazı (v3 §3.1).
///
/// Üç ekran: hoş geldin → kimlik → ölçüler. "Atla" yok — arkada boş
/// uygulama var. Yaşam tarzı soruları (saatler, ekipman, medikal)
/// buradan çıkarıldı; onları Ana Sayfa'daki kurulum kartları soruyor,
/// her birinin GEÇ yolu var. İlk karşılaşmada zorunlu olan yalnız
/// kimlik ve ölçü: kalori hesabının asgarisi.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  var _step = 0;
  var _saving = false;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _birthDay = TextEditingController();
  final _birthMonth = TextEditingController();
  final _birthYear = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _targetWeight = TextEditingController();

  /// male | female | unspecified — [ProfileKeys.gender] sözlüğü.
  String _gender = 'unspecified';

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _birthDay,
      _birthMonth,
      _birthYear,
      _height,
      _weight,
      _targetWeight,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _warn(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Doğum tarihini `yyyy-MM-dd` olarak döner; boşsa null, bozuksa
  /// uyarır ve `''` döner (çağıran ayırt eder).
  String? _birthDateOrWarn() {
    final d = _birthDay.text.trim();
    final m = _birthMonth.text.trim();
    final y = _birthYear.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) return null;

    final day = int.tryParse(d);
    final month = int.tryParse(m);
    final year = int.tryParse(y);
    if (day == null || month == null || year == null) return '';

    final date = DateTime(year, month, day);
    final now = DateTime.now();
    // DateTime taşan günü sessizce sonraki aya devreder (31 Şubat →
    // 2 Mart); geri okuyarak yakalıyoruz.
    final valid =
        date.day == day &&
        date.month == month &&
        date.year == year &&
        year > 1900 &&
        !date.isAfter(now);
    if (!valid) return '';
    return PlanRepository.iso(date);
  }

  void _nextFromIdentity() {
    if (_firstName.text.trim().isEmpty) {
      _warn(context.l10n.onboardingFirstNameRequired);
      return;
    }
    final birth = _birthDateOrWarn();
    if (birth != null && birth.isEmpty) {
      _warn(context.l10n.onboardingBirthDateInvalid);
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _finish() async {
    final height = _height.text.trim();
    if (height.isEmpty) {
      _warn(context.l10n.settingsProfileHeightRequired);
      return;
    }

    setState(() => _saving = true);

    final birth = _birthDateOrWarn();
    final weight = _weight.text.trim().replaceAll(',', '.');

    final values = <String, String>{
      ProfileKeys.firstName: _firstName.text.trim(),
      ProfileKeys.gender: _gender,
      ProfileKeys.heightCm: height,
      if (_lastName.text.trim().isNotEmpty)
        ProfileKeys.lastName: _lastName.text.trim(),
      if (birth != null && birth.isNotEmpty) ProfileKeys.birthDate: birth,
      if (weight.isNotEmpty) ProfileKeys.currentWeightKg: weight,
      if (_targetWeight.text.trim().isNotEmpty)
        ProfileKeys.targetWeightKg: _targetWeight.text
            .trim()
            .replaceAll(',', '.'),
    };

    await ref.read(profileRepositoryProvider).setAll(values);

    // İlk kilo aynı zamanda ilk tartı kaydı: İlerleme grafiği ilk günden
    // bir noktayla başlasın, kullanıcı aynı sayıyı iki kez girmesin.
    final weightValue = double.tryParse(weight);
    if (weightValue != null) {
      await ref
          .read(bodyMetricsRepositoryProvider)
          .upsert(
            isoDate: PlanRepository.iso(DateTime.now()),
            kind: MetricKinds.weight,
            value: weightValue,
            unit: 'kg',
          );
    }

    ref.invalidate(profileEntriesProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl2),
            _StepDots(current: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.respectingMotion(context, AppMotion.slow),
                child: switch (_step) {
                  0 => _WelcomeStep(
                    key: const ValueKey(0),
                    onStart: () => setState(() => _step = 1),
                  ),
                  1 => _IdentityStep(
                    key: const ValueKey(1),
                    firstName: _firstName,
                    lastName: _lastName,
                    birthDay: _birthDay,
                    birthMonth: _birthMonth,
                    birthYear: _birthYear,
                    gender: _gender,
                    onGenderChanged: (v) => setState(() => _gender = v),
                    onNext: _nextFromIdentity,
                    onBack: () => setState(() => _step = 0),
                  ),
                  _ => _MeasuresStep(
                    key: const ValueKey(2),
                    height: _height,
                    weight: _weight,
                    targetWeight: _targetWeight,
                    saving: _saving,
                    onFinish: _finish,
                    onBack: () => setState(() => _step = 1),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Üç nokta ilerleme (spec §3.1) — aktif nokta marka renginde ve geniş.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedContainer(
            duration: AppMotion.respectingMotion(context, AppMotion.base),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: i == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl3),
        Text(
          l10n.onboardingWelcomeTitle,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.onboardingWelcomeBody,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AreaLine(l10n.onboardingAreaDiet, AppArea.diet, LucideIcons.utensils),
              _AreaLine(l10n.onboardingAreaSport, AppArea.sport, LucideIcons.dumbbell),
              _AreaLine(l10n.onboardingAreaHealth, AppArea.health, LucideIcons.heartPulse),
              _AreaLine(l10n.onboardingAreaMed, AppArea.med, LucideIcons.pill),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Text(
          l10n.settingsOnboardingIntro,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('onboarding-start'),
          onPressed: onStart,
          child: Text(l10n.onboardingStart),
        ),
      ],
    );
  }
}

class _AreaLine extends StatelessWidget {
  const _AreaLine(this.text, this.area, this.icon);

  final String text;
  final AppArea area;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          AppIconTile(icon: icon, area: area, small: true),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.birthDay,
    required this.birthMonth,
    required this.birthYear,
    required this.gender,
    required this.onGenderChanged,
    required this.onNext,
    required this.onBack,
  });

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController birthDay;
  final TextEditingController birthMonth;
  final TextEditingController birthYear;
  final String gender;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.onboardingIdentityTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          key: const Key('onboarding-first-name'),
          controller: firstName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: '${l10n.onboardingFirstName} *',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const Key('onboarding-last-name'),
          controller: lastName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.onboardingLastName),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.onboardingBirthDate,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('onboarding-birth-day'),
                controller: birthDay,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.onboardingBirthDay,
                  hintText: '17',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                key: const Key('onboarding-birth-month'),
                controller: birthMonth,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.onboardingBirthMonth,
                  hintText: '4',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: TextField(
                key: const Key('onboarding-birth-year'),
                controller: birthYear,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.onboardingBirthYear,
                  hintText: '1990',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.onboardingGender,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          key: const Key('onboarding-gender'),
          segments: [
            ButtonSegment(value: 'male', label: Text(l10n.onboardingMale)),
            ButtonSegment(value: 'female', label: Text(l10n.onboardingFemale)),
            ButtonSegment(
              value: 'unspecified',
              label: Text(l10n.onboardingGenderUnspecified),
            ),
          ],
          selected: {gender},
          onSelectionChanged: (set) => onGenderChanged(set.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.onboardingGenderWhy,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Row(
          children: [
            TextButton(onPressed: onBack, child: Text(l10n.commonBack)),
            const Spacer(),
            FilledButton(
              key: const Key('onboarding-identity-next'),
              onPressed: onNext,
              child: Text(l10n.commonNext),
            ),
          ],
        ),
      ],
    );
  }
}

class _MeasuresStep extends StatelessWidget {
  const _MeasuresStep({
    super.key,
    required this.height,
    required this.weight,
    required this.targetWeight,
    required this.saving,
    required this.onFinish,
    required this.onBack,
  });

  final TextEditingController height;
  final TextEditingController weight;
  final TextEditingController targetWeight;
  final bool saving;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.onboardingMeasuresTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.onboardingMeasuresBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          key: const Key('field-heightCm'),
          controller: height,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${l10n.onboardingHeight} *',
            suffixText: 'cm',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const Key('field-currentWeightKg'),
          controller: weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.onboardingWeight,
            suffixText: 'kg',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const Key('field-targetWeightKg'),
          controller: targetWeight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.onboardingTargetWeight,
            suffixText: 'kg',
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Row(
          children: [
            TextButton(onPressed: onBack, child: Text(l10n.commonBack)),
            const Spacer(),
            FilledButton(
              key: const Key('save-profile-button'),
              onPressed: saving ? null : onFinish,
              child: Text(l10n.settingsOnboardingSave),
            ),
          ],
        ),
      ],
    );
  }
}
