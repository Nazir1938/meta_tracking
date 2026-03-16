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
      lastLatitude: (d['lastLatitude'] as num?)?.toDouble(),
      lastLongitude: (d['lastLongitude'] as num?)?.toDouble(),
      lastUpdate: (d['lastUpdate'] as Timestamp?)?.toDate(),
      speed: (d['speed'] as num?)?.toDouble(),
      batteryLevel: (d['batteryLevel'] as num?)?.toDouble(),
    );
  }

  // FIX: zoneId/zoneName null olduqda FieldValue.delete() istifadə et.
  // Əvvəl `if (zoneId != null)` şərti field-ləri ümumiyyətlə yazmırdı —
  // Firestore-da köhnə dəyər qalırdı, "Çıxar" işləmirdi.
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type.name,
        'ownerId': ownerId,
        'chipId': chipId ?? FieldValue.delete(),
        'isTracking': isTracking,
        'zoneStatus': zoneStatus.name,
        'zoneId': zoneId ?? FieldValue.delete(),
        'zoneName': zoneName ?? FieldValue.delete(),
        'notes': notes ?? FieldValue.delete(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

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
      batteryLevel: batteryLevel ?? this.batteryLevel,
      speed: speed ?? this.speed,
      zoneStatus: zoneStatus ?? this.zoneStatus,
      zoneName: zoneName ?? this.zoneName,
      zoneId: zoneId ?? this.zoneId,
      notes: notes,
      createdAt: createdAt,
    );
  }

  static AnimalType _parseType(String? s) {
    switch (s) {
      case 'cattle':
        return AnimalType.cattle;
      case 'sheep':
        return AnimalType.sheep;
      case 'goat':
        return AnimalType.goat;
      case 'horse':
        return AnimalType.horse;
      case 'pig':
        return AnimalType.pig;
      default:
        return AnimalType.cattle;
    }
  }

  static AnimalZoneStatus _parseZoneStatus(String? s) {
    switch (s) {
      case 'inside':
        return AnimalZoneStatus.inside;
      case 'outside':
        return AnimalZoneStatus.outside;
      case 'alert':
        return AnimalZoneStatus.alert;
      default:
        return AnimalZoneStatus.outside;
    }
  }
}
