import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/catalog/data/equipment_repository.dart';
import 'package:disport/features/catalog/data/favorite_sports_repository.dart';
import 'package:disport/features/nutrition/data/activities_repository.dart';

/// Ortam kaynağı (v3 §9.3/3): ekipman + sevilen sporlar.
///
/// Spor adları `activities` tablosundan çözülür — AI belgeye kimlik
/// değil ad gitmeli, ama not olduğu gibi taşınır.
class EnvironmentSourceAdapter implements EnvironmentSource {
  const EnvironmentSourceAdapter(
    this._equipment,
    this._favorites,
    this._activities,
  );

  final EquipmentRepository _equipment;
  final FavoriteSportsRepository _favorites;
  final ActivitiesRepository _activities;

  @override
  Future<({List<String> home, List<String> gym})> equipment() async {
    final inventory = await _equipment.watchInventory().first;
    return (
      home: [for (final kind in inventory.atHome) kind.name]..sort(),
      gym: [for (final kind in inventory.atGym) kind.name]..sort(),
    );
  }

  @override
  Future<List<({String name, String? note})>> favoriteSports() async {
    final favorites = await _favorites.watchAll().first;
    final result = <({String name, String? note})>[];
    for (final favorite in favorites) {
      final activity = await _activities.byId(favorite.activityId);
      result.add(
        (
          name: activity?.nameEn ?? favorite.activityId,
          note: favorite.note,
        ),
      );
    }
    return result;
  }
}
