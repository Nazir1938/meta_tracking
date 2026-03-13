import 'dart:math' show cos, sqrt, pow, pi, atan2, sin;
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';
import '../entities/zone.dart';

class GeofencingService {
  /// Haversine formula ilə iki nöqtə arasındakı məsafəni hesablayır (metrlə)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Heyvanın zonada olub-olmadığını yoxlayır
  static bool isInsideZone(AnimalLocationEntity location, ZoneEntity zone) {
    final distance = calculateDistance(
      location.latitude,
      location.longitude,
      zone.latitude,
      zone.longitude,
    );
    return distance <= zone.radiusInMeters;
  }

  /// Heyvanın zona vəziyyətini yeniləyir
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

  /// Zona daxil/çıxış vəziyyəti dəyişdikdə xəbərdarlıq generasiya edilsin?
  static bool shouldGenerateAlert(
    AnimalLocationEntity previousLocation,
    AnimalLocationEntity currentLocation,
  ) {
    final statusChanged = previousLocation.status != currentLocation.status;

    if (statusChanged &&
        previousLocation.status == AnimalStatus.inside &&
        currentLocation.status == AnimalStatus.outside) {
      return true; // Zona dışına çıxdı
    }

    if (statusChanged &&
        previousLocation.status == AnimalStatus.outside &&
        currentLocation.status == AnimalStatus.inside) {
      return true; // Zonaya daxil oldu
    }

    return false;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Heyvanın zona ilə əlaqəli məlumatlarını qaytarır
  static Map<String, dynamic> getZoneInfo(
    AnimalLocationEntity location,
    ZoneEntity zone,
  ) {
    final distance = calculateDistance(
      location.latitude,
      location.longitude,
      zone.latitude,
      zone.longitude,
    );

    final isInside = distance <= zone.radiusInMeters;
    final distanceFromBorder = (distance - zone.radiusInMeters).abs();

    return {
      'isInside': isInside,
      'distance': distance,
      'distanceFromBorder': distanceFromBorder,
      'radiusInMeters': zone.radiusInMeters,
      'percentageInside': (distance / zone.radiusInMeters * 100).clamp(0, 100),
    };
  }
}
