import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @tabToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get tabToday;

  /// No description provided for @tabProgress.
  ///
  /// In tr, this message translates to:
  /// **'İlerleme'**
  String get tabProgress;

  /// No description provided for @tabHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get tabHealth;

  /// No description provided for @tabHealthHint.
  ///
  /// In tr, this message translates to:
  /// **'Tahliller ve ölçümler'**
  String get tabHealthHint;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @commonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get commonDelete;

  /// No description provided for @commonClear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get commonClear;

  /// No description provided for @commonRetry.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dene'**
  String get commonRetry;

  /// No description provided for @appearanceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get appearanceTitle;

  /// No description provided for @appearanceDescription.
  ///
  /// In tr, this message translates to:
  /// **'Koyu tema uygulamanın asıl hâli; salonda ve sabahın köründe de okunur.'**
  String get appearanceDescription;

  /// No description provided for @appearanceSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get appearanceSystem;

  /// No description provided for @appearanceDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get appearanceDark;

  /// No description provided for @appearanceLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get appearanceLight;

  /// No description provided for @languageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get languageTitle;

  /// No description provided for @languageDescription.
  ///
  /// In tr, this message translates to:
  /// **'Arayüz dili. Hareket ve besin adları her iki dilde de aranabilir.'**
  String get languageDescription;

  /// No description provided for @languageSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @catalogTabHome.
  ///
  /// In tr, this message translates to:
  /// **'Evde'**
  String get catalogTabHome;

  /// No description provided for @catalogTabGym.
  ///
  /// In tr, this message translates to:
  /// **'Salonda'**
  String get catalogTabGym;

  /// No description provided for @catalogFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get catalogFilters;

  /// No description provided for @catalogSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Hareket veya kas ara…'**
  String get catalogSearchHint;

  /// No description provided for @catalogClearSearch.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı temizle'**
  String get catalogClearSearch;

  /// No description provided for @catalogClearFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri temizle'**
  String get catalogClearFilters;

  /// No description provided for @catalogRecentSection.
  ///
  /// In tr, this message translates to:
  /// **'Son yaptıkların'**
  String get catalogRecentSection;

  /// No description provided for @catalogExercisesSection.
  ///
  /// In tr, this message translates to:
  /// **'Hareketler'**
  String get catalogExercisesSection;

  /// No description provided for @catalogAllExercisesSection.
  ///
  /// In tr, this message translates to:
  /// **'Tüm hareketler'**
  String get catalogAllExercisesSection;

  /// No description provided for @catalogNoResults.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşen hareket yok'**
  String get catalogNoResults;

  /// No description provided for @catalogNoResultsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı değiştir ya da filtreleri kaldır.'**
  String get catalogNoResultsDescription;

  /// No description provided for @catalogOnlyMyEquipment.
  ///
  /// In tr, this message translates to:
  /// **'Ekipmanıma uygun'**
  String get catalogOnlyMyEquipment;

  /// No description provided for @catalogOnlyMyEquipmentDescription.
  ///
  /// In tr, this message translates to:
  /// **'Envanterinde olmayan ekipman isteyenleri gizler.'**
  String get catalogOnlyMyEquipmentDescription;

  /// No description provided for @catalogCategorySection.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get catalogCategorySection;

  /// No description provided for @catalogCategoryStrength.
  ///
  /// In tr, this message translates to:
  /// **'Kuvvet'**
  String get catalogCategoryStrength;

  /// No description provided for @catalogCategoryCore.
  ///
  /// In tr, this message translates to:
  /// **'Gövde'**
  String get catalogCategoryCore;

  /// No description provided for @catalogCategoryCardio.
  ///
  /// In tr, this message translates to:
  /// **'Kardiyo'**
  String get catalogCategoryCardio;

  /// No description provided for @catalogCategoryMobility.
  ///
  /// In tr, this message translates to:
  /// **'Hareketlilik'**
  String get catalogCategoryMobility;

  /// No description provided for @catalogDifficultySection.
  ///
  /// In tr, this message translates to:
  /// **'Zorluk'**
  String get catalogDifficultySection;

  /// No description provided for @catalogDifficultyChip.
  ///
  /// In tr, this message translates to:
  /// **'Zorluk {level}'**
  String catalogDifficultyChip(Object level);

  /// No description provided for @catalogDifficultyOutOfFive.
  ///
  /// In tr, this message translates to:
  /// **'Zorluk {level}/5'**
  String catalogDifficultyOutOfFive(Object level);

  /// No description provided for @catalogDifficultySemantics.
  ///
  /// In tr, this message translates to:
  /// **'Zorluk {level} / 5'**
  String catalogDifficultySemantics(Object level);

  /// No description provided for @catalogResultCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} hareket'**
  String catalogResultCount(Object count);

  /// No description provided for @catalogLocationHome.
  ///
  /// In tr, this message translates to:
  /// **'Ev'**
  String get catalogLocationHome;

  /// No description provided for @catalogLocationGym.
  ///
  /// In tr, this message translates to:
  /// **'Salon'**
  String get catalogLocationGym;

  /// No description provided for @catalogLocationBoth.
  ///
  /// In tr, this message translates to:
  /// **'Ev / Salon'**
  String get catalogLocationBoth;

  /// No description provided for @catalogLocationSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Yapılabildiği yer: {place}'**
  String catalogLocationSemantics(Object place);

  /// No description provided for @catalogEquipmentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekipmanım'**
  String get catalogEquipmentTitle;

  /// No description provided for @catalogEquipmentAddFab.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman'**
  String get catalogEquipmentAddFab;

  /// No description provided for @catalogEquipmentAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman ekle'**
  String get catalogEquipmentAddTitle;

  /// No description provided for @catalogEquipmentFieldLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman'**
  String get catalogEquipmentFieldLabel;

  /// No description provided for @catalogEquipmentFieldHint.
  ///
  /// In tr, this message translates to:
  /// **'Kettlebell'**
  String get catalogEquipmentFieldHint;

  /// No description provided for @catalogEquipmentAddAction.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get catalogEquipmentAddAction;

  /// No description provided for @catalogExerciseNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Hareket bulunamadı'**
  String get catalogExerciseNotFound;

  /// No description provided for @catalogExerciseNotFoundDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu hareket katalogdan kaldırılmış olabilir.'**
  String get catalogExerciseNotFoundDescription;

  /// No description provided for @catalogExerciseLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Hareket açılamadı'**
  String get catalogExerciseLoadError;

  /// No description provided for @catalogTabSteps.
  ///
  /// In tr, this message translates to:
  /// **'Adımlar'**
  String get catalogTabSteps;

  /// No description provided for @catalogTabMistakes.
  ///
  /// In tr, this message translates to:
  /// **'Hatalar'**
  String get catalogTabMistakes;

  /// No description provided for @catalogTabVariants.
  ///
  /// In tr, this message translates to:
  /// **'Varyantlar'**
  String get catalogTabVariants;

  /// No description provided for @catalogTabSafety.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get catalogTabSafety;

  /// No description provided for @catalogCuesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aklında tut'**
  String get catalogCuesTitle;

  /// No description provided for @catalogCuesDescription.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman sırasında bunlara bak.'**
  String get catalogCuesDescription;

  /// No description provided for @catalogSetupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get catalogSetupTitle;

  /// No description provided for @catalogExecutionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hareket'**
  String get catalogExecutionTitle;

  /// No description provided for @catalogBreathingTempoTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nefes ve tempo'**
  String get catalogBreathingTempoTitle;

  /// No description provided for @catalogBreathingLabel.
  ///
  /// In tr, this message translates to:
  /// **'Nefes'**
  String get catalogBreathingLabel;

  /// No description provided for @catalogTempoLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tempo'**
  String get catalogTempoLabel;

  /// No description provided for @catalogNoMistakes.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı hata yok'**
  String get catalogNoMistakes;

  /// No description provided for @catalogMistakeWhy.
  ///
  /// In tr, this message translates to:
  /// **'Neden sorun'**
  String get catalogMistakeWhy;

  /// No description provided for @catalogMistakeFix.
  ///
  /// In tr, this message translates to:
  /// **'Düzeltmesi'**
  String get catalogMistakeFix;

  /// No description provided for @catalogNoVariants.
  ///
  /// In tr, this message translates to:
  /// **'Varyant tanımlı değil'**
  String get catalogNoVariants;

  /// No description provided for @catalogNoVariantsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu hareketin kolay ya da zor bir sürümü kayıtlı değil.'**
  String get catalogNoVariantsDescription;

  /// No description provided for @catalogRegressionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kolaylaştır'**
  String get catalogRegressionsTitle;

  /// No description provided for @catalogRegressionsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Zorlanıyorsan buradan başla.'**
  String get catalogRegressionsDescription;

  /// No description provided for @catalogProgressionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zorlaştır'**
  String get catalogProgressionsTitle;

  /// No description provided for @catalogProgressionsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kolay gelmeye başladığında sıradaki basamak.'**
  String get catalogProgressionsDescription;

  /// No description provided for @catalogSafetyDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgiler genel niteliktedir ve hekim ya da fizyoterapist değerlendirmesinin yerine geçmez. Ağrı hissettiğinde hareketi bırak.'**
  String get catalogSafetyDisclaimer;

  /// No description provided for @catalogImageSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{name} hareketinin başlangıç ve bitiş pozisyonu'**
  String catalogImageSemantics(Object name);

  /// No description provided for @catalogMetaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Künye'**
  String get catalogMetaTitle;

  /// No description provided for @catalogTargetMuscles.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kaslar'**
  String get catalogTargetMuscles;

  /// No description provided for @catalogEquipmentLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman'**
  String get catalogEquipmentLabel;

  /// No description provided for @workoutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman'**
  String get workoutTitle;

  /// No description provided for @workoutNoExercisesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün hareket yok'**
  String get workoutNoExercisesTitle;

  /// No description provided for @workoutNoExercisesDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu gün dinlenme günü olarak planlanmış.'**
  String get workoutNoExercisesDescription;

  /// No description provided for @workoutElapsedCaption.
  ///
  /// In tr, this message translates to:
  /// **'dakikadır çalışıyorsun'**
  String get workoutElapsedCaption;

  /// No description provided for @workoutElapsedNew.
  ///
  /// In tr, this message translates to:
  /// **'yeni'**
  String get workoutElapsedNew;

  /// No description provided for @workoutMinuteUnit.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get workoutMinuteUnit;

  /// No description provided for @workoutSetsCaption.
  ///
  /// In tr, this message translates to:
  /// **'Set'**
  String get workoutSetsCaption;

  /// No description provided for @workoutExercisesCaption.
  ///
  /// In tr, this message translates to:
  /// **'Hareket'**
  String get workoutExercisesCaption;

  /// No description provided for @workoutSetsProgress.
  ///
  /// In tr, this message translates to:
  /// **'{done} / {total} set'**
  String workoutSetsProgress(Object done, Object total);

  /// No description provided for @workoutSetsDoneSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{done} / {total} set tamamlandı'**
  String workoutSetsDoneSemantics(Object done, Object total);

  /// No description provided for @workoutUndoLastSet.
  ///
  /// In tr, this message translates to:
  /// **'Son seti geri al'**
  String get workoutUndoLastSet;

  /// No description provided for @workoutAllSetsDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get workoutAllSetsDone;

  /// No description provided for @workoutSetDone.
  ///
  /// In tr, this message translates to:
  /// **'Set tamam'**
  String get workoutSetDone;

  /// No description provided for @workoutRefLast.
  ///
  /// In tr, this message translates to:
  /// **'Geçen'**
  String get workoutRefLast;

  /// No description provided for @workoutRefPlan.
  ///
  /// In tr, this message translates to:
  /// **'Plan'**
  String get workoutRefPlan;

  /// No description provided for @workoutRestLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme · {seconds} sn'**
  String workoutRestLabel(Object seconds);

  /// No description provided for @workoutRestSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme, {seconds} saniye kaldı'**
  String workoutRestSemantics(Object seconds);

  /// No description provided for @workoutRestSkip.
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get workoutRestSkip;

  /// No description provided for @healthNoLabsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil kaydı yok'**
  String get healthNoLabsTitle;

  /// No description provided for @healthNoLabsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Elindeki tahlil sonuçlarını ekle; referans aralığını da girersen değerin düşük mü yüksek mi olduğunu takip edebilirim.'**
  String get healthNoLabsDescription;

  /// No description provided for @healthAddLabFab.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil'**
  String get healthAddLabFab;

  /// No description provided for @healthAddLabTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil ekle'**
  String get healthAddLabTitle;

  /// No description provided for @healthLabMarkerLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil adı'**
  String get healthLabMarkerLabel;

  /// No description provided for @healthLabMarkerHint.
  ///
  /// In tr, this message translates to:
  /// **'Vitamin D'**
  String get healthLabMarkerHint;

  /// No description provided for @healthLabMarkerRequired.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil adı gerekli'**
  String get healthLabMarkerRequired;

  /// No description provided for @healthLabValueLabel.
  ///
  /// In tr, this message translates to:
  /// **'Değer'**
  String get healthLabValueLabel;

  /// No description provided for @healthLabValueInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Sayı girin'**
  String get healthLabValueInvalid;

  /// No description provided for @healthLabUnitLabel.
  ///
  /// In tr, this message translates to:
  /// **'Birim'**
  String get healthLabUnitLabel;

  /// No description provided for @healthLabUnitHint.
  ///
  /// In tr, this message translates to:
  /// **'ng/mL'**
  String get healthLabUnitHint;

  /// No description provided for @healthLabRefLowLabel.
  ///
  /// In tr, this message translates to:
  /// **'Referans alt'**
  String get healthLabRefLowLabel;

  /// No description provided for @healthLabRefHighLabel.
  ///
  /// In tr, this message translates to:
  /// **'Referans üst'**
  String get healthLabRefHighLabel;

  /// No description provided for @healthLabRefHelp.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı — girmezsen değer \"aralık yok\" olarak gösterilir.'**
  String get healthLabRefHelp;

  /// No description provided for @healthLabPanelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Panel'**
  String get healthLabPanelLabel;

  /// No description provided for @healthLabNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Laboratuvar'**
  String get healthLabNameLabel;

  /// No description provided for @healthLabNameHelp.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı — aralıklar laboratuvara göre değişir'**
  String get healthLabNameHelp;

  /// No description provided for @healthLabDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil tarihi'**
  String get healthLabDateLabel;

  /// No description provided for @healthMeasurementsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçümler'**
  String get healthMeasurementsTitle;

  /// No description provided for @healthMeasurementsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ayda bir ölç; geçiş kriteri şınav sayısına bakıyor.'**
  String get healthMeasurementsDescription;

  /// No description provided for @healthManageMetricsTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Ölçümleri düzenle'**
  String get healthManageMetricsTooltip;

  /// No description provided for @healthNoMetricsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm türü yok'**
  String get healthNoMetricsTitle;

  /// No description provided for @healthNoMetricsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Takip etmek istediğin ölçüleri ekle — bel, kol çevresi, istirahat nabzı.'**
  String get healthNoMetricsDescription;

  /// No description provided for @healthMetricNeverMeasured.
  ///
  /// In tr, this message translates to:
  /// **'henüz ölçülmedi'**
  String get healthMetricNeverMeasured;

  /// No description provided for @healthDueLabsTitleOne.
  ///
  /// In tr, this message translates to:
  /// **'Bir tahlilin vakti geldi'**
  String get healthDueLabsTitleOne;

  /// No description provided for @healthDueLabsTitleMany.
  ///
  /// In tr, this message translates to:
  /// **'{count} tahlilin vakti geldi'**
  String healthDueLabsTitleMany(Object count);

  /// No description provided for @healthDueInterval.
  ///
  /// In tr, this message translates to:
  /// **'{months} ayda bir'**
  String healthDueInterval(Object months);

  /// No description provided for @healthDueWithDate.
  ///
  /// In tr, this message translates to:
  /// **'{marker} — {interval}, {date} itibarıyla'**
  String healthDueWithDate(Object marker, Object interval, Object date);

  /// No description provided for @healthDueNoRecord.
  ///
  /// In tr, this message translates to:
  /// **'{marker} — {interval}, henüz hiç kaydedilmemiş'**
  String healthDueNoRecord(Object marker, Object interval);

  /// No description provided for @healthLabRefRange.
  ///
  /// In tr, this message translates to:
  /// **'ref {low}–{high}'**
  String healthLabRefRange(Object low, Object high);

  /// No description provided for @healthLabStatusLow.
  ///
  /// In tr, this message translates to:
  /// **'düşük'**
  String get healthLabStatusLow;

  /// No description provided for @healthLabStatusHigh.
  ///
  /// In tr, this message translates to:
  /// **'yüksek'**
  String get healthLabStatusHigh;

  /// No description provided for @healthLabStatusNormal.
  ///
  /// In tr, this message translates to:
  /// **'normal'**
  String get healthLabStatusNormal;

  /// No description provided for @healthLabStatusNoRange.
  ///
  /// In tr, this message translates to:
  /// **'aralık yok'**
  String get healthLabStatusNoRange;

  /// No description provided for @healthMetricsEditorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm türleri'**
  String get healthMetricsEditorTitle;

  /// No description provided for @healthMetricsEditorEmptyDescription.
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki düğmeden ilk ölçümünü ekle.'**
  String get healthMetricsEditorEmptyDescription;

  /// No description provided for @healthAddMetricFab.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm'**
  String get healthAddMetricFab;

  /// No description provided for @healthDeleteMetricTitle.
  ///
  /// In tr, this message translates to:
  /// **'\"{label}\" kaldırılsın mı?'**
  String healthDeleteMetricTitle(Object label);

  /// No description provided for @healthDeleteMetricBody.
  ///
  /// In tr, this message translates to:
  /// **'Listeden çıkar. Şimdiye kadar girdiğin değerler silinmez; türü geri eklersen yeniden görünür.'**
  String get healthDeleteMetricBody;

  /// No description provided for @healthMetricRemove.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get healthMetricRemove;

  /// No description provided for @healthMetricDailyHint.
  ///
  /// In tr, this message translates to:
  /// **'{unit} · her gün Bugün ekranından'**
  String healthMetricDailyHint(Object unit);

  /// No description provided for @healthMetricSheetAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm ekle'**
  String get healthMetricSheetAddTitle;

  /// No description provided for @healthMetricSheetEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçümü düzenle'**
  String get healthMetricSheetEditTitle;

  /// No description provided for @healthMetricLabelRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm adı gerekli'**
  String get healthMetricLabelRequired;

  /// No description provided for @healthMetricLabelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm'**
  String get healthMetricLabelLabel;

  /// No description provided for @healthMetricLabelHint.
  ///
  /// In tr, this message translates to:
  /// **'Kol çevresi'**
  String get healthMetricLabelHint;

  /// No description provided for @healthMetricUnitHint.
  ///
  /// In tr, this message translates to:
  /// **'cm'**
  String get healthMetricUnitHint;

  /// No description provided for @healthMetricDisplayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gösterim'**
  String get healthMetricDisplayTitle;

  /// No description provided for @healthMetricInteger.
  ///
  /// In tr, this message translates to:
  /// **'Tam sayı'**
  String get healthMetricInteger;

  /// No description provided for @healthMetricDecimal.
  ///
  /// In tr, this message translates to:
  /// **'Ondalıklı'**
  String get healthMetricDecimal;

  /// No description provided for @healthMetricExampleInteger.
  ///
  /// In tr, this message translates to:
  /// **'Örnek: 12'**
  String get healthMetricExampleInteger;

  /// No description provided for @healthMetricExampleDecimal.
  ///
  /// In tr, this message translates to:
  /// **'Örnek: 104,5'**
  String get healthMetricExampleDecimal;

  /// No description provided for @progressEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz gösterecek bir şey yok'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptyDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bugün sekmesinden tartını gir; birkaç gün sonra eğilim çizgisi anlamlı olmaya başlar.'**
  String get progressEmptyDescription;

  /// No description provided for @progressWeightTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get progressWeightTitle;

  /// No description provided for @progressWeightDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kalın çizgi 7 günlük ortalama — günlük oynamalar su ve tuzdur, eğilime bak.'**
  String get progressWeightDescription;

  /// No description provided for @progressWeeksTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftalar'**
  String get progressWeeksTitle;

  /// No description provided for @progressNoPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık özet için plan gerekli'**
  String get progressNoPlanTitle;

  /// No description provided for @progressNoPlanDescription.
  ///
  /// In tr, this message translates to:
  /// **'Hangi günün salon, hangisinin ev olduğunu plandan okuyorum. Plan sekmesinden bir program yükle.'**
  String get progressNoPlanDescription;

  /// No description provided for @progressHeroEmptyCaption.
  ///
  /// In tr, this message translates to:
  /// **'İlk tartıdan sonra değişim burada görünecek'**
  String get progressHeroEmptyCaption;

  /// No description provided for @progressHeroCaption.
  ///
  /// In tr, this message translates to:
  /// **'kg · ilk tartıdan bugüne'**
  String get progressHeroCaption;

  /// No description provided for @progressMetricNow.
  ///
  /// In tr, this message translates to:
  /// **'Şu an'**
  String get progressMetricNow;

  /// No description provided for @progressMetricPushups.
  ///
  /// In tr, this message translates to:
  /// **'Şınav'**
  String get progressMetricPushups;

  /// No description provided for @progressMetricWeeks.
  ///
  /// In tr, this message translates to:
  /// **'Hafta'**
  String get progressMetricWeeks;

  /// No description provided for @progressTransitionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Koşuya geçiş'**
  String get progressTransitionTitle;

  /// No description provided for @progressTransitionAllMet.
  ///
  /// In tr, this message translates to:
  /// **'Üç ölçüt de sağlandı. Kısa koşu denemelerine başlayabilirsin.'**
  String get progressTransitionAllMet;

  /// No description provided for @progressTransitionProgress.
  ///
  /// In tr, this message translates to:
  /// **'{met} / 3 ölçüt sağlandı.'**
  String progressTransitionProgress(Object met);

  /// No description provided for @progressCriterionWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo {limit} kg altında'**
  String progressCriterionWeight(Object limit);

  /// No description provided for @progressCriterionNotWeighed.
  ///
  /// In tr, this message translates to:
  /// **'henüz tartılmadı'**
  String get progressCriterionNotWeighed;

  /// No description provided for @progressCriterionWeightNow.
  ///
  /// In tr, this message translates to:
  /// **'şu an {value} kg'**
  String progressCriterionWeightNow(Object value);

  /// No description provided for @progressCriterionPushups.
  ///
  /// In tr, this message translates to:
  /// **'Kesintisiz {count} şınav'**
  String progressCriterionPushups(Object count);

  /// No description provided for @progressCriterionNotMeasured.
  ///
  /// In tr, this message translates to:
  /// **'henüz ölçülmedi'**
  String get progressCriterionNotMeasured;

  /// No description provided for @progressCriterionPushupsNow.
  ///
  /// In tr, this message translates to:
  /// **'şu an {value}'**
  String progressCriterionPushupsNow(Object value);

  /// No description provided for @progressCriterionPainFree.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüş sonrası diz/ayak ağrısı yok'**
  String get progressCriterionPainFree;

  /// No description provided for @progressCriterionPainFreeHint.
  ///
  /// In tr, this message translates to:
  /// **'Bunu ölçemem, sen bileceksin.'**
  String get progressCriterionPainFreeHint;

  /// No description provided for @progressWeekLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hafta {index}'**
  String progressWeekLabel(Object index);

  /// No description provided for @progressWeekPartial.
  ///
  /// In tr, this message translates to:
  /// **'sürüyor · {days} gün'**
  String progressWeekPartial(Object days);

  /// No description provided for @progressWeekAverage.
  ///
  /// In tr, this message translates to:
  /// **'haftalık ortalama'**
  String get progressWeekAverage;

  /// No description provided for @progressWeekGym.
  ///
  /// In tr, this message translates to:
  /// **'Salon'**
  String get progressWeekGym;

  /// No description provided for @progressWeekHome.
  ///
  /// In tr, this message translates to:
  /// **'Ev'**
  String get progressWeekHome;

  /// No description provided for @progressWeekNoSlips.
  ///
  /// In tr, this message translates to:
  /// **'Kaçak yok'**
  String get progressWeekNoSlips;

  /// No description provided for @progressWeekSlipDays.
  ///
  /// In tr, this message translates to:
  /// **'{count} kaçak gün'**
  String progressWeekSlipDays(Object count);

  /// No description provided for @progressWeekCountChip.
  ///
  /// In tr, this message translates to:
  /// **'{label} {done} / {target}'**
  String progressWeekCountChip(Object label, Object done, Object target);

  /// No description provided for @progressChartSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Kilo grafiği. {count} ölçüm. İlk {first} kilogram, son {last} kilogram.'**
  String progressChartSemantics(Object count, Object first, Object last);

  /// No description provided for @commonNoRecords.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok'**
  String get commonNoRecords;

  /// No description provided for @commonErrorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti'**
  String get commonErrorTitle;

  /// No description provided for @commonStatusGood.
  ///
  /// In tr, this message translates to:
  /// **'iyi'**
  String get commonStatusGood;

  /// No description provided for @commonStatusCaution.
  ///
  /// In tr, this message translates to:
  /// **'dikkat'**
  String get commonStatusCaution;

  /// No description provided for @commonStatusBad.
  ///
  /// In tr, this message translates to:
  /// **'sorunlu'**
  String get commonStatusBad;

  /// No description provided for @commonStatusUnknown.
  ///
  /// In tr, this message translates to:
  /// **'veri yok'**
  String get commonStatusUnknown;

  /// No description provided for @commonValueMissing.
  ///
  /// In tr, this message translates to:
  /// **'değer girilmedi'**
  String get commonValueMissing;

  /// No description provided for @commonMetricEmptySemantics.
  ///
  /// In tr, this message translates to:
  /// **'{caption}: girilmedi'**
  String commonMetricEmptySemantics(Object caption);

  /// No description provided for @commonMetricValueSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{caption}: {value}'**
  String commonMetricValueSemantics(Object caption, Object value);

  /// No description provided for @commonMetricChangeSemantics.
  ///
  /// In tr, this message translates to:
  /// **', değişim {delta}'**
  String commonMetricChangeSemantics(Object delta);

  /// No description provided for @commonHeroValueSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{value} · {caption}'**
  String commonHeroValueSemantics(Object value, Object caption);

  /// No description provided for @commonNowAt.
  ///
  /// In tr, this message translates to:
  /// **'Şu an saat {time}'**
  String commonNowAt(Object time);

  /// No description provided for @commonNowLabel.
  ///
  /// In tr, this message translates to:
  /// **'ŞİMDİ'**
  String get commonNowLabel;

  /// No description provided for @commonWeekDotDone.
  ///
  /// In tr, this message translates to:
  /// **'kayıt var'**
  String get commonWeekDotDone;

  /// No description provided for @commonWeekDotMissed.
  ///
  /// In tr, this message translates to:
  /// **'kayıt yok'**
  String get commonWeekDotMissed;

  /// No description provided for @commonWeekDotToday.
  ///
  /// In tr, this message translates to:
  /// **'bugün'**
  String get commonWeekDotToday;

  /// No description provided for @commonWeekDotFuture.
  ///
  /// In tr, this message translates to:
  /// **'gelecek'**
  String get commonWeekDotFuture;

  /// No description provided for @settingsEquipmentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekipmanım'**
  String get settingsEquipmentTitle;

  /// No description provided for @settingsEquipmentDescription.
  ///
  /// In tr, this message translates to:
  /// **'İşaretlediklerin katalog filtresini ve yapay zekâya gönderilen bağlamı besliyor.'**
  String get settingsEquipmentDescription;

  /// No description provided for @settingsEquipmentTile.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman listesi'**
  String get settingsEquipmentTile;

  /// No description provided for @settingsWeeklyFab.
  ///
  /// In tr, this message translates to:
  /// **'Saat aralığı'**
  String get settingsWeeklyFab;

  /// No description provided for @settingsWeeklyExplanationTitle.
  ///
  /// In tr, this message translates to:
  /// **'İki tür aralık var'**
  String get settingsWeeklyExplanationTitle;

  /// No description provided for @settingsWeeklyExplanationBody.
  ///
  /// In tr, this message translates to:
  /// **'· Mesai: iştesin. Yapay zekâ bu saatlere antrenman koymaz ama öğün koyabilir.\n· Uygun değil: hiçbir şey planlanmaz ve bu saatlerde bildirim çalmaz.'**
  String get settingsWeeklyExplanationBody;

  /// No description provided for @settingsWeeklyEmptyDay.
  ///
  /// In tr, this message translates to:
  /// **'boş'**
  String get settingsWeeklyEmptyDay;

  /// No description provided for @settingsWeeklyAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Saat aralığı ekle'**
  String get settingsWeeklyAddTitle;

  /// No description provided for @settingsWeeklyKindWork.
  ///
  /// In tr, this message translates to:
  /// **'Mesai'**
  String get settingsWeeklyKindWork;

  /// No description provided for @settingsWeeklyKindBlocked.
  ///
  /// In tr, this message translates to:
  /// **'Uygun değil'**
  String get settingsWeeklyKindBlocked;

  /// No description provided for @settingsWeeklyDays.
  ///
  /// In tr, this message translates to:
  /// **'Günler'**
  String get settingsWeeklyDays;

  /// No description provided for @settingsWeeklyPickDayError.
  ///
  /// In tr, this message translates to:
  /// **'En az bir gün seç'**
  String get settingsWeeklyPickDayError;

  /// No description provided for @settingsWeeklyStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get settingsWeeklyStart;

  /// No description provided for @settingsWeeklyEnd.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get settingsWeeklyEnd;

  /// No description provided for @settingsWeeklyOvernightHint.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş başlangıçtan küçükse aralık gece yarısını aşar.'**
  String get settingsWeeklyOvernightHint;

  /// No description provided for @settingsWeeklyLabel.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get settingsWeeklyLabel;

  /// No description provided for @settingsWeeklyLabelHint.
  ///
  /// In tr, this message translates to:
  /// **'Fabrika'**
  String get settingsWeeklyLabelHint;

  /// No description provided for @settingsWeeklyLabelHelper.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı'**
  String get settingsWeeklyLabelHelper;

  /// No description provided for @settingsWeeklyAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get settingsWeeklyAdd;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme'**
  String get settingsBackupTitle;

  /// No description provided for @settingsBackupDescription.
  ///
  /// In tr, this message translates to:
  /// **'Tüm veriler yalnız bu cihazda. Telefon değişirse yedek almadıysan geri dönüşü yok.'**
  String get settingsBackupDescription;

  /// No description provided for @settingsBackupExport.
  ///
  /// In tr, this message translates to:
  /// **'Yedek al'**
  String get settingsBackupExport;

  /// No description provided for @settingsBackupExportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Dosyayı paylaş menüsüyle bir yere kaydet'**
  String get settingsBackupExportSubtitle;

  /// No description provided for @settingsBackupImport.
  ///
  /// In tr, this message translates to:
  /// **'Yedekten geri yükle'**
  String get settingsBackupImport;

  /// No description provided for @settingsBackupImportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut verinin üstüne yazar'**
  String get settingsBackupImportSubtitle;

  /// No description provided for @settingsBackupShareText.
  ///
  /// In tr, this message translates to:
  /// **'di@sport yedeği'**
  String get settingsBackupShareText;

  /// No description provided for @settingsBackupRestored.
  ///
  /// In tr, this message translates to:
  /// **'Yedek yüklendi. Uygulamayı kapatıp yeniden aç — açık veritabanı bağlantısı eski veriyi göstermeye devam ediyor.'**
  String get settingsBackupRestored;

  /// No description provided for @settingsBackupConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut verinin üstüne yazılsın mı?'**
  String get settingsBackupConfirmTitle;

  /// No description provided for @settingsBackupConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Şu anki tüm kayıtların yedekteki hâlle değişecek. Değişmeden önceki hâl yine de cihazda saklanıyor.'**
  String get settingsBackupConfirmBody;

  /// No description provided for @settingsBackupConfirmAction.
  ///
  /// In tr, this message translates to:
  /// **'Üstüne yaz'**
  String get settingsBackupConfirmAction;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Sabah tartısı hatırlatması uyanma saatine bağlı; profilde uyanma saatini gir.'**
  String get settingsNotificationsDescription;

  /// No description provided for @settingsNotifWorkout.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman'**
  String get settingsNotifWorkout;

  /// No description provided for @settingsNotifWorkoutDescription.
  ///
  /// In tr, this message translates to:
  /// **'Programdaki antrenman saatinde'**
  String get settingsNotifWorkoutDescription;

  /// No description provided for @settingsNotifMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün'**
  String get settingsNotifMeal;

  /// No description provided for @settingsNotifMealDescription.
  ///
  /// In tr, this message translates to:
  /// **'Programdaki öğün saatlerinde'**
  String get settingsNotifMealDescription;

  /// No description provided for @settingsNotifWalk.
  ///
  /// In tr, this message translates to:
  /// **'Yürüyüş'**
  String get settingsNotifWalk;

  /// No description provided for @settingsNotifWalkDescription.
  ///
  /// In tr, this message translates to:
  /// **'Programdaki yürüyüş saatinde'**
  String get settingsNotifWalkDescription;

  /// No description provided for @settingsNotifSupplement.
  ///
  /// In tr, this message translates to:
  /// **'Takviye'**
  String get settingsNotifSupplement;

  /// No description provided for @settingsNotifSupplementDescription.
  ///
  /// In tr, this message translates to:
  /// **'Vitamin ve takviye saatlerinde'**
  String get settingsNotifSupplementDescription;

  /// No description provided for @settingsExactAlarmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tam zamanlı alarm izni'**
  String get settingsExactAlarmTitle;

  /// No description provided for @settingsExactAlarmGranted.
  ///
  /// In tr, this message translates to:
  /// **'Verildi — bildirimler tam saatinde çalar.'**
  String get settingsExactAlarmGranted;

  /// No description provided for @settingsExactAlarmDenied.
  ///
  /// In tr, this message translates to:
  /// **'Verilmedi. Bildirimler yine çalar ama pil tasarrufu kipinde birkaç dakika gecikebilir. Vermek için dokun.'**
  String get settingsExactAlarmDenied;

  /// No description provided for @settingsExactAlarmLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor…'**
  String get settingsExactAlarmLoading;

  /// No description provided for @settingsOnboardingIntro.
  ///
  /// In tr, this message translates to:
  /// **'Önce seni tanıyalım. Bu bilgiler cihazından çıkmaz; yalnızca sen bir yapay zekâya bağlam dosyası gönderdiğinde kullanılır.'**
  String get settingsOnboardingIntro;

  /// No description provided for @settingsOnboardingSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet ve başla'**
  String get settingsOnboardingSave;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'di@sport\'a hoş geldin'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In tr, this message translates to:
  /// **'Diyetini, sporunu, sağlık değerlerini ve ilaçlarını tek yerden takip et.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingAreaDiet.
  ///
  /// In tr, this message translates to:
  /// **'Diyet — öğünler, kalori bütçesi, su'**
  String get onboardingAreaDiet;

  /// No description provided for @onboardingAreaSport.
  ///
  /// In tr, this message translates to:
  /// **'Spor — plan, antrenman, hareket kataloğu'**
  String get onboardingAreaSport;

  /// No description provided for @onboardingAreaHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık — tahliller, ölçümler, ilerleme'**
  String get onboardingAreaHealth;

  /// No description provided for @onboardingAreaMed.
  ///
  /// In tr, this message translates to:
  /// **'İlaç ve takviye — hatırlatma ve takip'**
  String get onboardingAreaMed;

  /// No description provided for @onboardingStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get onboardingStart;

  /// No description provided for @onboardingIdentityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seni tanıyalım'**
  String get onboardingIdentityTitle;

  /// No description provided for @onboardingFirstName.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get onboardingFirstName;

  /// No description provided for @onboardingLastName.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get onboardingLastName;

  /// No description provided for @onboardingFirstNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Adını yazmadan geçemeyiz.'**
  String get onboardingFirstNameRequired;

  /// No description provided for @onboardingBirthDate.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihi'**
  String get onboardingBirthDate;

  /// No description provided for @onboardingBirthDay.
  ///
  /// In tr, this message translates to:
  /// **'Gün'**
  String get onboardingBirthDay;

  /// No description provided for @onboardingBirthMonth.
  ///
  /// In tr, this message translates to:
  /// **'Ay'**
  String get onboardingBirthMonth;

  /// No description provided for @onboardingBirthYear.
  ///
  /// In tr, this message translates to:
  /// **'Yıl'**
  String get onboardingBirthYear;

  /// No description provided for @onboardingBirthDateInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Doğum tarihi geçerli bir gün olmalı.'**
  String get onboardingBirthDateInvalid;

  /// No description provided for @onboardingGender.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get onboardingGender;

  /// No description provided for @onboardingMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get onboardingMale;

  /// No description provided for @onboardingFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get onboardingFemale;

  /// No description provided for @onboardingGenderUnspecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtmek istemiyorum'**
  String get onboardingGenderUnspecified;

  /// No description provided for @onboardingGenderWhy.
  ///
  /// In tr, this message translates to:
  /// **'Kalori hesabında kullanılır; belirtmezsen ortalama katsayı alınır.'**
  String get onboardingGenderWhy;

  /// No description provided for @onboardingMeasuresTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçülerin'**
  String get onboardingMeasuresTitle;

  /// No description provided for @onboardingMeasuresBody.
  ///
  /// In tr, this message translates to:
  /// **'Kilo ilk tartı kaydın olarak da işlenir — İlerleme grafiğin bugünden başlar.'**
  String get onboardingMeasuresBody;

  /// No description provided for @onboardingHeight.
  ///
  /// In tr, this message translates to:
  /// **'Boy'**
  String get onboardingHeight;

  /// No description provided for @onboardingWeight.
  ///
  /// In tr, this message translates to:
  /// **'Şu anki kilo'**
  String get onboardingWeight;

  /// No description provided for @onboardingTargetWeight.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kilo'**
  String get onboardingTargetWeight;

  /// No description provided for @commonBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get commonNext;

  /// No description provided for @setupPanelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum'**
  String get setupPanelTitle;

  /// No description provided for @setupPanelProgress.
  ///
  /// In tr, this message translates to:
  /// **'{done}/{total} tamam'**
  String setupPanelProgress(int done, int total);

  /// No description provided for @setupPanelBody.
  ///
  /// In tr, this message translates to:
  /// **'Birkaç kısa adım kaldı. Bunlar plana da gider — ne kadar dolu, plan o kadar isabetli.'**
  String get setupPanelBody;

  /// No description provided for @setupCardEquipment.
  ///
  /// In tr, this message translates to:
  /// **'Ekipmanlarını seç'**
  String get setupCardEquipment;

  /// No description provided for @setupCardMedical.
  ///
  /// In tr, this message translates to:
  /// **'Medikal bilgilerin'**
  String get setupCardMedical;

  /// No description provided for @setupCardRhythm.
  ///
  /// In tr, this message translates to:
  /// **'Günlük düzenin'**
  String get setupCardRhythm;

  /// No description provided for @setupCardMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String setupCardMinutes(int minutes);

  /// No description provided for @setupCardSkip.
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get setupCardSkip;

  /// No description provided for @todayBirthday.
  ///
  /// In tr, this message translates to:
  /// **'İyi ki doğdun {name}! 🎉'**
  String todayBirthday(String name);

  /// No description provided for @medicalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Medikal bilgiler'**
  String get medicalTitle;

  /// No description provided for @medicalPrivacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgiler cihazından çıkmaz; yalnızca sen yapay zekâ belgesini paylaştığında plana girer.'**
  String get medicalPrivacyNote;

  /// No description provided for @medicalKindCondition.
  ///
  /// In tr, this message translates to:
  /// **'Durumlar'**
  String get medicalKindCondition;

  /// No description provided for @medicalKindRestriction.
  ///
  /// In tr, this message translates to:
  /// **'Hareket kısıtları'**
  String get medicalKindRestriction;

  /// No description provided for @medicalKindAllergy.
  ///
  /// In tr, this message translates to:
  /// **'Alerjiler'**
  String get medicalKindAllergy;

  /// No description provided for @medicalKindBloodType.
  ///
  /// In tr, this message translates to:
  /// **'Kan grubu'**
  String get medicalKindBloodType;

  /// No description provided for @medicalKindEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt yok.'**
  String get medicalKindEmpty;

  /// No description provided for @medicalAddCustom.
  ///
  /// In tr, this message translates to:
  /// **'Başka ekle'**
  String get medicalAddCustom;

  /// No description provided for @medicalCustomHint.
  ///
  /// In tr, this message translates to:
  /// **'örn. diz hassasiyeti'**
  String get medicalCustomHint;

  /// No description provided for @medicalRemoveTitle.
  ///
  /// In tr, this message translates to:
  /// **'{label} silinsin mi?'**
  String medicalRemoveTitle(String label);

  /// No description provided for @medicalRemoveBody.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt listeden kalkar; geçmiş verilerin bozulmaz.'**
  String get medicalRemoveBody;

  /// No description provided for @medicalMedsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlaçlar'**
  String get medicalMedsTitle;

  /// No description provided for @medicalMedsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Tanımlı ilaç yok. İlaçlar hatırlatma ve takip için İlaç & Takviye ekranında tutulur.'**
  String get medicalMedsEmpty;

  /// No description provided for @medicalMedsManage.
  ///
  /// In tr, this message translates to:
  /// **'İlaç ve takviyeleri yönet'**
  String get medicalMedsManage;

  /// No description provided for @medicalCondInsulinResistance.
  ///
  /// In tr, this message translates to:
  /// **'İnsülin direnci'**
  String get medicalCondInsulinResistance;

  /// No description provided for @medicalCondType2Diabetes.
  ///
  /// In tr, this message translates to:
  /// **'Tip 2 diyabet'**
  String get medicalCondType2Diabetes;

  /// No description provided for @medicalCondHypertension.
  ///
  /// In tr, this message translates to:
  /// **'Hipertansiyon'**
  String get medicalCondHypertension;

  /// No description provided for @medicalCondThyroid.
  ///
  /// In tr, this message translates to:
  /// **'Tiroid'**
  String get medicalCondThyroid;

  /// No description provided for @medicalCondKneeIssue.
  ///
  /// In tr, this message translates to:
  /// **'Diz sorunu'**
  String get medicalCondKneeIssue;

  /// No description provided for @medicalCondBackIssue.
  ///
  /// In tr, this message translates to:
  /// **'Bel sorunu'**
  String get medicalCondBackIssue;

  /// No description provided for @medicalCondShoulderIssue.
  ///
  /// In tr, this message translates to:
  /// **'Omuz sorunu'**
  String get medicalCondShoulderIssue;

  /// No description provided for @medicalCondLactose.
  ///
  /// In tr, this message translates to:
  /// **'Laktoz'**
  String get medicalCondLactose;

  /// No description provided for @medicalCondGluten.
  ///
  /// In tr, this message translates to:
  /// **'Gluten'**
  String get medicalCondGluten;

  /// No description provided for @medicalCondNuts.
  ///
  /// In tr, this message translates to:
  /// **'Kuruyemiş'**
  String get medicalCondNuts;

  /// No description provided for @supplementKindSupplement.
  ///
  /// In tr, this message translates to:
  /// **'Takviye'**
  String get supplementKindSupplement;

  /// No description provided for @supplementKindMedication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç'**
  String get supplementKindMedication;

  /// No description provided for @equipmentTabHome.
  ///
  /// In tr, this message translates to:
  /// **'Evde'**
  String get equipmentTabHome;

  /// No description provided for @equipmentTabGym.
  ///
  /// In tr, this message translates to:
  /// **'Salonda'**
  String get equipmentTabGym;

  /// No description provided for @equipmentTabSports.
  ///
  /// In tr, this message translates to:
  /// **'Sporlar'**
  String get equipmentTabSports;

  /// No description provided for @equipmentImpactHome.
  ///
  /// In tr, this message translates to:
  /// **'Bu işaretlerle evde {count} hareket yapılabilir.'**
  String equipmentImpactHome(int count);

  /// No description provided for @equipmentImpactGym.
  ///
  /// In tr, this message translates to:
  /// **'Bu işaretlerle salonda {count} hareket yapılabilir.'**
  String equipmentImpactGym(int count);

  /// No description provided for @equipmentUnlocks.
  ///
  /// In tr, this message translates to:
  /// **'+{count} hareket açar'**
  String equipmentUnlocks(int count);

  /// No description provided for @equipmentGymToggle.
  ///
  /// In tr, this message translates to:
  /// **'Salona gidiyor musun?'**
  String get equipmentGymToggle;

  /// No description provided for @equipmentGymOffBody.
  ///
  /// In tr, this message translates to:
  /// **'Salona gitmiyorsan burada iş yok — plan yalnız evde ve dışarıda yapılabilenlerden kurulur. Fikrin değişirse anahtarı aç.'**
  String get equipmentGymOffBody;

  /// No description provided for @sportsIntro.
  ///
  /// In tr, this message translates to:
  /// **'Sevdiğin sporları seç; yapay zekâ planı onların etrafına kurar. İstersen sıklık notu ekle.'**
  String get sportsIntro;

  /// No description provided for @sportsChosen.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiklerin'**
  String get sportsChosen;

  /// No description provided for @sportsSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Spor ara — koşu, basketbol, yüzme…'**
  String get sportsSearchHint;

  /// No description provided for @sportsNoteTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Sıklık notu'**
  String get sportsNoteTooltip;

  /// No description provided for @sportsNoteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne sıklıkla?'**
  String get sportsNoteTitle;

  /// No description provided for @sportsNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'örn. haftada 1, pazar sabahı'**
  String get sportsNoteHint;

  /// No description provided for @reminderMealBody.
  ///
  /// In tr, this message translates to:
  /// **'Öğün saati. Yediklerini Diyet\'ten kaydet.'**
  String get reminderMealBody;

  /// No description provided for @planSlotItems.
  ///
  /// In tr, this message translates to:
  /// **'Öğün kalemleri'**
  String get planSlotItems;

  /// No description provided for @planSlotAddItem.
  ///
  /// In tr, this message translates to:
  /// **'Besin ekle'**
  String get planSlotAddItem;

  /// No description provided for @waterRowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get waterRowTitle;

  /// No description provided for @waterRowAmount.
  ///
  /// In tr, this message translates to:
  /// **'{current} / {target} ml'**
  String waterRowAmount(int current, int target);

  /// No description provided for @waterRowAddGlass.
  ///
  /// In tr, this message translates to:
  /// **'+250 ml'**
  String get waterRowAddGlass;

  /// No description provided for @waterRowRemoveGlass.
  ///
  /// In tr, this message translates to:
  /// **'Bir bardak geri al'**
  String get waterRowRemoveGlass;

  /// No description provided for @dietPlanBadge.
  ///
  /// In tr, this message translates to:
  /// **'PLAN'**
  String get dietPlanBadge;

  /// No description provided for @dietPlanCompliantBadge.
  ///
  /// In tr, this message translates to:
  /// **'PLANA UYGUN'**
  String get dietPlanCompliantBadge;

  /// No description provided for @dietAteAsPlanned.
  ///
  /// In tr, this message translates to:
  /// **'Plandaki gibi yedim'**
  String get dietAteAsPlanned;

  /// No description provided for @dietAteUsual.
  ///
  /// In tr, this message translates to:
  /// **'Her zamanki'**
  String get dietAteUsual;

  /// No description provided for @dietExternalMeal.
  ///
  /// In tr, this message translates to:
  /// **'Dışarıda/yemekhanede — plan beklenmez, yediğini serbest gir.'**
  String get dietExternalMeal;

  /// No description provided for @dietFixedUnbound.
  ///
  /// In tr, this message translates to:
  /// **'Sabit öğün: {note}'**
  String dietFixedUnbound(String note);

  /// No description provided for @foodSortAz.
  ///
  /// In tr, this message translates to:
  /// **'A–Z'**
  String get foodSortAz;

  /// No description provided for @foodSortKcalAsc.
  ///
  /// In tr, this message translates to:
  /// **'Kalori ↑'**
  String get foodSortKcalAsc;

  /// No description provided for @foodSortKcalDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kalori ↓'**
  String get foodSortKcalDesc;

  /// No description provided for @foodSortProteinDesc.
  ///
  /// In tr, this message translates to:
  /// **'Protein ↓'**
  String get foodSortProteinDesc;

  /// No description provided for @foodSortFrequent.
  ///
  /// In tr, this message translates to:
  /// **'Sık yenen'**
  String get foodSortFrequent;

  /// No description provided for @foodForbiddenBadge.
  ///
  /// In tr, this message translates to:
  /// **'YASAKLI'**
  String get foodForbiddenBadge;

  /// No description provided for @forbiddenTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yasaklı yiyecekler'**
  String get forbiddenTitle;

  /// No description provided for @forbiddenIntro.
  ///
  /// In tr, this message translates to:
  /// **'Bu liste yapay zekâ planına gider (önerilmez) ve eşleşen besinler listede rozet taşır. Kayıt engellenmez — karar senin.'**
  String get forbiddenIntro;

  /// No description provided for @forbiddenAddHint.
  ///
  /// In tr, this message translates to:
  /// **'örn. şeker, hamur işi, alkol'**
  String get forbiddenAddHint;

  /// No description provided for @forbiddenAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get forbiddenAdd;

  /// No description provided for @forbiddenLinkFoods.
  ///
  /// In tr, this message translates to:
  /// **'Besinlere bağla'**
  String get forbiddenLinkFoods;

  /// No description provided for @forbiddenLinkedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} besin bağlı'**
  String forbiddenLinkedCount(int count);

  /// No description provided for @forbiddenNoPlan.
  ///
  /// In tr, this message translates to:
  /// **'Yasaklı listesi plana yazılır; önce bir plan gerekli.'**
  String get forbiddenNoPlan;

  /// No description provided for @forbiddenEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Yasaklı yok. Satır ekle; istersen besinlere bağla.'**
  String get forbiddenEmpty;

  /// No description provided for @dietHistoryDays.
  ///
  /// In tr, this message translates to:
  /// **'Gün dökümü'**
  String get dietHistoryDays;

  /// No description provided for @planAdherence.
  ///
  /// In tr, this message translates to:
  /// **'Uyum %{percent} — {done}/{planned} antrenman günü'**
  String planAdherence(int percent, int done, int planned);

  /// No description provided for @plannedVsDoneTitle.
  ///
  /// In tr, this message translates to:
  /// **'Planlanan / Yapılan'**
  String get plannedVsDoneTitle;

  /// No description provided for @plannedVsDoneExercises.
  ///
  /// In tr, this message translates to:
  /// **'Hareketler'**
  String get plannedVsDoneExercises;

  /// No description provided for @plannedVsDoneColumns.
  ///
  /// In tr, this message translates to:
  /// **'PLAN · YAPILAN'**
  String get plannedVsDoneColumns;

  /// No description provided for @plannedVsDoneEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu günde antrenman yok'**
  String get plannedVsDoneEmptyTitle;

  /// No description provided for @plannedVsDoneEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Plan bu güne hareket koymadı ve kayıt da girilmemiş.'**
  String get plannedVsDoneEmptyBody;

  /// No description provided for @plannedVsDoneOpenLive.
  ///
  /// In tr, this message translates to:
  /// **'Antrenmanı başlat'**
  String get plannedVsDoneOpenLive;

  /// No description provided for @plannedVsDoneSession.
  ///
  /// In tr, this message translates to:
  /// **'Seans'**
  String get plannedVsDoneSession;

  /// No description provided for @plannedVsDoneNoSession.
  ///
  /// In tr, this message translates to:
  /// **'Seans kaydı yok. Geçmiş gün için saat aralığını elle girebilirsin.'**
  String get plannedVsDoneNoSession;

  /// No description provided for @plannedVsDoneSessionOpen.
  ///
  /// In tr, this message translates to:
  /// **'{start} — sürüyor'**
  String plannedVsDoneSessionOpen(String start);

  /// No description provided for @plannedVsDoneMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String plannedVsDoneMinutes(int minutes);

  /// No description provided for @plannedVsDoneAddSession.
  ///
  /// In tr, this message translates to:
  /// **'Seans ekle'**
  String get plannedVsDoneAddSession;

  /// No description provided for @plannedVsDoneSessionEdit.
  ///
  /// In tr, this message translates to:
  /// **'Seans saatleri'**
  String get plannedVsDoneSessionEdit;

  /// No description provided for @plannedVsDoneStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get plannedVsDoneStart;

  /// No description provided for @plannedVsDoneEnd.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get plannedVsDoneEnd;

  /// No description provided for @plannedVsDoneAdd.
  ///
  /// In tr, this message translates to:
  /// **'— EKLE'**
  String get plannedVsDoneAdd;

  /// No description provided for @plannedVsDoneNoSets.
  ///
  /// In tr, this message translates to:
  /// **'Set kaydı yok. Aşağıdan ekle.'**
  String get plannedVsDoneNoSets;

  /// No description provided for @plannedVsDoneAddSet.
  ///
  /// In tr, this message translates to:
  /// **'Set ekle'**
  String get plannedVsDoneAddSet;

  /// No description provided for @plannedVsDoneReps.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get plannedVsDoneReps;

  /// No description provided for @plannedVsDoneSeconds.
  ///
  /// In tr, this message translates to:
  /// **'Saniye'**
  String get plannedVsDoneSeconds;

  /// No description provided for @sportWorkoutTodayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün antrenmanı'**
  String get sportWorkoutTodayTitle;

  /// No description provided for @sportWorkoutTodayBody.
  ///
  /// In tr, this message translates to:
  /// **'Plan bugüne antrenman koydu.'**
  String get sportWorkoutTodayBody;

  /// No description provided for @sportWorkoutHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get sportWorkoutHistory;

  /// No description provided for @sportWorkoutExerciseCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} hareket'**
  String sportWorkoutExerciseCount(int count);

  /// No description provided for @catalogSafetyLabel.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get catalogSafetyLabel;

  /// No description provided for @catalogSafetyRestricted.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik — kısıtınla eşleşiyor'**
  String get catalogSafetyRestricted;

  /// No description provided for @bmiRowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vücut kitle indeksi'**
  String get bmiRowTitle;

  /// No description provided for @bmiUnderweight.
  ///
  /// In tr, this message translates to:
  /// **'Zayıf'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In tr, this message translates to:
  /// **'Fazla kilolu'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In tr, this message translates to:
  /// **'Obez'**
  String get bmiObese;

  /// No description provided for @healthShareLabs.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil özetini paylaş'**
  String get healthShareLabs;

  /// No description provided for @healthShareTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil özeti — di@sport'**
  String get healthShareTitle;

  /// No description provided for @checkupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Check-up rehberi'**
  String get checkupTitle;

  /// No description provided for @checkupDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Genel tarama önerileri — tıbbi tavsiye değildir, doktoruna danış.'**
  String get checkupDisclaimer;

  /// No description provided for @checkupNeedsWeight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo girilirse öneriler netleşir.'**
  String get checkupNeedsWeight;

  /// No description provided for @checkupDue.
  ///
  /// In tr, this message translates to:
  /// **'Vakti geldi'**
  String get checkupDue;

  /// No description provided for @checkupInMonths.
  ///
  /// In tr, this message translates to:
  /// **'{months} ay sonra'**
  String checkupInMonths(int months);

  /// No description provided for @checkupScheduled.
  ///
  /// In tr, this message translates to:
  /// **'{test} vadesi takvime eklendi.'**
  String checkupScheduled(String test);

  /// No description provided for @checkupFullPanel.
  ///
  /// In tr, this message translates to:
  /// **'Tam panel (CBC, CMP, lipit, HbA1c, TSH)'**
  String get checkupFullPanel;

  /// No description provided for @checkupHba1c.
  ///
  /// In tr, this message translates to:
  /// **'HbA1c'**
  String get checkupHba1c;

  /// No description provided for @checkupLipid.
  ///
  /// In tr, this message translates to:
  /// **'Lipit paneli'**
  String get checkupLipid;

  /// No description provided for @checkupVitaminDB12.
  ///
  /// In tr, this message translates to:
  /// **'D vitamini + B12'**
  String get checkupVitaminDB12;

  /// No description provided for @supplementsTodayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün dozları'**
  String get supplementsTodayTitle;

  /// No description provided for @supplementsAdherenceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün uyum'**
  String get supplementsAdherenceTitle;

  /// No description provided for @labImportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zekâ ile tahlil aktar'**
  String get labImportTitle;

  /// No description provided for @labImportStep1.
  ///
  /// In tr, this message translates to:
  /// **'Aktarım belgesini kopyala.'**
  String get labImportStep1;

  /// No description provided for @labImportCopyDoc.
  ///
  /// In tr, this message translates to:
  /// **'Belgeyi kopyala'**
  String get labImportCopyDoc;

  /// No description provided for @labImportShareDoc.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get labImportShareDoc;

  /// No description provided for @labImportCopied.
  ///
  /// In tr, this message translates to:
  /// **'Belge panoya kopyalandı.'**
  String get labImportCopied;

  /// No description provided for @labImportStep2.
  ///
  /// In tr, this message translates to:
  /// **'Belgeyi ve tahlil PDF\'ini herhangi bir yapay zekâ sohbetine ver. PDF uygulamaya girmez.'**
  String get labImportStep2;

  /// No description provided for @labImportStep3.
  ///
  /// In tr, this message translates to:
  /// **'Dönen JSON\'u buraya yapıştır.'**
  String get labImportStep3;

  /// No description provided for @labImportPasteHint.
  ///
  /// In tr, this message translates to:
  /// **'JSON belgesini buraya yapıştır'**
  String get labImportPasteHint;

  /// No description provided for @labImportParse.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıştır'**
  String get labImportParse;

  /// No description provided for @labImportPreview.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get labImportPreview;

  /// No description provided for @labImportUnknownMarker.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil sözlükte yok'**
  String get labImportUnknownMarker;

  /// No description provided for @labImportUnexpectedUnit.
  ///
  /// In tr, this message translates to:
  /// **'Birim beklenenden farklı'**
  String get labImportUnexpectedUnit;

  /// No description provided for @labImportImplausible.
  ///
  /// In tr, this message translates to:
  /// **'Değer akla yatkın aralığın dışında'**
  String get labImportImplausible;

  /// No description provided for @labImportEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Satırı düzelt'**
  String get labImportEditTitle;

  /// No description provided for @labImportSave.
  ///
  /// In tr, this message translates to:
  /// **'{save} değeri kaydet · {skip} atla'**
  String labImportSave(int save, int skip);

  /// No description provided for @labImportSaved.
  ///
  /// In tr, this message translates to:
  /// **'{count} tahlil değeri kaydedildi.'**
  String labImportSaved(int count);

  /// No description provided for @healthImportWithAi.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zekâ ile PDF\'ten aktar'**
  String get healthImportWithAi;

  /// No description provided for @ctxSectionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'AI\'a gönderilecekler'**
  String get ctxSectionsTitle;

  /// No description provided for @ctxSectionsIntro.
  ///
  /// In tr, this message translates to:
  /// **'Plan isteği belgesine hangi bölümlerin gireceğini sen seçersin. Kapalı bölüm belgeye hiç yazılmaz. Kim/hedef/görev her zaman girer — onlarsız plan istenemez.'**
  String get ctxSectionsIntro;

  /// No description provided for @ctxPreviewButton.
  ///
  /// In tr, this message translates to:
  /// **'Önce belgeyi gör'**
  String get ctxPreviewButton;

  /// No description provided for @ctxPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Belge önizleme'**
  String get ctxPreviewTitle;

  /// No description provided for @ctxCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get ctxCopy;

  /// No description provided for @ctxShare.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get ctxShare;

  /// No description provided for @ctxSectionMedical.
  ///
  /// In tr, this message translates to:
  /// **'Medikal'**
  String get ctxSectionMedical;

  /// No description provided for @ctxSectionMedicalHint.
  ///
  /// In tr, this message translates to:
  /// **'Durumlar, kısıtlar, tahliller ve ilaçlar'**
  String get ctxSectionMedicalHint;

  /// No description provided for @ctxSectionEnvironment.
  ///
  /// In tr, this message translates to:
  /// **'Ortam'**
  String get ctxSectionEnvironment;

  /// No description provided for @ctxSectionEnvironmentHint.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman envanteri ve sevdiğin sporlar'**
  String get ctxSectionEnvironmentHint;

  /// No description provided for @ctxSectionRoutine.
  ///
  /// In tr, this message translates to:
  /// **'Öğün davranışları'**
  String get ctxSectionRoutine;

  /// No description provided for @ctxSectionRoutineHint.
  ///
  /// In tr, this message translates to:
  /// **'Öğün saatleri ve yemekhane/sabit öğün bilgisi'**
  String get ctxSectionRoutineHint;

  /// No description provided for @ctxSectionForbidden.
  ///
  /// In tr, this message translates to:
  /// **'Yasaklı yiyecekler'**
  String get ctxSectionForbidden;

  /// No description provided for @ctxSectionForbiddenHint.
  ///
  /// In tr, this message translates to:
  /// **'AI bu listeyi asla önermez'**
  String get ctxSectionForbiddenHint;

  /// No description provided for @ctxSectionRecent.
  ///
  /// In tr, this message translates to:
  /// **'Son 14 gün'**
  String get ctxSectionRecent;

  /// No description provided for @ctxSectionRecentHint.
  ///
  /// In tr, this message translates to:
  /// **'Öğünler, su (ml), ilaç uyumu, antrenman, kilo'**
  String get ctxSectionRecentHint;

  /// No description provided for @ctxSectionNotes.
  ///
  /// In tr, this message translates to:
  /// **'Kendi sözlerin'**
  String get ctxSectionNotes;

  /// No description provided for @ctxSectionNotesHint.
  ///
  /// In tr, this message translates to:
  /// **'Gün notların olduğu gibi'**
  String get ctxSectionNotesHint;

  /// No description provided for @ctxSectionFoods.
  ///
  /// In tr, this message translates to:
  /// **'Besin listesi'**
  String get ctxSectionFoods;

  /// No description provided for @ctxSectionFoodsHint.
  ///
  /// In tr, this message translates to:
  /// **'368 besin — AI öğünleri besin id\'siyle yazabilsin'**
  String get ctxSectionFoodsHint;

  /// No description provided for @moreAiSections.
  ///
  /// In tr, this message translates to:
  /// **'AI\'a gönderilecekler'**
  String get moreAiSections;

  /// No description provided for @importPlanGraftTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut planın üstüne aşıla'**
  String get importPlanGraftTitle;

  /// No description provided for @importPlanGraftBody.
  ///
  /// In tr, this message translates to:
  /// **'{date} öncesi aynen korunur; o tarihten sonrası bu planla değiştirilir. Kayıtlarına dokunulmaz.'**
  String importPlanGraftBody(String date);

  /// No description provided for @requestScopeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Plan kapsamı'**
  String get requestScopeTitle;

  /// No description provided for @requestScopeBody.
  ///
  /// In tr, this message translates to:
  /// **'Aktif bir planın var. Yeni plan nereden başlasın?'**
  String get requestScopeBody;

  /// No description provided for @requestScopeGraft.
  ///
  /// In tr, this message translates to:
  /// **'Şu tarihten sonrası'**
  String get requestScopeGraft;

  /// No description provided for @requestScopeFresh.
  ///
  /// In tr, this message translates to:
  /// **'Baştan yeni plan'**
  String get requestScopeFresh;

  /// No description provided for @importWarningsTitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} uyarı'**
  String importWarningsTitle(int count);

  /// No description provided for @importWarningsFootnote.
  ///
  /// In tr, this message translates to:
  /// **'Uyarılar içeri almayı engellemez; istersen sonra editörle düzelt.'**
  String get importWarningsFootnote;

  /// No description provided for @importWarnForbidden.
  ///
  /// In tr, this message translates to:
  /// **'Yasaklı besin planda: {id}'**
  String importWarnForbidden(String id);

  /// No description provided for @importWarnUnknownFood.
  ///
  /// In tr, this message translates to:
  /// **'Besin listesinde yok: {id}'**
  String importWarnUnknownFood(String id);

  /// No description provided for @importWarnCannotPerform.
  ///
  /// In tr, this message translates to:
  /// **'Ekipmanınla yapılamıyor: {id}'**
  String importWarnCannotPerform(String id);

  /// No description provided for @importWarnExternalMeal.
  ///
  /// In tr, this message translates to:
  /// **'Dışarıda yenen öğüne plan yazılmış: {meal}'**
  String importWarnExternalMeal(String meal);

  /// No description provided for @importWarnFixedMeal.
  ///
  /// In tr, this message translates to:
  /// **'Sabit öğün planda farklı: {meal}'**
  String importWarnFixedMeal(String meal);

  /// No description provided for @importWarnRestriction.
  ///
  /// In tr, this message translates to:
  /// **'Hareket kısıtınla eşleşiyor: {id}'**
  String importWarnRestriction(String id);

  /// No description provided for @rhythmMealsSection.
  ///
  /// In tr, this message translates to:
  /// **'Öğünler'**
  String get rhythmMealsSection;

  /// No description provided for @rhythmMealFlexible.
  ///
  /// In tr, this message translates to:
  /// **'Saat esnek'**
  String get rhythmMealFlexible;

  /// No description provided for @mealBehaviorPlanned.
  ///
  /// In tr, this message translates to:
  /// **'Plan doldurur'**
  String get mealBehaviorPlanned;

  /// No description provided for @mealBehaviorFixed.
  ///
  /// In tr, this message translates to:
  /// **'Hep aynı'**
  String get mealBehaviorFixed;

  /// No description provided for @mealBehaviorExternal.
  ///
  /// In tr, this message translates to:
  /// **'Yemekhane/dışarıda'**
  String get mealBehaviorExternal;

  /// No description provided for @mealBehaviorFixedNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ne yenir?'**
  String get mealBehaviorFixedNoteLabel;

  /// No description provided for @mealBehaviorFixedNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'örn. menemen + çay'**
  String get mealBehaviorFixedNoteHint;

  /// No description provided for @mealBehaviorSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'{meal} düzeni'**
  String mealBehaviorSheetTitle(String meal);

  /// No description provided for @mealBehaviorTimeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get mealBehaviorTimeLabel;

  /// No description provided for @mealBehaviorTimeClear.
  ///
  /// In tr, this message translates to:
  /// **'Saati kaldır'**
  String get mealBehaviorTimeClear;

  /// No description provided for @mealBehaviorWhy.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgi yapay zekâ planına gider: sabit öğün değiştirilmez, dışarıda yenen öğün planlanmaz.'**
  String get mealBehaviorWhy;

  /// No description provided for @settingsProfileHeightRequired.
  ///
  /// In tr, this message translates to:
  /// **'Boy alanı gerekli.'**
  String get settingsProfileHeightRequired;

  /// No description provided for @settingsProfileContextNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu bilgiler yapay zekâya gönderilen bağlam dosyasına girer. Ne kadar doldurursan plan o kadar sana göre olur; boş bıraktıkların \"belirtilmedi\" diye geçer.'**
  String get settingsProfileContextNote;

  /// No description provided for @importPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Planı içeri al'**
  String get importPlanTitle;

  /// No description provided for @importPlanDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zekânın verdiği JSON belgesini buraya yapıştır.'**
  String get importPlanDescription;

  /// No description provided for @importPlanValidate.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula'**
  String get importPlanValidate;

  /// No description provided for @importPlanImport.
  ///
  /// In tr, this message translates to:
  /// **'İçeri al'**
  String get importPlanImport;

  /// No description provided for @importPlanFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Plan alınamadı'**
  String get importPlanFailedTitle;

  /// No description provided for @importPlanPasteBackHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu mesajı olduğu gibi yapay zekâya yapıştır; neyi düzelteceğini bilecek.'**
  String get importPlanPasteBackHint;

  /// No description provided for @importPlanCopyError.
  ///
  /// In tr, this message translates to:
  /// **'Hatayı kopyala'**
  String get importPlanCopyError;

  /// No description provided for @importPlanErrorCopied.
  ///
  /// In tr, this message translates to:
  /// **'Hata mesajı kopyalandı'**
  String get importPlanErrorCopied;

  /// No description provided for @importPlanLoaded.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük plan yüklendi.'**
  String importPlanLoaded(Object days);

  /// No description provided for @importPlanLoadedWithExercises.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük plan yüklendi, {count} yeni hareket eklendi.'**
  String importPlanLoadedWithExercises(Object days, Object count);

  /// No description provided for @importPlanSummary.
  ///
  /// In tr, this message translates to:
  /// **'{startDate} tarihinden itibaren {weeks} hafta · {days} gün'**
  String importPlanSummary(Object startDate, Object weeks, Object days);

  /// No description provided for @importPlanGym.
  ///
  /// In tr, this message translates to:
  /// **'Salon {count}'**
  String importPlanGym(Object count);

  /// No description provided for @importPlanHome.
  ///
  /// In tr, this message translates to:
  /// **'Ev {count}'**
  String importPlanHome(Object count);

  /// No description provided for @importPlanRest.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme {count}'**
  String importPlanRest(Object count);

  /// No description provided for @importPlanGoals.
  ///
  /// In tr, this message translates to:
  /// **'{kcal} kcal · {protein} g protein · {water} L su · hedef −{loss} kg'**
  String importPlanGoals(
    Object kcal,
    Object protein,
    Object water,
    Object loss,
  );

  /// No description provided for @importPlanNewExercisesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni hareket önerileri'**
  String get importPlanNewExercisesTitle;

  /// No description provided for @importPlanNewExercisesDescription.
  ///
  /// In tr, this message translates to:
  /// **'Onayladıkların kataloğa kalıcı olarak eklenir.'**
  String get importPlanNewExercisesDescription;

  /// No description provided for @todayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get todayTitle;

  /// No description provided for @todayWeekNumber.
  ///
  /// In tr, this message translates to:
  /// **'{week}. hafta'**
  String todayWeekNumber(Object week);

  /// No description provided for @todayDayTypeGym.
  ///
  /// In tr, this message translates to:
  /// **'Salon günü'**
  String get todayDayTypeGym;

  /// No description provided for @todayDayTypeHome.
  ///
  /// In tr, this message translates to:
  /// **'Ev antrenmanı'**
  String get todayDayTypeHome;

  /// No description provided for @todayDayTypeRest.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme günü'**
  String get todayDayTypeRest;

  /// No description provided for @todayMetricProgram.
  ///
  /// In tr, this message translates to:
  /// **'Program'**
  String get todayMetricProgram;

  /// No description provided for @todayMetricRules.
  ///
  /// In tr, this message translates to:
  /// **'Kurallar'**
  String get todayMetricRules;

  /// No description provided for @todayNextEyebrow.
  ///
  /// In tr, this message translates to:
  /// **'Sırada · {time}'**
  String todayNextEyebrow(Object time);

  /// No description provided for @todayExerciseCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} hareket'**
  String todayExerciseCount(Object count);

  /// No description provided for @todaySpineLabel.
  ///
  /// In tr, this message translates to:
  /// **'Günün omurgası'**
  String get todaySpineLabel;

  /// No description provided for @todayDinnerHint.
  ///
  /// In tr, this message translates to:
  /// **'Akşam önerisi: {text}'**
  String todayDinnerHint(Object text);

  /// No description provided for @todayNoPlanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için plan yok'**
  String get todayNoPlanTitle;

  /// No description provided for @todayNoPlanBody.
  ///
  /// In tr, this message translates to:
  /// **'Plan sekmesinden bir program yükle. Tartı ve günün kutucukları plan olmadan da çalışır.'**
  String get todayNoPlanBody;

  /// No description provided for @todayCheckedLabel.
  ///
  /// In tr, this message translates to:
  /// **'işaretli'**
  String get todayCheckedLabel;

  /// No description provided for @todayUncheckedLabel.
  ///
  /// In tr, this message translates to:
  /// **'işaretsiz'**
  String get todayUncheckedLabel;

  /// No description provided for @todayRulesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün kuralları'**
  String get todayRulesTitle;

  /// No description provided for @todayEditRulesTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kuralları düzenle'**
  String get todayEditRulesTooltip;

  /// No description provided for @todayNoRulesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kural yok'**
  String get todayNoRulesTitle;

  /// No description provided for @todayNoRulesBody.
  ///
  /// In tr, this message translates to:
  /// **'Her gün takip etmek istediğin şeyleri ekle — su, takviye, erken yatma. Sağ üstteki ayar düğmesinden.'**
  String get todayNoRulesBody;

  /// No description provided for @todayRulesEditorEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki düğmeden ilk kuralını ekle.'**
  String get todayRulesEditorEmptyBody;

  /// No description provided for @todayRuleFabLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kural'**
  String get todayRuleFabLabel;

  /// No description provided for @todayDeleteRuleTitle.
  ///
  /// In tr, this message translates to:
  /// **'\"{label}\" silinsin mi?'**
  String todayDeleteRuleTitle(Object label);

  /// No description provided for @todayDeleteRuleBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugünden sonra listede görünmez. Geçmiş günlerdeki işaretlerin olduğu gibi kalır.'**
  String get todayDeleteRuleBody;

  /// No description provided for @todayBuiltInRuleNote.
  ///
  /// In tr, this message translates to:
  /// **'Çizelgeden gelen kural'**
  String get todayBuiltInRuleNote;

  /// No description provided for @todayRuleNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kural adı gerekli'**
  String get todayRuleNameRequired;

  /// No description provided for @todayAddRule.
  ///
  /// In tr, this message translates to:
  /// **'Kural ekle'**
  String get todayAddRule;

  /// No description provided for @todayEditRule.
  ///
  /// In tr, this message translates to:
  /// **'Kuralı düzenle'**
  String get todayEditRule;

  /// No description provided for @todayRuleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kural'**
  String get todayRuleLabel;

  /// No description provided for @todayRuleHint.
  ///
  /// In tr, this message translates to:
  /// **'Kreatin aldım'**
  String get todayRuleHint;

  /// No description provided for @todayIconLabel.
  ///
  /// In tr, this message translates to:
  /// **'İkon'**
  String get todayIconLabel;

  /// No description provided for @todayNoteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get todayNoteTitle;

  /// No description provided for @todayNoteDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ne yedin, ne zorladı, nasıl geçti.'**
  String get todayNoteDescription;

  /// No description provided for @todayNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Bugün nasıl geçti?'**
  String get todayNoteHint;

  /// No description provided for @todayWeightLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get todayWeightLabel;

  /// No description provided for @todayWeightUnit.
  ///
  /// In tr, this message translates to:
  /// **'kg'**
  String get todayWeightUnit;

  /// No description provided for @todaySleepLabel.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get todaySleepLabel;

  /// No description provided for @todaySleepUnit.
  ///
  /// In tr, this message translates to:
  /// **'sa'**
  String get todaySleepUnit;

  /// No description provided for @todayMissedStreakTitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün üst üste antrenman yok'**
  String todayMissedStreakTitle(Object count);

  /// No description provided for @todayMissedStreakBody.
  ///
  /// In tr, this message translates to:
  /// **'Kural buydu: iki günü üst üste kaçırma. Bugün kısa da olsa bir şey yap.'**
  String get todayMissedStreakBody;

  /// No description provided for @planEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz plan yok'**
  String get planEmptyTitle;

  /// No description provided for @planEmptyBody.
  ///
  /// In tr, this message translates to:
  /// **'Yukarıdaki \"Yeni plan iste\" düğmesiyle bağlam dosyanı üret, bir yapay zekâya ver, dönen JSON belgesini \"İçeri al\" ile buraya aktar.'**
  String get planEmptyBody;

  /// No description provided for @planLoadSample.
  ///
  /// In tr, this message translates to:
  /// **'Örnek planı yükle (geliştirme)'**
  String get planLoadSample;

  /// No description provided for @planShareSubject.
  ///
  /// In tr, this message translates to:
  /// **'di@sport — plan isteği'**
  String get planShareSubject;

  /// No description provided for @planRequestButton.
  ///
  /// In tr, this message translates to:
  /// **'Yeni plan iste'**
  String get planRequestButton;

  /// No description provided for @planImportButton.
  ///
  /// In tr, this message translates to:
  /// **'İçeri al'**
  String get planImportButton;

  /// No description provided for @planDayCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String planDayCount(Object count);

  /// No description provided for @planWeekLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hafta {week}'**
  String planWeekLabel(Object week);

  /// No description provided for @planLegendDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get planLegendDone;

  /// No description provided for @planLegendPartial.
  ///
  /// In tr, this message translates to:
  /// **'Kısmen'**
  String get planLegendPartial;

  /// No description provided for @planLegendFree.
  ///
  /// In tr, this message translates to:
  /// **'Serbest'**
  String get planLegendFree;

  /// No description provided for @planLegendWorkout.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman ▲'**
  String get planLegendWorkout;

  /// No description provided for @planGoalDaily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get planGoalDaily;

  /// No description provided for @planGoalProtein.
  ///
  /// In tr, this message translates to:
  /// **'Protein'**
  String get planGoalProtein;

  /// No description provided for @planGoalWater.
  ///
  /// In tr, this message translates to:
  /// **'Su'**
  String get planGoalWater;

  /// No description provided for @planGoalTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get planGoalTarget;

  /// No description provided for @planNutritionRules.
  ///
  /// In tr, this message translates to:
  /// **'Beslenme kuralları'**
  String get planNutritionRules;

  /// No description provided for @planRulesForbidden.
  ///
  /// In tr, this message translates to:
  /// **'Kesinlikle yok'**
  String get planRulesForbidden;

  /// No description provided for @planRulesFree.
  ///
  /// In tr, this message translates to:
  /// **'Serbest'**
  String get planRulesFree;

  /// No description provided for @planWeekdayInitials.
  ///
  /// In tr, this message translates to:
  /// **'P,S,Ç,P,C,C,P'**
  String get planWeekdayInitials;

  /// No description provided for @planMonthNames.
  ///
  /// In tr, this message translates to:
  /// **'Ocak,Şubat,Mart,Nisan,Mayıs,Haziran,Temmuz,Ağustos,Eylül,Ekim,Kasım,Aralık'**
  String get planMonthNames;

  /// No description provided for @planCellToday.
  ///
  /// In tr, this message translates to:
  /// **'bugün'**
  String get planCellToday;

  /// No description provided for @planCellDone.
  ///
  /// In tr, this message translates to:
  /// **'tamamlandı'**
  String get planCellDone;

  /// No description provided for @planCellEmpty.
  ///
  /// In tr, this message translates to:
  /// **'kayıt yok'**
  String get planCellEmpty;

  /// No description provided for @planCellFuture.
  ///
  /// In tr, this message translates to:
  /// **'henüz gelmedi'**
  String get planCellFuture;

  /// No description provided for @planCellFreeSpoken.
  ///
  /// In tr, this message translates to:
  /// **'serbest gün'**
  String get planCellFreeSpoken;

  /// No description provided for @reminderSlotFallbackTitle.
  ///
  /// In tr, this message translates to:
  /// **'Programda bir adım'**
  String get reminderSlotFallbackTitle;

  /// No description provided for @reminderSlotWorkoutBody.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman vakti. Hazırsan başlayalım.'**
  String get reminderSlotWorkoutBody;

  /// No description provided for @reminderSlotOtherBody.
  ///
  /// In tr, this message translates to:
  /// **'Programdaki sıradaki adım.'**
  String get reminderSlotOtherBody;

  /// No description provided for @reminderWeighInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sabah tartısı'**
  String get reminderWeighInTitle;

  /// No description provided for @reminderWeighInBody.
  ///
  /// In tr, this message translates to:
  /// **'Aç karnına, aynı koşullarda tartıl.'**
  String get reminderWeighInBody;

  /// No description provided for @reminderMissStreakTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zincir kopuyor'**
  String get reminderMissStreakTitle;

  /// No description provided for @reminderMissStreakBody.
  ///
  /// In tr, this message translates to:
  /// **'Antrenmanı iki gün üst üste kaçırdın. Bugün kısa bir şey yapmak, hiç yapmamaktan iyi.'**
  String get reminderMissStreakBody;

  /// No description provided for @reminderDueLabTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil zamanı'**
  String get reminderDueLabTitle;

  /// No description provided for @reminderDueLabBody.
  ///
  /// In tr, this message translates to:
  /// **'{marker} tahlilinin vakti geldi.'**
  String reminderDueLabBody(Object marker);

  /// No description provided for @reminderPlanEndingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Plan bitiyor'**
  String get reminderPlanEndingTitle;

  /// No description provided for @reminderPlanEndingToday.
  ///
  /// In tr, this message translates to:
  /// **'Plan bugün bitiyor. Yeni plan için bağlam dosyasını al.'**
  String get reminderPlanEndingToday;

  /// No description provided for @reminderPlanEndingIn.
  ///
  /// In tr, this message translates to:
  /// **'Plan {days} gün sonra bitiyor. Yeni planı hazırlamanın vakti.'**
  String reminderPlanEndingIn(Object days);

  /// No description provided for @supplementsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takviye ve ilaçlar'**
  String get supplementsTitle;

  /// No description provided for @supplementsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Vitamin, takviye, ilaç — saatini gir, Bugün ekranında işaretle.'**
  String get supplementsDescription;

  /// No description provided for @supplementsOpen.
  ///
  /// In tr, this message translates to:
  /// **'Takviye listesi'**
  String get supplementsOpen;

  /// No description provided for @supplementsEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takviye eklenmemiş'**
  String get supplementsEmptyTitle;

  /// No description provided for @supplementsEmptyDescription.
  ///
  /// In tr, this message translates to:
  /// **'Vitamin, ilaç, ne alıyorsan ekle. Saatini girersen hatırlatma da kurulur.'**
  String get supplementsEmptyDescription;

  /// No description provided for @supplementAddFab.
  ///
  /// In tr, this message translates to:
  /// **'Takviye'**
  String get supplementAddFab;

  /// No description provided for @supplementAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takviye ekle'**
  String get supplementAddTitle;

  /// No description provided for @supplementEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Takviyeyi düzenle'**
  String get supplementEditTitle;

  /// No description provided for @supplementNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get supplementNameLabel;

  /// No description provided for @supplementNameHint.
  ///
  /// In tr, this message translates to:
  /// **'D Vitamini'**
  String get supplementNameHint;

  /// No description provided for @supplementNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Ad gerekli'**
  String get supplementNameRequired;

  /// No description provided for @supplementDoseLabel.
  ///
  /// In tr, this message translates to:
  /// **'Doz'**
  String get supplementDoseLabel;

  /// No description provided for @supplementDoseHint.
  ///
  /// In tr, this message translates to:
  /// **'1000'**
  String get supplementDoseHint;

  /// No description provided for @supplementUnitLabel.
  ///
  /// In tr, this message translates to:
  /// **'Birim'**
  String get supplementUnitLabel;

  /// No description provided for @supplementUnitHint.
  ///
  /// In tr, this message translates to:
  /// **'IU'**
  String get supplementUnitHint;

  /// No description provided for @supplementNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get supplementNoteLabel;

  /// No description provided for @supplementNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Yemekle birlikte'**
  String get supplementNoteHint;

  /// No description provided for @supplementTimesSection.
  ///
  /// In tr, this message translates to:
  /// **'Saatler'**
  String get supplementTimesSection;

  /// No description provided for @supplementTimesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Saat eklenmedi — hatırlatma kurulmaz.'**
  String get supplementTimesEmpty;

  /// No description provided for @supplementAddTime.
  ///
  /// In tr, this message translates to:
  /// **'Saat ekle'**
  String get supplementAddTime;

  /// No description provided for @supplementDaysSection.
  ///
  /// In tr, this message translates to:
  /// **'Günler'**
  String get supplementDaysSection;

  /// No description provided for @supplementEveryDay.
  ///
  /// In tr, this message translates to:
  /// **'Her gün'**
  String get supplementEveryDay;

  /// No description provided for @supplementDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" silinsin mi?'**
  String supplementDeleteTitle(Object name);

  /// No description provided for @supplementDeleteBody.
  ///
  /// In tr, this message translates to:
  /// **'Listeden ve hatırlatmalardan kalkar. Geçmiş kayıtların durur — hiçbir şey kaybolmaz.'**
  String get supplementDeleteBody;

  /// No description provided for @supplementTakenSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{name}, {time}, alındı'**
  String supplementTakenSemantics(Object name, Object time);

  /// No description provided for @supplementNotTakenSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{name}, {time}, alınmadı'**
  String supplementNotTakenSemantics(Object name, Object time);

  /// No description provided for @supplementSectionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Takviye'**
  String get supplementSectionLabel;

  /// No description provided for @reminderSupplementBody.
  ///
  /// In tr, this message translates to:
  /// **'Alma vakti geldi.'**
  String get reminderSupplementBody;

  /// No description provided for @reminderSupplementBodyWithDose.
  ///
  /// In tr, this message translates to:
  /// **'{dose} — alma vakti geldi.'**
  String reminderSupplementBodyWithDose(Object dose);

  /// No description provided for @equipmentBodyOnly.
  ///
  /// In tr, this message translates to:
  /// **'Vücut ağırlığı'**
  String get equipmentBodyOnly;

  /// No description provided for @equipmentBarbell.
  ///
  /// In tr, this message translates to:
  /// **'Halter'**
  String get equipmentBarbell;

  /// No description provided for @equipmentDumbbell.
  ///
  /// In tr, this message translates to:
  /// **'Dambıl'**
  String get equipmentDumbbell;

  /// No description provided for @equipmentKettlebell.
  ///
  /// In tr, this message translates to:
  /// **'Kettlebell'**
  String get equipmentKettlebell;

  /// No description provided for @equipmentCable.
  ///
  /// In tr, this message translates to:
  /// **'Kablo makinesi'**
  String get equipmentCable;

  /// No description provided for @equipmentMachine.
  ///
  /// In tr, this message translates to:
  /// **'Makine'**
  String get equipmentMachine;

  /// No description provided for @equipmentBands.
  ///
  /// In tr, this message translates to:
  /// **'Direnç bandı'**
  String get equipmentBands;

  /// No description provided for @equipmentMedicineBall.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık topu'**
  String get equipmentMedicineBall;

  /// No description provided for @equipmentExerciseBall.
  ///
  /// In tr, this message translates to:
  /// **'Pilates topu'**
  String get equipmentExerciseBall;

  /// No description provided for @equipmentFoamRoll.
  ///
  /// In tr, this message translates to:
  /// **'Köpük rulo'**
  String get equipmentFoamRoll;

  /// No description provided for @equipmentEzCurlBar.
  ///
  /// In tr, this message translates to:
  /// **'Z bar'**
  String get equipmentEzCurlBar;

  /// No description provided for @equipmentOther.
  ///
  /// In tr, this message translates to:
  /// **'Ev eşyası'**
  String get equipmentOther;

  /// No description provided for @equipmentNone.
  ///
  /// In tr, this message translates to:
  /// **'Ekipman gerekmiyor'**
  String get equipmentNone;

  /// No description provided for @equipmentPullUpBar.
  ///
  /// In tr, this message translates to:
  /// **'Barfiks demiri'**
  String get equipmentPullUpBar;

  /// No description provided for @equipmentDipBars.
  ///
  /// In tr, this message translates to:
  /// **'Paralel bar'**
  String get equipmentDipBars;

  /// No description provided for @equipmentBench.
  ///
  /// In tr, this message translates to:
  /// **'Sehpa'**
  String get equipmentBench;

  /// No description provided for @equipmentJumpRope.
  ///
  /// In tr, this message translates to:
  /// **'Atlama ipi'**
  String get equipmentJumpRope;

  /// No description provided for @catalogEquipmentMissingHome.
  ///
  /// In tr, this message translates to:
  /// **'{equipment} gerekiyor (evinde yok)'**
  String catalogEquipmentMissingHome(Object equipment);

  /// No description provided for @catalogEquipmentMissingGym.
  ///
  /// In tr, this message translates to:
  /// **'{equipment} gerekiyor (salonunda yok)'**
  String catalogEquipmentMissingGym(Object equipment);

  /// No description provided for @foodSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Besin ara'**
  String get foodSearchHint;

  /// No description provided for @foodSearchEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bulunamadı'**
  String get foodSearchEmptyTitle;

  /// No description provided for @foodSearchEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Daha kısa bir sözcük dene ya da diğer dilde ara.'**
  String get foodSearchEmptyMessage;

  /// No description provided for @foodStartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kayıt yok'**
  String get foodStartTitle;

  /// No description provided for @foodStartMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bir besin ara ya da yukarıdan tür seç.'**
  String get foodStartMessage;

  /// No description provided for @foodFrequentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sık yediklerin'**
  String get foodFrequentTitle;

  /// No description provided for @foodCopyLastMeal.
  ///
  /// In tr, this message translates to:
  /// **'Bu öğünü son seferkinden kopyala'**
  String get foodCopyLastMeal;

  /// No description provided for @foodCopyDone.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, one{1 kalem kopyalandı} other{{count} kalem kopyalandı}}'**
  String foodCopyDone(int count);

  /// No description provided for @foodCopyNothingToCopy.
  ///
  /// In tr, this message translates to:
  /// **'Bu öğünde daha önce kayıt yok'**
  String get foodCopyNothingToCopy;

  /// No description provided for @foodPer100g.
  ///
  /// In tr, this message translates to:
  /// **'100 g\'da {kcal} kcal'**
  String foodPer100g(int kcal);

  /// No description provided for @foodPerPortion.
  ///
  /// In tr, this message translates to:
  /// **'{portion} — {kcal} kcal'**
  String foodPerPortion(String portion, int kcal);

  /// No description provided for @foodCategoryYemek.
  ///
  /// In tr, this message translates to:
  /// **'Yemek'**
  String get foodCategoryYemek;

  /// No description provided for @foodCategoryCorba.
  ///
  /// In tr, this message translates to:
  /// **'Çorba'**
  String get foodCategoryCorba;

  /// No description provided for @foodCategoryKahvaltilik.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltılık'**
  String get foodCategoryKahvaltilik;

  /// No description provided for @foodCategoryMeyve.
  ///
  /// In tr, this message translates to:
  /// **'Meyve'**
  String get foodCategoryMeyve;

  /// No description provided for @foodCategorySebze.
  ///
  /// In tr, this message translates to:
  /// **'Sebze'**
  String get foodCategorySebze;

  /// No description provided for @foodCategoryKuruyemis.
  ///
  /// In tr, this message translates to:
  /// **'Kuruyemiş'**
  String get foodCategoryKuruyemis;

  /// No description provided for @foodCategoryIcecek.
  ///
  /// In tr, this message translates to:
  /// **'İçecek'**
  String get foodCategoryIcecek;

  /// No description provided for @foodCategoryTahil.
  ///
  /// In tr, this message translates to:
  /// **'Tahıl'**
  String get foodCategoryTahil;

  /// No description provided for @foodCategoryEtBalik.
  ///
  /// In tr, this message translates to:
  /// **'Et ve balık'**
  String get foodCategoryEtBalik;

  /// No description provided for @foodCategorySutUrunu.
  ///
  /// In tr, this message translates to:
  /// **'Süt ürünü'**
  String get foodCategorySutUrunu;

  /// No description provided for @foodCategoryAtistirmalik.
  ///
  /// In tr, this message translates to:
  /// **'Atıştırmalık'**
  String get foodCategoryAtistirmalik;

  /// No description provided for @foodCategoryDiger.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get foodCategoryDiger;

  /// No description provided for @mealKahvalti.
  ///
  /// In tr, this message translates to:
  /// **'Kahvaltı'**
  String get mealKahvalti;

  /// No description provided for @mealAraOgun.
  ///
  /// In tr, this message translates to:
  /// **'Kuşluk'**
  String get mealAraOgun;

  /// No description provided for @mealOgle.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get mealOgle;

  /// No description provided for @mealIkindi.
  ///
  /// In tr, this message translates to:
  /// **'İkindi'**
  String get mealIkindi;

  /// No description provided for @mealAksam.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get mealAksam;

  /// No description provided for @mealGece.
  ///
  /// In tr, this message translates to:
  /// **'Gece'**
  String get mealGece;

  /// No description provided for @portionUnitGrams100.
  ///
  /// In tr, this message translates to:
  /// **'100 g'**
  String get portionUnitGrams100;

  /// No description provided for @portionCustomGramsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tarttın mı?'**
  String get portionCustomGramsLabel;

  /// No description provided for @portionCustomGramsHelper.
  ///
  /// In tr, this message translates to:
  /// **'Gram girersen porsiyonun yerine geçer'**
  String get portionCustomGramsHelper;

  /// No description provided for @portionGrams.
  ///
  /// In tr, this message translates to:
  /// **'MİKTAR'**
  String get portionGrams;

  /// No description provided for @portionKcal.
  ///
  /// In tr, this message translates to:
  /// **'KALORİ'**
  String get portionKcal;

  /// No description provided for @portionProtein.
  ///
  /// In tr, this message translates to:
  /// **'PROTEİN'**
  String get portionProtein;

  /// No description provided for @portionAddToMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğüne ekle'**
  String get portionAddToMeal;

  /// No description provided for @portionDecrease.
  ///
  /// In tr, this message translates to:
  /// **'Bir azalt'**
  String get portionDecrease;

  /// No description provided for @portionIncrease.
  ///
  /// In tr, this message translates to:
  /// **'Bir artır'**
  String get portionIncrease;

  /// No description provided for @activityLogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite ekle'**
  String get activityLogTitle;

  /// No description provided for @activitySearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite ara'**
  String get activitySearchHint;

  /// No description provided for @activityMinutesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dakika'**
  String get activityMinutesLabel;

  /// No description provided for @activityAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get activityAdd;

  /// No description provided for @activityEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşen aktivite yok'**
  String get activityEmptyTitle;

  /// No description provided for @activityEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir sözcük dene ya da aşağıdan kendin ekle.'**
  String get activityEmptyMessage;

  /// No description provided for @effortLight.
  ///
  /// In tr, this message translates to:
  /// **'Hafif'**
  String get effortLight;

  /// No description provided for @effortModerate.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get effortModerate;

  /// No description provided for @effortVigorous.
  ///
  /// In tr, this message translates to:
  /// **'Zorlu'**
  String get effortVigorous;

  /// No description provided for @todayMealsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğünler'**
  String get todayMealsTitle;

  /// No description provided for @todayActivitiesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hareket'**
  String get todayActivitiesTitle;

  /// No description provided for @todayAddMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün ekle'**
  String get todayAddMeal;

  /// No description provided for @todayAddActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktivite ekle'**
  String get todayAddActivity;

  /// No description provided for @todayHeroRemaining.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN KALAN'**
  String get todayHeroRemaining;

  /// No description provided for @todayHeroEatenNoPlan.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN YENEN'**
  String get todayHeroEatenNoPlan;

  /// No description provided for @todayMetricWater.
  ///
  /// In tr, this message translates to:
  /// **'SU'**
  String get todayMetricWater;

  /// No description provided for @todayMetricMeds.
  ///
  /// In tr, this message translates to:
  /// **'İLAÇ'**
  String get todayMetricMeds;

  /// No description provided for @todayMetricProtein.
  ///
  /// In tr, this message translates to:
  /// **'PROTEİN'**
  String get todayMetricProtein;

  /// No description provided for @todayMetricBurned.
  ///
  /// In tr, this message translates to:
  /// **'YAKILAN'**
  String get todayMetricBurned;

  /// No description provided for @mealEntryRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Kaldırıldı'**
  String get mealEntryRemoved;

  /// No description provided for @progressCaloriesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftanın kalorisi'**
  String get progressCaloriesTitle;

  /// No description provided for @progressCaloriesGoalLine.
  ///
  /// In tr, this message translates to:
  /// **'Hedef'**
  String get progressCaloriesGoalLine;

  /// No description provided for @progressDayBreakdown.
  ///
  /// In tr, this message translates to:
  /// **'{date} dökümü'**
  String progressDayBreakdown(String date);

  /// No description provided for @catalogTabOutside.
  ///
  /// In tr, this message translates to:
  /// **'Dışarıda'**
  String get catalogTabOutside;

  /// No description provided for @dayBadgePast.
  ///
  /// In tr, this message translates to:
  /// **'GEÇMİŞ GÜN'**
  String get dayBadgePast;

  /// No description provided for @dayBadgeFuture.
  ///
  /// In tr, this message translates to:
  /// **'PLANLANAN GÜN'**
  String get dayBadgeFuture;

  /// No description provided for @dayBackToToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugüne dön'**
  String get dayBackToToday;

  /// No description provided for @dayPrevious.
  ///
  /// In tr, this message translates to:
  /// **'Önceki gün'**
  String get dayPrevious;

  /// No description provided for @dayNext.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki gün'**
  String get dayNext;

  /// No description provided for @dayPickDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get dayPickDate;

  /// No description provided for @dayFutureNoEntry.
  ///
  /// In tr, this message translates to:
  /// **'Planı görebilirsin ama kayıt günü gelince girilir.'**
  String get dayFutureNoEntry;

  /// No description provided for @planSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Plan ayarları'**
  String get planSettingsTitle;

  /// No description provided for @planSettingsName.
  ///
  /// In tr, this message translates to:
  /// **'Plan adı'**
  String get planSettingsName;

  /// No description provided for @planSettingsNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Plana bir ad ver'**
  String get planSettingsNameRequired;

  /// No description provided for @planSettingsGoals.
  ///
  /// In tr, this message translates to:
  /// **'Hedefler'**
  String get planSettingsGoals;

  /// No description provided for @planGoalKcal.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kalori'**
  String get planGoalKcal;

  /// No description provided for @planGoalWeeklyGym.
  ///
  /// In tr, this message translates to:
  /// **'Haftada salon günü'**
  String get planGoalWeeklyGym;

  /// No description provided for @planGoalWeeklyHome.
  ///
  /// In tr, this message translates to:
  /// **'Haftada ev günü'**
  String get planGoalWeeklyHome;

  /// No description provided for @planGoalTargetLoss.
  ///
  /// In tr, this message translates to:
  /// **'Hedef kayıp (kg)'**
  String get planGoalTargetLoss;

  /// No description provided for @planGoalRange.
  ///
  /// In tr, this message translates to:
  /// **'{min} ile {max} arasında bir değer gir'**
  String planGoalRange(String min, String max);

  /// No description provided for @planRuleAdd.
  ///
  /// In tr, this message translates to:
  /// **'Satır ekle'**
  String get planRuleAdd;

  /// No description provided for @commonRemove.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get commonRemove;

  /// No description provided for @commonAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get commonAdd;

  /// No description provided for @planEditDay.
  ///
  /// In tr, this message translates to:
  /// **'Günü düzenle'**
  String get planEditDay;

  /// No description provided for @planDayType.
  ///
  /// In tr, this message translates to:
  /// **'Gün tipi'**
  String get planDayType;

  /// No description provided for @planDayTypeGym.
  ///
  /// In tr, this message translates to:
  /// **'Salon'**
  String get planDayTypeGym;

  /// No description provided for @planDayTypeHome.
  ///
  /// In tr, this message translates to:
  /// **'Ev'**
  String get planDayTypeHome;

  /// No description provided for @planDayTypeRest.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme'**
  String get planDayTypeRest;

  /// No description provided for @planDayHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get planDayHeadline;

  /// No description provided for @planDayDinner.
  ///
  /// In tr, this message translates to:
  /// **'Akşam önerisi'**
  String get planDayDinner;

  /// No description provided for @planSlotNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni slot'**
  String get planSlotNew;

  /// No description provided for @planSlotEdit.
  ///
  /// In tr, this message translates to:
  /// **'Slotu düzenle'**
  String get planSlotEdit;

  /// No description provided for @planSlotTime.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get planSlotTime;

  /// No description provided for @planSlotKind.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get planSlotKind;

  /// No description provided for @planSlotLabel.
  ///
  /// In tr, this message translates to:
  /// **'Etiket'**
  String get planSlotLabel;

  /// No description provided for @planSlotNote.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get planSlotNote;

  /// No description provided for @planSlotMealKind.
  ///
  /// In tr, this message translates to:
  /// **'Hangi öğün'**
  String get planSlotMealKind;

  /// No description provided for @planSlotMealKindRequired.
  ///
  /// In tr, this message translates to:
  /// **'Hangi öğün olduğunu seç'**
  String get planSlotMealKindRequired;

  /// No description provided for @planSlotLabelRequired.
  ///
  /// In tr, this message translates to:
  /// **'Slota bir etiket ver'**
  String get planSlotLabelRequired;

  /// No description provided for @planExerciseNew.
  ///
  /// In tr, this message translates to:
  /// **'Hareket ekle'**
  String get planExerciseNew;

  /// No description provided for @planExerciseEdit.
  ///
  /// In tr, this message translates to:
  /// **'Hareketi düzenle'**
  String get planExerciseEdit;

  /// No description provided for @planExercisePick.
  ///
  /// In tr, this message translates to:
  /// **'Katalogdan seç'**
  String get planExercisePick;

  /// No description provided for @planExerciseSets.
  ///
  /// In tr, this message translates to:
  /// **'Set'**
  String get planExerciseSets;

  /// No description provided for @planExerciseReps.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar'**
  String get planExerciseReps;

  /// No description provided for @planExerciseDuration.
  ///
  /// In tr, this message translates to:
  /// **'Süre (dk)'**
  String get planExerciseDuration;

  /// No description provided for @planExerciseRest.
  ///
  /// In tr, this message translates to:
  /// **'Dinlenme (sn)'**
  String get planExerciseRest;

  /// No description provided for @planExerciseSpeed.
  ///
  /// In tr, this message translates to:
  /// **'Hız (km/sa)'**
  String get planExerciseSpeed;

  /// No description provided for @planExerciseGrade.
  ///
  /// In tr, this message translates to:
  /// **'Eğim (%)'**
  String get planExerciseGrade;

  /// No description provided for @planExerciseEffort.
  ///
  /// In tr, this message translates to:
  /// **'Efor'**
  String get planExerciseEffort;

  /// No description provided for @planExerciseRequired.
  ///
  /// In tr, this message translates to:
  /// **'Önce bir hareket seç'**
  String get planExerciseRequired;

  /// No description provided for @planOriginAiEdited.
  ///
  /// In tr, this message translates to:
  /// **'AI planı · düzenlendi'**
  String get planOriginAiEdited;

  /// No description provided for @planOriginManual.
  ///
  /// In tr, this message translates to:
  /// **'Elle kuruldu'**
  String get planOriginManual;

  /// No description provided for @planCreateEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Boş plan kur'**
  String get planCreateEmpty;

  /// No description provided for @planCreateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni plan'**
  String get planCreateTitle;

  /// No description provided for @planCreateWeeks.
  ///
  /// In tr, this message translates to:
  /// **'Hafta'**
  String get planCreateWeeks;

  /// No description provided for @planCreateStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç tarihi'**
  String get planCreateStart;

  /// No description provided for @planCreateDone.
  ///
  /// In tr, this message translates to:
  /// **'Kur'**
  String get planCreateDone;

  /// No description provided for @dailyRhythmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Düzen'**
  String get dailyRhythmTitle;

  /// No description provided for @dailyRhythmDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ne zaman kalkıyorsun, ne zaman yatıyorsun, ne zaman ulaşılamıyorsun.'**
  String get dailyRhythmDescription;

  /// No description provided for @dailyRhythmWake.
  ///
  /// In tr, this message translates to:
  /// **'Kalkış'**
  String get dailyRhythmWake;

  /// No description provided for @dailyRhythmSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get dailyRhythmSleep;

  /// No description provided for @slotKindMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün'**
  String get slotKindMeal;

  /// No description provided for @slotKindWorkout.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman'**
  String get slotKindWorkout;

  /// No description provided for @slotKindSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get slotKindSleep;

  /// No description provided for @slotKindMeasurement.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm'**
  String get slotKindMeasurement;

  /// No description provided for @slotKindLab.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil'**
  String get slotKindLab;

  /// No description provided for @slotKindOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get slotKindOther;

  /// No description provided for @tabHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get tabHome;

  /// No description provided for @tabDiet.
  ///
  /// In tr, this message translates to:
  /// **'Diyet'**
  String get tabDiet;

  /// No description provided for @tabSport.
  ///
  /// In tr, this message translates to:
  /// **'Spor'**
  String get tabSport;

  /// No description provided for @tabMore.
  ///
  /// In tr, this message translates to:
  /// **'Daha'**
  String get tabMore;

  /// No description provided for @tabHomeHint.
  ///
  /// In tr, this message translates to:
  /// **'Günün özeti ve akışı'**
  String get tabHomeHint;

  /// No description provided for @tabDietHint.
  ///
  /// In tr, this message translates to:
  /// **'Öğünler, besinler, kalori geçmişi'**
  String get tabDietHint;

  /// No description provided for @tabSportHint.
  ///
  /// In tr, this message translates to:
  /// **'Plan, antrenman, hareket kataloğu'**
  String get tabSportHint;

  /// No description provided for @tabMoreHint.
  ///
  /// In tr, this message translates to:
  /// **'Verilerin ve uygulama ayarları'**
  String get tabMoreHint;

  /// No description provided for @dietTabDaily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get dietTabDaily;

  /// No description provided for @dietTabFoods.
  ///
  /// In tr, this message translates to:
  /// **'Besinler'**
  String get dietTabFoods;

  /// No description provided for @dietTabHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get dietTabHistory;

  /// No description provided for @sportTabPlan.
  ///
  /// In tr, this message translates to:
  /// **'Plan'**
  String get sportTabPlan;

  /// No description provided for @sportTabWorkout.
  ///
  /// In tr, this message translates to:
  /// **'Antrenman'**
  String get sportTabWorkout;

  /// No description provided for @sportTabCatalog.
  ///
  /// In tr, this message translates to:
  /// **'Katalog'**
  String get sportTabCatalog;

  /// No description provided for @healthTabLabs.
  ///
  /// In tr, this message translates to:
  /// **'Tahlil'**
  String get healthTabLabs;

  /// No description provided for @healthTabMeasure.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm'**
  String get healthTabMeasure;

  /// No description provided for @healthTabMeds.
  ///
  /// In tr, this message translates to:
  /// **'İlaç'**
  String get healthTabMeds;

  /// No description provided for @sportWorkoutEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz seans yok'**
  String get sportWorkoutEmptyTitle;

  /// No description provided for @sportWorkoutEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Antrenmanı plandan başlat; biten seanslar burada görünür.'**
  String get sportWorkoutEmptyMessage;

  /// No description provided for @moreYourData.
  ///
  /// In tr, this message translates to:
  /// **'Planını etkileyenler'**
  String get moreYourData;

  /// No description provided for @moreYourDataHint.
  ///
  /// In tr, this message translates to:
  /// **'AI\'a gider'**
  String get moreYourDataHint;

  /// No description provided for @moreApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama'**
  String get moreApp;

  /// No description provided for @moreProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get moreProfile;

  /// No description provided for @moreEquipment.
  ///
  /// In tr, this message translates to:
  /// **'Ekipmanların'**
  String get moreEquipment;

  /// No description provided for @moreRhythm.
  ///
  /// In tr, this message translates to:
  /// **'Günlük düzen'**
  String get moreRhythm;

  /// No description provided for @moreRules.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kurallar'**
  String get moreRules;

  /// No description provided for @moreNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get moreNotifications;

  /// No description provided for @moreAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm ve dil'**
  String get moreAppearance;

  /// No description provided for @moreBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme'**
  String get moreBackup;

  /// No description provided for @sleepBlockTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get sleepBlockTitle;

  /// No description provided for @sleepBedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yatış'**
  String get sleepBedLabel;

  /// No description provided for @sleepWakeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kalkış'**
  String get sleepWakeLabel;

  /// No description provided for @sleepNapLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kestirme'**
  String get sleepNapLabel;

  /// No description provided for @sleepNapUnit.
  ///
  /// In tr, this message translates to:
  /// **'dk'**
  String get sleepNapUnit;

  /// No description provided for @sleepHoursOnlyLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız süre'**
  String get sleepHoursOnlyLabel;

  /// No description provided for @sleepHoursUnit.
  ///
  /// In tr, this message translates to:
  /// **'sa'**
  String get sleepHoursUnit;

  /// No description provided for @sleepTotal.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk uyku'**
  String sleepTotal(Object hours, Object minutes);

  /// No description provided for @sleepPickTime.
  ///
  /// In tr, this message translates to:
  /// **'Saat seç'**
  String get sleepPickTime;

  /// No description provided for @sleepClear.
  ///
  /// In tr, this message translates to:
  /// **'Saatleri temizle'**
  String get sleepClear;

  /// No description provided for @dayFlowEnterMeal.
  ///
  /// In tr, this message translates to:
  /// **'+ GİR'**
  String get dayFlowEnterMeal;

  /// No description provided for @dayFlowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün akışı'**
  String get dayFlowTitle;

  /// No description provided for @dayFlowWeighIn.
  ///
  /// In tr, this message translates to:
  /// **'Tartı'**
  String get dayFlowWeighIn;

  /// No description provided for @dayFlowCollapse.
  ///
  /// In tr, this message translates to:
  /// **'Daha az göster'**
  String get dayFlowCollapse;

  /// No description provided for @dayFlowExpand.
  ///
  /// In tr, this message translates to:
  /// **'Günün tamamı ({count})'**
  String dayFlowExpand(int count);

  /// No description provided for @equipmentChair.
  ///
  /// In tr, this message translates to:
  /// **'Sandalye'**
  String get equipmentChair;

  /// No description provided for @equipmentStep.
  ///
  /// In tr, this message translates to:
  /// **'Basamak / merdiven'**
  String get equipmentStep;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
