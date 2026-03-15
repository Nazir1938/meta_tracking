import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/herds/domain/entities/herd_entity.dart';

abstract class HerdRemoteDataSource {
  Stream<List<HerdEntity>> watchHerds(String ownerId);
  Future<HerdEntity> createHerd(HerdEntity herd);
  Future<void> updateHerd(HerdEntity herd);
  Future<void> deleteHerd(String herdId);
  Future<void> addAnimalToHerd(String herdId, String animalId);
  Future<void> removeAnimalFromHerd(String herdId, String animalId);
  Future<void> addAnimalsToHerd(String herdId, List<String> animalIds);
}

class HerdRemoteDataSourceImpl implements HerdRemoteDataSource {
  final FirebaseFirestore _db;

  HerdRemoteDataSourceImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('herds');

  // ── Watch ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<HerdEntity>> watchHerds(String ownerId) {
    AppLogger.melumat('HERD DS', 'Naxırlar dinlənilir: $ownerId');
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      final herds = snap.docs
          .map((doc) => _fromFirestore(doc))
          .whereType<HerdEntity>()
          .toList();
      AppLogger.ugur('HERD DS', '${herds.length} naxır alındı');
      return herds;
    });
  }

  // ── Create ────────────────────────────────────────────────────────────────

  @override
  Future<HerdEntity> createHerd(HerdEntity herd) async {
    AppLogger.melumat('HERD DS', 'Naxır yaradılır: ${herd.name}');
    final ref = await _col.add(_toFirestore(herd));
    AppLogger.ugur('HERD DS', 'Naxır yaradıldı: ${ref.id}');
    return herd.copyWith(id: ref.id);
  }

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  Future<void> updateHerd(HerdEntity herd) async {
    AppLogger.melumat('HERD DS', 'Naxır yenilənir: ${herd.id}');
    await _col.doc(herd.id).update({
      'name': herd.name,
      'animalIds': herd.animalIds,
      'isTracking': herd.isTracking,
      'description': herd.description,
      'separationThresholdMeters': herd.separationThresholdMeters,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.ugur('HERD DS', 'Naxır yeniləndi: ${herd.id}');
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteHerd(String herdId) async {
    AppLogger.melumat('HERD DS', 'Naxır silinir: $herdId');
    await _col.doc(herdId).delete();
    AppLogger.ugur('HERD DS', 'Naxır silindi: $herdId');
  }

  // ── Animal management ─────────────────────────────────────────────────────

  @override
  Future<void> addAnimalToHerd(String herdId, String animalId) async {
    AppLogger.melumat('HERD DS', 'Heyvan naxıra əlavə edilir: $animalId → $herdId');
    await _col.doc(herdId).update({
      'animalIds': FieldValue.arrayUnion([animalId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeAnimalFromHerd(String herdId, String animalId) async {
    AppLogger.melumat('HERD DS', 'Heyvan naxırdan çıxarılır: $animalId');
    await _col.doc(herdId).update({
      'animalIds': FieldValue.arrayRemove([animalId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addAnimalsToHerd(String herdId, List<String> animalIds) async {
    AppLogger.melumat('HERD DS',
        '${animalIds.length} heyvan naxıra əlavə edilir: $herdId');
    await _col.doc(herdId).update({
      'animalIds': FieldValue.arrayUnion(animalIds),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toFirestore(HerdEntity h) => {
        'name': h.name,
        'ownerId': h.ownerId,
        'animalIds': h.animalIds,
        'animalType': h.animalType,
        'isTracking': h.isTracking,
        'description': h.description,
        'separationThresholdMeters': h.separationThresholdMeters,
        'createdAt': Timestamp.fromDate(h.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  HerdEntity? _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data()!;
      return HerdEntity(
        id: doc.id,
        name: d['name'] as String? ?? '',
        ownerId: d['ownerId'] as String? ?? '',
        animalIds: List<String>.from(d['animalIds'] as List? ?? []),
        animalType: d['animalType'] as String?,
        isTracking: d['isTracking'] as bool? ?? false,
        description: d['description'] as String?,
        separationThresholdMeters:
            (d['separationThresholdMeters'] as num?)?.toDouble() ?? 500,
        createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      AppLogger.xeta('HERD DS', 'Parse xətası: ${doc.id}', xetaObyekti: e);
      return null;
    }
  }
}