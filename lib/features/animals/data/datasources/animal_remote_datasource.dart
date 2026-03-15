import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/data/models/animal_model.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

// ─── Abstract ────────────────────────────────────────────────────────────────

abstract class AnimalRemoteDataSource {
  /// Heyvanları real-time stream kimi qaytar (Firestore)
  Stream<List<AnimalModel>> watchAnimals(String ownerId);

  /// Heyvan əlavə et → yaradılmış model qaytar
  Future<AnimalModel> addAnimal(AnimalModel animal);

  /// Heyvan məlumatlarını yenilə (ad, tip, çip, zona, qeyd)
  Future<void> updateAnimal(AnimalModel animal);

  /// Heyvanı sil (Firestore + Realtime DB)
  Future<void> deleteAnimal(String animalId);

  /// GPS izləməni başlat
  Future<void> startTracking(String animalId);

  /// GPS izləməni dayandır
  Future<void> stopTracking(String animalId);

  /// Heyvanın canlı GPS mövqeyini dinlə (Realtime DB)
  Stream<Map<String, dynamic>?> watchLocation(String animalId);

  /// GPS mövqeyini yenilə (Realtime DB)
  Future<void> updateLocation(
    String animalId,
    double lat,
    double lng,
    double speed,
    double battery,
  );

  /// Heyvanın zona statusunu Firestore-da yenilə
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

  // Firestore collection referansı
  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('animals');

  // ── Watch ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<AnimalModel>> watchAnimals(String ownerId) {
    AppLogger.melumat('ANIMAL DS', 'Heyvanlar dinlənilir: $ownerId');
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .asyncMap((snap) async {
      final animals = <AnimalModel>[];

      for (final doc in snap.docs) {
        try {
          final model = AnimalModel.fromFirestore(doc);

          // Realtime DB-dən canlı GPS məlumatını birləşdir
          final locationSnap = await _database.ref('locations/${doc.id}').get();
          if (locationSnap.exists && locationSnap.value != null) {
            final loc = Map<String, dynamic>.from(locationSnap.value as Map);
            animals.add(model.copyWithModel(
              lastLatitude: (loc['lat'] as num?)?.toDouble(),
              lastLongitude: (loc['lng'] as num?)?.toDouble(),
              lastUpdate: loc['updatedAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      (loc['updatedAt'] as num).toInt())
                  : null,
              batteryLevel: (loc['battery'] as num?)?.toDouble(),
              speed: (loc['speed'] as num?)?.toDouble(),
            ));
          } else {
            animals.add(model);
          }
        } catch (e) {
          AppLogger.xeta('ANIMAL DS', 'Parse xətası: ${doc.id}',
              xetaObyekti: e);
        }
      }

      AppLogger.ugur('ANIMAL DS', '${animals.length} heyvan yükləndi');
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
      // Firestore sənədini sil
      await _col.doc(animalId).delete();
      // Realtime DB-dəki GPS məlumatını sil
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

  @override
  Future<void> updateLocation(
    String animalId,
    double lat,
    double lng,
    double speed,
    double battery,
  ) async {
    try {
      await _database.ref('locations/$animalId').set({
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'battery': battery,
        'updatedAt': ServerValue.timestamp,
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
        'zoneId': zoneId,
        'zoneName': zoneName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.geofenceHadise(
        animalId,
        zoneName ?? 'Naməlum',
        status == AnimalZoneStatus.inside,
      );
    } catch (e) {
      AppLogger.xeta('ANIMAL DS', 'Zona status xətası', xetaObyekti: e);
      rethrow;
    }
  }
}
