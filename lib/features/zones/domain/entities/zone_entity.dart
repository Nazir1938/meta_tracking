import 'package:equatable/equatable.dart';

class ZoneLatLng extends Equatable {
  final double latitude;
  final double longitude;

  const ZoneLatLng({required this.latitude, required this.longitude});

  Map<String, dynamic> toMap() => {
        'lat': latitude,
        'lng': longitude,
      };

  factory ZoneLatLng.fromMap(Map<String, dynamic> m) => ZoneLatLng(
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lng'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Zona növü: dairə (radius) ya da çoxbucaqlı (polygon)
enum ZoneType { circle, polygon }

class ZoneEntity extends Equatable {
  final String id;
  final String name;
  final double latitude; // Mərkəz (dairə üçün) / ağırlıq mərkəzi (polygon üçün)
  final double longitude;
  final double
      radiusInMeters; // Dairə üçün radius; polygon üçün bounding radius (hesab üçün)
  final DateTime createdAt;
  final bool isActive;
  final String? description;
  final String? ownerId;
  final bool isPublic;

  /// Zona növü
  final ZoneType zoneType;

  /// Polygon nöqtələri — yalnız zoneType == polygon olduqda istifadə olunur
  final List<ZoneLatLng> polygonPoints;

  /// Polygon sahəsi km² — yalnız polygon üçün hesablanır, saxlanır
  final double? areaKm2;

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
    this.zoneType = ZoneType.circle,
    this.polygonPoints = const [],
    this.areaKm2,
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
        ownerId,
        isPublic,
        zoneType,
        polygonPoints,
        areaKm2,
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
    ZoneType? zoneType,
    List<ZoneLatLng>? polygonPoints,
    double? areaKm2,
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
      zoneType: zoneType ?? this.zoneType,
      polygonPoints: polygonPoints ?? this.polygonPoints,
      areaKm2: areaKm2 ?? this.areaKm2,
    );
  }

  /// Göstəriləcək sahə mətni
  String get displayArea {
    if (zoneType == ZoneType.polygon && areaKm2 != null) {
      return '${areaKm2!.toStringAsFixed(3)} km²';
    }
    final r = radiusInMeters / 1000;
    final area = 3.14159 * r * r;
    return '${area.toStringAsFixed(3)} km²';
  }

  /// Göstəriləcək radius/ölçü mətni
  String get displayRadius {
    if (zoneType == ZoneType.polygon) {
      return areaKm2 != null
          ? '${areaKm2!.toStringAsFixed(3)} km²'
          : '${(radiusInMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${(radiusInMeters / 1000).toStringAsFixed(2)} km';
  }
}
