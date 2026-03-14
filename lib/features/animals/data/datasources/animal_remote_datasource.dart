import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import '../models/animal_model.dart';

abstract class AnimalRemoteDataSource {
  Stream<List<AnimalModel>> watchAnimals(String ownerId);
  Future<AnimalModel> addAnimal(AnimalModel animal);
  Future<void> updateAnimal(AnimalModel animal);
  Future<void> deleteAnimal(String animalId);
  Future<void> startTracking(String animalId);
  Future<void> stopTracking(String animalId);
  Stream<Map<String, dynamic>?> watchLocation(String animalId);
  Future<void> updateLocation(String animalId, double lat, double lng, double speed, double battery);
}

class AnimalRemoteDataSourceImpl implements AnimalRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  AnimalRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance;

  @override
  Stream<List<AnimalModel>> watchAnimals(String ownerId) {
    AppLogger.melumat('ANIMAL DS', 'Heyvanlar dinlənilir: $ownerId');
    return _firestore
        .collection('animals')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
          final animals = snap.docs.map(AnimalModel.fromFirestore).toList();
          AppLogger.ugur('ANIMAL DS', '${animals.length} heyvan alındı');
          return animals;
        });
  }

  @override
  Future<AnimalModel> addAnimal(AnimalModel animal) async {
    AppLogger.melumat('ANIMAL DS', 'Heyvan əlavə edilir: ${animal.name}');
    final ref = await _firestore.collection('animals').add(animal.toFirestore());
    AppLogger.ugur('ANIMAL DS', 'Heyvan yaradıldı: ${ref.id}');
    return AnimalModel(
      id: ref.id,
      name: animal.name,
      type: animal.type,
      ownerId: animal.ownerId,
      chipId: animal.chipId,
      isTracking: animal.isTracking,
      notes: animal.notes,
      createdAt: animal.createdAt,
    );
  }

  @override
  Future<void> updateAnimal(AnimalModel animal) async {
    AppLogger.melumat('ANIMAL DS', 'Heyvan yenilənir: ${animal.id}');
    await _firestore
        .collection('animals')
        .doc(animal.id)
        .update(animal.toFirestore());
    AppLogger.ugur('ANIMAL DS', 'Heyvan yeniləndi: ${animal.id}');
  }

  @override
  Future<void> deleteAnimal(String animalId) async {
    AppLogger.melumat('ANIMAL DS', 'Heyvan silinir: $animalId');
    await _firestore.collection('animals').doc(animalId).delete();
    await _database.ref('locations/$animalId').remove();
    AppLogger.ugur('ANIMAL DS', 'Heyvan silindi: $animalId');
  }

  @override
  Future<void> startTracking(String animalId) async {
    await _firestore.collection('animals').doc(animalId).update({'isTracking': true});
    AppLogger.ugur('ANIMAL DS', 'İzləmə başladı: $animalId');
  }

  @override
  Future<void> stopTracking(String animalId) async {
    await _firestore.collection('animals').doc(animalId).update({'isTracking': false});
    AppLogger.xeberdarliq('ANIMAL DS', 'İzləmə dayandırıldı: $animalId');
  }

  @override
  Stream<Map<String, dynamic>?> watchLocation(String animalId) {
    return _database.ref('locations/$animalId').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  @override
  Future<void> updateLocation(
    String animalId,
    double lat,
    double lng,
    double speed,
    double battery,
  ) async {
    await _database.ref('locations/$animalId').set({
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'battery': battery,
      'updatedAt': ServerValue.timestamp,
    });
    AppLogger.melumat('ANIMAL DS', 'Mövqe yeniləndi: $animalId → ($lat, $lng)');
  }
}