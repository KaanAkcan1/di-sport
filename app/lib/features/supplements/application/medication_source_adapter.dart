import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/supplements/data/supplements_repository.dart';
import 'package:disport/features/supplements/domain/supplement.dart';

/// `supplements` feature'ının `ai_bridge`'e verdiği ilaç kaynağı.
///
/// Reçeteli/takviye ayrımı belgede korunur; sınır satırı (etkileşim ve
/// doz önerisi yasağı) belgeyi yazan tarafta basılır.
class MedicationSourceAdapter implements MedicationSource {
  const MedicationSourceAdapter(this._repository);

  final SupplementsRepository _repository;

  @override
  Future<List<MedicationDump>> medications() async {
    final all = await _repository.all();
    return [
      for (final item in all)
        MedicationDump(
          name: item.name,
          isPrescription: item.kind == SupplementKind.medication,
          doseLabel: item.doseLabel,
          times: item.times,
        ),
    ];
  }
}
