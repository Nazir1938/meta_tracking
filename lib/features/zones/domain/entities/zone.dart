import 'package:equatable/equatable.dart';

class ZoneEntity extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final DateTime createdAt;
  final bool isActive;
  final String? description;

  const ZoneEntity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.createdAt,
    this.isActive = true,
    this.description,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    latitude,
    longitude,
    radiusInMeters,
    createdAt,
    isActive,
    description,
  ];

  ZoneEntity copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusInMeters,
    DateTime? createdAt,
    bool? isActive,
    String? description,
  }) {
    return ZoneEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }
}
