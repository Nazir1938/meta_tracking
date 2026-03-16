import '../entities/animal_entity.dart';

abstract class AnimalRepository {
  Stream<List<AnimalEntity>> watchAnimals(String ownerId);

  Future<AnimalEntity> addAnimal({
    required String name,
    required AnimalType type,
    required String ownerId,
    String? chipId,
    String? notes,
    String? zoneId,
    String? zoneName,
  });

  Future<void> updateAnimal(AnimalEntity animal);
  Future<void> deleteAnimal(String animalId);

  /// GPS izləməni Firestore-da aktiv et (isTracking = true)
  Future<void> startTracking(String animalId);

  /// GPS izləməni Firestore-da dayandır (isTracking = false)
  Future<void> stopTracking(String animalId);

  Stream<Map<String, dynamic>?> watchLocation(String animalId);

  Future<void> updateLocation(
    String animalId,
    double lat,
    double lng,
    double speed,
    double battery,
  );

  Future<void> updateZoneStatus(
    String animalId,
    AnimalZoneStatus status,
    String? zoneId,
    String? zoneName,
  );
}
