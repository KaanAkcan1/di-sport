import 'dart:convert';

import 'package:disport/features/ai_bridge/domain/ports.dart';

/// Profil anahtarları.
///
/// Aynı adlar onboarding formunda, veritabanında ve `context.md`'de
/// kullanılıyor; tek yerde tanımlı olmaları üçünün ayrışmasını önlüyor.
abstract final class ProfileKeys {
  static const age = 'age';

  // v3 kimlik anahtarları. Ad AI belgesine girmez (kimlik gitmez);
  // cinsiyet girer (kalori katsayısı). `birthDate` varsa yaş ondan
  // türetilir, eski `age` yalnız yedek.
  static const firstName = 'firstName';
  static const lastName = 'lastName';
  static const birthDate = 'birthDate'; // yyyy-MM-dd
  static const gender = 'gender'; // male | female | unspecified

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

  /// **Ayarlar** formu — yalnız ölçüler.
  ///
  /// Kalanların hepsinin v3'te kendi evi var ve form oradan taşınanı
  /// ikinci kez sormaz (kullanıcı bildirimi, v3.1 sonrası temizlik):
  ///
  /// - **Yaş** doğum tarihinden türetilir (sihirbaz soruyor); elle
  ///   girilen yaş her yıl bayatlar. Eski `age` anahtarı yalnız yedek.
  /// - **İş düzeni ve saatler** → Günlük Düzen (mesai/yasaklı pencere).
  /// - **Evdeki ekipman** → Ekipmanların (tipli envanter; serbest metin
  ///   `canPerform` süzgecine giremiyordu).
  /// - **Sağlık kısıtları** → Medikal (kimlikli kısıtlar; motorlar
  ///   serbest metni okuyamıyor).
  /// - **Aile yemeği saati** M10'da kaldırılmıştı.
  ///
  /// Eski anahtarların verisi `profile_entries`'te duruyor — eski
  /// kurulumlarda kayıp yok, yalnız yeni girilemiyor; `context.md`
  /// doluysa basmaya devam ediyor.
  static const form = <(String, String, String)>[
    (heightCm, 'Boy', 'cm'),
    (currentWeightKg, 'Şu anki kilo', 'kg'),
    (targetWeightKg, 'Hedef kilo', 'kg'),
  ];
}

/// Belgeye girip girmeyeceği seçilebilen bölümler (v3 §9.3).
///
/// Kim/hedef/görev hep girer — onlarsız plan istenemez. Gerisi
/// kullanıcının kararı: kapalı bölüm belgeye **hiç** yazılmaz.
enum ContextSection {
  medical,
  environment,
  routine,
  forbidden,
  recent,
  notes,
  foods,
}

/// Dokuz bölümlü `context.md` üretir (v3 §9.3, v3.1 §8).
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
    required this.medical,
    required this.medications,
    required this.environment,
    required this.routine,
    required this.nutrition,
    required this.rules,
  });

  final ProfileSource profile;
  final LogSource logs;
  final HealthSource health;
  final CatalogSource catalog;
  final PlanSource plan;
  final AvailabilitySource availability;
  final MedicalSource medical;
  final MedicationSource medications;
  final EnvironmentSource environment;
  final RoutineSource routine;
  final NutritionSource nutrition;
  final RulesSource rules;

  /// Geçen dönem verisi için bakılacak gün sayısı (v3 §9.3/6: 14).
  static const lookbackDays = 14;

  Future<String> build({
    required DateTime today,
    int weeks = 4,
    DateTime? graftFrom,
    Set<ContextSection> sections = const {
      ContextSection.medical,
      ContextSection.environment,
      ContextSection.routine,
      ContextSection.forbidden,
      ContextSection.recent,
      ContextSection.notes,
      ContextSection.foods,
    },
  }) async {
    final profileData = await profile.profile();
    final compliance = await logs.compliance(lastDays: lookbackDays);
    final notes = await logs.userNotes(lastDays: lookbackDays);
    final actuals = await logs.actuals(lastDays: lookbackDays);
    final reality = await logs.reality(lastDays: lookbackDays);
    final sessions = await logs.sessions(lastDays: lookbackDays);
    final metrics = await health.bodyMetrics(lastDays: lookbackDays);
    final labs = await health.recentLabs();
    final exercises = await catalog.all();
    final activePlan = await plan.activePlanSummary();
    final windows = await availability.windows();
    final facts = await medical.facts();
    final meds = await medications.medications();
    final gear = await environment.equipment();
    final sports = await environment.favoriteSports();
    final behaviors = await routine.mealBehaviors();
    final intake = await nutrition.dailyIntake(lastDays: lookbackDays);
    final foods = await nutrition.foods();
    final forbidden = await rules.forbidden();

    // Kapsam: aşılamada plan seçilen günden başlar; yoksa yarından.
    final startDate = _iso(
      graftFrom ?? today.add(const Duration(days: 1)),
    );

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
    if (sections.contains(ContextSection.medical)) {
      _writeMedical(buffer, facts, labs, meds);
    }
    if (sections.contains(ContextSection.environment)) {
      _writeEnvironment(buffer, gear, sports);
    }
    _writeConstraints(buffer, profileData, windows);
    if (sections.contains(ContextSection.routine)) {
      _writeMealBehaviors(buffer, behaviors);
    }
    if (sections.contains(ContextSection.forbidden)) {
      _writeForbidden(buffer, forbidden);
    }
    if (sections.contains(ContextSection.recent)) {
      _writeLastPeriod(
        buffer,
        compliance,
        metrics,
        actuals,
        intake,
        reality,
        sessions,
      );
    }
    if (sections.contains(ContextSection.notes)) {
      _writeNotes(buffer, notes);
    }
    _writeTask(buffer, exercises, weeks, startDate, graftFrom != null);
    if (sections.contains(ContextSection.foods)) {
      _writeFoods(buffer, foods);
    }

    return buffer.toString();
  }

  void _writeWho(StringBuffer buffer, Map<String, String> data) {
    String value(String key) => data[key]?.trim().isNotEmpty ?? false
        ? data[key]!
        : 'belirtilmedi';

    // Yaş doğum tarihinden türetilir; eski `age` anahtarı yedek. Ad
    // hiç yazılmaz — kimlik AI'a gitmez (v3 §9.3/1).
    String age() {
      final birth = DateTime.tryParse(data[ProfileKeys.birthDate] ?? '');
      if (birth == null) return value(ProfileKeys.age);
      final now = DateTime.now();
      var years = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        years--;
      }
      return '$years';
    }

    final gender = switch (data[ProfileKeys.gender]) {
      'male' => 'erkek',
      'female' => 'kadın',
      _ => 'belirtilmedi',
    };

    buffer
      ..writeln('## 1. Kim')
      ..writeln()
      ..writeln('- Yaş: ${age()}')
      ..writeln('- Cinsiyet: $gender')
      ..writeln('- Boy: ${value(ProfileKeys.heightCm)} cm')
      ..writeln('- Şu anki kilo: ${value(ProfileKeys.currentWeightKg)} kg')
      ..writeln(
        '- Uyanma: ${value(ProfileKeys.wakeTime)} · '
        'Uyku: ${value(ProfileKeys.sleepTime)}',
      )
      ..writeln('- Salona erişim: ${value(ProfileKeys.gymAccessHours)}');
    // Eski serbest alan: formdan kalktı (gerçek kaynak §5'teki
    // pencereler); eski kurulumda değer varsa basılmaya devam eder.
    if (data[ProfileKeys.workSchedule]?.trim().isNotEmpty ?? false) {
      buffer.writeln('- İş düzeni: ${data[ProfileKeys.workSchedule]}');
    }
    buffer.writeln();
  }

  /// Medikal bölüm (v3 §9.3/2): durumlar + tahliller + ilaçlar, sınır
  /// satırıyla.
  void _writeMedical(
    StringBuffer buffer,
    List<MedicalFactDump> facts,
    List<LabValueDump> labs,
    List<MedicationDump> meds,
  ) {
    buffer
      ..writeln('## 3. Medikal')
      ..writeln();

    // Teşhisler tarihli alt listeye ayrılıyor (v3.1 §8) — ana liste
    // durum/kısıt/alerji/kan grubu.
    final diagnoses = [
      for (final fact in facts)
        if (fact.kind == 'diagnosis') fact,
    ];
    final others = [
      for (final fact in facts)
        if (fact.kind != 'diagnosis') fact,
    ];

    if (others.isEmpty) {
      buffer.writeln('- Bilinen durum/kısıt/alerji kaydı yok.');
    } else {
      String label(String kind) => switch (kind) {
        'condition' => 'Durum',
        'restriction' => 'Hareket kısıtı',
        'allergy' => 'Alerji',
        'bloodType' => 'Kan grubu',
        _ => kind,
      };
      for (final fact in others) {
        buffer.writeln(
          '- ${label(fact.kind)}: ${fact.label}'
          '${fact.note == null ? '' : ' (${fact.note})'}',
        );
      }
    }

    if (diagnoses.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('### Tanılar')
        ..writeln();
      for (final fact in diagnoses) {
        buffer.writeln(
          '- ${fact.label}'
          '${fact.factDate == null ? '' : ' — ${fact.factDate}'}'
          '${fact.note == null ? '' : ' (${fact.note})'}',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('### Son tahliller')
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

    buffer
      ..writeln()
      ..writeln('### İlaç ve takviyeler')
      ..writeln();
    if (meds.isEmpty) {
      buffer.writeln('(tanımlı ilaç/takviye yok)');
    } else {
      for (final med in meds) {
        buffer.writeln(
          '- ${med.isPrescription ? "Reçeteli" : "Takviye"}: ${med.name}'
          '${med.doseLabel.isEmpty ? '' : ' · ${med.doseLabel}'}'
          '${med.times.isEmpty ? '' : ' · ${med.times.join(", ")}'}',
        );
      }
    }
    buffer
      ..writeln()
      ..writeln(
        '**Sınır:** İlaç etkileşimi, doz değişikliği ya da ilaç önerisi '
        'verme; ilaçları yalnız zamanlama ve beslenme bağlamı olarak '
        'kullan.',
      )
      ..writeln();
  }

  /// Ortam (v3 §9.3/3): ekipman enum adlarıyla + sevilen sporlar.
  void _writeEnvironment(
    StringBuffer buffer,
    ({List<String> home, List<String> gym}) gear,
    List<({String name, String? note})> sports,
  ) {
    buffer
      ..writeln('## 4. Ortam')
      ..writeln()
      ..writeln(
        '- Evdeki ekipman: '
        '${gear.home.isEmpty ? "yok (yalnız vücut ağırlığı)" : gear.home.join(", ")}',
      )
      ..writeln(
        '- Salondaki ekipman: '
        '${gear.gym.isEmpty ? "salona gitmiyor" : gear.gym.join(", ")}',
      );

    if (sports.isNotEmpty) {
      buffer.writeln(
        '- Sevdiği sporlar (plana serpiştir): '
        '${sports.map((s) => s.note == null ? s.name : "${s.name} (${s.note})").join(", ")}',
      );
    }
    buffer.writeln();
  }

  /// Öğün davranışı tablosu (v3 §9.3/4).
  void _writeMealBehaviors(
    StringBuffer buffer,
    List<MealBehaviorDump> behaviors,
  ) {
    if (behaviors.isEmpty) return;

    buffer
      ..writeln('### Öğün davranışları')
      ..writeln()
      ..writeln(
        'planned = plan doldurur · fixed = hep aynı şey yenir, '
        'kalorisini hesaba kat ama değiştirme · external = '
        'yemekhane/dışarıda, bu öğünü planlama ve kalan öğünleri '
        'denge için ayarla.',
      )
      ..writeln();
    for (final behavior in behaviors) {
      buffer.writeln(
        '- ${behavior.meal}: ${behavior.behavior}'
        '${behavior.time == null ? '' : ' · ${behavior.time}'}'
        '${behavior.fixedNote == null ? '' : ' · "${behavior.fixedNote}"'}',
      );
    }
    buffer.writeln();
  }

  /// Yasaklılar (v3 §9.3/5).
  void _writeForbidden(StringBuffer buffer, List<String> forbidden) {
    if (forbidden.isEmpty) return;

    buffer
      ..writeln('## 6. Yasaklı yiyecekler')
      ..writeln()
      ..writeln('Bunları **asla önerme**:')
      ..writeln();
    for (final label in forbidden) {
      buffer.writeln('- $label');
    }
    buffer.writeln();
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
      ..writeln('## 5. Kısıtlar ve düzen')
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
    List<DayIntakeDump> intake,
    List<DayRealityDump> reality,
    List<SessionDump> sessions,
  ) {
    buffer
      ..writeln('## 7. Geçen dönem')
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
          // v3.1 §8: günlük gerçeklik — uyku saatleri, his, belirti,
          // stres, atlanan öğünler. Boş alan yazılmaz.
          'dailyReality': [
            for (final day in reality)
              {
                'date': day.date,
                if (day.bedTime != null) 'bedTime': day.bedTime,
                if (day.wakeTime != null) 'wakeTime': day.wakeTime,
                if (day.napMinutes != null) 'napMinutes': day.napMinutes,
                if (day.moodScore != null) 'mood1to5': day.moodScore,
                if (day.symptoms.isNotEmpty) 'symptoms': day.symptoms,
                if (day.stressedDay) 'stressfulDay': true,
                if (day.skippedMeals.isNotEmpty)
                  'skippedMeals': day.skippedMeals,
              },
          ],
          // v3.1 §8: seanslar süre + RPE + ağrı notuyla.
          'workoutSessions': [
            for (final session in sessions)
              {
                'date': session.date,
                'minutes': session.minutes,
                if (session.rpe != null) 'rpe': session.rpe,
                if (session.painNote.isNotEmpty)
                  'painNote': session.painNote,
              },
          ],
          // v3: su ml ve ilaç uyumu da paylaşılıyor — kullanıcı kararı
          // ("geçmiş su ilaç alım bilgisi de AI ile paylaşılır").
          'dailyIntake': [
            for (final day in intake)
              {
                'date': day.date,
                'kcalEaten': day.kcalEaten.round(),
                if (day.waterMl != null) 'waterMl': day.waterMl,
                if (day.dosesPlanned != null)
                  'doses': '${day.dosesTaken}/${day.dosesPlanned}',
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
      ..writeln('## 8. Kendi sözlerim')
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

  /// Besin listesi (v3 §9.3/9): AI plana besin id'siyle kalem yazsın.
  void _writeFoods(StringBuffer buffer, List<FoodDump> foods) {
    buffer
      ..writeln('### Besin listesi')
      ..writeln()
      ..writeln(
        'Öğün kalemlerinde (`items[].foodId`) yalnız bu id\'leri kullan:',
      )
      ..writeln()
      ..writeln('```')
      ..writeln('id · ad · kcal/100g · varsayılan porsiyon');
    for (final food in foods) {
      buffer.writeln(
        '${food.id} · ${food.name} · ${food.kcal100.round()} · '
        '${food.defaultPortion ?? "100 g"}',
      );
    }
    buffer
      ..writeln('```')
      ..writeln();
  }

  void _writeTask(
    StringBuffer buffer,
    List<ExerciseRef> exercises,
    int weeks,
    String startDate,
    bool graft,
  ) {
    buffer
      ..writeln('## 9. Görev ve format')
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
        'gün sayısı hafta sayısının 7 katı olsun.'
        '${graft ? ' Bu bir devam planı: yalnız bu tarihten sonrasını yaz; önceki günlere dokunulmayacak.' : ''}',
      )
      ..writeln(
        '6. `dailyKcal` 1200-4000, `proteinG` 50-300, `waterL` 1-6 '
        'aralığında olmalı.',
      )
      ..writeln(
        '7. Öğün slotlarına istersen `mealKind` '
        '(kahvalti|araOgun|ogle|ikindi|aksam|gece) ve besin '
        'listesindeki id\'lerle `items` dizisi ekle: '
        '`[{"foodId": "...", "quantity": 1.5, "portionId": "..."}]`. '
        'Listede olmayan besin id\'si kullanma.',
      )
      ..writeln(
        '8. Bölüm 7\'deki `workoutSessions` verisini yük ilerletmesinde '
        'dikkate al: RPE 8 ve üzeri seanslardan sonra yükü artırma, '
        '`painNote` geçen hareketleri değiştirilmiş ya da azaltılmış '
        'varyantla planla.',
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
