import 'package:disport/core/design/app_dimens.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/core/widgets/widgets.dart';
import 'package:disport/features/plan/application/plan_editor_providers.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plan ayarları: başlık, hedefler, kurallar.
///
/// **Tek sayfa, üç bölüm:** üçü de "planın tamamına ait" ayarlar ve
/// kullanıcı hedefi değiştirirken kuralı da düzeltmek isteyebiliyor.
/// Ayrı sayfalara bölmek her biri için ayrı gidiş-dönüş demek olurdu.
class PlanSettingsScreen extends ConsumerStatefulWidget {
  const PlanSettingsScreen({super.key, required this.plan});

  final FullPlan plan;

  @override
  ConsumerState<PlanSettingsScreen> createState() =>
      _PlanSettingsScreenState();
}

class _PlanSettingsScreenState extends ConsumerState<PlanSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _title = TextEditingController(text: widget.plan.title);
  late final _kcal = _numberField(widget.plan.goals.dailyKcal);
  late final _protein = _numberField(widget.plan.goals.proteinG);
  late final _water = _numberField(widget.plan.goals.waterL);
  late final _gym = _numberField(widget.plan.goals.weeklyGym);
  late final _home = _numberField(widget.plan.goals.weeklyHome);
  late final _loss = _numberField(widget.plan.goals.targetLossKg);

  late List<String> _forbidden = [...widget.plan.rules.forbidden];
  late List<String> _free = [...widget.plan.rules.free];

  static TextEditingController _numberField(num value) =>
      TextEditingController(text: '$value');

  @override
  void dispose() {
    for (final controller in [
      _title,
      _kcal,
      _protein,
      _water,
      _gym,
      _home,
      _loss,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.planSettingsTitle),
        actions: [
          TextButton(onPressed: _save, child: Text(l10n.commonSave)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.planSettingsName),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.planSettingsNameRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),

            AppSectionLabel(l10n.planSettingsGoals),
            _NumberField(
              controller: _kcal,
              label: l10n.planGoalKcal,
              min: 800,
              max: 6000,
            ),
            _NumberField(
              controller: _protein,
              label: l10n.planGoalProtein,
              min: 20,
              max: 400,
            ),
            _NumberField(
              controller: _water,
              label: l10n.planGoalWater,
              min: 0.5,
              max: 10,
              decimal: true,
            ),
            _NumberField(
              controller: _gym,
              label: l10n.planGoalWeeklyGym,
              min: 0,
              max: 7,
            ),
            _NumberField(
              controller: _home,
              label: l10n.planGoalWeeklyHome,
              min: 0,
              max: 7,
            ),
            _NumberField(
              controller: _loss,
              label: l10n.planGoalTargetLoss,
              min: 0,
              max: 50,
              decimal: true,
            ),

            const SizedBox(height: AppSpacing.xl),
            _RuleList(
              title: l10n.planRulesForbidden,
              items: _forbidden,
              onChanged: (items) => setState(() => _forbidden = items),
            ),
            const SizedBox(height: AppSpacing.xl),
            _RuleList(
              title: l10n.planRulesFree,
              items: _free,
              onChanged: (items) => setState(() => _free = items),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final navigator = Navigator.of(context);
    final editor = ref.read(planEditorRepositoryProvider);
    final planChanged = ref.read(planChangedProvider);

    await editor.updateTitle(widget.plan.id, _title.text);
    await editor.updateGoals(
      widget.plan.id,
      PlanGoals(
        dailyKcal: int.parse(_kcal.text),
        proteinG: int.parse(_protein.text),
        waterL: double.parse(_water.text.replaceAll(',', '.')),
        weeklyGym: int.parse(_gym.text),
        weeklyHome: int.parse(_home.text),
        targetLossKg: double.parse(_loss.text.replaceAll(',', '.')),
      ),
    );
    await editor.updateRules(
      widget.plan.id,
      PlanRules(forbidden: _forbidden, free: _free),
    );

    await planChanged();
    navigator.pop();
  }
}

/// Aralık doğrulamalı sayı alanı.
///
/// Sınırlar dar tutulmadı: kullanıcı kendi hedefini biliyor. Ama bir
/// sıfır fazla yazmak (22000 kcal) bütçeyi anlamsızlaştırır ve
/// takvimin tamamı yeşile döner — bu yüzden üst sınır var.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final num min;
  final num max;
  final bool decimal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
      validator: (raw) {
        // Virgül de kabul: Türkçe klavyede ondalık ayracı virgül ve
        // kullanıcıyı nokta yazmaya zorlamak gereksiz sürtünme.
        final value = num.tryParse((raw ?? '').replaceAll(',', '.'));
        if (value == null || value < min || value > max) {
          return context.l10n.planGoalRange(min.toString(), max.toString());
        }
        return null;
      },
    ),
  );
}

/// Satır ekle/sil listesi — yasak ve serbest yiyecekler.
class _RuleList extends StatelessWidget {
  const _RuleList({
    required this.title,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppSectionLabel(title),
      for (final (index, item) in items.indexed)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(item),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: context.l10n.commonRemove,
            onPressed: () =>
                onChanged([...items]..removeAt(index)),
          ),
        ),
      TextButton.icon(
        icon: const Icon(Icons.add),
        label: Text(context.l10n.planRuleAdd),
        onPressed: () async {
          final value = await _askForText(context, title);
          if (value != null && value.trim().isNotEmpty) {
            onChanged([...items, value.trim()]);
          }
        },
      ),
    ],
  );

  Future<String?> _askForText(BuildContext context, String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.l10n.commonAdd),
          ),
        ],
      ),
    );
  }
}
