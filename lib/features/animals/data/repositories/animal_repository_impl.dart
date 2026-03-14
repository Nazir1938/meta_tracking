import 'package:meta_tracking/core/logger/app_logger.dart';
import '../../domain/entities/animal_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../datasources/animal_remote_datasource.dart';
import '../models/animal_model.dart';

class AnimalRepositoryImpl implements AnimalRepository {
  final AnimalRemoteDataSource _remote;

  AnimalRepositoryImpl(this._remote);

  @override
  Stream<List<AnimalEntity>> watchAnimals(String ownerId) {
    AppLogger.melumat('ANIMAL REPO', 'watchAnimals çağırıldı');
    return _remote.watchAnimals(ownerId);
  }

  @override
  Future<AnimalEntity> addAnimal({
    required String name,
    required AnimalType type,
    required String ownerId,
    String? chipId,
    String? notes,
    String? zoneId,
    String? zoneName,
  }) async {
    AppLogger.heyvanEmeliyyati('Heyvan əlavə edilir', name);
    final model = AnimalModel(
      id: '',
      name: name,
      type: type,
      ownerId: ownerId,
      chipId: chipId,
      isTracking: false,
      notes: notes,
      zoneId: zoneId,
      zoneName: zoneName,
      createdAt: DateTime.now(),
    );
    return await _remote.addAnimal(model);
  }

  @override
  Future<void> updateAnimal(AnimalEntity animal) async {
    AppLogger.heyvanEmeliyyati('Heyvan yenilənir', animal.name);
    final model = AnimalModel(
      id: animal.id,
      name: animal.name,
      type: animal.type,
      ownerId: animal.ownerId,
      chipId: animal.chipId,
      isTracking: animal.isTracking,
      zoneStatus: animal.zoneStatus,
      zoneName: animal.zoneName,
      zoneId: animal.zoneId,
      notes: animal.notes,
      createdAt: animal.createdAt,
    );
    await _remote.updateAnimal(model);
  }

  @override
  Future<void> deleteAnimal(String animalId) async {
    AppLogger.heyvanEmeliyyati('Heyvan silinir', animalId);
    await _remote.deleteAnimal(animalId);
  }

  @override
  Stream<Map<String, dynamic>?> watchLocation(String animalId) =>
      _remote.watchLocation(animalId);

  @override
  Future<void> updateLocation(
    String animalId,
    double lat,
    double lng,
    double speed,
    double battery,
  ) =>
      _remote.updateLocation(animalId, lat, lng, speed, battery);
}
