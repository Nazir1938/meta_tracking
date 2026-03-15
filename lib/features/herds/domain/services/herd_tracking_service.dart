import 'dart:math' show cos, sqrt, pow, pi, atan2, sin;
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/herds/domain/entities/herd_entity.dart';
import 'package:meta_tracking/features/herds/domain/entities/separation_alert.dart';

/// Sürü mərkəzi nəticəsi
class HerdCentroid {
  final double lat;
  final double lng;
  final int animalCount;

  const HerdCentroid({
    required this.lat,
    required this.lng,
    required this.animalCount,
  });
}

/// Sürüdən ayrılma yoxlaması nəticəsi
class HerdSeparationResult {
  /// Sürünün mərkəzi
  final HerdCentroid centroid;

  /// Sürüdən ayrılan heyvanlar
  final List<AnimalEntity> separatedAnimals;

  /// Sürü içindəki heyvanlar
  final List<AnimalEntity> inHerdAnimals;

  /// GPS məlumatı olmayan heyvanlar
  final List<AnimalEntity> noLocationAnimals;

  const HerdSeparationResult({
    required this.centroid,
    required this.separatedAnimals,
    required this.inHerdAnimals,
    required this.noLocationAnimals,
  });

  bool get hasSeparation => separatedAnimals.isNotEmpty;
}

class HerdTrackingService {
  // ── Məsafə hesabla (Haversine formula) ───────────────────────────────────

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _rad(double deg) => deg * pi / 180;

  // ── Sürünün centroid-ini hesabla ─────────────────────────────────────────
  // GPS məlumatı olan bütün heyvanların orta koordinatı

  static HerdCentroid? calculateCentroid(List<AnimalEntity> animals) {
    final located = animals
        .where((a) => a.lastLatitude != null && a.lastLongitude != null)
        .toList();

    if (located.isEmpty) return null;

    // Sadə ortalama (kiçik məsafələr üçün kifayətdir)
    final avgLat = located.map((a) => a.lastLatitude!).reduce((a, b) => a + b) /
        located.length;
    final avgLng =
        located.map((a) => a.lastLongitude!).reduce((a, b) => a + b) /
            located.length;

    return HerdCentroid(
      lat: avgLat,
      lng: avgLng,
      animalCount: located.length,
    );
  }

  // ── Sürüdən ayrılma yoxla ────────────────────────────────────────────────
  // Heyvanın centroid-dən məsafəsi threshold-u keçirsə → ayrıldı

  static HerdSeparationResult checkSeparation({
    required HerdEntity herd,
    required List<AnimalEntity> animals,
  }) {
    // Yalnız bu naxıra aid heyvanları filtr et
    final herdAnimals =
        animals.where((a) => herd.animalIds.contains(a.id)).toList();

    // GPS məlumatı olanlar
    final located = herdAnimals
        .where((a) => a.lastLatitude != null && a.lastLongitude != null)
        .toList();

    // GPS məlumatı olmayanlar
    final noLocation = herdAnimals
        .where((a) => a.lastLatitude == null || a.lastLongitude == null)
        .toList();

    // Centroid hesabla
    final centroid = calculateCentroid(located);
    if (centroid == null) {
      return HerdSeparationResult(
        centroid: const HerdCentroid(lat: 0, lng: 0, animalCount: 0),
        separatedAnimals: [],
        inHerdAnimals: [],
        noLocationAnimals: herdAnimals,
      );
    }

    final separated = <AnimalEntity>[];
    final inHerd = <AnimalEntity>[];

    for (final animal in located) {
      final dist = calculateDistance(
        animal.lastLatitude!,
        animal.lastLongitude!,
        centroid.lat,
        centroid.lng,
      );

      if (dist > herd.separationThresholdMeters) {
        separated.add(animal);
      } else {
        inHerd.add(animal);
      }
    }

    return HerdSeparationResult(
      centroid: centroid,
      separatedAnimals: separated,
      inHerdAnimals: inHerd,
      noLocationAnimals: noLocation,
    );
  }

  // ── Alert yarat ───────────────────────────────────────────────────────────

  static List<SeparationAlert> generateAlerts({
    required HerdEntity herd,
    required HerdSeparationResult result,
  }) {
    return result.separatedAnimals.map((animal) {
      return SeparationAlert(
        id: '${herd.id}-${animal.id}-${DateTime.now().millisecondsSinceEpoch}',
        herdId: herd.id,
        herdName: herd.name,
        animalId: animal.id,
        animalName: animal.name,
        animalEmoji: animal.typeEmoji,
        type: SeparationAlertType.farFromHerd,
        distanceFromCenter: calculateDistance(
          animal.lastLatitude!,
          animal.lastLongitude!,
          result.centroid.lat,
          result.centroid.lng,
        ),
        herdCenterLat: result.centroid.lat,
        herdCenterLng: result.centroid.lng,
        animalLat: animal.lastLatitude!,
        animalLng: animal.lastLongitude!,
        timestamp: DateTime.now(),
      );
    }).toList();
  }

  // ── Sürünün ortalama sıxlığını hesabla ───────────────────────────────────
  // Heyvanlar arasındakı ortalama məsafə

  static double calculateHerdSpread(List<AnimalEntity> animals) {
    final located = animals
        .where((a) => a.lastLatitude != null && a.lastLongitude != null)
        .toList();

    if (located.length < 2) return 0;

    final centroid = calculateCentroid(located);
    if (centroid == null) return 0;

    final distances = located.map((a) => calculateDistance(
          a.lastLatitude!,
          a.lastLongitude!,
          centroid.lat,
          centroid.lng,
        ));

    return distances.reduce((a, b) => a + b) / distances.length;
  }
}
