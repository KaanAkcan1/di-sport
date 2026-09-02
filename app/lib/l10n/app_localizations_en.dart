// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabToday => 'Today';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabHealth => 'Health';

  @override
  String get tabHealthHint => 'Lab results and measurements';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonRetry => 'Try again';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceDescription =>
      'Dark is how the app is meant to look — readable in the gym and before sunrise.';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceLight => 'Light';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageDescription =>
      'Interface language. Exercise and food names stay searchable in both.';

  @override
  String get languageSystem => 'System';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get catalogTabHome => 'At home';

  @override
  String get catalogTabGym => 'At the gym';

  @override
  String get catalogFilters => 'Filters';

  @override
  String get catalogSearchHint => 'Search exercise or muscle…';

  @override
  String get catalogClearSearch => 'Clear search';

  @override
  String get catalogClearFilters => 'Clear filters';

  @override
  String get catalogRecentSection => 'Recently done';

  @override
  String get catalogExercisesSection => 'Exercises';

  @override
  String get catalogAllExercisesSection => 'All exercises';

  @override
  String get catalogNoResults => 'No matching exercise';

  @override
  String get catalogNoResultsDescription =>
      'Change your search or remove the filters.';

  @override
  String get catalogOnlyMyEquipment => 'Fits my equipment';

  @override
  String get catalogOnlyMyEquipmentDescription =>
      'Hides exercises that need equipment you do not own.';

  @override
  String get catalogCategorySection => 'Type';

  @override
  String get catalogCategoryStrength => 'Strength';

  @override
  String get catalogCategoryCore => 'Core';

  @override
  String get catalogCategoryCardio => 'Cardio';

  @override
  String get catalogCategoryMobility => 'Mobility';

  @override
  String get catalogDifficultySection => 'Difficulty';

  @override
  String catalogDifficultyChip(Object level) {
    return 'Difficulty $level';
  }

  @override
  String catalogDifficultyOutOfFive(Object level) {
    return 'Difficulty $level/5';
  }

  @override
  String catalogDifficultySemantics(Object level) {
    return 'Difficulty $level out of 5';
  }

  @override
  String catalogResultCount(Object count) {
    return '$count exercises';
  }

  @override
  String get catalogLocationHome => 'Home';

  @override
  String get catalogLocationGym => 'Gym';

  @override
  String get catalogLocationBoth => 'Home / Gym';

  @override
  String catalogLocationSemantics(Object place) {
    return 'Can be done at: $place';
  }

  @override
  String get catalogEquipmentTitle => 'My equipment';

  @override
  String get catalogEquipmentAddFab => 'Equipment';

  @override
  String get catalogEquipmentAddTitle => 'Add equipment';

  @override
  String get catalogEquipmentFieldLabel => 'Equipment';

  @override
  String get catalogEquipmentFieldHint => 'Kettlebell';

  @override
  String get catalogEquipmentAddAction => 'Add';

  @override
  String get catalogExerciseNotFound => 'Exercise not found';

  @override
  String get catalogExerciseNotFoundDescription =>
      'This exercise may have been removed from the catalogue.';

  @override
  String get catalogExerciseLoadError => 'Could not open the exercise';

  @override
  String get catalogTabSteps => 'Steps';

  @override
  String get catalogTabMistakes => 'Mistakes';

  @override
  String get catalogTabVariants => 'Variants';

  @override
  String get catalogTabSafety => 'Safety';

  @override
  String get catalogCuesTitle => 'Keep in mind';

  @override
  String get catalogCuesDescription => 'Check these while you train.';

  @override
  String get catalogSetupTitle => 'Setup';

  @override
  String get catalogExecutionTitle => 'Execution';

  @override
  String get catalogBreathingTempoTitle => 'Breathing and tempo';

  @override
  String get catalogBreathingLabel => 'Breathing';

  @override
  String get catalogTempoLabel => 'Tempo';

  @override
  String get catalogNoMistakes => 'No mistakes recorded';

  @override
  String get catalogMistakeWhy => 'Why it matters';

  @override
  String get catalogMistakeFix => 'The fix';

  @override
  String get catalogNoVariants => 'No variants defined';

  @override
  String get catalogNoVariantsDescription =>
      'No easier or harder version of this exercise is recorded.';

  @override
  String get catalogRegressionsTitle => 'Make it easier';

  @override
  String get catalogRegressionsDescription =>
      'Start here if it feels too hard.';

  @override
  String get catalogProgressionsTitle => 'Make it harder';

  @override
  String get catalogProgressionsDescription =>
      'The next step once it starts feeling easy.';

  @override
  String get catalogSafetyDisclaimer =>
      'This information is general and does not replace assessment by a physician or physiotherapist. Stop the movement if you feel pain.';

  @override
  String catalogImageSemantics(Object name) {
    return 'Start and end position of $name';
  }

  @override
  String get catalogMetaTitle => 'Details';

  @override
  String get catalogTargetMuscles => 'Target muscles';

  @override
  String get catalogEquipmentLabel => 'Equipment';

  @override
  String get workoutTitle => 'Workout';

  @override
  String get workoutNoExercisesTitle => 'No exercises today';

  @override
  String get workoutNoExercisesDescription =>
      'This day is planned as a rest day.';

  @override
  String get workoutElapsedCaption => 'minutes into your session';

  @override
  String get workoutElapsedNew => 'new';

  @override
  String get workoutMinuteUnit => 'min';

  @override
  String get workoutSetsCaption => 'Sets';

  @override
  String get workoutExercisesCaption => 'Exercises';

  @override
  String workoutSetsProgress(Object done, Object total) {
    return '$done / $total sets';
  }

  @override
  String workoutSetsDoneSemantics(Object done, Object total) {
    return '$done of $total sets completed';
  }

  @override
  String get workoutUndoLastSet => 'Undo last set';

  @override
  String get workoutAllSetsDone => 'Completed';

  @override
  String get workoutSetDone => 'Set done';

  @override
  String get workoutRefLast => 'Last';

  @override
  String get workoutRefPlan => 'Plan';

  @override
  String workoutRestLabel(Object seconds) {
    return 'Rest · $seconds s';
  }

  @override
  String workoutRestSemantics(Object seconds) {
    return 'Rest, $seconds seconds left';
  }

  @override
  String get workoutRestSkip => 'Skip';

  @override
  String get healthNoLabsTitle => 'No lab results yet';

  @override
  String get healthNoLabsDescription =>
      'Add the lab results you have; if you enter the reference range too, I can track whether a value is low or high.';

  @override
  String get healthAddLabFab => 'Lab result';

  @override
  String get healthAddLabTitle => 'Add lab result';

  @override
  String get healthLabMarkerLabel => 'Marker name';

  @override
  String get healthLabMarkerHint => 'Vitamin D';

  @override
  String get healthLabMarkerRequired => 'Marker name is required';

  @override
  String get healthLabValueLabel => 'Value';

  @override
  String get healthLabValueInvalid => 'Enter a number';

  @override
  String get healthLabUnitLabel => 'Unit';

  @override
  String get healthLabUnitHint => 'ng/mL';

  @override
  String get healthLabRefLowLabel => 'Reference low';

  @override
  String get healthLabRefHighLabel => 'Reference high';

  @override
  String get healthLabRefHelp =>
      'Optional — without it the value is shown as \"no range\".';

  @override
  String get healthLabPanelLabel => 'Panel';

  @override
  String get healthLabNameLabel => 'Laboratory';

  @override
  String get healthLabNameHelp => 'Optional — ranges differ from lab to lab';

  @override
  String get healthLabDateLabel => 'Test date';

  @override
  String get healthMeasurementsTitle => 'Measurements';

  @override
  String get healthMeasurementsDescription =>
      'Measure once a month; the transition criteria look at your push-up count.';

  @override
  String get healthManageMetricsTooltip => 'Manage measurements';

  @override
  String get healthNoMetricsTitle => 'No measurement types';

  @override
  String get healthNoMetricsDescription =>
      'Add the measurements you want to track — waist, arm circumference, resting heart rate.';

  @override
  String get healthMetricNeverMeasured => 'not measured yet';

  @override
  String get healthDueLabsTitleOne => 'One lab test is due';

  @override
  String healthDueLabsTitleMany(Object count) {
    return '$count lab tests are due';
  }

  @override
  String healthDueInterval(Object months) {
    return 'every $months months';
  }

  @override
  String healthDueWithDate(Object marker, Object interval, Object date) {
    return '$marker — $interval, as of $date';
  }

  @override
  String healthDueNoRecord(Object marker, Object interval) {
    return '$marker — $interval, never recorded';
  }

  @override
  String healthLabRefRange(Object low, Object high) {
    return 'ref $low–$high';
  }

  @override
  String get healthLabStatusLow => 'low';

  @override
  String get healthLabStatusHigh => 'high';

  @override
  String get healthLabStatusNormal => 'normal';

  @override
  String get healthLabStatusNoRange => 'no range';

  @override
  String get healthMetricsEditorTitle => 'Measurement types';

  @override
  String get healthMetricsEditorEmptyDescription =>
      'Add your first measurement with the button below.';

  @override
  String get healthAddMetricFab => 'Measurement';

  @override
  String healthDeleteMetricTitle(Object label) {
    return 'Remove \"$label\"?';
  }

  @override
  String get healthDeleteMetricBody =>
      'Removes it from the list. The values you have entered are kept; add the type back and they reappear.';

  @override
  String get healthMetricRemove => 'Remove';

  @override
  String healthMetricDailyHint(Object unit) {
    return '$unit · daily, from the Today screen';
  }

  @override
  String get healthMetricSheetAddTitle => 'Add measurement';

  @override
  String get healthMetricSheetEditTitle => 'Edit measurement';

  @override
  String get healthMetricLabelRequired => 'Measurement name is required';

  @override
  String get healthMetricLabelLabel => 'Measurement';

  @override
  String get healthMetricLabelHint => 'Arm circumference';

  @override
  String get healthMetricUnitHint => 'cm';

  @override
  String get healthMetricDisplayTitle => 'Display';

  @override
  String get healthMetricInteger => 'Whole number';

  @override
  String get healthMetricDecimal => 'Decimal';

  @override
  String get healthMetricExampleInteger => 'Example: 12';

  @override
  String get healthMetricExampleDecimal => 'Example: 104.5';

  @override
  String get progressEmptyTitle => 'Nothing to show yet';

  @override
  String get progressEmptyDescription =>
      'Log your weight from the Today tab; after a few days the trend line starts to mean something.';

  @override
  String get progressWeightTitle => 'Weight';

  @override
  String get progressWeightDescription =>
      'The thick line is the 7-day average — daily swings are water and salt, watch the trend.';

  @override
  String get progressWeeksTitle => 'Weeks';

  @override
  String get progressNoPlanTitle => 'A plan is needed for the weekly summary';

  @override
  String get progressNoPlanDescription =>
      'I read which days are gym and which are home from the plan. Load a program from the Plan tab.';

  @override
  String get progressHeroEmptyCaption =>
      'The change will show up here after your first weigh-in';

  @override
  String get progressHeroCaption => 'kg · since your first weigh-in';

  @override
  String get progressMetricNow => 'Now';

  @override
  String get progressMetricPushups => 'Push-ups';

  @override
  String get progressMetricWeeks => 'Weeks';

  @override
  String get progressTransitionTitle => 'Transition to running';

  @override
  String get progressTransitionAllMet =>
      'All three criteria are met. You can start short running attempts.';

  @override
  String progressTransitionProgress(Object met) {
    return '$met of 3 criteria met.';
  }

  @override
  String progressCriterionWeight(Object limit) {
    return 'Weight below $limit kg';
  }

  @override
  String get progressCriterionNotWeighed => 'not weighed yet';

  @override
  String progressCriterionWeightNow(Object value) {
    return 'now $value kg';
  }

  @override
  String progressCriterionPushups(Object count) {
    return '$count push-ups without stopping';
  }

  @override
  String get progressCriterionNotMeasured => 'not measured yet';

  @override
  String progressCriterionPushupsNow(Object value) {
    return 'now $value';
  }

  @override
  String get progressCriterionPainFree => 'No knee or foot pain after walking';

  @override
  String get progressCriterionPainFreeHint =>
      'I cannot measure this — only you know.';

  @override
  String progressWeekLabel(Object index) {
    return 'Week $index';
  }

  @override
  String progressWeekPartial(Object days) {
    return 'in progress · $days days';
  }

  @override
  String get progressWeekAverage => 'weekly average';

  @override
  String get progressWeekGym => 'Gym';

  @override
  String get progressWeekHome => 'Home';

  @override
  String get progressWeekNoSlips => 'No slips';

  @override
  String progressWeekSlipDays(Object count) {
    return '$count slip days';
  }

  @override
  String progressWeekCountChip(Object label, Object done, Object target) {
    return '$label $done / $target';
  }

  @override
  String progressChartSemantics(Object count, Object first, Object last) {
    return 'Weight chart. $count measurements. First $first kilograms, last $last kilograms.';
  }

  @override
  String get commonNoRecords => 'No records';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String get commonStatusGood => 'good';

  @override
  String get commonStatusCaution => 'caution';

  @override
  String get commonStatusBad => 'problem';

  @override
  String get commonStatusUnknown => 'no data';

  @override
  String get commonValueMissing => 'no value entered';

  @override
  String commonMetricEmptySemantics(Object caption) {
    return '$caption: not entered';
  }

  @override
  String commonMetricValueSemantics(Object caption, Object value) {
    return '$caption: $value';
  }

  @override
  String commonMetricChangeSemantics(Object delta) {
    return ', change $delta';
  }

  @override
  String commonHeroValueSemantics(Object value, Object caption) {
    return '$value · $caption';
  }

  @override
  String commonNowAt(Object time) {
    return 'The time is now $time';
  }

  @override
  String get commonNowLabel => 'NOW';

  @override
  String get commonWeekDotDone => 'logged';

  @override
  String get commonWeekDotMissed => 'not logged';

  @override
  String get commonWeekDotToday => 'today';

  @override
  String get commonWeekDotFuture => 'upcoming';

  @override
  String get settingsEquipmentTitle => 'My equipment';

  @override
  String get settingsEquipmentDescription =>
      'What you check here feeds the catalogue filter and the context sent to the AI.';

  @override
  String get settingsEquipmentTile => 'Equipment list';

  @override
  String get settingsWeeklyFab => 'Time range';

  @override
  String get settingsWeeklyExplanationTitle => 'There are two kinds of range';

  @override
  String get settingsWeeklyExplanationBody =>
      '· Work: you are on the job. The AI will not schedule training then, but it may schedule meals.\n· Unavailable: nothing is scheduled and no reminder fires.';

  @override
  String get settingsWeeklyEmptyDay => 'empty';

  @override
  String get settingsWeeklyAddTitle => 'Add a time range';

  @override
  String get settingsWeeklyKindWork => 'Work';

  @override
  String get settingsWeeklyKindBlocked => 'Unavailable';

  @override
  String get settingsWeeklyDays => 'Days';

  @override
  String get settingsWeeklyPickDayError => 'Pick at least one day';

  @override
  String get settingsWeeklyStart => 'Start';

  @override
  String get settingsWeeklyEnd => 'End';

  @override
  String get settingsWeeklyOvernightHint =>
      'If the end is earlier than the start, the range crosses midnight.';

  @override
  String get settingsWeeklyLabel => 'Description';

  @override
  String get settingsWeeklyLabelHint => 'Factory';

  @override
  String get settingsWeeklyLabelHelper => 'Optional';

  @override
  String get settingsWeeklyAdd => 'Add';

  @override
  String get settingsBackupTitle => 'Backup';

  @override
  String get settingsBackupDescription =>
      'All data lives on this device only. If you change phones without a backup, there is no way back.';

  @override
  String get settingsBackupExport => 'Create backup';

  @override
  String get settingsBackupExportSubtitle =>
      'Save the file somewhere with the share sheet';

  @override
  String get settingsBackupImport => 'Restore from backup';

  @override
  String get settingsBackupImportSubtitle => 'Overwrites your current data';

  @override
  String get settingsBackupShareText => 'di@sport backup';

  @override
  String get settingsBackupRestored =>
      'Backup restored. Close and reopen the app — the open database connection still shows the old data.';

  @override
  String get settingsBackupConfirmTitle => 'Overwrite your current data?';

  @override
  String get settingsBackupConfirmBody =>
      'All of your current records will be replaced by the ones in the backup. The previous state is still kept on the device.';

  @override
  String get settingsBackupConfirmAction => 'Overwrite';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsDescription =>
      'The morning weigh-in reminder follows your wake-up time; set it in your profile.';

  @override
  String get settingsNotifWorkout => 'Workout';

  @override
  String get settingsNotifWorkoutDescription =>
      'At the workout time in your plan';

  @override
  String get settingsNotifMeal => 'Meal';

  @override
  String get settingsNotifMealDescription => 'At the meal times in your plan';

  @override
  String get settingsNotifWalk => 'Walk';

  @override
  String get settingsNotifWalkDescription => 'At the walk time in your plan';

  @override
  String get settingsNotifSupplement => 'Supplement';

  @override
  String get settingsNotifSupplementDescription =>
      'At vitamin and supplement times';

  @override
  String get settingsExactAlarmTitle => 'Exact alarm permission';

  @override
  String get settingsExactAlarmGranted =>
      'Granted — reminders fire exactly on time.';

  @override
  String get settingsExactAlarmDenied =>
      'Not granted. Reminders still fire but may be a few minutes late in battery saver. Tap to grant.';

  @override
  String get settingsExactAlarmLoading => 'Loading…';

  @override
  String get settingsOnboardingIntro =>
      'Let\'s get to know you first. This information never leaves your device; it is only used when you send a context file to an AI yourself.';

  @override
  String get settingsOnboardingSave => 'Save and start';

  @override
  String get onboardingWelcomeTitle => 'Welcome to di@sport';

  @override
  String get onboardingWelcomeBody =>
      'Track your diet, workouts, health values and medication in one place.';

  @override
  String get onboardingAreaDiet => 'Diet — meals, calorie budget, water';

  @override
  String get onboardingAreaSport => 'Sport — plan, workouts, exercise catalog';

  @override
  String get onboardingAreaHealth => 'Health — labs, measurements, progress';

  @override
  String get onboardingAreaMed =>
      'Medication & supplements — reminders and tracking';

  @override
  String get onboardingStart => 'Let\'s start';

  @override
  String get onboardingIdentityTitle => 'About you';

  @override
  String get onboardingFirstName => 'First name';

  @override
  String get onboardingLastName => 'Last name';

  @override
  String get onboardingFirstNameRequired =>
      'We need your first name to continue.';

  @override
  String get onboardingBirthDate => 'Birth date';

  @override
  String get onboardingBirthDay => 'Day';

  @override
  String get onboardingBirthMonth => 'Month';

  @override
  String get onboardingBirthYear => 'Year';

  @override
  String get onboardingBirthDateInvalid => 'Birth date must be a valid day.';

  @override
  String get onboardingGender => 'Gender';

  @override
  String get onboardingMale => 'Male';

  @override
  String get onboardingFemale => 'Female';

  @override
  String get onboardingGenderUnspecified => 'Prefer not to say';

  @override
  String get onboardingGenderWhy =>
      'Used for calorie estimates; an average factor is used if unspecified.';

  @override
  String get onboardingMeasuresTitle => 'Your measurements';

  @override
  String get onboardingMeasuresBody =>
      'Your weight also becomes your first weigh-in — your Progress chart starts today.';

  @override
  String get onboardingHeight => 'Height';

  @override
  String get onboardingWeight => 'Current weight';

  @override
  String get onboardingTargetWeight => 'Target weight';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get setupPanelTitle => 'Setup';

  @override
  String setupPanelProgress(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get setupPanelBody =>
      'A few short steps left. These feed your plan too — the fuller they are, the better the plan.';

  @override
  String get setupCardEquipment => 'Pick your equipment';

  @override
  String get setupCardMedical => 'Your medical info';

  @override
  String get setupCardRhythm => 'Your daily rhythm';

  @override
  String setupCardMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get setupCardSkip => 'Skip';

  @override
  String todayBirthday(String name) {
    return 'Happy birthday, $name! 🎉';
  }

  @override
  String get medicalTitle => 'Medical info';

  @override
  String get medicalPrivacyNote =>
      'This never leaves your device; it only reaches a plan when you share the AI document yourself.';

  @override
  String get medicalKindCondition => 'Conditions';

  @override
  String get medicalKindRestriction => 'Movement restrictions';

  @override
  String get medicalKindAllergy => 'Allergies';

  @override
  String get medicalKindBloodType => 'Blood type';

  @override
  String get medicalKindEmpty => 'No records.';

  @override
  String get medicalAddCustom => 'Add another';

  @override
  String get medicalCustomHint => 'e.g. knee sensitivity';

  @override
  String medicalRemoveTitle(String label) {
    return 'Remove $label?';
  }

  @override
  String get medicalRemoveBody =>
      'The record leaves the list; your history stays intact.';

  @override
  String get medicalMedsTitle => 'Medication';

  @override
  String get medicalMedsEmpty =>
      'No medication defined. Medication lives in the Medication & Supplements screen for reminders and tracking.';

  @override
  String get medicalMedsManage => 'Manage medication and supplements';

  @override
  String get medicalCondInsulinResistance => 'Insulin resistance';

  @override
  String get medicalCondType2Diabetes => 'Type 2 diabetes';

  @override
  String get medicalCondHypertension => 'Hypertension';

  @override
  String get medicalCondThyroid => 'Thyroid';

  @override
  String get medicalCondKneeIssue => 'Knee issue';

  @override
  String get medicalCondBackIssue => 'Back issue';

  @override
  String get medicalCondShoulderIssue => 'Shoulder issue';

  @override
  String get medicalCondLactose => 'Lactose';

  @override
  String get medicalCondGluten => 'Gluten';

  @override
  String get medicalCondNuts => 'Nuts';

  @override
  String get supplementKindSupplement => 'Supplement';

  @override
  String get supplementKindMedication => 'Medication';

  @override
  String get equipmentTabHome => 'At home';

  @override
  String get equipmentTabGym => 'At the gym';

  @override
  String get equipmentTabSports => 'Sports';

  @override
  String equipmentImpactHome(int count) {
    return 'With these checks you can do $count exercises at home.';
  }

  @override
  String equipmentImpactGym(int count) {
    return 'With these checks you can do $count exercises at the gym.';
  }

  @override
  String equipmentUnlocks(int count) {
    return 'unlocks +$count';
  }

  @override
  String get equipmentGymToggle => 'Do you go to a gym?';

  @override
  String get equipmentGymOffBody =>
      'If you don\'t go to a gym there\'s nothing to do here — plans are built only from what\'s doable at home and outdoors. Flip the switch if that changes.';

  @override
  String get sportsIntro =>
      'Pick the sports you love; the AI builds the plan around them. Add a frequency note if you like.';

  @override
  String get sportsChosen => 'Your picks';

  @override
  String get sportsSearchHint =>
      'Search sports — running, basketball, swimming…';

  @override
  String get sportsNoteTooltip => 'Frequency note';

  @override
  String get sportsNoteTitle => 'How often?';

  @override
  String get sportsNoteHint => 'e.g. once a week, Sunday morning';

  @override
  String get reminderMealBody => 'Meal time. Log what you eat from Diet.';

  @override
  String get planSlotItems => 'Meal items';

  @override
  String get planSlotAddItem => 'Add food';

  @override
  String get waterRowTitle => 'Water';

  @override
  String waterRowAmount(int current, int target) {
    return '$current / $target ml';
  }

  @override
  String get waterRowAddGlass => '+250 ml';

  @override
  String get waterRowRemoveGlass => 'Take back one glass';

  @override
  String get dietPlanBadge => 'PLAN';

  @override
  String get dietPlanCompliantBadge => 'ON PLAN';

  @override
  String get dietAteAsPlanned => 'I ate as planned';

  @override
  String get dietAteUsual => 'The usual';

  @override
  String get dietExternalMeal =>
      'Canteen/eating out — no plan expected, log freely.';

  @override
  String dietFixedUnbound(String note) {
    return 'Fixed meal: $note';
  }

  @override
  String get foodSortAz => 'A–Z';

  @override
  String get foodSortKcalAsc => 'Calories ↑';

  @override
  String get foodSortKcalDesc => 'Calories ↓';

  @override
  String get foodSortProteinDesc => 'Protein ↓';

  @override
  String get foodSortFrequent => 'Often eaten';

  @override
  String get foodForbiddenBadge => 'FORBIDDEN';

  @override
  String get forbiddenTitle => 'Forbidden foods';

  @override
  String get forbiddenIntro =>
      'This list goes into the AI plan (never suggested) and matching foods carry a badge. Logging is never blocked — your call.';

  @override
  String get forbiddenAddHint => 'e.g. sugar, pastry, alcohol';

  @override
  String get forbiddenAdd => 'Add';

  @override
  String get forbiddenLinkFoods => 'Link to foods';

  @override
  String forbiddenLinkedCount(int count) {
    return '$count foods linked';
  }

  @override
  String get forbiddenNoPlan =>
      'The forbidden list is stored on the plan; you need a plan first.';

  @override
  String get forbiddenEmpty =>
      'Nothing forbidden. Add a line; link it to foods if you like.';

  @override
  String get dietHistoryDays => 'Day breakdown';

  @override
  String planAdherence(int percent, int done, int planned) {
    return 'Adherence $percent% — $done/$planned workout days';
  }

  @override
  String get plannedVsDoneTitle => 'Planned / Done';

  @override
  String get plannedVsDoneExercises => 'Exercises';

  @override
  String get plannedVsDoneColumns => 'PLAN · DONE';

  @override
  String get plannedVsDoneEmptyTitle => 'No workout on this day';

  @override
  String get plannedVsDoneEmptyBody =>
      'The plan put no exercises here and nothing was logged.';

  @override
  String get plannedVsDoneOpenLive => 'Start workout';

  @override
  String get plannedVsDoneSession => 'Session';

  @override
  String get plannedVsDoneNoSession =>
      'No session recorded. For a past day you can enter the time range by hand.';

  @override
  String plannedVsDoneSessionOpen(String start) {
    return '$start — in progress';
  }

  @override
  String plannedVsDoneMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get plannedVsDoneAddSession => 'Add session';

  @override
  String get plannedVsDoneSessionEdit => 'Session times';

  @override
  String get plannedVsDoneStart => 'Start';

  @override
  String get plannedVsDoneEnd => 'End';

  @override
  String get plannedVsDoneAdd => '— ADD';

  @override
  String get plannedVsDoneNoSets => 'No sets logged. Add one below.';

  @override
  String get plannedVsDoneAddSet => 'Add set';

  @override
  String get plannedVsDoneReps => 'Reps';

  @override
  String get plannedVsDoneSeconds => 'Seconds';

  @override
  String get sportWorkoutTodayTitle => 'Today\'s workout';

  @override
  String get sportWorkoutTodayBody => 'The plan scheduled a workout today.';

  @override
  String get sportWorkoutHistory => 'History';

  @override
  String sportWorkoutExerciseCount(int count) {
    return '$count exercises';
  }

  @override
  String get catalogSafetyLabel => 'Safety';

  @override
  String get catalogSafetyRestricted => 'Safety — matches your restriction';

  @override
  String get bmiMissingHeight => 'BMI needs your height — add it in Profile';

  @override
  String get bmiMissingWeight =>
      'BMI needs your weight — weigh in or add it in Profile';

  @override
  String get onboardingBmiContext =>
      'Your starting point on the way to the goal — the plan builds from here.';

  @override
  String get bmiRowTitle => 'Body mass index';

  @override
  String get bmiUnderweight => 'Underweight';

  @override
  String get bmiNormal => 'Normal';

  @override
  String get bmiOverweight => 'Overweight';

  @override
  String get bmiObese => 'Obese';

  @override
  String get healthShareLabs => 'Share lab summary';

  @override
  String get healthShareTitle => 'Lab summary — di@sport';

  @override
  String get checkupTitle => 'Check-up guide';

  @override
  String get checkupDisclaimer =>
      'General screening suggestions — not medical advice, ask your doctor.';

  @override
  String get checkupNeedsWeight =>
      'Enter your weight to sharpen the suggestions.';

  @override
  String get checkupDue => 'Due now';

  @override
  String checkupInMonths(int months) {
    return 'in $months months';
  }

  @override
  String checkupScheduled(String test) {
    return '$test added to your lab schedule.';
  }

  @override
  String get checkupFullPanel => 'Full panel (CBC, CMP, lipid, HbA1c, TSH)';

  @override
  String get checkupHba1c => 'HbA1c';

  @override
  String get checkupLipid => 'Lipid panel';

  @override
  String get checkupVitaminDB12 => 'Vitamin D + B12';

  @override
  String get supplementsTodayTitle => 'Today\'s doses';

  @override
  String get supplementsAdherenceTitle => 'Last 7 days adherence';

  @override
  String get labImportTitle => 'Import labs with AI';

  @override
  String get labImportStep1 => 'Copy the transfer document.';

  @override
  String get labImportCopyDoc => 'Copy document';

  @override
  String get labImportShareDoc => 'Share';

  @override
  String get labImportCopied => 'Document copied to clipboard.';

  @override
  String get labImportStep2 =>
      'Give the document and your lab PDF to any AI chat. The PDF never enters the app.';

  @override
  String get labImportStep3 => 'Paste the returned JSON here.';

  @override
  String get labImportPasteHint => 'Paste the JSON document here';

  @override
  String get labImportParse => 'Parse';

  @override
  String get labImportPreview => 'Preview';

  @override
  String get labImportUnknownMarker => 'Marker not in the dictionary';

  @override
  String get labImportUnexpectedUnit => 'Unit differs from expected';

  @override
  String get labImportImplausible => 'Value outside the plausible range';

  @override
  String get labImportEditTitle => 'Fix row';

  @override
  String labImportSave(int save, int skip) {
    return 'Save $save values · skip $skip';
  }

  @override
  String labImportSaved(int count) {
    return '$count lab values saved.';
  }

  @override
  String get healthImportWithAi => 'Import from PDF with AI';

  @override
  String get ctxSectionsTitle => 'What goes to the AI';

  @override
  String get ctxSectionsIntro =>
      'You choose which sections enter the plan request document. A disabled section is never written. Who/goal/task always go — no plan can be requested without them.';

  @override
  String get ctxPreviewButton => 'See the document first';

  @override
  String get ctxPreviewTitle => 'Document preview';

  @override
  String get ctxCopy => 'Copy';

  @override
  String get ctxShare => 'Share';

  @override
  String get ctxSectionMedical => 'Medical';

  @override
  String get ctxSectionMedicalHint =>
      'Conditions, restrictions, labs and medication';

  @override
  String get ctxSectionEnvironment => 'Environment';

  @override
  String get ctxSectionEnvironmentHint =>
      'Equipment inventory and favourite sports';

  @override
  String get ctxSectionRoutine => 'Meal behaviours';

  @override
  String get ctxSectionRoutineHint => 'Meal times and canteen/fixed meal info';

  @override
  String get ctxSectionForbidden => 'Forbidden foods';

  @override
  String get ctxSectionForbiddenHint => 'The AI never suggests these';

  @override
  String get ctxSectionRecent => 'Last 14 days';

  @override
  String get ctxSectionRecentHint =>
      'Meals, water (ml), medication adherence, workouts, weight';

  @override
  String get ctxSectionNotes => 'Your own words';

  @override
  String get ctxSectionNotesHint => 'Your day notes, verbatim';

  @override
  String get ctxSectionFoods => 'Food list';

  @override
  String get ctxSectionFoodsHint =>
      '368 foods — so the AI can write meals with food ids';

  @override
  String get moreAiSections => 'What goes to the AI';

  @override
  String get importPlanGraftTitle => 'Graft onto the current plan';

  @override
  String importPlanGraftBody(String date) {
    return 'Everything before $date stays untouched; from that date on this plan takes over. Your records are never touched.';
  }

  @override
  String get requestScopeTitle => 'Plan scope';

  @override
  String get requestScopeBody =>
      'You have an active plan. Where should the new plan start?';

  @override
  String get requestScopeGraft => 'From a chosen date';

  @override
  String get requestScopeFresh => 'A fresh plan';

  @override
  String importWarningsTitle(int count) {
    return '$count warnings';
  }

  @override
  String get importWarningsFootnote =>
      'Warnings never block the import; fix them later in the editor if you like.';

  @override
  String importWarnForbidden(String id) {
    return 'Forbidden food in the plan: $id';
  }

  @override
  String importWarnUnknownFood(String id) {
    return 'Not in the food list: $id';
  }

  @override
  String importWarnCannotPerform(String id) {
    return 'Not doable with your equipment: $id';
  }

  @override
  String importWarnExternalMeal(String meal) {
    return 'Plan written for an external meal: $meal';
  }

  @override
  String importWarnFixedMeal(String meal) {
    return 'Fixed meal differs in the plan: $meal';
  }

  @override
  String importWarnRestriction(String id) {
    return 'Matches your movement restriction: $id';
  }

  @override
  String get rhythmMealsSection => 'Meals';

  @override
  String get rhythmMealFlexible => 'Flexible time';

  @override
  String get mealBehaviorPlanned => 'Plan fills it';

  @override
  String get mealBehaviorFixed => 'Always the same';

  @override
  String get mealBehaviorExternal => 'Canteen/eating out';

  @override
  String get mealBehaviorFixedNoteLabel => 'What do you eat?';

  @override
  String get mealBehaviorFixedNoteHint => 'e.g. menemen + tea';

  @override
  String mealBehaviorSheetTitle(String meal) {
    return '$meal routine';
  }

  @override
  String get mealBehaviorTimeLabel => 'Time';

  @override
  String get mealBehaviorTimeClear => 'Clear time';

  @override
  String get mealBehaviorWhy =>
      'This goes into the AI plan: a fixed meal is left untouched, an external meal is never planned.';

  @override
  String get settingsProfileHeightRequired => 'Height is required.';

  @override
  String get settingsProfileContextNote =>
      'This information goes into the context file sent to the AI. The more you fill in, the more the plan fits you; whatever you leave blank is reported as \"not specified\".';

  @override
  String get importPlanTitle => 'Import plan';

  @override
  String get importPlanDescription =>
      'Paste the JSON document the AI gave you here.';

  @override
  String get importPlanValidate => 'Validate';

  @override
  String get importPlanImport => 'Import';

  @override
  String get importPlanFailedTitle => 'Plan could not be imported';

  @override
  String get importPlanPasteBackHint =>
      'Paste this message back to the AI as is; it will know what to fix.';

  @override
  String get importPlanCopyError => 'Copy error';

  @override
  String get importPlanErrorCopied => 'Error message copied';

  @override
  String importPlanLoaded(Object days) {
    return 'Loaded a $days-day plan.';
  }

  @override
  String importPlanLoadedWithExercises(Object days, Object count) {
    return 'Loaded a $days-day plan and added $count new exercises.';
  }

  @override
  String importPlanSummary(Object startDate, Object weeks, Object days) {
    return '$weeks weeks · $days days, starting $startDate';
  }

  @override
  String importPlanGym(Object count) {
    return 'Gym $count';
  }

  @override
  String importPlanHome(Object count) {
    return 'Home $count';
  }

  @override
  String importPlanRest(Object count) {
    return 'Rest $count';
  }

  @override
  String importPlanGoals(
    Object kcal,
    Object protein,
    Object water,
    Object loss,
  ) {
    return '$kcal kcal · $protein g protein · $water L water · target −$loss kg';
  }

  @override
  String get importPlanNewExercisesTitle => 'Suggested new exercises';

  @override
  String get importPlanNewExercisesDescription =>
      'The ones you approve are added to the catalogue permanently.';

  @override
  String get todayTitle => 'Today';

  @override
  String todayWeekNumber(Object week) {
    return 'week $week';
  }

  @override
  String get todayDayTypeGym => 'Gym day';

  @override
  String get todayDayTypeHome => 'Home workout';

  @override
  String get todayDayTypeRest => 'Rest day';

  @override
  String get todayMetricProgram => 'Program';

  @override
  String get todayMetricRules => 'Rules';

  @override
  String todayNextEyebrow(Object time) {
    return 'Next · $time';
  }

  @override
  String todayExerciseCount(Object count) {
    return '$count exercises';
  }

  @override
  String get todaySpineLabel => 'Backbone of the day';

  @override
  String todayDinnerHint(Object text) {
    return 'Dinner suggestion: $text';
  }

  @override
  String get todayNoPlanTitle => 'No plan for today';

  @override
  String get todayNoPlanBody =>
      'Load a program from the Plan tab. The scale and the daily checkboxes work without a plan too.';

  @override
  String get todayCheckedLabel => 'checked';

  @override
  String get todayUncheckedLabel => 'unchecked';

  @override
  String get todayRulesTitle => 'Rules of the day';

  @override
  String get todayEditRulesTooltip => 'Edit rules';

  @override
  String get todayNoRulesTitle => 'No rules';

  @override
  String get todayNoRulesBody =>
      'Add the things you want to track every day — water, supplements, early bedtime. Use the settings button at the top right.';

  @override
  String get todayRulesEditorEmptyBody =>
      'Add your first rule with the button below.';

  @override
  String get todayRuleFabLabel => 'Rule';

  @override
  String todayDeleteRuleTitle(Object label) {
    return 'Delete \"$label\"?';
  }

  @override
  String get todayDeleteRuleBody =>
      'It will no longer appear in the list from today on. Your marks on past days stay untouched.';

  @override
  String get todayBuiltInRuleNote => 'Rule from the chart';

  @override
  String get todayRuleNameRequired => 'Rule name is required';

  @override
  String get todayAddRule => 'Add rule';

  @override
  String get todayEditRule => 'Edit rule';

  @override
  String get todayRuleLabel => 'Rule';

  @override
  String get todayRuleHint => 'Took creatine';

  @override
  String get todayIconLabel => 'Icon';

  @override
  String get todayNoteTitle => 'Note';

  @override
  String get todayNoteDescription =>
      'What you ate, what was hard, how it went.';

  @override
  String get todayNoteHint => 'How did today go?';

  @override
  String get todayWeightLabel => 'Weight';

  @override
  String get todayWeightUnit => 'kg';

  @override
  String get todaySleepLabel => 'Sleep';

  @override
  String get todaySleepUnit => 'h';

  @override
  String todayMissedStreakTitle(Object count) {
    return '$count days in a row without a workout';
  }

  @override
  String get todayMissedStreakBody =>
      'That was the rule: never miss two days in a row. Do something today, even if it is short.';

  @override
  String get planEmptyTitle => 'No plan yet';

  @override
  String get planEmptyBody =>
      'Use the \"Request a new plan\" button above to generate your context file, hand it to any AI, then bring the returned JSON document back here with \"Import\".';

  @override
  String get planLoadSample => 'Load sample plan (development)';

  @override
  String get planShareSubject => 'di@sport — plan request';

  @override
  String get planRequestButton => 'Request a new plan';

  @override
  String get planImportButton => 'Import';

  @override
  String planDayCount(Object count) {
    return '$count days';
  }

  @override
  String planWeekLabel(Object week) {
    return 'Week $week';
  }

  @override
  String get planLegendDone => 'Completed';

  @override
  String get planLegendPartial => 'Partial';

  @override
  String get planLegendFree => 'Free';

  @override
  String get planLegendWorkout => 'Workout ▲';

  @override
  String get planGoalDaily => 'Daily';

  @override
  String get planGoalProtein => 'Protein';

  @override
  String get planGoalWater => 'Water';

  @override
  String get planGoalTarget => 'Target';

  @override
  String get planNutritionRules => 'Nutrition rules';

  @override
  String get planRulesForbidden => 'Absolutely not';

  @override
  String get planRulesFree => 'Allowed';

  @override
  String get planWeekdayInitials => 'M,T,W,T,F,S,S';

  @override
  String get planMonthNames =>
      'January,February,March,April,May,June,July,August,September,October,November,December';

  @override
  String get planCellToday => 'today';

  @override
  String get planCellDone => 'completed';

  @override
  String get planCellEmpty => 'no record';

  @override
  String get planCellFuture => 'not here yet';

  @override
  String get planCellFreeSpoken => 'free day';

  @override
  String get reminderSlotFallbackTitle => 'A step in your plan';

  @override
  String get reminderSlotWorkoutBody =>
      'Training time. Let\'s go when you\'re ready.';

  @override
  String get reminderSlotOtherBody => 'The next step in your plan.';

  @override
  String get reminderWeighInTitle => 'Morning weigh-in';

  @override
  String get reminderWeighInBody =>
      'On an empty stomach, same conditions every day.';

  @override
  String get reminderMissStreakTitle => 'The streak is breaking';

  @override
  String get reminderMissStreakBody =>
      'You\'ve missed two days in a row. Something short today beats nothing.';

  @override
  String get reminderDueLabTitle => 'Lab test due';

  @override
  String reminderDueLabBody(Object marker) {
    return '$marker is due for a retest.';
  }

  @override
  String get reminderPlanEndingTitle => 'Plan is ending';

  @override
  String get reminderPlanEndingToday =>
      'Your plan ends today. Grab the context file for a new one.';

  @override
  String reminderPlanEndingIn(Object days) {
    return 'Your plan ends in $days days. Time to prepare the next one.';
  }

  @override
  String get supplementsTitle => 'Supplements and medication';

  @override
  String get supplementsDescription =>
      'Vitamins, supplements, medication — set the times and tick them off on Today.';

  @override
  String get supplementsOpen => 'Supplement list';

  @override
  String get supplementsEmptyTitle => 'No supplements yet';

  @override
  String get supplementsEmptyDescription =>
      'Add whatever you take. Give it a time and you\'ll get a reminder too.';

  @override
  String get supplementAddFab => 'Supplement';

  @override
  String get supplementAddTitle => 'Add supplement';

  @override
  String get supplementEditTitle => 'Edit supplement';

  @override
  String get supplementNameLabel => 'Name';

  @override
  String get supplementNameHint => 'Vitamin D';

  @override
  String get supplementNameRequired => 'Name is required';

  @override
  String get supplementDoseLabel => 'Dose';

  @override
  String get supplementDoseHint => '1000';

  @override
  String get supplementUnitLabel => 'Unit';

  @override
  String get supplementUnitHint => 'IU';

  @override
  String get supplementNoteLabel => 'Note';

  @override
  String get supplementNoteHint => 'With food';

  @override
  String get supplementTimesSection => 'Times';

  @override
  String get supplementTimesEmpty =>
      'No times set — no reminder will be scheduled.';

  @override
  String get supplementAddTime => 'Add time';

  @override
  String get supplementDaysSection => 'Days';

  @override
  String get supplementEveryDay => 'Every day';

  @override
  String supplementDeleteTitle(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get supplementDeleteBody =>
      'Removed from the list and from reminders. Your past records stay — nothing is lost.';

  @override
  String supplementTakenSemantics(Object name, Object time) {
    return '$name at $time, taken';
  }

  @override
  String supplementNotTakenSemantics(Object name, Object time) {
    return '$name at $time, not taken';
  }

  @override
  String get supplementSectionLabel => 'Supplements';

  @override
  String get reminderSupplementBody => 'Time to take it.';

  @override
  String reminderSupplementBodyWithDose(Object dose) {
    return '$dose — time to take it.';
  }

  @override
  String get equipmentBodyOnly => 'Body only';

  @override
  String get equipmentBarbell => 'Barbell';

  @override
  String get equipmentDumbbell => 'Dumbbell';

  @override
  String get equipmentKettlebell => 'Kettlebell';

  @override
  String get equipmentCable => 'Cable';

  @override
  String get equipmentMachine => 'Machine';

  @override
  String get equipmentBands => 'Resistance bands';

  @override
  String get equipmentMedicineBall => 'Medicine ball';

  @override
  String get equipmentExerciseBall => 'Exercise ball';

  @override
  String get equipmentFoamRoll => 'Foam roller';

  @override
  String get equipmentEzCurlBar => 'E-Z curl bar';

  @override
  String get equipmentOther => 'Household item';

  @override
  String get equipmentNone => 'No equipment';

  @override
  String get equipmentPullUpBar => 'Pull-up bar';

  @override
  String get equipmentDipBars => 'Dip bars';

  @override
  String get equipmentBench => 'Bench';

  @override
  String get equipmentJumpRope => 'Jump rope';

  @override
  String catalogEquipmentMissingHome(Object equipment) {
    return 'Needs $equipment (not at home)';
  }

  @override
  String catalogEquipmentMissingGym(Object equipment) {
    return 'Needs $equipment (not at the gym)';
  }

  @override
  String get foodSearchHint => 'Search foods';

  @override
  String get foodSearchEmptyTitle => 'Nothing found';

  @override
  String get foodSearchEmptyMessage =>
      'Try a shorter word, or search in the other language.';

  @override
  String get foodStartTitle => 'Nothing logged yet';

  @override
  String get foodStartMessage => 'Search for a food, or pick a category above.';

  @override
  String get foodFrequentTitle => 'You eat these often';

  @override
  String get foodCopyLastMeal => 'Copy this meal from last time';

  @override
  String foodCopyDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count items',
      one: 'Copied 1 item',
    );
    return '$_temp0';
  }

  @override
  String get foodCopyNothingToCopy => 'No earlier entry for this meal';

  @override
  String foodPer100g(int kcal) {
    return '$kcal kcal per 100 g';
  }

  @override
  String foodPerPortion(String portion, int kcal) {
    return '$portion - $kcal kcal';
  }

  @override
  String get foodCategoryYemek => 'Dishes';

  @override
  String get foodCategoryCorba => 'Soups';

  @override
  String get foodCategoryKahvaltilik => 'Breakfast';

  @override
  String get foodCategoryMeyve => 'Fruit';

  @override
  String get foodCategorySebze => 'Vegetables';

  @override
  String get foodCategoryKuruyemis => 'Nuts';

  @override
  String get foodCategoryIcecek => 'Drinks';

  @override
  String get foodCategoryTahil => 'Grains';

  @override
  String get foodCategoryEtBalik => 'Meat and fish';

  @override
  String get foodCategorySutUrunu => 'Dairy';

  @override
  String get foodCategoryAtistirmalik => 'Snacks';

  @override
  String get foodCategoryDiger => 'Other';

  @override
  String get mealKahvalti => 'Breakfast';

  @override
  String get mealAraOgun => 'Morning snack';

  @override
  String get mealOgle => 'Lunch';

  @override
  String get mealIkindi => 'Afternoon snack';

  @override
  String get mealAksam => 'Dinner';

  @override
  String get mealGece => 'Late snack';

  @override
  String get portionUnitGrams100 => '100 g';

  @override
  String get portionCustomGramsLabel => 'Weighed it?';

  @override
  String get portionCustomGramsHelper => 'Enter grams to override the portion';

  @override
  String get portionGrams => 'AMOUNT';

  @override
  String get portionKcal => 'CALORIES';

  @override
  String get portionProtein => 'PROTEIN';

  @override
  String get portionAddToMeal => 'Add to meal';

  @override
  String get portionDecrease => 'One less';

  @override
  String get portionIncrease => 'One more';

  @override
  String get activityLogTitle => 'Log activity';

  @override
  String get activitySearchHint => 'Search activities';

  @override
  String get activityMinutesLabel => 'Minutes';

  @override
  String get activityAdd => 'Add';

  @override
  String get activityEmptyTitle => 'No activities match';

  @override
  String get activityEmptyMessage => 'Try another word, or add your own below.';

  @override
  String get effortLight => 'Light';

  @override
  String get effortModerate => 'Moderate';

  @override
  String get effortVigorous => 'Hard';

  @override
  String get todayMealsTitle => 'Meals';

  @override
  String get todayActivitiesTitle => 'Activity';

  @override
  String get todayAddMeal => 'Add meal';

  @override
  String get todayAddActivity => 'Add activity';

  @override
  String get todayHeroRemaining => 'LEFT TODAY';

  @override
  String get todayHeroEatenNoPlan => 'EATEN TODAY';

  @override
  String get todayMetricWater => 'WATER';

  @override
  String get todayMetricMeds => 'MEDS';

  @override
  String get todayMetricProtein => 'PROTEIN';

  @override
  String get todayMetricBurned => 'BURNED';

  @override
  String get mealEntryRemoved => 'Removed';

  @override
  String get progressCaloriesTitle => 'Calories this week';

  @override
  String get progressCaloriesGoalLine => 'Goal';

  @override
  String progressDayBreakdown(String date) {
    return '$date breakdown';
  }

  @override
  String get catalogTabOutside => 'Outside';

  @override
  String get dayBadgePast => 'PAST DAY';

  @override
  String get dayBadgeFuture => 'PLANNED DAY';

  @override
  String get dayBackToToday => 'Back to today';

  @override
  String get dayPrevious => 'Previous day';

  @override
  String get dayNext => 'Next day';

  @override
  String get dayPickDate => 'Pick a date';

  @override
  String get dayFutureNoEntry =>
      'You can look at the plan, but entries start on the day itself.';

  @override
  String get planSettingsTitle => 'Plan settings';

  @override
  String get planSettingsName => 'Plan name';

  @override
  String get planSettingsNameRequired => 'Give the plan a name';

  @override
  String get planSettingsGoals => 'Goals';

  @override
  String get planGoalKcal => 'Daily calories';

  @override
  String get planGoalWeeklyGym => 'Gym days per week';

  @override
  String get planGoalWeeklyHome => 'Home days per week';

  @override
  String get planGoalTargetLoss => 'Target loss (kg)';

  @override
  String planGoalRange(String min, String max) {
    return 'Enter a value between $min and $max';
  }

  @override
  String get planRuleAdd => 'Add item';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonAdd => 'Add';

  @override
  String get planEditDay => 'Edit day';

  @override
  String get planDayType => 'Day type';

  @override
  String get planDayTypeGym => 'Gym';

  @override
  String get planDayTypeHome => 'Home';

  @override
  String get planDayTypeRest => 'Rest';

  @override
  String get planDayHeadline => 'Headline';

  @override
  String get planDayDinner => 'Dinner suggestion';

  @override
  String get planSlotNew => 'New slot';

  @override
  String get planSlotEdit => 'Edit slot';

  @override
  String get planSlotTime => 'Time';

  @override
  String get planSlotKind => 'Kind';

  @override
  String get planSlotLabel => 'Label';

  @override
  String get planSlotNote => 'Note';

  @override
  String get planSlotMealKind => 'Which meal';

  @override
  String get planSlotMealKindRequired => 'Pick which meal this is';

  @override
  String get planSlotLabelRequired => 'Give the slot a label';

  @override
  String get planExerciseNew => 'Add exercise';

  @override
  String get planExerciseEdit => 'Edit exercise';

  @override
  String get planExercisePick => 'Pick from catalogue';

  @override
  String get planExerciseSets => 'Sets';

  @override
  String get planExerciseReps => 'Reps';

  @override
  String get planExerciseDuration => 'Duration (min)';

  @override
  String get planExerciseRest => 'Rest (sec)';

  @override
  String get planExerciseSpeed => 'Speed (km/h)';

  @override
  String get planExerciseGrade => 'Incline (%)';

  @override
  String get planExerciseEffort => 'Effort';

  @override
  String get planExerciseRequired => 'Pick an exercise first';

  @override
  String get planOriginAiEdited => 'From an AI plan, edited';

  @override
  String get planOriginManual => 'Built by hand';

  @override
  String get planCreateEmpty => 'Build an empty plan';

  @override
  String get planCreateTitle => 'New plan';

  @override
  String get planCreateWeeks => 'Weeks';

  @override
  String get planCreateStart => 'Start date';

  @override
  String get planCreateDone => 'Create';

  @override
  String get dailyRhythmTitle => 'Daily rhythm';

  @override
  String get dailyRhythmDescription =>
      'When you get up, when you sleep, and when you cannot be reached.';

  @override
  String get dailyRhythmWake => 'Wake up';

  @override
  String get dailyRhythmSleep => 'Sleep';

  @override
  String get slotKindMeal => 'Meal';

  @override
  String get slotKindWorkout => 'Workout';

  @override
  String get slotKindSleep => 'Sleep';

  @override
  String get slotKindMeasurement => 'Measurement';

  @override
  String get slotKindLab => 'Lab test';

  @override
  String get slotKindOther => 'Other';

  @override
  String get tabHome => 'Home';

  @override
  String get tabDiet => 'Diet';

  @override
  String get tabSport => 'Sport';

  @override
  String get tabMore => 'More';

  @override
  String get tabHomeHint => 'Today\'s summary and flow';

  @override
  String get tabDietHint => 'Meals, foods, calorie history';

  @override
  String get tabSportHint => 'Plan, workouts, exercise catalogue';

  @override
  String get tabMoreHint => 'Your data and app settings';

  @override
  String get dietTabDaily => 'Daily';

  @override
  String get dietTabFoods => 'Foods';

  @override
  String get dietTabHistory => 'History';

  @override
  String get sportTabPlan => 'Plan';

  @override
  String get sportTabWorkout => 'Workout';

  @override
  String get sportTabCatalog => 'Catalogue';

  @override
  String get healthTabLabs => 'Labs';

  @override
  String get healthTabMeasure => 'Measures';

  @override
  String get healthTabMeds => 'Meds';

  @override
  String get sportWorkoutEmptyTitle => 'No sessions yet';

  @override
  String get sportWorkoutEmptyMessage =>
      'Start a workout from the plan; finished sessions appear here.';

  @override
  String get moreYourData => 'Shapes your plan';

  @override
  String get moreYourDataHint => 'Goes to the AI';

  @override
  String get moreApp => 'App';

  @override
  String get moreProfile => 'Profile';

  @override
  String get moreEquipment => 'Your equipment';

  @override
  String get moreRhythm => 'Daily rhythm';

  @override
  String get moreRules => 'Daily rules';

  @override
  String get moreNotifications => 'Notifications';

  @override
  String get moreAppearance => 'Appearance and language';

  @override
  String get moreBackup => 'Backup';

  @override
  String get todayStepsLabel => 'Steps';

  @override
  String get todayStepsUnit => 'steps';

  @override
  String get dietMealSkippedAction => 'Skipped';

  @override
  String dietMealSkippedLabel(Object reason) {
    return 'Skipped: $reason';
  }

  @override
  String get dietSkipUndo => 'Undo skip';

  @override
  String get dietSkipSheetTitle => 'Why was it skipped?';

  @override
  String get dietSkipReasonWork => 'Work';

  @override
  String get dietSkipReasonAppetite => 'No appetite';

  @override
  String get dietSkipReasonOut => 'Ate out';

  @override
  String get dietSkipReasonOther => 'Other';

  @override
  String get dietSkipReasonHint => 'short reason';

  @override
  String get moodBlockTitle => 'How did you feel today?';

  @override
  String get moodLevel1 => 'Awful';

  @override
  String get moodLevel2 => 'Bad';

  @override
  String get moodLevel3 => 'Okay';

  @override
  String get moodLevel4 => 'Good';

  @override
  String get moodLevel5 => 'Great';

  @override
  String get moodSymptomsLabel => 'Symptoms';

  @override
  String get moodSymptomsHint => 'headache, fatigue';

  @override
  String get moodStressedLabel => 'Busy/stressful day';

  @override
  String get sleepBlockTitle => 'Sleep';

  @override
  String get sleepBedLabel => 'Bed';

  @override
  String get sleepWakeLabel => 'Wake';

  @override
  String get sleepNapLabel => 'Nap';

  @override
  String get sleepNapUnit => 'min';

  @override
  String get sleepHoursOnlyLabel => 'Duration only';

  @override
  String get sleepHoursUnit => 'h';

  @override
  String sleepTotal(Object hours, Object minutes) {
    return '$hours h $minutes min of sleep';
  }

  @override
  String get sleepPickTime => 'Pick time';

  @override
  String get sleepClear => 'Clear times';

  @override
  String get dayFlowEnterMeal => '+ LOG';

  @override
  String get dayFlowTitle => 'Day flow';

  @override
  String get dayFlowWeighIn => 'Weigh-in';

  @override
  String get dayFlowCollapse => 'Show less';

  @override
  String dayFlowExpand(int count) {
    return 'All of the day ($count)';
  }

  @override
  String get equipmentChair => 'Chair';

  @override
  String get equipmentStep => 'Step / stairs';
}
