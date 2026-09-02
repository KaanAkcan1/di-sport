import 'package:disport/features/ai_bridge/application/ai_bridge_providers.dart';
import 'package:disport/features/ai_bridge/domain/context_md_builder.dart'
    show ProfileKeys;
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/medical/application/medical_providers.dart';
import 'package:disport/features/settings/data/profile_repository.dart';
import 'package:disport/features/settings/domain/setup_progress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setup_providers.g.dart';

/// Kurulum ilerlemesi — Ana Sayfa paneli bunu okuyor.
///
/// Üç kaynak da akış: kullanıcı ekipman ekranında bir çip işaretleyip
/// Ana Sayfa'ya döndüğünde kart anında düşmeli (`IndexedStack` ekranı
/// canlı tutuyor, tek seferlik okuma bir daha çalışmazdı).
///
/// Kaynaklardan biri henüz yüklenmemişse null: paneli erken çizmek
/// "0/4" gösterip bir kare sonra düzeltmek olurdu.
@riverpod
SetupProgress? setupProgress(Ref ref) {
  final profile = ref.watch(profileEntriesProvider).value;
  final equipment = ref.watch(equipmentItemsProvider).value;
  final medical = ref.watch(medicalFactsProvider).value;
  if (profile == null || equipment == null || medical == null) return null;

  String entry(String key) => (profile[key] ?? '').trim();

  return buildSetupProgress(
    // Sihirbazın ölçütü boy — `isOnboarded` ile aynı. v2'den yükselen
    // kullanıcıda ad yok ama boy var; onu sihirbaza geri atmıyoruz.
    hasIdentity: entry(ProfileKeys.heightCm).isNotEmpty,
    hasAnyEquipmentChecked: equipment.any((e) => e.atHome || e.atGym),
    equipmentSkipped: entry(SetupSkipKeys.equipment).isNotEmpty,
    hasAnyMedicalFact: medical.isNotEmpty,
    medicalSkipped: entry(SetupSkipKeys.medical).isNotEmpty,
    hasWakeTime: entry(ProfileKeys.wakeTime).isNotEmpty,
    rhythmSkipped: entry(SetupSkipKeys.rhythm).isNotEmpty,
  );
}

/// Bir kurulum adımını geçilmiş olarak işaretler.
///
/// Anahtar `profile_entries`e yazılır; `profileEntries` bir akış olduğu
/// için panel kartı anında düşürür — invalidate gerekmez.
Future<void> skipSetupStep(ProfileRepository repository, SetupStep step) {
  final key = switch (step) {
    SetupStep.equipment => SetupSkipKeys.equipment,
    SetupStep.medical => SetupSkipKeys.medical,
    SetupStep.rhythm => SetupSkipKeys.rhythm,
    // Sihirbazın GEÇ yolu yok — arkada boş uygulama var.
    // l10n-exempt: geliştiriciye giden hata metni.
    SetupStep.wizard => throw ArgumentError('sihirbaz geçilemez'),
  };
  return repository.set(key, '1');
}
