import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/data/models/animal_model.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

// ─── Abstract ────────────────────────────────────────────────────────────────

abstract class AnimalRemoteDataSource {
  Stream<List<AnimalModel>> watchAnimals(String ownerId);
  Future<AnimalModel> addAnimal(AnimalModel animal);
  Future<void> updateAnimal(AnimalModel animal);
  Future<void> deleteAnimal(String animalId);
  Future<void> startTracking(String animalId);
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

// ─── Implementation ──────────────────────────────────────────────────────────

class AnimalRemoteDataSourceImpl implements AnimalRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  AnimalRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('animals');

  // ── Watch ─────────────────────────────────────────────────────────────────
  // FIX: asyncMap + RTDB.get() əvəzinə sadə .map() — koordinatlar artıq
  // Firestore-da saxlanır (updateLocation həm FS-ə yazır), buna görə stream
  // GPS yeniləndikdə dərhal tetiklenir və xəritə markeri yenilənir.

  @override
  Stream<List<AnimalModel>> watchAnimals(String ownerId) {
    AppLogger.melumat('ANIMAL DS', 'Heyvanlar dinlənilir: $ownerId');
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      final animals = <AnimalModel>[];
      for (final doc in snap.docs) {
        try {
          animals.add(AnimalModel.fromFirestore(doc));
        } catch (e) {
          AppLogger.xeta('ANIMAL DS', 'Parse xətası: ${doc.id}',
              xetaObyekti: e);
        }
      }
      AppLogger.ugur('ANIMAL DS', '${animals.length} heyvan alındı');
      return animals;
    });
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  @override
  Future<AnimalModel> addAnimal(AnimalModel animal) async {
    AppLogger.melumat('ANIMAL DS', 'Heyvan əlavə edilir: ${animal.name}');
    try {
      final ref = await _col.add({
        ...animal.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.ugur('ANIMAL DS', 'Heyvan yaradıldı: ${ref.id}');
      return AnimalModel(
        id: ref.id,
        name: animal.name,
        type: animal.type,
        ownerId: animal.ownerId,
        chipId: animal.chipId,
        isTracking: false,
        notes: animal.notes,
        zoneId: animal.zoneId,
        zoneName: animal.zoneName,
        zoneStatus: AnimalZoneStatus.outside,
        createdAt: DateTime.now(),
      );
    } catch (e, st) {
      AppLogger.xeta('ANIMAL DS', 'Əlavə etmə xətası',
          xetaObyekti: e, yiginIzi: st);
      rethrow;
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  Future<void> updateAnimal(AnimalModel animal) async {
    AppLogger.melumat('ANIMAL DS', 'Heyvan yenilənir: ${animal.id}');
    try {
      await _col.doc(animal.id).update({
        ...animal.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.ugur('ANIMAL DS', 'Heyvan yeniləndi: ${animal.id}');
    } catch (e, st) {
      AppLogger.xeta('ANIMAL DS', 'Yeniləmə xətası',
          xetaObyekti: e, yiginIzi: st);
      rethrow;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteAnimal(String animalId) async {
    AppLogger.melumat('ANIMAL DS', 'Heyvan silinir: $animalId');
    try {
      await _col.doc(animalId).delete();
      await _database.ref('locations/$animalId').remove();
      AppLogger.ugur('ANIMAL DS', 'Heyvan silindi: $animalId');
    } catch (e, st) {
      AppLogger.xeta('ANIMAL DS', 'Silmə xətası', xetaObyekti: e, yiginIzi: st);
      rethrow;
    }
  }

  // ── Tracking ──────────────────────────────────────────────────────────────

  @override
  Future<void> startTracking(String animalId) async {
    AppLogger.melumat('ANIMAL DS', 'İzləmə başladılır: $animalId');
    await _col.doc(animalId).update({
      'isTracking': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.ugur('ANIMAL DS', 'İzləmə başladı: $animalId');
  }

  @override
  Future<void> stopTracking(String animalId) async {
    AppLogger.melumat('ANIMAL DS', 'İzləmə dayandırılır: $animalId');
    await _col.doc(animalId).update({
      'isTracking': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.xeberdarliq('ANIMAL DS', 'İzləmə dayandırıldı: $animalId');
  }

  // ── Location ──────────────────────────────────────────────────────────────

  @override
  Stream<Map<String, dynamic>?> watchLocation(String animalId) {
    return _database.ref('locations/$animalId').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  // FIX: updateLocation artıq həm RTDB-ə həm də Firestore-a yazır.
  // ┌─────────────────────────────────────────────────────────────────┐
  // │ Niyə ikisi də?                                                  │
  // │ • RTDB  → real GPS cihazları üçün saxlanır (gələcək üçün)      │
  // │ • Firestore → watchAnimals stream-ini tetikləyir,               │
  // │              telefon GPS test rejimində xəritəni yeniləyir      │
  // └─────────────────────────────────────────────────────────────────┘

  @override
  Future<void> updateLocation(
    String animalId,
    double lat,
    double lng,
    double speed,
    double battery,
  ) async {
    try {
      // 1. RTDB-ə yaz (real GPS cihazları üçün əsas mənbə saxlanır)
      await _database.ref('locations/$animalId').set({
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'battery': battery,
        'updatedAt': ServerValue.timestamp,
      });

      // 2. Firestore-a da yaz → watchAnimals stream tetiklənir →
      //    BlocBuilder yenilənir → xəritədə marker real-time hərəkət edir
      await _col.doc(animalId).update({
        'lastLatitude': lat,
        'lastLongitude': lng,
        'speed': speed,
        'batteryLevel': battery,
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      AppLogger.melumat(
          'ANIMAL DS', 'Mövqe yeniləndi: $animalId → ($lat, $lng)');
    } catch (e) {
      AppLogger.xeta('ANIMAL DS', 'Mövqe yeniləmə xətası', xetaObyekti: e);
      rethrow;
    }
  }

  // ── Zone Status ───────────────────────────────────────────────────────────

  @override
  Future<void> updateZoneStatus(
    String animalId,
    AnimalZoneStatus status,
    String? zoneId,
    String? zoneName,
  ) async {
    try {
      await _col.doc(animalId).update({
        'zoneStatus': status.name,
        if (zoneId != null) 'zoneId': zoneId,
        if (zoneName != null) 'zoneName': zoneName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.xeta('ANIMAL DS', 'Zona status xətası', xetaObyekti: e);
      rethrow;
    }
  }
}
