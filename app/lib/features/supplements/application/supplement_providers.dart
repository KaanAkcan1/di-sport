import 'package:disport/app/app.dart';
import 'package:disport/features/supplements/data/supplements_repository.dart';
import 'package:disport/features/supplements/domain/supplement.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'supplement_providers.g.dart';

@riverpod
SupplementsRepository supplementsRepository(Ref ref) =>
    SupplementsRepository(ref.watch(appDatabaseProvider));

/// Tanımlı takviyeler — silinmişler hariç.
@riverpod
Stream<List<Supplement>> supplements(Ref ref) =>
    ref.watch(supplementsRepositoryProvider).watchAll();

/// Bugünün alım işaretleri.
@riverpod
Stream<Map<String, DateTime?>> todaySupplementLog(Ref ref) => ref
    .watch(supplementsRepositoryProvider)
    .watchDay(ref.watch(todayIsoProvider));

/// Bugün alınması gereken dozlar — saate göre sıralı.
///
/// Hafta günü süzgeci burada uygulanıyor: ekran "bugün hangi takviye"
/// sorusunu sormak zorunda kalmasın.
@riverpod
List<SupplementDose> todayDoses(Ref ref) {
  final all = ref.watch(supplementsProvider).value ?? const [];
  final log = ref.watch(todaySupplementLogProvider).value ?? const {};
  final today = DateTime.parse(ref.watch(todayIsoProvider));

  final doses = <SupplementDose>[
    for (final supplement in all)
      if (supplement.activeOn(today))
        for (final time in supplement.times)
          SupplementDose(
            supplement: supplement,
            time: time,
            takenAt: log[SupplementsRepository.doseKey(supplement.id, time)],
          ),
  ];

  return doses..sort((a, b) => a.time.compareTo(b.time));
}
