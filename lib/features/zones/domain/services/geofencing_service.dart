import 'dart:math' show cos, sqrt, pow, pi, atan2, sin;
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';
import '../entities/zone_entity.dart';

class GeofencingService {
  // ── Məsafə hesabla (Haversine) ────────────────────────────────────────────
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  // ── Zona daxilindəmi? ────────────────────────────────────────────────────
  static bool isInsideZone(AnimalLocationEntity location, ZoneEntity zone) {
    if (zone.zoneType == ZoneType.polygon && zone.polygonPoints.length >= 3) {
      return _isPointInPolygon(
        location.latitude,
        location.longitude,
        zone.polygonPoints,
      );
    }
    // Dairə
    final distance = calculateDistance(
      location.latitude,
      location.longitude,
      zone.latitude,
      zone.longitude,
    );
    return distance <= zone.radiusInMeters;
  }

  // ── Ray-casting algoritması (polygon) ────────────────────────────────────
  static bool _isPointInPolygon(
    double lat,
    double lng,
    List<ZoneLatLng> polygon,
  ) {
    int intersections = 0;
    final n = polygon.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersect = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) intersections++;
    }

    return intersections % 2 == 1;
  }

  // ── Heyvan statusunu yenilə ───────────────────────────────────────────────
  static AnimalLocationEntity updateAnimalStatus(
    AnimalLocationEntity location,
    List<ZoneEntity> zones,
  ) {
    AnimalStatus newStatus = AnimalStatus.outside;
    String? insideZoneId;

    for (final zone in zones) {
      if (isInsideZone(location, zone)) {
        newStatus = AnimalStatus.inside;
        insideZoneId = zone.id;
        break;
      }
    }

    return location.copyWith(status: newStatus, zoneId: insideZoneId);
  }

  // ── Alert lazımdırsa ──────────────────────────────────────────────────────
  static bool shouldGenerateAlert(
    AnimalLocationEntity prev,
    AnimalLocationEntity curr,
  ) {
    if (prev.status == curr.status) return false;
    return (prev.status == AnimalStatus.inside &&
            curr.status == AnimalStatus.outside) ||
        (prev.status == AnimalStatus.outside &&
            curr.status == AnimalStatus.inside);
  }

  // ── Zona məlumatı ─────────────────────────────────────────────────────────
  static Map<String, dynamic> getZoneInfo(
    AnimalLocationEntity location,
    ZoneEntity zone,
  ) {
    final isInside = isInsideZone(location, zone);
    final distance = calculateDistance(
      location.latitude,
      location.longitude,
      zone.latitude,
      zone.longitude,
    );
    return {
      'isInside': isInside,
      'distance': distance,
      'distanceFromBorder': (distance - zone.radiusInMeters).abs(),
      'radiusInMeters': zone.radiusInMeters,
      'percentageInside': (distance / zone.radiusInMeters * 100).clamp(0, 100),
    };
  }

  // ── Polygon sahəsini km² hesabla (Shoelace formula) ───────────────────────
  static double calculatePolygonAreaKm2(List<ZoneLatLng> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    final n = points.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final xi =
          points[i].longitude * 111320 * cos(_toRadians(points[i].latitude));
      final yi = points[i].latitude * 111320;
      final xj =
          points[j].longitude * 111320 * cos(_toRadians(points[j].latitude));
      final yj = points[j].latitude * 111320;

      area += xi * yj;
      area -= xj * yi;
    }

    // (area / 2).abs() → m²,  / 1000000 → km²
    final areaM2 = (area / 2).abs();
    return areaM2 / 1000000;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
