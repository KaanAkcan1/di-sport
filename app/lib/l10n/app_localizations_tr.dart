// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get tabToday => 'Bugün';

  @override
  String get tabProgress => 'İlerleme';

  @override
  String get tabHealth => 'Sağlık';

  @override
  String get tabHealthHint => 'Tahliller ve ölçümler';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonClear => 'Temizle';

  @override
  String get commonRetry => 'Yeniden dene';

  @override
  String get appearanceTitle => 'Görünüm';

  @override
  String get appearanceDescription =>
      'Koyu tema uygulamanın asıl hâli; salonda ve sabahın köründe de okunur.';

  @override
  String get appearanceSystem => 'Sistem';

  @override
  String get appearanceDark => 'Koyu';

  @override
  String get appearanceLight => 'Açık';

  @override
  String get languageTitle => 'Dil';

  @override
  String get languageDescription =>
      'Arayüz dili. Hareket ve besin adları her iki dilde de aranabilir.';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get catalogTabHome => 'Evde';

  @override
  String get catalogTabGym => 'Salonda';

  @override
  String get catalogFilters => 'Filtreler';

  @override
  String get catalogSearchHint => 'Hareket veya kas ara…';

  @override
  String get catalogClearSearch => 'Aramayı temizle';

  @override
  String get catalogClearFilters => 'Filtreleri temizle';

  @override
  String get catalogRecentSection => 'Son yaptıkların';

  @override
  String get catalogExercisesSection => 'Hareketler';

  @override
  String get catalogAllExercisesSection => 'Tüm hareketler';

  @override
  String get catalogNoResults => 'Eşleşen hareket yok';

  @override
  String get catalogNoResultsDescription =>
      'Aramayı değiştir ya da filtreleri kaldır.';

  @override
  String get catalogOnlyMyEquipment => 'Ekipmanıma uygun';

  @override
  String get catalogOnlyMyEquipmentDescription =>
      'Envanterinde olmayan ekipman isteyenleri gizler.';

  @override
  String get catalogCategorySection => 'Tür';

  @override
  String get catalogCategoryStrength => 'Kuvvet';

  @override
  String get catalogCategoryCore => 'Gövde';

  @override
  String get catalogCategoryCardio => 'Kardiyo';

  @override
  String get catalogCategoryMobility => 'Hareketlilik';

  @override
  String get catalogDifficultySection => 'Zorluk';

  @override
  String catalogDifficultyChip(Object level) {
    return 'Zorluk $level';
  }

  @override
  String catalogDifficultyOutOfFive(Object level) {
    return 'Zorluk $level/5';
  }

  @override
  String catalogDifficultySemantics(Object level) {
    return 'Zorluk $level / 5';
  }

  @override
  String catalogResultCount(Object count) {
    return '$count hareket';
  }

  @override
  String get catalogLocationHome => 'Ev';

  @override
  String get catalogLocationGym => 'Salon';

  @override
  String get catalogLocationBoth => 'Ev / Salon';

  @override
  String catalogLocationSemantics(Object place) {
    return 'Yapılabildiği yer: $place';
  }

  @override
  String get catalogEquipmentTitle => 'Ekipmanım';

  @override
  String get catalogEquipmentAddFab => 'Ekipman';

  @override
  String get catalogEquipmentAddTitle => 'Ekipman ekle';

  @override
  String get catalogEquipmentFieldLabel => 'Ekipman';

  @override
  String get catalogEquipmentFieldHint => 'Kettlebell';

  @override
  String get catalogEquipmentAddAction => 'Ekle';

  @override
  String get catalogExerciseNotFound => 'Hareket bulunamadı';

  @override
  String get catalogExerciseNotFoundDescription =>
      'Bu hareket katalogdan kaldırılmış olabilir.';

  @override
  String get catalogExerciseLoadError => 'Hareket açılamadı';

  @override
  String get catalogTabSteps => 'Adımlar';

  @override
  String get catalogTabMistakes => 'Hatalar';

  @override
  String get catalogTabVariants => 'Varyantlar';

  @override
  String get catalogTabSafety => 'Güvenlik';

  @override
  String get catalogCuesTitle => 'Aklında tut';

  @override
  String get catalogCuesDescription => 'Antrenman sırasında bunlara bak.';

  @override
  String get catalogSetupTitle => 'Başlangıç';

  @override
  String get catalogExecutionTitle => 'Hareket';

  @override
  String get catalogBreathingTempoTitle => 'Nefes ve tempo';

  @override
  String get catalogBreathingLabel => 'Nefes';

  @override
  String get catalogTempoLabel => 'Tempo';

  @override
  String get catalogNoMistakes => 'Kayıtlı hata yok';

  @override
  String get catalogMistakeWhy => 'Neden sorun';

  @override
  String get catalogMistakeFix => 'Düzeltmesi';

  @override
  String get catalogNoVariants => 'Varyant tanımlı değil';

  @override
  String get catalogNoVariantsDescription =>
      'Bu hareketin kolay ya da zor bir sürümü kayıtlı değil.';

  @override
  String get catalogRegressionsTitle => 'Kolaylaştır';

  @override
  String get catalogRegressionsDescription => 'Zorlanıyorsan buradan başla.';

  @override
  String get catalogProgressionsTitle => 'Zorlaştır';

  @override
  String get catalogProgressionsDescription =>
      'Kolay gelmeye başladığında sıradaki basamak.';

  @override
  String get catalogSafetyDisclaimer =>
      'Bu bilgiler genel niteliktedir ve hekim ya da fizyoterapist değerlendirmesinin yerine geçmez. Ağrı hissettiğinde hareketi bırak.';

  @override
  String catalogImageSemantics(Object name) {
    return '$name hareketinin başlangıç ve bitiş pozisyonu';
  }

  @override
  String get catalogMetaTitle => 'Künye';

  @override
  String get catalogTargetMuscles => 'Hedef kaslar';

  @override
  String get catalogEquipmentLabel => 'Ekipman';

  @override
  String get sessionRpeLabel => 'Zorlanma (1-10)';

  @override
  String get sessionPainLabel => 'Ağrı/rahatsızlık notu';

  @override
  String get sessionPainHint => 'omuz pres rahatsız etti';

  @override
  String get sessionDebriefTitle => 'Seans nasıldı?';

  @override
  String get sessionDebriefSave => 'Kaydet';

  @override
  String get sessionDebriefSaved => 'Değerlendirme kaydedildi';

  @override
  String get workoutTitle => 'Antrenman';

  @override
  String get workoutNoExercisesTitle => 'Bugün hareket yok';

  @override
  String get workoutNoExercisesDescription =>
      'Bu gün dinlenme günü olarak planlanmış.';

  @override
  String get workoutElapsedCaption => 'dakikadır çalışıyorsun';

  @override
  String get workoutElapsedNew => 'yeni';

  @override
  String get workoutMinuteUnit => 'dk';

  @override
  String get workoutSetsCaption => 'Set';

  @override
  String get workoutExercisesCaption => 'Hareket';

  @override
  String workoutSetsProgress(Object done, Object total) {
    return '$done / $total set';
  }

  @override
  String workoutSetsDoneSemantics(Object done, Object total) {
    return '$done / $total set tamamlandı';
  }

  @override
  String get workoutUndoLastSet => 'Son seti geri al';

  @override
  String get workoutAllSetsDone => 'Tamamlandı';

  @override
  String get workoutSetDone => 'Set tamam';

  @override
  String get workoutRefLast => 'Geçen';

  @override
  String get workoutRefPlan => 'Plan';

  @override
  String workoutRestLabel(Object seconds) {
    return 'Dinlenme · $seconds sn';
  }

  @override
  String workoutRestSemantics(Object seconds) {
    return 'Dinlenme, $seconds saniye kaldı';
  }

  @override
  String get workoutRestSkip => 'Geç';

  @override
  String get healthNoLabsTitle => 'Tahlil kaydı yok';

  @override
  String get healthNoLabsDescription =>
      'Elindeki tahlil sonuçlarını ekle; referans aralığını da girersen değerin düşük mü yüksek mi olduğunu takip edebilirim.';

  @override
  String get healthAddLabFab => 'Tahlil';

  @override
  String get healthAddLabTitle => 'Tahlil ekle';

  @override
  String get healthLabMarkerLabel => 'Tahlil adı';

  @override
  String get healthLabMarkerHint => 'Vitamin D';

  @override
  String get healthLabMarkerRequired => 'Tahlil adı gerekli';

  @override
  String get healthLabValueLabel => 'Değer';

  @override
  String get healthLabValueInvalid => 'Sayı girin';

  @override
  String get healthLabUnitLabel => 'Birim';

  @override
  String get healthLabUnitHint => 'ng/mL';

  @override
  String get healthLabRefLowLabel => 'Referans alt';

  @override
  String get healthLabRefHighLabel => 'Referans üst';

  @override
  String get healthLabRefHelp =>
      'İsteğe bağlı — girmezsen değer \"aralık yok\" olarak gösterilir.';

  @override
  String get healthLabPanelLabel => 'Panel';

  @override
  String get healthLabNameLabel => 'Laboratuvar';

  @override
  String get healthLabNameHelp =>
      'İsteğe bağlı — aralıklar laboratuvara göre değişir';

  @override
  String get healthLabDateLabel => 'Tahlil tarihi';

  @override
  String get healthMeasurementsTitle => 'Ölçümler';

  @override
  String get healthMeasurementsDescription =>
      'Ayda bir ölç; geçiş kriteri şınav sayısına bakıyor.';

  @override
  String get healthManageMetricsTooltip => 'Ölçümleri düzenle';

  @override
  String get healthNoMetricsTitle => 'Ölçüm türü yok';

  @override
  String get healthNoMetricsDescription =>
      'Takip etmek istediğin ölçüleri ekle — bel, kol çevresi, istirahat nabzı.';

  @override
  String get healthMetricNeverMeasured => 'henüz ölçülmedi';

  @override
  String get healthDueLabsTitleOne => 'Bir tahlilin vakti geldi';

  @override
  String healthDueLabsTitleMany(Object count) {
    return '$count tahlilin vakti geldi';
  }

  @override
  String healthDueInterval(Object months) {
    return '$months ayda bir';
  }

  @override
  String healthDueWithDate(Object marker, Object interval, Object date) {
    return '$marker — $interval, $date itibarıyla';
  }

  @override
  String healthDueNoRecord(Object marker, Object interval) {
    return '$marker — $interval, henüz hiç kaydedilmemiş';
  }

  @override
  String healthLabRefRange(Object low, Object high) {
    return 'ref $low–$high';
  }

  @override
  String get healthLabStatusLow => 'düşük';

  @override
  String get healthLabStatusHigh => 'yüksek';

  @override
  String get healthLabStatusNormal => 'normal';

  @override
  String get healthLabStatusNoRange => 'aralık yok';

  @override
  String get healthMetricsEditorTitle => 'Ölçüm türleri';

  @override
  String get healthMetricsEditorEmptyDescription =>
      'Aşağıdaki düğmeden ilk ölçümünü ekle.';

  @override
  String get healthAddMetricFab => 'Ölçüm';

  @override
  String healthDeleteMetricTitle(Object label) {
    return '\"$label\" kaldırılsın mı?';
  }

  @override
  String get healthDeleteMetricBody =>
      'Listeden çıkar. Şimdiye kadar girdiğin değerler silinmez; türü geri eklersen yeniden görünür.';

  @override
  String get healthMetricRemove => 'Kaldır';

  @override
  String healthMetricDailyHint(Object unit) {
    return '$unit · her gün Bugün ekranından';
  }

  @override
  String get healthMetricSheetAddTitle => 'Ölçüm ekle';

  @override
  String get healthMetricSheetEditTitle => 'Ölçümü düzenle';

  @override
  String get healthMetricLabelRequired => 'Ölçüm adı gerekli';

  @override
  String get healthMetricLabelLabel => 'Ölçüm';

  @override
  String get healthMetricLabelHint => 'Kol çevresi';

  @override
  String get healthMetricUnitHint => 'cm';

  @override
  String get healthMetricDisplayTitle => 'Gösterim';

  @override
  String get healthMetricInteger => 'Tam sayı';

  @override
  String get healthMetricDecimal => 'Ondalıklı';

  @override
  String get healthMetricExampleInteger => 'Örnek: 12';

  @override
  String get healthMetricExampleDecimal => 'Örnek: 104,5';

  @override
  String get progressEmptyTitle => 'Henüz gösterecek bir şey yok';

  @override
  String get progressEmptyDescription =>
      'Bugün sekmesinden tartını gir; birkaç gün sonra eğilim çizgisi anlamlı olmaya başlar.';

  @override
  String get progressWeightTitle => 'Kilo';

  @override
  String get progressWeightDescription =>
      'Kalın çizgi 7 günlük ortalama — günlük oynamalar su ve tuzdur, eğilime bak.';

  @override
  String get progressWeeksTitle => 'Haftalar';

  @override
  String get progressNoPlanTitle => 'Haftalık özet için plan gerekli';

  @override
  String get progressNoPlanDescription =>
      'Hangi günün salon, hangisinin ev olduğunu plandan okuyorum. Plan sekmesinden bir program yükle.';

  @override
  String get progressHeroEmptyCaption =>
      'İlk tartıdan sonra değişim burada görünecek';

  @override
  String get progressHeroCaption => 'kg · ilk tartıdan bugüne';

  @override
  String get progressMetricNow => 'Şu an';

  @override
  String get progressMetricPushups => 'Şınav';

  @override
  String get progressMetricWeeks => 'Hafta';

  @override
  String get progressTransitionTitle => 'Koşuya geçiş';

  @override
  String get progressTransitionAllMet =>
      'Üç ölçüt de sağlandı. Kısa koşu denemelerine başlayabilirsin.';

  @override
  String progressTransitionProgress(Object met) {
    return '$met / 3 ölçüt sağlandı.';
  }

  @override
  String progressCriterionWeight(Object limit) {
    return 'Kilo $limit kg altında';
  }

  @override
  String get progressCriterionNotWeighed => 'henüz tartılmadı';

  @override
  String progressCriterionWeightNow(Object value) {
    return 'şu an $value kg';
  }

  @override
  String progressCriterionPushups(Object count) {
    return 'Kesintisiz $count şınav';
  }

  @override
  String get progressCriterionNotMeasured => 'henüz ölçülmedi';

  @override
  String progressCriterionPushupsNow(Object value) {
    return 'şu an $value';
  }

  @override
  String get progressCriterionPainFree => 'Yürüyüş sonrası diz/ayak ağrısı yok';

  @override
  String get progressCriterionPainFreeHint => 'Bunu ölçemem, sen bileceksin.';

  @override
  String progressWeekLabel(Object index) {
    return 'Hafta $index';
  }

  @override
  String progressWeekPartial(Object days) {
    return 'sürüyor · $days gün';
  }

  @override
  String get progressWeekAverage => 'haftalık ortalama';

  @override
  String get progressWeekGym => 'Salon';

  @override
  String get progressWeekHome => 'Ev';

  @override
  String get progressWeekNoSlips => 'Kaçak yok';

  @override
  String progressWeekSlipDays(Object count) {
    return '$count kaçak gün';
  }

  @override
  String progressWeekCountChip(Object label, Object done, Object target) {
    return '$label $done / $target';
  }

  @override
  String progressChartSemantics(Object count, Object first, Object last) {
    return 'Kilo grafiği. $count ölçüm. İlk $first kilogram, son $last kilogram.';
  }

  @override
  String get commonNoRecords => 'Kayıt yok';

  @override
  String get commonErrorTitle => 'Bir şeyler ters gitti';

  @override
  String get commonStatusGood => 'iyi';

  @override
  String get commonStatusCaution => 'dikkat';

  @override
  String get commonStatusBad => 'sorunlu';

  @override
  String get commonStatusUnknown => 'veri yok';

  @override
  String get commonValueMissing => 'değer girilmedi';

  @override
  String commonMetricEmptySemantics(Object caption) {
    return '$caption: girilmedi';
  }

  @override
  String commonMetricValueSemantics(Object caption, Object value) {
    return '$caption: $value';
  }

  @override
  String commonMetricChangeSemantics(Object delta) {
    return ', değişim $delta';
  }

  @override
  String commonHeroValueSemantics(Object value, Object caption) {
    return '$value · $caption';
  }

  @override
  String commonNowAt(Object time) {
    return 'Şu an saat $time';
  }

  @override
  String get commonNowLabel => 'ŞİMDİ';

  @override
  String get commonWeekDotDone => 'kayıt var';

  @override
  String get commonWeekDotMissed => 'kayıt yok';

  @override
  String get commonWeekDotToday => 'bugün';

  @override
  String get commonWeekDotFuture => 'gelecek';

  @override
  String get settingsEquipmentTitle => 'Ekipmanım';

  @override
  String get settingsEquipmentDescription =>
      'İşaretlediklerin katalog filtresini ve yapay zekâya gönderilen bağlamı besliyor.';

  @override
  String get settingsEquipmentTile => 'Ekipman listesi';

  @override
  String get settingsWeeklyFab => 'Saat aralığı';

  @override
  String get settingsWeeklyExplanationTitle => 'İki tür aralık var';

  @override
  String get settingsWeeklyExplanationBody =>
      '· Mesai: iştesin. Yapay zekâ bu saatlere antrenman koymaz ama öğün koyabilir.\n· Uygun değil: hiçbir şey planlanmaz ve bu saatlerde bildirim çalmaz.';

  @override
  String get settingsWeeklyEmptyDay => 'boş';

  @override
  String get settingsWeeklyAddTitle => 'Saat aralığı ekle';

  @override
  String get settingsWeeklyKindWork => 'Mesai';

  @override
  String get settingsWeeklyKindBlocked => 'Uygun değil';

  @override
  String get settingsWeeklyDays => 'Günler';

  @override
  String get settingsWeeklyPickDayError => 'En az bir gün seç';

  @override
  String get settingsWeeklyStart => 'Başlangıç';

  @override
  String get settingsWeeklyEnd => 'Bitiş';

  @override
  String get settingsWeeklyOvernightHint =>
      'Bitiş başlangıçtan küçükse aralık gece yarısını aşar.';

  @override
  String get settingsWeeklyLabel => 'Açıklama';

  @override
  String get settingsWeeklyLabelHint => 'Fabrika';

  @override
  String get settingsWeeklyLabelHelper => 'İsteğe bağlı';

  @override
  String get settingsWeeklyAdd => 'Ekle';

  @override
  String get settingsBackupTitle => 'Yedekleme';

  @override
  String get settingsBackupDescription =>
      'Tüm veriler yalnız bu cihazda. Telefon değişirse yedek almadıysan geri dönüşü yok.';

  @override
  String get settingsBackupExport => 'Yedek al';

  @override
  String get settingsBackupExportSubtitle =>
      'Dosyayı paylaş menüsüyle bir yere kaydet';

  @override
  String get settingsBackupImport => 'Yedekten geri yükle';

  @override
  String get settingsBackupImportSubtitle => 'Mevcut verinin üstüne yazar';

  @override
  String get settingsBackupShareText => 'di@sport yedeği';

  @override
  String get settingsBackupRestored =>
      'Yedek yüklendi. Uygulamayı kapatıp yeniden aç — açık veritabanı bağlantısı eski veriyi göstermeye devam ediyor.';

  @override
  String get settingsBackupConfirmTitle => 'Mevcut verinin üstüne yazılsın mı?';

  @override
  String get settingsBackupConfirmBody =>
      'Şu anki tüm kayıtların yedekteki hâlle değişecek. Değişmeden önceki hâl yine de cihazda saklanıyor.';

  @override
  String get settingsBackupConfirmAction => 'Üstüne yaz';

  @override
  String get settingsNotificationsTitle => 'Bildirimler';

  @override
  String get settingsNotificationsDescription =>
      'Sabah tartısı hatırlatması uyanma saatine bağlı; profilde uyanma saatini gir.';

  @override
  String get settingsNotifWorkout => 'Antrenman';

  @override
  String get settingsNotifWorkoutDescription =>
      'Programdaki antrenman saatinde';

  @override
  String get settingsNotifMeal => 'Öğün';

  @override
  String get settingsNotifMealDescription => 'Programdaki öğün saatlerinde';

  @override
  String get settingsNotifWalk => 'Yürüyüş';

  @override
  String get settingsNotifWalkDescription => 'Programdaki yürüyüş saatinde';

  @override
  String get settingsNotifSupplement => 'Takviye';

  @override
  String get settingsNotifSupplementDescription =>
      'Vitamin ve takviye saatlerinde';

  @override
  String get settingsExactAlarmTitle => 'Tam zamanlı alarm izni';

  @override
  String get settingsExactAlarmGranted =>
      'Verildi — bildirimler tam saatinde çalar.';

  @override
  String get settingsExactAlarmDenied =>
      'Verilmedi. Bildirimler yine çalar ama pil tasarrufu kipinde birkaç dakika gecikebilir. Vermek için dokun.';

  @override
  String get settingsExactAlarmLoading => 'Yükleniyor…';

  @override
  String get settingsOnboardingIntro =>
      'Önce seni tanıyalım. Bu bilgiler cihazından çıkmaz; yalnızca sen bir yapay zekâya bağlam dosyası gönderdiğinde kullanılır.';

  @override
  String get settingsOnboardingSave => 'Kaydet ve başla';

  @override
  String get onboardingWelcomeTitle => 'di@sport\'a hoş geldin';

  @override
  String get onboardingWelcomeBody =>
      'Diyetini, sporunu, sağlık değerlerini ve ilaçlarını tek yerden takip et.';

  @override
  String get onboardingAreaDiet => 'Diyet — öğünler, kalori bütçesi, su';

  @override
  String get onboardingAreaSport => 'Spor — plan, antrenman, hareket kataloğu';

  @override
  String get onboardingAreaHealth => 'Sağlık — tahliller, ölçümler, ilerleme';

  @override
  String get onboardingAreaMed => 'İlaç ve takviye — hatırlatma ve takip';

  @override
  String get onboardingStart => 'Başlayalım';

  @override
  String get onboardingIdentityTitle => 'Seni tanıyalım';

  @override
  String get onboardingFirstName => 'Ad';

  @override
  String get onboardingLastName => 'Soyad';

  @override
  String get onboardingFirstNameRequired => 'Adını yazmadan geçemeyiz.';

  @override
  String get onboardingBirthDate => 'Doğum tarihi';

  @override
  String get onboardingBirthDay => 'Gün';

  @override
  String get onboardingBirthMonth => 'Ay';

  @override
  String get onboardingBirthYear => 'Yıl';

  @override
  String get onboardingBirthDateInvalid =>
      'Doğum tarihi geçerli bir gün olmalı.';

  @override
  String get onboardingGender => 'Cinsiyet';

  @override
  String get onboardingMale => 'Erkek';

  @override
  String get onboardingFemale => 'Kadın';

  @override
  String get onboardingGenderUnspecified => 'Belirtmek istemiyorum';

  @override
  String get onboardingGenderWhy =>
      'Kalori hesabında kullanılır; belirtmezsen ortalama katsayı alınır.';

  @override
  String get onboardingMeasuresTitle => 'Ölçülerin';

  @override
  String get onboardingMeasuresBody =>
      'Kilo ilk tartı kaydın olarak da işlenir — İlerleme grafiğin bugünden başlar.';

  @override
  String get onboardingHeight => 'Boy';

  @override
  String get onboardingWeight => 'Şu anki kilo';

  @override
  String get onboardingTargetWeight => 'Hedef kilo';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonNext => 'Devam';

  @override
  String get setupPanelTitle => 'Kurulum';

  @override
  String setupPanelProgress(int done, int total) {
    return '$done/$total tamam';
  }

  @override
  String get setupPanelBody =>
      'Birkaç kısa adım kaldı. Bunlar plana da gider — ne kadar dolu, plan o kadar isabetli.';

  @override
  String get setupCardEquipment => 'Ekipmanlarını seç';

  @override
  String get setupCardMedical => 'Medikal bilgilerin';

  @override
  String get setupCardRhythm => 'Günlük düzenin';

  @override
  String setupCardMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String get setupCardSkip => 'Geç';

  @override
  String todayBirthday(String name) {
    return 'İyi ki doğdun $name! 🎉';
  }

  @override
  String get medicalTitle => 'Medikal bilgiler';

  @override
  String get medicalPrivacyNote =>
      'Bu bilgiler cihazından çıkmaz; yalnızca sen yapay zekâ belgesini paylaştığında plana girer.';

  @override
  String get medicalKindDiagnosis => 'Tanılar';

  @override
  String get medicalKindCondition => 'Durumlar';

  @override
  String get medicalKindRestriction => 'Hareket kısıtları';

  @override
  String get medicalKindAllergy => 'Alerjiler';

  @override
  String get medicalKindBloodType => 'Kan grubu';

  @override
  String get medicalKindEmpty => 'Kayıt yok.';

  @override
  String get medicalAddCustom => 'Başka ekle';

  @override
  String get medicalCustomHint => 'örn. diz hassasiyeti';

  @override
  String medicalRemoveTitle(String label) {
    return '$label silinsin mi?';
  }

  @override
  String get medicalRemoveBody =>
      'Kayıt listeden kalkar; geçmiş verilerin bozulmaz.';

  @override
  String get medicalMedsTitle => 'İlaçlar';

  @override
  String get medicalMedsEmpty =>
      'Tanımlı ilaç yok. İlaçlar hatırlatma ve takip için İlaç & Takviye ekranında tutulur.';

  @override
  String get medicalMedsManage => 'İlaç ve takviyeleri yönet';

  @override
  String get medicalCondInsulinResistance => 'İnsülin direnci';

  @override
  String get medicalCondType2Diabetes => 'Tip 2 diyabet';

  @override
  String get medicalCondHypertension => 'Hipertansiyon';

  @override
  String get medicalCondThyroid => 'Tiroid';

  @override
  String get medicalCondKneeIssue => 'Diz sorunu';

  @override
  String get medicalCondBackIssue => 'Bel sorunu';

  @override
  String get medicalCondShoulderIssue => 'Omuz sorunu';

  @override
  String get medicalCondLactose => 'Laktoz';

  @override
  String get medicalCondGluten => 'Gluten';

  @override
  String get medicalCondNuts => 'Kuruyemiş';

  @override
  String get supplementKindSupplement => 'Takviye';

  @override
  String get supplementKindMedication => 'İlaç';

  @override
  String get equipmentTabHome => 'Evde';

  @override
  String get equipmentTabGym => 'Salonda';

  @override
  String get equipmentTabSports => 'Sporlar';

  @override
  String equipmentImpactHome(int count) {
    return 'Bu işaretlerle evde $count hareket yapılabilir.';
  }

  @override
  String equipmentImpactGym(int count) {
    return 'Bu işaretlerle salonda $count hareket yapılabilir.';
  }

  @override
  String equipmentUnlocks(int count) {
    return '+$count hareket açar';
  }

  @override
  String get equipmentGymToggle => 'Salona gidiyor musun?';

  @override
  String get equipmentGymOffBody =>
      'Salona gitmiyorsan burada iş yok — plan yalnız evde ve dışarıda yapılabilenlerden kurulur. Fikrin değişirse anahtarı aç.';

  @override
  String get sportsIntro =>
      'Sevdiğin sporları seç; yapay zekâ planı onların etrafına kurar. İstersen sıklık notu ekle.';

  @override
  String get sportsChosen => 'Seçtiklerin';

  @override
  String get sportsSearchHint => 'Spor ara — koşu, basketbol, yüzme…';

  @override
  String get sportsNoteTooltip => 'Sıklık notu';

  @override
  String get sportsNoteTitle => 'Ne sıklıkla?';

  @override
  String get sportsNoteHint => 'örn. haftada 1, pazar sabahı';

  @override
  String get reminderMealBody => 'Öğün saati. Yediklerini Diyet\'ten kaydet.';

  @override
  String get planSlotItems => 'Öğün kalemleri';

  @override
  String get planSlotAddItem => 'Besin ekle';

  @override
  String get waterRowTitle => 'Su';

  @override
  String waterRowAmount(int current, int target) {
    return '$current / $target ml';
  }

  @override
  String get waterRowAddGlass => '+250 ml';

  @override
  String get waterRowRemoveGlass => 'Bir bardak geri al';

  @override
  String get dietPlanBadge => 'PLAN';

  @override
  String get dietPlanCompliantBadge => 'PLANA UYGUN';

  @override
  String get dietAteAsPlanned => 'Plandaki gibi yedim';

  @override
  String get dietAteUsual => 'Her zamanki';

  @override
  String get dietExternalMeal =>
      'Dışarıda/yemekhanede — plan beklenmez, yediğini serbest gir.';

  @override
  String dietFixedUnbound(String note) {
    return 'Sabit öğün: $note';
  }

  @override
  String get foodSortAz => 'A–Z';

  @override
  String get foodSortKcalAsc => 'Kalori ↑';

  @override
  String get foodSortKcalDesc => 'Kalori ↓';

  @override
  String get foodSortProteinDesc => 'Protein ↓';

  @override
  String get foodSortFrequent => 'Sık yenen';

  @override
  String get foodForbiddenBadge => 'YASAKLI';

  @override
  String get forbiddenTitle => 'Yasaklı yiyecekler';

  @override
  String get forbiddenIntro =>
      'Bu liste yapay zekâ planına gider (önerilmez) ve eşleşen besinler listede rozet taşır. Kayıt engellenmez — karar senin.';

  @override
  String get forbiddenAddHint => 'örn. şeker, hamur işi, alkol';

  @override
  String get forbiddenAdd => 'Ekle';

  @override
  String get forbiddenLinkFoods => 'Besinlere bağla';

  @override
  String forbiddenLinkedCount(int count) {
    return '$count besin bağlı';
  }

  @override
  String get forbiddenNoPlan =>
      'Yasaklı listesi plana yazılır; önce bir plan gerekli.';

  @override
  String get forbiddenEmpty =>
      'Yasaklı yok. Satır ekle; istersen besinlere bağla.';

  @override
  String get dietHistoryDays => 'Gün dökümü';

  @override
  String planAdherence(int percent, int done, int planned) {
    return 'Uyum %$percent — $done/$planned antrenman günü';
  }

  @override
  String get plannedVsDoneTitle => 'Planlanan / Yapılan';

  @override
  String get plannedVsDoneExercises => 'Hareketler';

  @override
  String get plannedVsDoneColumns => 'PLAN · YAPILAN';

  @override
  String get plannedVsDoneEmptyTitle => 'Bu günde antrenman yok';

  @override
  String get plannedVsDoneEmptyBody =>
      'Plan bu güne hareket koymadı ve kayıt da girilmemiş.';

  @override
  String get plannedVsDoneOpenLive => 'Antrenmanı başlat';

  @override
  String get plannedVsDoneSession => 'Seans';

  @override
  String get plannedVsDoneNoSession =>
      'Seans kaydı yok. Geçmiş gün için saat aralığını elle girebilirsin.';

  @override
  String plannedVsDoneSessionOpen(String start) {
    return '$start — sürüyor';
  }

  @override
  String plannedVsDoneMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String get plannedVsDoneAddSession => 'Seans ekle';

  @override
  String get plannedVsDoneSessionEdit => 'Seans saatleri';

  @override
  String get plannedVsDoneStart => 'Başlangıç';

  @override
  String get plannedVsDoneEnd => 'Bitiş';

  @override
  String get plannedVsDoneAdd => '— EKLE';

  @override
  String get plannedVsDoneNoSets => 'Set kaydı yok. Aşağıdan ekle.';

  @override
  String get plannedVsDoneAddSet => 'Set ekle';

  @override
  String get plannedVsDoneReps => 'Tekrar';

  @override
  String get plannedVsDoneSeconds => 'Saniye';

  @override
  String get sportWorkoutTodayTitle => 'Bugünün antrenmanı';

  @override
  String get sportWorkoutTodayBody => 'Plan bugüne antrenman koydu.';

  @override
  String get sportWorkoutHistory => 'Geçmiş';

  @override
  String sportWorkoutExerciseCount(int count) {
    return '$count hareket';
  }

  @override
  String get catalogSafetyLabel => 'Güvenlik';

  @override
  String get catalogSafetyRestricted => 'Güvenlik — kısıtınla eşleşiyor';

  @override
  String get bmiMissingHeight => 'VKİ için boy gerekli — Profil\'den ekle';

  @override
  String get bmiMissingWeight =>
      'VKİ için kilo gerekli — tartıl ya da Profil\'e yaz';

  @override
  String get onboardingBmiContext =>
      'Hedefe giden yolda başlangıç noktan — plan buradan kurulacak.';

  @override
  String get bmiRowTitle => 'Vücut kitle indeksi';

  @override
  String get bmiUnderweight => 'Zayıf';

  @override
  String get bmiNormal => 'Normal';

  @override
  String get bmiOverweight => 'Fazla kilolu';

  @override
  String get bmiObese => 'Obez';

  @override
  String get healthShareLabs => 'Tahlil özetini paylaş';

  @override
  String get healthShareTitle => 'Tahlil özeti — di@sport';

  @override
  String get checkupTitle => 'Check-up rehberi';

  @override
  String get checkupDisclaimer =>
      'Genel tarama önerileri — tıbbi tavsiye değildir, doktoruna danış.';

  @override
  String get checkupNeedsWeight => 'Kilo girilirse öneriler netleşir.';

  @override
  String get checkupDue => 'Vakti geldi';

  @override
  String checkupInMonths(int months) {
    return '$months ay sonra';
  }

  @override
  String checkupScheduled(String test) {
    return '$test vadesi takvime eklendi.';
  }

  @override
  String get checkupFullPanel => 'Tam panel (CBC, CMP, lipit, HbA1c, TSH)';

  @override
  String get checkupHba1c => 'HbA1c';

  @override
  String get checkupLipid => 'Lipit paneli';

  @override
  String get checkupVitaminDB12 => 'D vitamini + B12';

  @override
  String get supplementsTodayTitle => 'Bugünün dozları';

  @override
  String get supplementsAdherenceTitle => 'Son 7 gün uyum';

  @override
  String get labImportTitle => 'Yapay zekâ ile tahlil aktar';

  @override
  String get labImportStep1 => 'Aktarım belgesini kopyala.';

  @override
  String get labImportCopyDoc => 'Belgeyi kopyala';

  @override
  String get labImportShareDoc => 'Paylaş';

  @override
  String get labImportCopied => 'Belge panoya kopyalandı.';

  @override
  String get labImportStep2 =>
      'Belgeyi ve tahlil PDF\'ini herhangi bir yapay zekâ sohbetine ver. PDF uygulamaya girmez.';

  @override
  String get labImportStep3 => 'Dönen JSON\'u buraya yapıştır.';

  @override
  String get labImportPasteHint => 'JSON belgesini buraya yapıştır';

  @override
  String get labImportParse => 'Ayrıştır';

  @override
  String get labImportPreview => 'Önizleme';

  @override
  String get labImportUnknownMarker => 'Tahlil sözlükte yok';

  @override
  String get labImportUnexpectedUnit => 'Birim beklenenden farklı';

  @override
  String get labImportImplausible => 'Değer akla yatkın aralığın dışında';

  @override
  String get labImportEditTitle => 'Satırı düzelt';

  @override
  String labImportSave(int save, int skip) {
    return '$save değeri kaydet · $skip atla';
  }

  @override
  String labImportSaved(int count) {
    return '$count tahlil değeri kaydedildi.';
  }

  @override
  String get healthImportWithAi => 'Yapay zekâ ile PDF\'ten aktar';

  @override
  String get ctxSectionsTitle => 'AI\'a gönderilecekler';

  @override
  String get ctxSectionsIntro =>
      'Plan isteği belgesine hangi bölümlerin gireceğini sen seçersin. Kapalı bölüm belgeye hiç yazılmaz. Kim/hedef/görev her zaman girer — onlarsız plan istenemez.';

  @override
  String get ctxPreviewButton => 'Önce belgeyi gör';

  @override
  String get ctxPreviewTitle => 'Belge önizleme';

  @override
  String get ctxCopy => 'Kopyala';

  @override
  String get ctxShare => 'Paylaş';

  @override
  String get ctxSectionMedical => 'Medikal';

  @override
  String get ctxSectionMedicalHint =>
      'Durumlar, kısıtlar, tahliller ve ilaçlar';

  @override
  String get ctxSectionEnvironment => 'Ortam';

  @override
  String get ctxSectionEnvironmentHint =>
      'Ekipman envanteri ve sevdiğin sporlar';

  @override
  String get ctxSectionRoutine => 'Öğün davranışları';

  @override
  String get ctxSectionRoutineHint =>
      'Öğün saatleri ve yemekhane/sabit öğün bilgisi';

  @override
  String get ctxSectionForbidden => 'Yasaklı yiyecekler';

  @override
  String get ctxSectionForbiddenHint => 'AI bu listeyi asla önermez';

  @override
  String get ctxSectionRecent => 'Son 14 gün';

  @override
  String get ctxSectionRecentHint =>
      'Öğünler, su (ml), ilaç uyumu, antrenman, kilo';

  @override
  String get ctxSectionNotes => 'Kendi sözlerin';

  @override
  String get ctxSectionNotesHint => 'Gün notların olduğu gibi';

  @override
  String get ctxSectionFoods => 'Besin listesi';

  @override
  String get ctxSectionFoodsHint =>
      '368 besin — AI öğünleri besin id\'siyle yazabilsin';

  @override
  String get moreAiSections => 'AI\'a gönderilecekler';

  @override
  String get importPlanGraftTitle => 'Mevcut planın üstüne aşıla';

  @override
  String importPlanGraftBody(String date) {
    return '$date öncesi aynen korunur; o tarihten sonrası bu planla değiştirilir. Kayıtlarına dokunulmaz.';
  }

  @override
  String get requestScopeTitle => 'Plan kapsamı';

  @override
  String get requestScopeBody =>
      'Aktif bir planın var. Yeni plan nereden başlasın?';

  @override
  String get requestScopeGraft => 'Şu tarihten sonrası';

  @override
  String get requestScopeFresh => 'Baştan yeni plan';

  @override
  String importWarningsTitle(int count) {
    return '$count uyarı';
  }

  @override
  String get importWarningsFootnote =>
      'Uyarılar içeri almayı engellemez; istersen sonra editörle düzelt.';

  @override
  String importWarnForbidden(String id) {
    return 'Yasaklı besin planda: $id';
  }

  @override
  String importWarnUnknownFood(String id) {
    return 'Besin listesinde yok: $id';
  }

  @override
  String importWarnCannotPerform(String id) {
    return 'Ekipmanınla yapılamıyor: $id';
  }

  @override
  String importWarnExternalMeal(String meal) {
    return 'Dışarıda yenen öğüne plan yazılmış: $meal';
  }

  @override
  String importWarnFixedMeal(String meal) {
    return 'Sabit öğün planda farklı: $meal';
  }

  @override
  String importWarnRestriction(String id) {
    return 'Hareket kısıtınla eşleşiyor: $id';
  }

  @override
  String get rhythmMealsSection => 'Öğünler';

  @override
  String get rhythmMealFlexible => 'Saat esnek';

  @override
  String get mealBehaviorPlanned => 'Plan doldurur';

  @override
  String get mealBehaviorFixed => 'Hep aynı';

  @override
  String get mealBehaviorExternal => 'Yemekhane/dışarıda';

  @override
  String get mealBehaviorFixedNoteLabel => 'Ne yenir?';

  @override
  String get mealBehaviorFixedNoteHint => 'örn. menemen + çay';

  @override
  String mealBehaviorSheetTitle(String meal) {
    return '$meal düzeni';
  }

  @override
  String get mealBehaviorTimeLabel => 'Saat';

  @override
  String get mealBehaviorTimeClear => 'Saati kaldır';

  @override
  String get mealBehaviorWhy =>
      'Bu bilgi yapay zekâ planına gider: sabit öğün değiştirilmez, dışarıda yenen öğün planlanmaz.';

  @override
  String get settingsProfileHeightRequired => 'Boy alanı gerekli.';

  @override
  String get settingsProfileMovedNote =>
      'İş düzeni ve saatler Günlük Düzen\'de, ekipman Ekipmanların\'da, sağlık kısıtları Medikal\'de düzenlenir — hepsi Daha sekmesinde.';

  @override
  String get settingsProfileContextNote =>
      'Bu bilgiler yapay zekâya gönderilen bağlam dosyasına girer. Ne kadar doldurursan plan o kadar sana göre olur; boş bıraktıkların \"belirtilmedi\" diye geçer.';

  @override
  String get importPlanTitle => 'Planı içeri al';

  @override
  String get importPlanDescription =>
      'Yapay zekânın verdiği JSON belgesini buraya yapıştır.';

  @override
  String get importPlanValidate => 'Doğrula';

  @override
  String get importPlanImport => 'İçeri al';

  @override
  String get importPlanFailedTitle => 'Plan alınamadı';

  @override
  String get importPlanPasteBackHint =>
      'Bu mesajı olduğu gibi yapay zekâya yapıştır; neyi düzelteceğini bilecek.';

  @override
  String get importPlanCopyError => 'Hatayı kopyala';

  @override
  String get importPlanErrorCopied => 'Hata mesajı kopyalandı';

  @override
  String importPlanLoaded(Object days) {
    return '$days günlük plan yüklendi.';
  }

  @override
  String importPlanLoadedWithExercises(Object days, Object count) {
    return '$days günlük plan yüklendi, $count yeni hareket eklendi.';
  }

  @override
  String importPlanSummary(Object startDate, Object weeks, Object days) {
    return '$startDate tarihinden itibaren $weeks hafta · $days gün';
  }

  @override
  String importPlanGym(Object count) {
    return 'Salon $count';
  }

  @override
  String importPlanHome(Object count) {
    return 'Ev $count';
  }

  @override
  String importPlanRest(Object count) {
    return 'Dinlenme $count';
  }

  @override
  String importPlanGoals(
    Object kcal,
    Object protein,
    Object water,
    Object loss,
  ) {
    return '$kcal kcal · $protein g protein · $water L su · hedef −$loss kg';
  }

  @override
  String get importPlanNewExercisesTitle => 'Yeni hareket önerileri';

  @override
  String get importPlanNewExercisesDescription =>
      'Onayladıkların kataloğa kalıcı olarak eklenir.';

  @override
  String todayWeekNumber(Object week) {
    return '$week. hafta';
  }

  @override
  String get todayDayTypeGym => 'Salon günü';

  @override
  String get todayDayTypeHome => 'Ev antrenmanı';

  @override
  String get todayDayTypeRest => 'Dinlenme günü';

  @override
  String todayNextEyebrow(Object time) {
    return 'Sırada · $time';
  }

  @override
  String todayExerciseCount(Object count) {
    return '$count hareket';
  }

  @override
  String todayDinnerHint(Object text) {
    return 'Akşam önerisi: $text';
  }

  @override
  String get todayNoPlanTitle => 'Bugün için plan yok';

  @override
  String get todayNoPlanBody =>
      'Plan sekmesinden bir program yükle. Tartı ve günün kutucukları plan olmadan da çalışır.';

  @override
  String get todayCheckedLabel => 'işaretli';

  @override
  String get todayUncheckedLabel => 'işaretsiz';

  @override
  String get todayRulesTitle => 'Günün kuralları';

  @override
  String get todayEditRulesTooltip => 'Kuralları düzenle';

  @override
  String get todayNoRulesTitle => 'Kural yok';

  @override
  String get todayNoRulesBody =>
      'Her gün takip etmek istediğin şeyleri ekle — su, takviye, erken yatma. Sağ üstteki ayar düğmesinden.';

  @override
  String get todayRulesEditorEmptyBody =>
      'Aşağıdaki düğmeden ilk kuralını ekle.';

  @override
  String get todayRuleFabLabel => 'Kural';

  @override
  String todayDeleteRuleTitle(Object label) {
    return '\"$label\" silinsin mi?';
  }

  @override
  String get todayDeleteRuleBody =>
      'Bugünden sonra listede görünmez. Geçmiş günlerdeki işaretlerin olduğu gibi kalır.';

  @override
  String get todayBuiltInRuleNote => 'Çizelgeden gelen kural';

  @override
  String get todayRuleNameRequired => 'Kural adı gerekli';

  @override
  String get todayAddRule => 'Kural ekle';

  @override
  String get todayEditRule => 'Kuralı düzenle';

  @override
  String get todayRuleLabel => 'Kural';

  @override
  String get todayRuleHint => 'Kreatin aldım';

  @override
  String get todayIconLabel => 'İkon';

  @override
  String get todayNoteTitle => 'Not';

  @override
  String get todayNoteDescription => 'Ne yedin, ne zorladı, nasıl geçti.';

  @override
  String get todayNoteHint => 'Bugün nasıl geçti?';

  @override
  String get todayWeightLabel => 'Kilo';

  @override
  String get todayWeightUnit => 'kg';

  @override
  String todayMissedStreakTitle(Object count) {
    return '$count gün üst üste antrenman yok';
  }

  @override
  String get todayMissedStreakBody =>
      'Kural buydu: iki günü üst üste kaçırma. Bugün kısa da olsa bir şey yap.';

  @override
  String get planEmptyTitle => 'Henüz plan yok';

  @override
  String get planEmptyBody =>
      'Yukarıdaki \"Yeni plan iste\" düğmesiyle bağlam dosyanı üret, bir yapay zekâya ver, dönen JSON belgesini \"İçeri al\" ile buraya aktar.';

  @override
  String get planLoadSample => 'Örnek planı yükle (geliştirme)';

  @override
  String get planShareSubject => 'di@sport — plan isteği';

  @override
  String get planRequestButton => 'Yeni plan iste';

  @override
  String get planImportButton => 'İçeri al';

  @override
  String planDayCount(Object count) {
    return '$count gün';
  }

  @override
  String planWeekLabel(Object week) {
    return 'Hafta $week';
  }

  @override
  String get planLegendDone => 'Tamamlandı';

  @override
  String get planLegendPartial => 'Kısmen';

  @override
  String get planLegendFree => 'Serbest';

  @override
  String get planLegendWorkout => 'Antrenman ▲';

  @override
  String get planGoalDaily => 'Günlük';

  @override
  String get planGoalProtein => 'Protein';

  @override
  String get planGoalWater => 'Su';

  @override
  String get planGoalTarget => 'Hedef';

  @override
  String get planNutritionRules => 'Beslenme kuralları';

  @override
  String get planRulesForbidden => 'Kesinlikle yok';

  @override
  String get planRulesFree => 'Serbest';

  @override
  String get planWeekdayInitials => 'P,S,Ç,P,C,C,P';

  @override
  String get planMonthNames =>
      'Ocak,Şubat,Mart,Nisan,Mayıs,Haziran,Temmuz,Ağustos,Eylül,Ekim,Kasım,Aralık';

  @override
  String get planCellToday => 'bugün';

  @override
  String get planCellDone => 'tamamlandı';

  @override
  String get planCellEmpty => 'kayıt yok';

  @override
  String get planCellFuture => 'henüz gelmedi';

  @override
  String get planCellFreeSpoken => 'serbest gün';

  @override
  String get reminderSlotFallbackTitle => 'Programda bir adım';

  @override
  String get reminderSlotWorkoutBody => 'Antrenman vakti. Hazırsan başlayalım.';

  @override
  String get reminderSlotOtherBody => 'Programdaki sıradaki adım.';

  @override
  String get reminderWeighInTitle => 'Sabah tartısı';

  @override
  String get reminderWeighInBody => 'Aç karnına, aynı koşullarda tartıl.';

  @override
  String get reminderMissStreakTitle => 'Zincir kopuyor';

  @override
  String get reminderMissStreakBody =>
      'Antrenmanı iki gün üst üste kaçırdın. Bugün kısa bir şey yapmak, hiç yapmamaktan iyi.';

  @override
  String get reminderDueLabTitle => 'Tahlil zamanı';

  @override
  String reminderDueLabBody(Object marker) {
    return '$marker tahlilinin vakti geldi.';
  }

  @override
  String get reminderPlanEndingTitle => 'Plan bitiyor';

  @override
  String get reminderPlanEndingToday =>
      'Plan bugün bitiyor. Yeni plan için bağlam dosyasını al.';

  @override
  String reminderPlanEndingIn(Object days) {
    return 'Plan $days gün sonra bitiyor. Yeni planı hazırlamanın vakti.';
  }

  @override
  String get supplementsTitle => 'Takviye ve ilaçlar';

  @override
  String get supplementsDescription =>
      'Vitamin, takviye, ilaç — saatini gir, Bugün ekranında işaretle.';

  @override
  String get supplementsOpen => 'Takviye listesi';

  @override
  String get supplementsEmptyTitle => 'Takviye eklenmemiş';

  @override
  String get supplementsEmptyDescription =>
      'Vitamin, ilaç, ne alıyorsan ekle. Saatini girersen hatırlatma da kurulur.';

  @override
  String get supplementAddFab => 'Takviye';

  @override
  String get supplementAddTitle => 'Takviye ekle';

  @override
  String get supplementEditTitle => 'Takviyeyi düzenle';

  @override
  String get supplementNameLabel => 'Ad';

  @override
  String get supplementNameHint => 'D Vitamini';

  @override
  String get supplementNameRequired => 'Ad gerekli';

  @override
  String get supplementDoseLabel => 'Doz';

  @override
  String get supplementDoseHint => '1000';

  @override
  String get supplementUnitLabel => 'Birim';

  @override
  String get supplementUnitHint => 'IU';

  @override
  String get supplementNoteLabel => 'Not';

  @override
  String get supplementNoteHint => 'Yemekle birlikte';

  @override
  String get supplementTimesSection => 'Saatler';

  @override
  String get supplementTimesEmpty => 'Saat eklenmedi — hatırlatma kurulmaz.';

  @override
  String get supplementAddTime => 'Saat ekle';

  @override
  String get supplementDaysSection => 'Günler';

  @override
  String get supplementEveryDay => 'Her gün';

  @override
  String supplementDeleteTitle(Object name) {
    return '\"$name\" silinsin mi?';
  }

  @override
  String get supplementDeleteBody =>
      'Listeden ve hatırlatmalardan kalkar. Geçmiş kayıtların durur — hiçbir şey kaybolmaz.';

  @override
  String get reminderSupplementBody => 'Alma vakti geldi.';

  @override
  String reminderSupplementBodyWithDose(Object dose) {
    return '$dose — alma vakti geldi.';
  }

  @override
  String get equipmentBodyOnly => 'Vücut ağırlığı';

  @override
  String get equipmentBarbell => 'Halter';

  @override
  String get equipmentDumbbell => 'Dambıl';

  @override
  String get equipmentKettlebell => 'Kettlebell';

  @override
  String get equipmentCable => 'Kablo makinesi';

  @override
  String get equipmentMachine => 'Makine';

  @override
  String get equipmentBands => 'Direnç bandı';

  @override
  String get equipmentMedicineBall => 'Sağlık topu';

  @override
  String get equipmentExerciseBall => 'Pilates topu';

  @override
  String get equipmentFoamRoll => 'Köpük rulo';

  @override
  String get equipmentEzCurlBar => 'Z bar';

  @override
  String get equipmentOther => 'Ev eşyası';

  @override
  String get equipmentNone => 'Ekipman gerekmiyor';

  @override
  String get equipmentPullUpBar => 'Barfiks demiri';

  @override
  String get equipmentDipBars => 'Paralel bar';

  @override
  String get equipmentBench => 'Sehpa';

  @override
  String get equipmentJumpRope => 'Atlama ipi';

  @override
  String catalogEquipmentMissingHome(Object equipment) {
    return '$equipment gerekiyor (evinde yok)';
  }

  @override
  String catalogEquipmentMissingGym(Object equipment) {
    return '$equipment gerekiyor (salonunda yok)';
  }

  @override
  String get foodSearchHint => 'Besin ara';

  @override
  String get foodSearchEmptyTitle => 'Bulunamadı';

  @override
  String get foodSearchEmptyMessage =>
      'Daha kısa bir sözcük dene ya da diğer dilde ara.';

  @override
  String get foodStartTitle => 'Henüz kayıt yok';

  @override
  String get foodStartMessage => 'Bir besin ara ya da yukarıdan tür seç.';

  @override
  String get foodFrequentTitle => 'Sık yediklerin';

  @override
  String get foodCopyLastMeal => 'Bu öğünü son seferkinden kopyala';

  @override
  String foodCopyDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kalem kopyalandı',
      one: '1 kalem kopyalandı',
    );
    return '$_temp0';
  }

  @override
  String get foodCopyNothingToCopy => 'Bu öğünde daha önce kayıt yok';

  @override
  String foodPer100g(int kcal) {
    return '100 g\'da $kcal kcal';
  }

  @override
  String foodPerPortion(String portion, int kcal) {
    return '$portion — $kcal kcal';
  }

  @override
  String get foodCategoryYemek => 'Yemek';

  @override
  String get foodCategoryCorba => 'Çorba';

  @override
  String get foodCategoryKahvaltilik => 'Kahvaltılık';

  @override
  String get foodCategoryMeyve => 'Meyve';

  @override
  String get foodCategorySebze => 'Sebze';

  @override
  String get foodCategoryKuruyemis => 'Kuruyemiş';

  @override
  String get foodCategoryIcecek => 'İçecek';

  @override
  String get foodCategoryTahil => 'Tahıl';

  @override
  String get foodCategoryEtBalik => 'Et ve balık';

  @override
  String get foodCategorySutUrunu => 'Süt ürünü';

  @override
  String get foodCategoryAtistirmalik => 'Atıştırmalık';

  @override
  String get foodCategoryDiger => 'Diğer';

  @override
  String get mealKahvalti => 'Kahvaltı';

  @override
  String get mealAraOgun => 'Kuşluk';

  @override
  String get mealOgle => 'Öğle';

  @override
  String get mealIkindi => 'İkindi';

  @override
  String get mealAksam => 'Akşam';

  @override
  String get mealGece => 'Gece';

  @override
  String get portionUnitGrams100 => '100 g';

  @override
  String get portionCustomGramsLabel => 'Tarttın mı?';

  @override
  String get portionCustomGramsHelper =>
      'Gram girersen porsiyonun yerine geçer';

  @override
  String get portionGrams => 'MİKTAR';

  @override
  String get portionKcal => 'KALORİ';

  @override
  String get portionProtein => 'PROTEİN';

  @override
  String get portionAddToMeal => 'Öğüne ekle';

  @override
  String get portionDecrease => 'Bir azalt';

  @override
  String get portionIncrease => 'Bir artır';

  @override
  String get activityLogTitle => 'Aktivite ekle';

  @override
  String get activitySearchHint => 'Aktivite ara';

  @override
  String get activityMinutesLabel => 'Dakika';

  @override
  String get activityAdd => 'Ekle';

  @override
  String get activityEmptyTitle => 'Eşleşen aktivite yok';

  @override
  String get activityEmptyMessage =>
      'Başka bir sözcük dene ya da aşağıdan kendin ekle.';

  @override
  String get effortLight => 'Hafif';

  @override
  String get effortModerate => 'Orta';

  @override
  String get effortVigorous => 'Zorlu';

  @override
  String get todayMealsTitle => 'Öğünler';

  @override
  String get todayActivitiesTitle => 'Hareket';

  @override
  String get todayAddMeal => 'Öğün ekle';

  @override
  String get todayAddActivity => 'Aktivite ekle';

  @override
  String get dayHeroRemainingPast => 'O GÜN KALAN';

  @override
  String get dayHeroEatenPast => 'O GÜN YENEN';

  @override
  String get todayHeroRemaining => 'BUGÜN KALAN';

  @override
  String get todayHeroEatenNoPlan => 'BUGÜN YENEN';

  @override
  String get todayMetricWater => 'SU';

  @override
  String get todayMetricMeds => 'İLAÇ';

  @override
  String get todayMetricProtein => 'PROTEİN';

  @override
  String get todayMetricBurned => 'YAKILAN';

  @override
  String get mealEntryRemoved => 'Kaldırıldı';

  @override
  String get progressCaloriesTitle => 'Bu haftanın kalorisi';

  @override
  String get progressCaloriesGoalLine => 'Hedef';

  @override
  String progressDayBreakdown(String date) {
    return '$date dökümü';
  }

  @override
  String get catalogTabOutside => 'Dışarıda';

  @override
  String get dayBadgePast => 'GEÇMİŞ GÜN';

  @override
  String get dayBadgeFuture => 'PLANLANAN GÜN';

  @override
  String get dayBackToToday => 'Bugüne dön';

  @override
  String get dayPrevious => 'Önceki gün';

  @override
  String get dayNext => 'Sonraki gün';

  @override
  String get dayPickDate => 'Tarih seç';

  @override
  String get dayFutureNoEntry =>
      'Planı görebilirsin ama kayıt günü gelince girilir.';

  @override
  String get planSettingsTitle => 'Plan ayarları';

  @override
  String get planSettingsName => 'Plan adı';

  @override
  String get planSettingsNameRequired => 'Plana bir ad ver';

  @override
  String get planSettingsGoals => 'Hedefler';

  @override
  String get planGoalKcal => 'Günlük kalori';

  @override
  String get planGoalWeeklyGym => 'Haftada salon günü';

  @override
  String get planGoalWeeklyHome => 'Haftada ev günü';

  @override
  String get planGoalTargetLoss => 'Hedef kayıp (kg)';

  @override
  String planGoalRange(String min, String max) {
    return '$min ile $max arasında bir değer gir';
  }

  @override
  String get planRuleAdd => 'Satır ekle';

  @override
  String get commonRemove => 'Kaldır';

  @override
  String get commonAdd => 'Ekle';

  @override
  String get planEditDay => 'Günü düzenle';

  @override
  String get planDayType => 'Gün tipi';

  @override
  String get planDayTypeGym => 'Salon';

  @override
  String get planDayTypeHome => 'Ev';

  @override
  String get planDayTypeRest => 'Dinlenme';

  @override
  String get planDayHeadline => 'Başlık';

  @override
  String get planDayDinner => 'Akşam önerisi';

  @override
  String get planSlotNew => 'Yeni slot';

  @override
  String get planSlotEdit => 'Slotu düzenle';

  @override
  String get planSlotTime => 'Saat';

  @override
  String get planSlotKind => 'Tür';

  @override
  String get planSlotLabel => 'Etiket';

  @override
  String get planSlotNote => 'Not';

  @override
  String get planSlotMealKind => 'Hangi öğün';

  @override
  String get planSlotMealKindRequired => 'Hangi öğün olduğunu seç';

  @override
  String get planSlotLabelRequired => 'Slota bir etiket ver';

  @override
  String get planExerciseNew => 'Hareket ekle';

  @override
  String get planExerciseEdit => 'Hareketi düzenle';

  @override
  String get planExercisePick => 'Katalogdan seç';

  @override
  String get planExerciseSets => 'Set';

  @override
  String get planExerciseReps => 'Tekrar';

  @override
  String get planExerciseDuration => 'Süre (dk)';

  @override
  String get planExerciseRest => 'Dinlenme (sn)';

  @override
  String get planExerciseSpeed => 'Hız (km/sa)';

  @override
  String get planExerciseGrade => 'Eğim (%)';

  @override
  String get planExerciseEffort => 'Efor';

  @override
  String get planExerciseRequired => 'Önce bir hareket seç';

  @override
  String get planOriginAiEdited => 'AI planı · düzenlendi';

  @override
  String get planOriginManual => 'Elle kuruldu';

  @override
  String get planCreateEmpty => 'Boş plan kur';

  @override
  String get planCreateTitle => 'Yeni plan';

  @override
  String get planCreateWeeks => 'Hafta';

  @override
  String get planCreateStart => 'Başlangıç tarihi';

  @override
  String get planCreateDone => 'Kur';

  @override
  String get dailyRhythmTitle => 'Günlük Düzen';

  @override
  String get dailyRhythmDescription =>
      'Ne zaman kalkıyorsun, ne zaman yatıyorsun, ne zaman ulaşılamıyorsun.';

  @override
  String get dailyRhythmWake => 'Kalkış';

  @override
  String get dailyRhythmSleep => 'Uyku';

  @override
  String get slotKindMeal => 'Öğün';

  @override
  String get slotKindWorkout => 'Antrenman';

  @override
  String get slotKindSleep => 'Uyku';

  @override
  String get slotKindMeasurement => 'Ölçüm';

  @override
  String get slotKindLab => 'Tahlil';

  @override
  String get slotKindOther => 'Diğer';

  @override
  String get tabHome => 'Ana Sayfa';

  @override
  String get tabDiet => 'Diyet';

  @override
  String get tabSport => 'Spor';

  @override
  String get tabMore => 'Daha';

  @override
  String get tabHomeHint => 'Günün özeti ve akışı';

  @override
  String get tabDietHint => 'Öğünler, besinler, kalori geçmişi';

  @override
  String get tabSportHint => 'Plan, antrenman, hareket kataloğu';

  @override
  String get tabMoreHint => 'Verilerin ve uygulama ayarları';

  @override
  String get dietTabDaily => 'Günlük';

  @override
  String get dietTabFoods => 'Besinler';

  @override
  String get dietTabHistory => 'Geçmiş';

  @override
  String get sportTabPlan => 'Plan';

  @override
  String get sportTabWorkout => 'Antrenman';

  @override
  String get sportTabCatalog => 'Katalog';

  @override
  String get healthTabLabs => 'Tahlil';

  @override
  String get healthTabMeasure => 'Ölçüm';

  @override
  String get healthTabMeds => 'İlaç';

  @override
  String get sportWorkoutEmptyTitle => 'Henüz seans yok';

  @override
  String get sportWorkoutEmptyMessage =>
      'Antrenmanı plandan başlat; biten seanslar burada görünür.';

  @override
  String get moreYourData => 'Planını etkileyenler';

  @override
  String get moreYourDataHint => 'AI\'a gider';

  @override
  String get moreApp => 'Uygulama';

  @override
  String get moreProfile => 'Profil';

  @override
  String get moreEquipment => 'Ekipmanların';

  @override
  String get moreRhythm => 'Günlük düzen';

  @override
  String get moreRules => 'Günlük kurallar';

  @override
  String get moreNotifications => 'Bildirimler';

  @override
  String get moreAppearance => 'Görünüm ve dil';

  @override
  String get moreBackup => 'Yedekleme';

  @override
  String get todayStepsLabel => 'Adım';

  @override
  String get todayStepsUnit => 'adım';

  @override
  String get dietMealSkippedAction => 'Atlandı';

  @override
  String dietMealSkippedLabel(Object reason) {
    return 'Atlandı: $reason';
  }

  @override
  String get dietSkipUndo => 'Atlamayı geri al';

  @override
  String get dietSkipSheetTitle => 'Neden atlandı?';

  @override
  String get dietSkipReasonWork => 'Mesai';

  @override
  String get dietSkipReasonAppetite => 'İştahsızlık';

  @override
  String get dietSkipReasonOut => 'Dışarıdaydım';

  @override
  String get dietSkipReasonOther => 'Diğer';

  @override
  String get dietSkipReasonHint => 'kısa neden';

  @override
  String get moodBlockTitle => 'Bugün nasıl hissettin?';

  @override
  String get moodLevel1 => 'Çok kötü';

  @override
  String get moodLevel2 => 'Kötü';

  @override
  String get moodLevel3 => 'İdaresi';

  @override
  String get moodLevel4 => 'İyi';

  @override
  String get moodLevel5 => 'Çok iyi';

  @override
  String get moodSymptomsLabel => 'Belirti';

  @override
  String get moodSymptomsHint => 'baş ağrısı, halsizlik';

  @override
  String get moodStressedLabel => 'Yoğun/stresli gündü';

  @override
  String get sleepBlockTitle => 'Uyku';

  @override
  String get sleepBedLabel => 'Yatış';

  @override
  String get sleepWakeLabel => 'Kalkış';

  @override
  String get sleepNapLabel => 'Kestirme';

  @override
  String get sleepNapUnit => 'dk';

  @override
  String get sleepHoursOnlyLabel => 'Yalnız süre';

  @override
  String get sleepHoursUnit => 'sa';

  @override
  String sleepTotal(Object hours, Object minutes) {
    return '$hours sa $minutes dk uyku';
  }

  @override
  String get sleepPickTime => 'Saat seç';

  @override
  String get sleepClear => 'Saatleri temizle';

  @override
  String get dayFlowEnterMeal => '+ GİR';

  @override
  String get dayFlowTitle => 'Günün akışı';

  @override
  String get dayFlowWeighIn => 'Tartı';

  @override
  String get dayFlowCollapse => 'Daha az göster';

  @override
  String dayFlowExpand(int count) {
    return 'Günün tamamı ($count)';
  }

  @override
  String get equipmentChair => 'Sandalye';

  @override
  String get equipmentStep => 'Basamak / merdiven';
}
