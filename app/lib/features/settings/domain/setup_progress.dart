/// Kurulum adımları (v3 §3.2) — Ana Sayfa panelinin saf modeli.
///
/// Dört adım: sihirbaz (kimlik + ölçü), ekipman, medikal, günlük düzen.
/// Panel 4/4'te kendini kaldırıyor ve kahraman kalori devreye giriyor.
/// Her adımın GEÇ yolu var — geçilen adım "tamam" sayılır (kart düşer)
/// ama ekranı Daha'dan her zaman erişilebilir kalır.
library;

enum SetupStep { wizard, equipment, medical, rhythm }

class SetupProgress {
  const SetupProgress({
    required this.wizardDone,
    required this.equipmentDone,
    required this.medicalDone,
    required this.rhythmDone,
  });

  final bool wizardDone;
  final bool equipmentDone;
  final bool medicalDone;
  final bool rhythmDone;

  int get done => [
    wizardDone,
    equipmentDone,
    medicalDone,
    rhythmDone,
  ].where((step) => step).length;

  int get total => 4;

  bool get complete => done == total;

  /// Panelde gösterilecek bekleyen adımlar — sihirbaz hariç (o zaten
  /// onboarding'de bitmiş olmak zorunda; panel görünürken bitmiştir).
  List<SetupStep> get pending => [
    if (!equipmentDone) SetupStep.equipment,
    if (!medicalDone) SetupStep.medical,
    if (!rhythmDone) SetupStep.rhythm,
  ];
}

/// Geçilme anahtarları — `profile_entries`e yazılır.
///
/// Geçmek adımı "tamam" yapar: kullanıcı GEÇ dediyse kartın her açılışta
/// geri gelmesi dırdırdır. Veri sonradan girilirse anahtar önemsizleşir.
abstract final class SetupSkipKeys {
  static const equipment = 'setup.skipped.equipment';
  static const medical = 'setup.skipped.medical';
  static const rhythm = 'setup.skipped.rhythm';
}

/// Ham girdilerden ilerleme durumu.
///
/// Girdiler bilinçli olarak bool: bu fonksiyon veritabanı görmez,
/// "ekipman tamam mı" sorusunun cevabını çağıran toplar (işaret var YA
/// DA geçildi).
SetupProgress buildSetupProgress({
  required bool hasIdentity,
  required bool hasAnyEquipmentChecked,
  required bool equipmentSkipped,
  required bool hasAnyMedicalFact,
  required bool medicalSkipped,
  required bool hasWakeTime,
  required bool rhythmSkipped,
}) => SetupProgress(
  wizardDone: hasIdentity,
  equipmentDone: hasAnyEquipmentChecked || equipmentSkipped,
  medicalDone: hasAnyMedicalFact || medicalSkipped,
  rhythmDone: hasWakeTime || rhythmSkipped,
);
