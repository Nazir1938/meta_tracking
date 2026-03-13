import 'package:equatable/equatable.dart';

enum AnimalStatus { inside, outside, alert }

class AnimalLocationEntity extends Equatable {
  final String animalId;
  final String animalName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed; // km/h
  final double accuracy; // metres
  final AnimalStatus status;
  final String? zoneId; // Əgər məsuliyyətdədirsə

  const AnimalLocationEntity({
    required this.animalId,
    required this.animalName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.speed,
    required this.accuracy,
    required this.status,
    this.zoneId,
  });

  @override
  List<Object?> get props => [
    animalId,
    animalName,
    latitude,
    longitude,
    timestamp,
    speed,
    accuracy,
    status,
    zoneId,
  ];

  AnimalLocationEntity copyWith({
    String? animalId,
    String? animalName,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? speed,
    double? accuracy,
    AnimalStatus? status,
    String? zoneId,
  }) {
    return AnimalLocationEntity(
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      status: status ?? this.status,
      zoneId: zoneId ?? this.zoneId,
    );
  }
}

class GeofenceAlertEntity extends Equatable {
  final String id;
  final String animalId;
  final String animalName;
  final String zoneId;
  final String zoneName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String message; // "Inside zone" / "Outside zone" / "Speed alert"
  final bool isRead;

  const GeofenceAlertEntity({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.zoneId,
    required this.zoneName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.message,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
    id,
    animalId,
    animalName,
    zoneId,
    zoneName,
    latitude,
    longitude,
    timestamp,
    message,
    isRead,
  ];
}