import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/medical/data/medical_repository.dart';

/// `medical` feature'ının `ai_bridge`'e verdiği kaynak (v3 §9.3/2).
class MedicalSourceAdapter implements MedicalSource {
  const MedicalSourceAdapter(this._repository);

  final MedicalRepository _repository;

  @override
  Future<List<MedicalFactDump>> facts() async {
    final all = await _repository.watchAll().first;
    return [
      for (final fact in all)
        MedicalFactDump(
          kind: fact.kind.name,
          label: fact.label,
          note: fact.note,
        ),
    ];
  }
}
