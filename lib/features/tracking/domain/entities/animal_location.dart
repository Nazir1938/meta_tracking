import 'package:equatable/equatable.dart';

enum AnimalStatus { inside, outside, alert }

class AnimalLocationEntity extends Equatable {
  final String animalId;
  final String animalName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed;
  final double accuracy;
  final AnimalStatus status;
  final String? zoneId;

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
