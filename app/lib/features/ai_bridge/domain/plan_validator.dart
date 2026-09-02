import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/json_reader.dart';
import 'package:disport/features/ai_bridge/domain/plan_json.dart';
import 'package:disport/features/catalog/domain/exercise.dart';

/// Katalogdan doğrulayıcıya geçen asgari bilgi.
///
/// Tüm `Exercise` nesnesi yerine iki alan: doğrulayıcı anlatıma değil
/// yalnızca id'nin varlığına ve yapılabildiği yere bakıyor.
typedef CatalogEntry = ({ExerciseLocation location, String nameTr});

/// Doğrulamayı geçmiş plan.
class ValidatedPlan {
  const ValidatedPlan({required this.plan, required this.rawJson});

  final PlanJson plan;

  /// Ham belge — `plans.sourceRaw`'a yazılıyor (spec 5.2).
  final String rawJson;

  List<NewExerciseJson> get newExercises => plan.newExercises;

  int get dayCount => plan.days.length;

  int daysOfType(String type) =>
      plan.days.where((day) => day.type == type).length;
}

/// `plan.json` doğrulaması — spec 7.3'ün ilk üç kapısı.
///
/// Dördüncü kapı (önizleme ve kullanıcı onayı) arayüzdedir.
///
/// Tasarım kararı: **ilk hatada durulmaz.** Anlam denetiminde bulunan
/// bütün sorunlar toplanıp tek mesajda verilir. Kullanıcı bu mesajı AI'a
/// yapıştıracak; her seferinde tek hata bildirmek beş tur sürerdi.
class PlanValidator {
  const PlanValidator({required this.catalog});

  final Map<String, CatalogEntry> catalog;

  static const supportedSchemaVersion = 1;

  static final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static const _kcalRange = (min: 1200, max: 4000);
  static const _proteinRange = (min: 50, max: 300);
  static const _waterRange = (min: 1.0, max: 6.0);

  Result<ValidatedPlan> validate(String rawJson) {
    // --- Kapı 1: ayrıştırma -------------------------------------------
    final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (error) {
      return Err(
        Failure(
          message:
              'JSON ayrıştırılamadı: ${error.message}\n'
              'Yanıtın yalnızca JSON belgesi olsun; açıklama metni, '
              'giriş cümlesi ya da kod bloğu dışında bir şey ekleme.',
          cause: error,
        ),
      );
    }

    // --- Kapı 2: şema --------------------------------------------------
    final PlanJson plan;
    try {
      plan = PlanJson.parse(JsonReader.root(decoded));
    } on JsonFieldError catch (error) {
      return Err(
        Failure(
          message:
              'Şema hatası: ${error.path} ${error.problem}.\n'
              'Alanı düzeltip belgeyi yeniden gönder.',
          cause: error,
        ),
      );
    }

    if (plan.schemaVersion != supportedSchemaVersion) {
      return Err(
        Failure(
          message:
              'schemaVersion ${plan.schemaVersion} desteklenmiyor; '
              'beklenen $supportedSchemaVersion.',
        ),
      );
    }

    // --- Kapı 3: anlam -------------------------------------------------
    final problems = <String>[
      ..._checkNewExercises(plan),
      ..._checkGoals(plan),
      ..._checkDates(plan),
      ..._checkDays(plan),
    ];

    if (problems.isNotEmpty) {
      return Err(
        Failure(
          message:
              'Plan doğrulanamadı. Aşağıdaki maddeleri düzeltip JSON\'u '
              'yeniden gönder:\n${problems.map((p) => '• $p').join('\n')}',
        ),
      );
    }

    return Ok(ValidatedPlan(plan: plan, rawJson: rawJson));
  }

  /// AI'ın önerdiği yeni hareketler spec 7.4'teki çıtayı geçmeli.
  ///
  /// Esnek mod "özensiz" demek değil: katalogda kalıcı olacak bir kayıt,
  /// elle yazılan tohum verisiyle aynı ayrıntıda olmalı.
  List<String> _checkNewExercises(PlanJson plan) {
    final problems = <String>[];

    for (final candidate in plan.newExercises) {
      final data = candidate.data;
      final issues = <String>[];

      if ((data['id'] as String?)?.trim().isEmpty ?? true) {
        issues.add('id boş olamaz');
      } else if (catalog.containsKey(data['id'])) {
        issues.add('"${data['id']}" katalogda zaten var');
      }

      if ((data['execution'] as List? ?? const []).length < 3) {
        issues.add('execution en az 3 adım olmalı');
      }

      final mistakes = data['commonMistakes'] as List? ?? const [];
      final mistakesComplete =
          mistakes.length >= 2 &&
          mistakes.every(
            (item) =>
                item is Map &&
                _filled(item['mistake']) &&
                _filled(item['why']) &&
                _filled(item['fix']),
          );
      if (!mistakesComplete) {
        issues.add(
          'commonMistakes en az 2 kayıt olmalı ve her birinde '
          'mistake/why/fix dolu olmalı',
        );
      }

      for (final field in ['breathing', 'safety', 'summary']) {
        if (!_filled(data[field])) issues.add('$field boş olamaz');
      }

      for (final field in ['primaryMuscles', 'equipment']) {
        if ((data[field] as List? ?? const []).isEmpty) {
          issues.add(
            '$field boş olamaz — ekipmansız hareket için '
            '["bodyOnly"] yaz',
          );
        }
      }

      // Şema uyumunu son adımda dene: alan eksikleri yukarıda daha
      // anlaşılır bildirildi, burada kalan tip hataları yakalanıyor.
      if (issues.isEmpty) {
        try {
          Exercise.fromJson(data);
        } on ArgumentError catch (error) {
          issues.add('${error.name}: ${error.message}');
        } catch (error) {
          issues.add('şemaya uymuyor ($error)');
        }
      }

      if (issues.isNotEmpty) {
        problems.add(
          'newExercises "${candidate.id}": ${issues.join('; ')}.',
        );
      }
    }

    return problems;
  }

  static bool _filled(Object? value) =>
      value is String && value.trim().isNotEmpty;

  List<String> _checkGoals(PlanJson plan) {
    final goals = plan.goals;
    final problems = <String>[];

    void range(String field, num value, num min, num max) {
      if (value < min || value > max) {
        problems.add(
          'goals.$field değeri $value makul aralık dışında ($min-$max).',
        );
      }
    }

    range('dailyKcal', goals.dailyKcal, _kcalRange.min, _kcalRange.max);
    range('proteinG', goals.proteinG, _proteinRange.min, _proteinRange.max);
    range('waterL', goals.waterL, _waterRange.min, _waterRange.max);

    if (goals.targetLossKg <= 0) {
      problems.add('goals.targetLossKg pozitif olmalı.');
    }

    return problems;
  }

  List<String> _checkDates(PlanJson plan) {
    final problems = <String>[];

    if (!_datePattern.hasMatch(plan.meta.startDate)) {
      problems.add(
        'meta.startDate "${plan.meta.startDate}" yyyy-MM-dd biçiminde olmalı.',
      );
      return problems;
    }

    final start = DateTime.tryParse(plan.meta.startDate);
    if (start == null) {
      problems.add('meta.startDate geçerli bir tarih değil.');
      return problems;
    }

    final expectedDays = plan.meta.weeks * 7;
    if (plan.days.length != expectedDays) {
      problems.add(
        '${plan.meta.weeks} hafta için $expectedDays gün bekleniyordu, '
        '${plan.days.length} gün geldi.',
      );
    }

    for (final (index, day) in plan.days.indexed) {
      final expected = start.add(Duration(days: index));
      if (DateTime.tryParse(day.date) != expected) {
        problems.add(
          '${index + 1}. gün: tarihler ardışık olmalı — "${day.date}" '
          'yerine "${_iso(expected)}" bekleniyordu. '
          'Sonraki günleri de kaydırman gerekebilir.',
        );
        // İlk kopukluk yeterli: sonraki 27 günü de bildirmek mesajı
        // okunamaz hale getirir.
        break;
      }
    }

    return problems;
  }

  List<String> _checkDays(PlanJson plan) {
    final problems = <String>[];
    final newIds = {
      for (final candidate in plan.newExercises) candidate.id,
    };

    for (final (index, day) in plan.days.indexed) {
      final label = '${index + 1}. gün (${day.date})';

      final workoutSlots = day.slots
          .where((slot) => slot.kind == 'workout')
          .length;
      if (workoutSlots > 1) {
        problems.add(
          '$label: $workoutSlots antrenman slotu var; günde en çok 1 olmalı.',
        );
      }

      for (final slot in day.slots) {
        if (!_timePattern.hasMatch(slot.time)) {
          problems.add(
            '$label: slot saati "${slot.time}" HH:mm biçiminde olmalı.',
          );
        }
      }

      if (day.type == 'rest' && day.exercises.isNotEmpty) {
        problems.add(
          '$label: dinlenme günü egzersiz içeremez. Ya günü home/gym yap '
          'ya da exercises dizisini boşalt.',
        );
      }

      for (final exercise in day.exercises) {
        problems.addAll(_checkExercise(label, day, exercise, newIds));
      }
    }

    return problems;
  }

  List<String> _checkExercise(
    String dayLabel,
    PlanDayJson day,
    PlanExerciseJson exercise,
    Set<String> newIds,
  ) {
    final problems = <String>[];
    final entry = catalog[exercise.exerciseId];

    if (entry == null) {
      if (!newIds.contains(exercise.exerciseId)) {
        problems.add(
          '$dayLabel: "${exercise.exerciseId}" katalogda yok. '
          'Uygun alternatifler: ${_suggestions(day.type)}. '
          'Ya bunlardan birini kullan ya da hareketi newExercises '
          'dizisinde tam tanımıyla gönder.',
        );
      }
      // Yeni hareketin yeri henüz bilinmiyor; konum denetimi atlanır.
      return problems;
    }

    final fitsLocation = switch (day.type) {
      'home' => entry.location != ExerciseLocation.gym,
      'gym' => entry.location != ExerciseLocation.home,
      _ => true,
    };

    if (!fitsLocation) {
      final place = day.type == 'home' ? 'ev' : 'salon';
      problems.add(
        '$dayLabel: "${exercise.exerciseId}" ($place günü) burada '
        'yapılamaz. Uygun alternatifler: ${_suggestions(day.type)}.',
      );
    }

    if (exercise.sets == null) {
      problems.add('$dayLabel: "${exercise.exerciseId}" için sets zorunlu.');
    }
    if (exercise.reps == null && exercise.durationSec == null) {
      problems.add(
        '$dayLabel: "${exercise.exerciseId}" için reps ya da durationSec '
        'verilmeli.',
      );
    }

    return problems;
  }

  /// Gün tipine uyan üç örnek id — AI düzeltmeyi bunlarla yapabiliyor.
  String _suggestions(String dayType) {
    final matches = catalog.entries.where((entry) {
      return switch (dayType) {
        'home' => entry.value.location != ExerciseLocation.gym,
        'gym' => entry.value.location != ExerciseLocation.home,
        _ => true,
      };
    }).take(3);

    return matches.isEmpty
        ? '(katalog boş)'
        : matches.map((entry) => entry.key).join(', ');
  }

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
