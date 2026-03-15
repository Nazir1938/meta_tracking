import '../entities/animal_entity.dart';

abstract class AnimalRepository {
  /// Heyvanları real-time stream kimi qaytar
  Stream<List<AnimalEntity>> watchAnimals(String ownerId);

  /// Yeni heyvan əlavə et
  Future<AnimalEntity> addAnimal({
    required String name,
    required AnimalType type,
    required String ownerId,
    String? chipId,
    String? notes,
    String? zoneId,
    String? zoneName,
  });

  /// Mövcud heyvanı yenilə
  Future<void> updateAnimal(AnimalEntity animal);

  /// Heyvanı sil
  Future<void> deleteAnimal(String animalId);

  /// Heyvanın canlı GPS mövqeyini dinlə
  Stream<Map<String, dynamic>?> watchLocation(String animalId);

  /// GPS mövqeyini yenilə
  Future<void> updateLocation(
    String animalId,
    double lat,
    double lng,
    double speed,
    double battery,
  );

  /// Zona statusunu yenilə (geofence nəticəsi)
  Future<void> updateZoneStatus(
    String animalId,
    AnimalZoneStatus status,
    String? zoneId,
    String? zoneName,
  );
}