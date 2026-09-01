/// Herhangi bir günün verisi — Bugün bunun `dateKey = bugün` hâli.
///
/// **Neden aile:** kullanıcı geçmiş bir güne girip tartısını
/// düzeltebilmeli (spec §6.2). Bugün'e özel bir provider seti
/// tutmak, aynı ekranı iki kez yazmak demek olurdu.
///
/// **Argüman `String`, `DateTime` değil.** Riverpod aile argümanlarını
/// `==` ile karşılaştırıyor; `DateTime` saat bileşeni taşıdığı için
/// aynı günün iki örneği eşit çıkmaz ve provider sonsuza dek yeniden
/// kurulur. `'2026-09-01'` değer eşitliği olan bir tip.
library;

import 'package:disport/features/health/data/body_metric_table.dart';
import 'package:disport/features/plan/application/plan_providers.dart';
import 'package:disport/features/plan/data/plan_repository.dart';
import 'package:disport/features/plan/domain/full_plan.dart';
import 'package:disport/features/today/application/today_providers.dart';
import 'package:disport/features/today/data/today_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_providers.g.dart';


/// `yyyy-MM-dd`.
String dateKeyOf(DateTime date) => PlanRepository.iso(date);

/// Ekranın **baktığı** gün.
///
/// Varsayılanı bugün; `DayScreen` bir `ProviderScope` ile bunu geçmiş
/// bir güne çeviriyor. Böylece gün ekranının içindeki her parça
/// "hangi gün" sorusunu tek yerden soruyor ve `dateKey`'i onlarca
/// widget yapıcısından geçirmek gerekmiyor.
@riverpod
String viewedDate(Ref ref) => ref.watch(todayIsoProvider);

/// O günün plan günü — plan yoksa ya da günü kapsamıyorsa null.
@riverpod
Stream<FullPlanDay?> dayPlanDay(Ref ref, String dateKey) =>
    ref.watch(planRepositoryProvider).watchDay(dateKey);

/// O günün işaret ve not durumu.
///
/// `null` değil boş görünüm dönüyor: "kayıt yok" ile "boş kayıt"
/// ekranda aynı şey ve çağıran her yerde null kontrolü yazmasın.
@riverpod
Stream<DailyLogView> dayLog(Ref ref, String dateKey) =>
    ref.watch(todayRepositoryProvider).watchDay(dateKey);

@riverpod
Stream<double?> dayWeight(Ref ref, String dateKey) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchValue(dateKey, MetricKinds.weight);

@riverpod
Stream<double?> daySleep(Ref ref, String dateKey) => ref
    .watch(bodyMetricsRepositoryProvider)
    .watchValue(dateKey, MetricKinds.sleepHours);

/// Seçili günün etrafındaki yedi günün doluluğu.
///
/// Bugün ekranında son yedi gün; geçmiş bir günde o günü **merkez**
/// alan pencere. Kullanıcı düne baktığında hafta şeridinin hâlâ bugünü
/// merkez alması, baktığı yerle şeridin ilgisiz görünmesine yol açardı.
@riverpod
Stream<List<({DateTime day, bool filled})>> dayWeekFill(
  Ref ref,
  String dateKey,
) {
  final anchor = DateTime.parse(dateKey);
  final todayKey = ref.watch(todayIsoProvider);
  final isToday = dateKey == todayKey;

  // Bugünde geriye yedi gün (gelecek boş olurdu); geçmişte üç önce,
  // üç sonra.
  final days = isToday
      ? [
          for (var back = 6; back >= 0; back--)
            DateTime(anchor.year, anchor.month, anchor.day - back),
        ]
      : [
          for (var offset = -3; offset <= 3; offset++)
            DateTime(anchor.year, anchor.month, anchor.day + offset),
        ];

  return ref
      .watch(todayRepositoryProvider)
      .watchBetween(dateKeyOf(days.first), dateKeyOf(days.last))
      .map(
        (logs) => [
          for (final day in days)
            (
              day: day,
              filled:
                  !(logs[dateKeyOf(day)] ?? const DailyLogView()).isEmpty,
            ),
        ],
      );
}

/// Seçili gün bugüne göre nerede duruyor.
enum DayPosition { past, today, future }

DayPosition positionOf(String dateKey, String todayKey) {
  final compared = dateKey.compareTo(todayKey);
  if (compared < 0) return DayPosition.past;
  if (compared > 0) return DayPosition.future;
  return DayPosition.today;
}

@riverpod
DayPosition dayPosition(Ref ref, String dateKey) =>
    positionOf(dateKey, ref.watch(todayIsoProvider));
