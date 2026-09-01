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
  String get tabPlan => 'Plan';

  @override
  String get tabProgress => 'İlerleme';

  @override
  String get tabHealth => 'Sağlık';

  @override
  String get tabCatalog => 'Katalog';

  @override
  String get tabTodayHint => 'Günün programı ve kayıtları';

  @override
  String get tabPlanHint => 'Dört haftalık program';

  @override
  String get tabProgressHint => 'Kilo trendi ve haftalık özet';

  @override
  String get tabHealthHint => 'Tahliller ve ölçümler';

  @override
  String get tabCatalogHint => 'Egzersiz kütüphanesi';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsTooltip => 'Profil ve yaşam tarzı';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonEdit => 'Düzenle';

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
  String get catalogEquipmentEmptyTitle => 'Ekipman listesi boş';

  @override
  String get catalogEquipmentEmptyDescription =>
      'Katalog yüklendiğinde liste kendiliğinden dolar. Aşağıdaki düğmeden elle de ekleyebilirsin.';

  @override
  String get catalogEquipmentNoneOwned =>
      'Hiç ekipman işaretlenmedi. Sadece vücut ağırlığıyla yapılan hareketler her zaman kullanılabilir.';

  @override
  String catalogEquipmentOwnedCount(Object count) {
    return '$count ekipman işaretli. Katalogda \"Ekipmanım\" filtresi bunlara göre süzüyor.';
  }

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
  String get settingsWeeklyTitle => 'Haftalık düzen';

  @override
  String get settingsWeeklyDescription =>
      'Mesain ve uygun olmadığın saatler. Yapay zekâ planı bunlara göre kurar, alarmlar yasaklı saatlerde çalmaz.';

  @override
  String get settingsWeeklyTile => 'Mesai ve uygun olmayan saatler';

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
  String get settingsOnboardingWelcome => 'Hoş geldin';

  @override
  String get settingsOnboardingIntro =>
      'Önce seni tanıyalım. Bu bilgiler cihazından çıkmaz; yalnızca sen bir yapay zekâya bağlam dosyası gönderdiğinde kullanılır.';

  @override
  String get settingsOnboardingSave => 'Kaydet ve başla';

  @override
  String get settingsProfileHeightRequired => 'Boy alanı gerekli.';

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
  String get todayTitle => 'Bugün';

  @override
  String todayWeekNumber(Object week) {
    return '$week. hafta';
  }

  @override
  String get todayHeroNoPlan => 'Plan yok · tartını yine de kaydedebilirsin';

  @override
  String get todayHeroFreeDay => 'Serbest gün';

  @override
  String todayHeroDietFree(Object type) {
    return '$type · diyet serbest';
  }

  @override
  String get todayDayTypeGym => 'Salon günü';

  @override
  String get todayDayTypeHome => 'Ev antrenmanı';

  @override
  String get todayDayTypeRest => 'Dinlenme günü';

  @override
  String get todayMetricProgram => 'Program';

  @override
  String get todayMetricRules => 'Kurallar';

  @override
  String todayNextEyebrow(Object time) {
    return 'Sırada · $time';
  }

  @override
  String todayExerciseCount(Object count) {
    return '$count hareket';
  }

  @override
  String get todaySpineLabel => 'Günün omurgası';

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
  String get todaySleepLabel => 'Uyku';

  @override
  String get todaySleepUnit => 'sa';

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
  String get planCellFree => 'boş';

  @override
  String get planCellToday => 'bugün';

  @override
  String get planCellDone => 'tamamlandı';

  @override
  String planCellPartial(Object total, Object checked) {
    return '$total işten $checked tamam';
  }

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
  String get supplementRemoveTime => 'Saati kaldır';

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
  String supplementTakenSemantics(Object name, Object time) {
    return '$name, $time, alındı';
  }

  @override
  String supplementNotTakenSemantics(Object name, Object time) {
    return '$name, $time, alınmadı';
  }

  @override
  String supplementDoseCount(Object count) {
    return '$count kalem';
  }

  @override
  String get supplementSectionLabel => 'Takviye';

  @override
  String get reminderSupplementBody => 'Alma vakti geldi.';

  @override
  String reminderSupplementBodyWithDose(Object dose) {
    return '$dose — alma vakti geldi.';
  }
}
