import 'package:disport/app/app.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_providers.g.dart';

@riverpod
PlanRepository planRepository(Ref ref) =>
    PlanRepository(ref.watch(appDatabaseProvider));

/// Etkin plan. Plan yoksa null.
@riverpod
Future<FullPlan?> activePlan(Ref ref) =>
    ref.watch(planRepositoryProvider).activePlan();

/// Planın kapsadığı günlerin kayıt durumu — takvim tonlamasının kaynağı.
///
/// Tek sorguda tüm aralık: 28 hücre için 28 ayrı akış açmak hem
/// veritabanını hem de yeniden çizimi gereksiz meşgul ederdi.
///
/// Akış olması şart (`IndexedStack` kuralı): kullanıcı Bugün sekmesinde
/// bir kutucuk işaretleyip Plan'a döndüğünde takvim güncel olmalı.
@riverpod
Stream<Map<String, DailyLogView>> planRangeLogs(Ref ref) async* {
  final plan = await ref.watch(activePlanProvider.future);
  if (plan == null) {
    yield const {};
    return;
  }

  yield* ref
      .watch(todayRepositoryProvider)
      .watchBetween(
        PlanRepository.iso(plan.startDate),
        PlanRepository.iso(plan.endDate),
      );
}
