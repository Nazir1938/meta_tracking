import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

class AnimalModel extends AnimalEntity {
  const AnimalModel({
    required super.id,
    required super.name,
    required super.type,
    required super.ownerId,
    super.chipId,
    required super.isTracking,
    super.lastLatitude,
    super.lastLongitude,
    super.lastUpdate,
    super.zoneStatus,
    super.zoneName,
    super.zoneId,
    super.batteryLevel,
    super.speed,
    super.notes,
    required super.createdAt,
  });

  // ── Firestore-dan oxu ─────────────────────────────────────────────────────
  // FIX: lastLatitude, lastLongitude, speed, batteryLevel, lastUpdate
  // artıq Firestore-da saxlanır — updateLocation həm RTDB həm FS-ə yazır.

  factory AnimalModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AnimalModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      type: _parseType(d['type'] as String?),
      ownerId: d['ownerId'] as String? ?? '',
      chipId: d['chipId'] as String?,
      isTracking: d['isTracking'] as bool? ?? false,
      zoneStatus: _parseZoneStatus(d['zoneStatus'] as String?),
      zoneName: d['zoneName'] as String?,
      zoneId: d['zoneId'] as String?,
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // ── FIX: GPS koordinatları Firestore-dan oxunur ──────────────────────
      lastLatitude: (d['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (d['lastLongitude'] as num?)?.toDouble(),
      lastUpdate: (d['lastUpdate'] as Timestamp?)?.toDate(),
      speed: (d['speed'] as num?)?.toDouble(),
      batteryLevel: (d['batteryLevel'] as num?)?.toDouble(),
    );
  }

  // ── Firestore-a yaz ───────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type.name,
        'ownerId': ownerId,
        if (chipId != null) 'chipId': chipId,
        'isTracking': isTracking,
        'zoneStatus': zoneStatus.name,
        if (zoneId != null) 'zoneId': zoneId,
        if (zoneName != null) 'zoneName': zoneName,
        if (notes != null) 'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // ── GPS məlumatları ilə birləşdir (köhnə RTDB merge üçün saxlanır) ────────

  AnimalModel copyWithModel({
    double? lastLatitude,
    double? lastLongitude,
    DateTime? lastUpdate,
    double? batteryLevel,
    double? speed,
    AnimalZoneStatus? zoneStatus,
    String? zoneName,
    String? zoneId,
  }) {
    return AnimalModel(
      id: id,
      name: name,
      type: type,
      ownerId: ownerId,
      chipId: chipId,
      isTracking: isTracking,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      zoneStatus: zoneStatus ?? this.zoneStatus,
      zoneName: zoneName ?? this.zoneName,
      zoneId: zoneId ?? this.zoneId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      speed: speed ?? this.speed,
      notes: notes,
      createdAt: createdAt,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static AnimalType _parseType(String? s) {
    switch (s) {
      case 'cattle':
        return AnimalType.cattle;
      case 'sheep':
        return AnimalType.sheep;
      case 'horse':
        return AnimalType.horse;
      case 'goat':
        return AnimalType.goat;
      case 'pig':
        return AnimalType.pig;
      default:
        return AnimalType.other;
    }
  }

  static AnimalZoneStatus _parseZoneStatus(String? s) {
    switch (s) {
      case 'inside':
        return AnimalZoneStatus.inside;
      case 'alert':
        return AnimalZoneStatus.alert;
      default:
        return AnimalZoneStatus.outside;
    }
  }
}
