import 'package:equatable/equatable.dart';

enum AnimalType { cattle, sheep, horse, goat, pig, other }

enum AnimalZoneStatus { inside, outside, alert }

class AnimalEntity extends Equatable {
  final String id;
  final String name;
  final AnimalType type;
  final String ownerId;
  final String? chipId;
  final bool isTracking;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastUpdate;
  final AnimalZoneStatus zoneStatus;
  final String? zoneName;
  final String? zoneId;
  final double? batteryLevel;
  final double? speed;
  final String? notes;
  final DateTime createdAt;

  const AnimalEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    this.chipId,
    required this.isTracking,
    this.lastLatitude,
    this.lastLongitude,
    this.lastUpdate,
    this.zoneStatus = AnimalZoneStatus.outside,
    this.zoneName,
    this.zoneId,
    this.batteryLevel,
    this.speed,
    this.notes,
    required this.createdAt,
  });

  // FIX: zoneId və zoneName props-a əlavə edildi.
  // Əvvəl props-da yox idi — Equatable zoneId dəyişəndə obyektləri
  // "eyni" hesab edirdi, BLoC yeni state emit etmirdi, UI yenilənmirdi.
  @override
  List<Object?> get props => [
        id,
        name,
        type,
        ownerId,
        isTracking,
        zoneStatus,
        zoneId,
        zoneName,
      ];

  /// zoneId/zoneName null-a sıfırlamaq üçün clearZone: true istifadə et.
  /// Dart-da nullable parametrləri null-a sıfırlamaq mümkün deyil (?? operatoru),
  /// buna görə explicit flag əlavə edilib.
  AnimalEntity copyWith({
    String? id,
    String? name,
    AnimalType? type,
    String? ownerId,
    String? chipId,
    bool? isTracking,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? lastUpdate,
    AnimalZoneStatus? zoneStatus,
    String? zoneName,
    String? zoneId,
    double? batteryLevel,
    double? speed,
    String? notes,
    DateTime? createdAt,
    bool clearZone = false,
  }) {
    return AnimalEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      chipId: chipId ?? this.chipId,
      isTracking: isTracking ?? this.isTracking,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      zoneStatus: zoneStatus ?? this.zoneStatus,
      zoneName: clearZone ? null : (zoneName ?? this.zoneName),
      zoneId: clearZone ? null : (zoneId ?? this.zoneId),
      batteryLevel: batteryLevel ?? this.batteryLevel,
      speed: speed ?? this.speed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeEmoji {
    switch (type) {
      case AnimalType.cattle:
        return '🐄';
      case AnimalType.sheep:
        return '🐑';
      case AnimalType.horse:
        return '🐎';
      case AnimalType.goat:
        return '🐐';
      case AnimalType.pig:
        return '🐖';
      case AnimalType.other:
        return '🐾';
    }
  }

  String get typeName {
    switch (type) {
      case AnimalType.cattle:
        return 'İnək';
      case AnimalType.sheep:
        return 'Qoyun';
      case AnimalType.horse:
        return 'At';
      case AnimalType.goat:
        return 'Keçi';
      case AnimalType.pig:
        return 'Donuz';
      case AnimalType.other:
        return 'Digər';
    }
  }
}
