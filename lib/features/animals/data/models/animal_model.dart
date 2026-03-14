import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/animal_entity.dart';

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

  factory AnimalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnimalModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: _parseType(data['type']),
      ownerId: data['ownerId'] ?? '',
      chipId: data['chipId'],
      isTracking: data['isTracking'] ?? false,
      zoneStatus: _parseZoneStatus(data['zoneStatus']),
      zoneName: data['zoneName'],
      zoneId: data['zoneId'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type.name,
    'ownerId': ownerId,
    'chipId': chipId,
    'isTracking': isTracking,
    'zoneStatus': zoneStatus.name,
    'zoneName': zoneName,
    'zoneId': zoneId,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  static AnimalType _parseType(String? t) {
    return AnimalType.values.firstWhere(
      (e) => e.name == t,
      orElse: () => AnimalType.other,
    );
  }

  static AnimalZoneStatus _parseZoneStatus(String? s) {
    return AnimalZoneStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => AnimalZoneStatus.outside,
    );
  }

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
}