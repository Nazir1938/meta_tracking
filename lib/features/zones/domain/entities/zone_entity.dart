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
  final String? ownerId;

  /// true → bütün istifadəçilər görə bilər (ictimai otlaq, meşə və s.)
  /// false → yalnız sahibi görür (şəxsi ərazi)
  final bool isPublic;

  const ZoneEntity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.createdAt,
    this.isActive = true,
    this.description,
    this.ownerId,
    this.isPublic = false,
  });

  @override
  List<Object?> get props => [
        id, name, latitude, longitude,
        radiusInMeters, createdAt, isActive,
        description, ownerId, isPublic,
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
    String? ownerId,
    bool? isPublic,
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
      ownerId: ownerId ?? this.ownerId,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}