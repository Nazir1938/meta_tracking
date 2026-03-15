import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';

// ─── Abstract ────────────────────────────────────────────────────────────────

abstract class ZoneRemoteDataSource {
  /// Bütün zonaları real-time stream kimi qaytar
  Stream<List<ZoneEntity>> watchZones(String ownerId);

  /// Zona yarat → yaradılmış entity qaytar
  Future<ZoneEntity> createZone(ZoneEntity zone, String ownerId);

  /// Zona yenilə
  Future<void> updateZone(ZoneEntity zone);

  /// Zona sil
  Future<void> deleteZone(String zoneId);
}

// ─── Implementation ──────────────────────────────────────────────────────────

class ZoneRemoteDataSourceImpl implements ZoneRemoteDataSource {
  final FirebaseFirestore _db;

  ZoneRemoteDataSourceImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('zones');

  // ── Watch ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<ZoneEntity>> watchZones(String ownerId) {
    AppLogger.melumat('ZONE DS', 'Zonalar dinlənilir: $ownerId');
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      final zones = snap.docs
          .map((doc) => _fromFirestore(doc))
          .whereType<ZoneEntity>()
          .toList();
      AppLogger.ugur('ZONE DS', '${zones.length} zona alındı');
      return zones;
    });
  }

  // ── Create ────────────────────────────────────────────────────────────────

  @override
  Future<ZoneEntity> createZone(ZoneEntity zone, String ownerId) async {
    AppLogger.melumat('ZONE DS', 'Zona yaradılır: ${zone.name}');
    final ref = await _col.add(_toFirestore(zone, ownerId));
    AppLogger.ugur('ZONE DS', 'Zona Firestore-a yazıldı: ${ref.id}');
    return zone.copyWith(id: ref.id);
  }

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  Future<void> updateZone(ZoneEntity zone) async {
    AppLogger.melumat('ZONE DS', 'Zona yenilənir: ${zone.id}');
    await _col.doc(zone.id).update({
      'name': zone.name,
      'latitude': zone.latitude,
      'longitude': zone.longitude,
      'radiusInMeters': zone.radiusInMeters,
      'isActive': zone.isActive,
      'description': zone.description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    AppLogger.ugur('ZONE DS', 'Zona yeniləndi: ${zone.id}');
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteZone(String zoneId) async {
    AppLogger.melumat('ZONE DS', 'Zona silinir: $zoneId');
    await _col.doc(zoneId).delete();
    AppLogger.ugur('ZONE DS', 'Zona silindi: $zoneId');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toFirestore(ZoneEntity z, String ownerId) => {
        'ownerId': ownerId,
        'name': z.name,
        'latitude': z.latitude,
        'longitude': z.longitude,
        'radiusInMeters': z.radiusInMeters,
        'isActive': z.isActive,
        'description': z.description,
        'createdAt': Timestamp.fromDate(z.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  ZoneEntity? _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data()!;
      return ZoneEntity(
        id: doc.id,
        name: d['name'] as String? ?? '',
        latitude: (d['latitude'] as num).toDouble(),
        longitude: (d['longitude'] as num).toDouble(),
        radiusInMeters: (d['radiusInMeters'] as num).toDouble(),
        isActive: d['isActive'] as bool? ?? true,
        description: d['description'] as String?,
        createdAt:
            (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      AppLogger.xeta('ZONE DS', 'Parse xətası: ${doc.id}', xetaObyekti: e);
      return null;
    }
  }
}