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
  String get tabPlan => 'Plan';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabHealth => 'Health';

  @override
  String get tabCatalog => 'Catalog';

  @override
  String get tabTodayHint => 'Today\'s schedule and entries';

  @override
  String get tabPlanHint => 'Four-week programme';

  @override
  String get tabProgressHint => 'Weight trend and weekly summary';

  @override
  String get tabHealthHint => 'Lab results and measurements';

  @override
  String get tabCatalogHint => 'Exercise library';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Profile and lifestyle';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

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
  String get catalogEquipmentEmptyTitle => 'Equipment list is empty';

  @override
  String get catalogEquipmentEmptyDescription =>
      'The list fills itself once the catalogue loads. You can also add items by hand with the button below.';

  @override
  String get catalogEquipmentNoneOwned =>
      'No equipment marked. Bodyweight-only exercises are always available.';

  @override
  String catalogEquipmentOwnedCount(Object count) {
    return '$count item(s) marked. The \"My equipment\" filter in the catalogue uses these.';
  }

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
  String get settingsWeeklyTitle => 'Weekly schedule';

  @override
  String get settingsWeeklyDescription =>
      'Your working hours and the times you are unavailable. The AI builds the plan around them and reminders stay silent during blocked hours.';

  @override
  String get settingsWeeklyTile => 'Working and unavailable hours';

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
  String get settingsOnboardingWelcome => 'Welcome';

  @override
  String get settingsOnboardingIntro =>
      'Let\'s get to know you first. This information never leaves your device; it is only used when you send a context file to an AI yourself.';

  @override
  String get settingsOnboardingSave => 'Save and start';

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
  String get todayHeroNoPlan => 'No plan · you can still log your weight';

  @override
  String get todayHeroFreeDay => 'Free day';

  @override
  String todayHeroDietFree(Object type) {
    return '$type · diet free';
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
  String get planCellFree => 'empty';

  @override
  String get planCellToday => 'today';

  @override
  String get planCellDone => 'completed';

  @override
  String planCellPartial(Object total, Object checked) {
    return '$checked of $total done';
  }

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
  String get supplementRemoveTime => 'Remove time';

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
  String supplementDoseCount(Object count) {
    return '$count item(s)';
  }

  @override
  String get supplementSectionLabel => 'Supplements';

  @override
  String get reminderSupplementBody => 'Time to take it.';

  @override
  String reminderSupplementBodyWithDose(Object dose) {
    return '$dose — time to take it.';
  }
}
