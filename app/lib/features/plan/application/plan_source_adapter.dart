import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/plan/data/plan_repository.dart';

/// `plan` feature'ının `ai_bridge`'e verdiği plan özeti.
///
/// Yalnız özet: `context.md`'nin ihtiyacı "hangi planın devamındayım"
/// bilgisi, 28 günün tamamı değil. Geçen dönemin ne kadarının
/// gerçekleştiği zaten `LogSource`'tan geliyor.
class PlanSourceAdapter implements PlanSource {
  const PlanSourceAdapter(this._repository);

  final PlanRepository _repository;

  @override
  Future<ActivePlanSummary?> activePlanSummary() async {
    final plan = await _repository.activePlan();
    if (plan == null) return null;

    return ActivePlanSummary(
      title: plan.title,
      startDate: PlanRepository.iso(plan.startDate),
      endDate: PlanRepository.iso(plan.endDate),
      weeks: plan.weeks,
    );
  }
}
