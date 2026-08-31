import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/settings/data/profile_repository.dart';

/// `settings` feature'ının `ai_bridge`'e verdiği profil kaynağı.
class ProfileSourceAdapter implements ProfileSource {
  const ProfileSourceAdapter(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Map<String, String>> profile() => _repository.all();
}
