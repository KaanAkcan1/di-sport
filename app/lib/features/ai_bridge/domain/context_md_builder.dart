import 'dart:convert';

import 'package:disport/features/ai_bridge/domain/ports.dart';

/// Profil anahtarları.
///
/// Aynı adlar onboarding formunda, veritabanında ve `context.md`'de
/// kullanılıyor; tek yerde tanımlı olmaları üçünün ayrışmasını önlüyor.
abstract final class ProfileKeys {
  static const age = 'age';
  static const heightCm = 'heightCm';
  static const currentWeightKg = 'currentWeightKg';
  static const targetWeightKg = 'targetWeightKg';
  static const wakeTime = 'wakeTime';
  static const sleepTime = 'sleepTime';
  static const workSchedule = 'workSchedule';
  static const gymAccessHours = 'gymAccessHours';
  static const familyDinnerTime = 'familyDinnerTime';
  static const equipmentAtHome = 'equipmentAtHome';
  static const healthConstraints = 'healthConstraints';

  /// Onboarding formundaki sıra ve etiketler.
  static const form = <(String, String, String)>[
    (age, 'Yaş', ''),
    (heightCm, 'Boy', 'cm'),
    (currentWeightKg, 'Şu anki kilo', 'kg'),
    (targetWeightKg, 'Hedef kilo', 'kg'),
    (wakeTime, 'Uyanma saati', 'örn. 06:11'),
    (sleepTime, 'Uyku saati', 'örn. 23:45'),
    (workSchedule, 'İş düzeni', 'örn. Fabrika, 07:30-17:30'),
    (gymAccessHours, 'Salona gidebildiğin saatler', 'örn. 22:00 sonrası'),
    (familyDinnerTime, 'Aile yemeği saati', 'örn. 19:50'),
    (equipmentAtHome, 'Evdeki ekipman', 'örn. direnç bandı, sandalye'),
    (healthConstraints, 'Sağlık kısıtları', 'örn. diz hassasiyeti'),
  ];
}

/// Yedi bölümlü `context.md` üretir (spec 7.1).
///
/// Sağlayıcı bağımsız: çıktı herhangi bir AI sohbetine yapıştırılabilir.
/// Uygulama hangi AI'ın kullanıldığını bilmez.
class ContextMdBuilder {
  const ContextMdBuilder({
    required this.profile,
    required this.logs,
    required this.health,
    required this.catalog,
    required this.plan,
    required this.availability,
  });

  final ProfileSource profile;
  final LogSource logs;
  final HealthSource health;
  final CatalogSource catalog;
  final PlanSource plan;
  final AvailabilitySource availability;

  /// Geçen dönem verisi için bakılacak gün sayısı.
  static const lookbackDays = 28;

  Future<String> build({required DateTime today, int weeks = 4}) async {
    final profileData = await profile.profile();
    final compliance = await logs.compliance(lastDays: lookbackDays);
    final notes = await logs.userNotes(lastDays: lookbackDays);
    final actuals = await logs.actuals(lastDays: lookbackDays);
    final metrics = await health.bodyMetrics(lastDays: lookbackDays);
    final labs = await health.recentLabs();
    final exercises = await catalog.selectable();
    final activePlan = await plan.activePlanSummary();
    final windows = await availability.windows();

    final startDate = _iso(today.add(const Duration(days: 1)));

    final buffer = StringBuffer()
      ..writeln('# Antrenman ve beslenme planı isteği')
      ..writeln()
      ..writeln(
        'Bu belgeyi bir yapay zekâ sohbetine yapıştır. Dönen JSON\'u '
        'uygulamadaki "Planı içeri al" ekranına yapıştırarak planı '
        'yükleyebilirsin.',
      )
      ..writeln();

    _writeWho(buffer, profileData);
    _writeGoal(buffer, profileData, weeks, activePlan);
    _writeConstraints(buffer, profileData, windows);
    _writeLastPeriod(buffer, compliance, metrics, actuals);
    _writeNotes(buffer, notes);
    _writeLabs(buffer, labs);
    _writeTask(buffer, exercises, weeks, startDate);

    return buffer.toString();
  }

  void _writeWho(StringBuffer buffer, Map<String, String> data) {
    String value(String key) => data[key]?.trim().isNotEmpty ?? false
        ? data[key]!
        : 'belirtilmedi';

    buffer
      ..writeln('## 1. Kim')
      ..writeln()
      ..writeln('- Yaş: ${value(ProfileKeys.age)}')
      ..writeln('- Boy: ${value(ProfileKeys.heightCm)} cm')
      ..writeln('- Şu anki kilo: ${value(ProfileKeys.currentWeightKg)} kg')
      ..writeln(
        '- Uyanma: ${value(ProfileKeys.wakeTime)} · '
        'Uyku: ${value(ProfileKeys.sleepTime)}',
      )
      ..writeln('- İş düzeni: ${value(ProfileKeys.workSchedule)}')
      ..writeln('- Salona erişim: ${value(ProfileKeys.gymAccessHours)}')
      ..writeln('- Aile yemeği: ${value(ProfileKeys.familyDinnerTime)}')
      ..writeln('- Evdeki ekipman: ${value(ProfileKeys.equipmentAtHome)}')
      ..writeln();
  }

  void _writeGoal(
    StringBuffer buffer,
    Map<String, String> data,
    int weeks,
    ActivePlanSummary? activePlan,
  ) {
    buffer
      ..writeln('## 2. Hedef')
      ..writeln()
      ..writeln(
        '- Hedef kilo: ${data[ProfileKeys.targetWeightKg] ?? "belirtilmedi"} kg',
      )
      ..writeln(
        '- $weeks haftalık plan istiyorum; haftada 0,7-1 kg '
        'sürdürülebilir kayıp.',
      );

    if (activePlan != null) {
      buffer.writeln(
        '- Şu an "${activePlan.title}" planındayım '
        '(${activePlan.startDate} – ${activePlan.endDate}). '
        'Yeni plan bunun devamı olacak.',
      );
    }

    buffer.writeln();
  }

  void _writeConstraints(
    StringBuffer buffer,
    Map<String, String> data,
    List<WindowDump> windows,
  ) {
    final constraints = data[ProfileKeys.healthConstraints];

    buffer
      ..writeln('## 3. Kısıtlar')
      ..writeln()
      ..writeln(
        '- Sağlık: '
        '${constraints?.trim().isNotEmpty ?? false ? constraints : "bilinen yok"}',
      )
      ..writeln(
        '- Zıplamalı hareket ve uzun koşu yok. Geçiş kriteri: 105 kg '
        'altına inmek, 8 nizami şınav yapmak ve koşu ertesi diz/incik '
        'ağrısı olmaması — üçü birden sağlanana kadar.',
      );

    _writeWindows(buffer, windows);
    buffer.writeln();
  }

  /// Haftalık uygunluk.
  ///
  /// İki tür ayrı yazılıyor çünkü AI için anlamları farklı: mesaide
  /// öğün olur ama antrenman olmaz, yasaklı saatte hiçbir şey olmaz.
  /// Tek liste hâlinde verilseydi bu ayrım kaybolurdu.
  void _writeWindows(StringBuffer buffer, List<WindowDump> windows) {
    if (windows.isEmpty) {
      buffer.writeln('- Haftalık uygunluk belirtilmedi.');
      return;
    }

    String describe(Iterable<WindowDump> group) => group
        .map(
          (w) =>
              '${_weekdayNames[w.weekday - 1]} ${w.startTime}-${w.endTime}'
              '${w.label.isEmpty ? '' : ' (${w.label})'}',
        )
        .join(', ');

    final work = windows.where((w) => w.kind == 'work');
    final blocked = windows.where((w) => w.kind == 'blocked');

    if (work.isNotEmpty) {
      buffer.writeln(
        '- Mesai (bu saatlerde işte; öğün olabilir, antrenman olamaz): '
        '${describe(work)}',
      );
    }
    if (blocked.isNotEmpty) {
      buffer.writeln(
        '- Uygun olunmayan saatler (hiçbir şey planlama): '
        '${describe(blocked)}',
      );
    }
  }

  static const _weekdayNames = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  void _writeLastPeriod(
    StringBuffer buffer,
    List<DayCompliance> compliance,
    List<MetricPoint> metrics,
    List<SetActualDump> actuals,
  ) {
    buffer
      ..writeln('## 4. Geçen dönem')
      ..writeln()
      ..writeln(
        'Aşağıdaki blok uygulamanın ürettiği kayıttır; son '
        '$lookbackDays günü kapsar.',
      )
      ..writeln()
      ..writeln('```json')
      ..writeln(
        const JsonEncoder.withIndent('  ').convert({
          'days': [
            for (final day in compliance)
              {
                'date': day.date,
                'type': day.dayType,
                'workoutDone': day.workoutDone,
                'water3L': day.waterTargetMet,
                'noAlcoholSugar': day.noAlcoholSugar,
                'slotsChecked': '${day.checkedSlots}/${day.totalSlots}',
              },
          ],
          'weightSeries': [
            for (final metric in metrics)
              if (metric.kind == 'weight')
                {'date': metric.date, 'kg': metric.value},
          ],
          'otherMeasurements': [
            for (final metric in metrics)
              if (metric.kind != 'weight')
                {
                  'date': metric.date,
                  'kind': metric.kind,
                  'value': metric.value,
                  'unit': metric.unit,
                },
          ],
          'setActuals': [
            for (final actual in actuals)
              {
                'date': actual.date,
                'exerciseId': actual.exerciseId,
                'set': actual.setIndex + 1,
                if (actual.reps != null) 'reps': actual.reps,
                if (actual.durationSec != null)
                  'durationSec': actual.durationSec,
              },
          ],
        }),
      )
      ..writeln('```')
      ..writeln();
  }

  void _writeNotes(
    StringBuffer buffer,
    List<({String date, String text})> notes,
  ) {
    buffer
      ..writeln('## 5. Kendi sözlerim')
      ..writeln();

    if (notes.isEmpty) {
      buffer.writeln('(not yazılmamış)');
    } else {
      for (final note in notes) {
        buffer.writeln('- **${note.date}:** ${note.text}');
      }
    }

    buffer.writeln();
  }

  void _writeLabs(StringBuffer buffer, List<LabValueDump> labs) {
    buffer
      ..writeln('## 6. Son tahliller')
      ..writeln();

    if (labs.isEmpty) {
      buffer.writeln('(tahlil kaydı yok)');
    } else {
      for (final lab in labs) {
        final range = lab.refLow == null && lab.refHigh == null
            ? ''
            : ' (referans ${lab.refLow ?? "?"}-${lab.refHigh ?? "?"})';
        buffer.writeln(
          '- ${lab.marker}: ${lab.value} ${lab.unit}$range — ${lab.date}',
        );
      }
    }

    buffer.writeln();
  }

  void _writeTask(
    StringBuffer buffer,
    List<ExerciseRef> exercises,
    int weeks,
    String startDate,
  ) {
    buffer
      ..writeln('## 7. Görev ve format')
      ..writeln()
      ..writeln('Bana $weeks haftalık, gün gün bir plan üret. Kurallar:')
      ..writeln()
      ..writeln(
        '1. Yanıtın **yalnızca** aşağıdaki şemaya uyan tek bir JSON '
        'belgesi olsun. Açıklama cümlesi, giriş metni ya da markdown '
        'kod bloğu ekleme.',
      )
      ..writeln(
        '2. `exercises[].exerciseId` için **yalnızca** aşağıdaki katalog '
        'listesindeki id\'leri kullan.',
      )
      ..writeln(
        '3. Katalogda olmayan bir hareket önermek istersen onu '
        '`newExercises` dizisine **tam tanımıyla** ekle: `execution` en '
        'az 3 adım, `commonMistakes` en az 2 kayıt (mistake/why/fix üçü '
        'de dolu), `breathing`, `safety`, `summary`, `primaryMuscles` ve '
        '`equipment` boş olamaz. Ekipman değerleri sabit bir listeden '
        'seçilir: `bodyOnly`, `barbell`, `dumbbell`, `kettlebell`, '
        '`cable`, `machine`, `bands`, `medicineBall`, `exerciseBall`, '
        '`foamRoll`, `ezCurlBar`, `other`, `none`. Ekipmansız hareket '
        'için `["bodyOnly"]` yaz.',
      )
      ..writeln(
        '4. Saatleri bölüm 1\'deki yaşam düzenime göre koy. Dinlenme '
        'günü egzersiz içermesin; günde en fazla 1 antrenman slotu olsun.',
      )
      ..writeln(
        '5. Tarihler `$startDate` gününden başlayarak ardışık olsun ve '
        'gün sayısı hafta sayısının 7 katı olsun.',
      )
      ..writeln(
        '6. `dailyKcal` 1200-4000, `proteinG` 50-300, `waterL` 1-6 '
        'aralığında olmalı.',
      )
      ..writeln()
      ..writeln('### Kullanılabilir katalog')
      ..writeln()
      ..writeln('```')
      ..writeln('id · name · yer · ekipman · hedef kas');
    for (final exercise in exercises) {
      buffer.writeln(
        '${exercise.id} · ${exercise.name} · ${exercise.location} · '
        '${exercise.equipment.isEmpty ? "none" : exercise.equipment.join("+")} · '
        '${exercise.primaryMuscles.join(", ")}',
      );
    }
    buffer
      ..writeln('```')
      ..writeln()
      ..writeln('### JSON şeması')
      ..writeln()
      ..writeln('```json')
      ..writeln(
        const JsonEncoder.withIndent('  ').convert({
          'schemaVersion': 1,
          'meta': {
            'title': 'Ekim Planı',
            'startDate': startDate,
            'weeks': weeks,
          },
          'goals': {
            'dailyKcal': 2400,
            'proteinG': 170,
            'waterL': 3,
            'weeklyGym': 3,
            'weeklyHome': 4,
            'targetLossKg': 3.5,
          },
          'rules': {
            'forbidden': ['Alkol', '...'],
            'free': ['Su — günde 3 litre', '...'],
          },
          'days': [
            {
              'date': startDate,
              'type': 'home',
              'weekIndex': 1,
              'headline': 'Tempoyu bul.',
              'dinnerSuggestion': 'Izgara tavuk 200 g + salata',
              'slots': [
                {'time': '05:45', 'kind': 'workout', 'label': 'Ev antrenmanı'},
                {'time': '06:30', 'kind': 'meal', 'label': 'Kahvaltı'},
              ],
              'exercises': [
                {
                  'exerciseId': 'incline_pushup',
                  'sets': 3,
                  'reps': 10,
                  'restSec': 60,
                },
              ],
            },
          ],
          'newExercises': <Object>[],
        }),
      )
      ..writeln('```');
  }

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
