import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';

/// GPS + overlay mixin — MapScreenState tərəfindən istifadə olunur
mixin MapOverlayMixin<T extends StatefulWidget> on State<T> {
  GoogleMapController? mapController;
  MapType mapType = MapType.hybrid;

  final Set<Circle> circles = {};
  final Set<Marker> markers = {};
  final Set<Polygon> polygons = {};

  LatLng? currentLocation;
  StreamSubscription<Position>? locationSub;
  bool locationReady = false;

  static const LatLng defaultLocation = LatLng(40.3686, 49.8671);

  // ── GPS ───────────────────────────────────────────────────────────────────
  Future<void> initLocation({bool skipCameraMove = false}) async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p != LocationPermission.whileInUse && p != LocationPermission.always)
        return;

      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      setState(() {
        currentLocation = LatLng(pos.latitude, pos.longitude);
        locationReady = true;
      });

      if (!skipCameraMove) {
        mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(currentLocation!, 15));
      }

      locationSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 15),
      ).listen((p) {
        if (mounted) {
          setState(() => currentLocation = LatLng(p.latitude, p.longitude));
        }
      });
    } catch (e) {
      AppLogger.xeta('MAP GPS', 'Xəta', xetaObyekti: e);
    }
  }

  void goToMyLocation() {
    final t = currentLocation ?? defaultLocation;
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(t, 15));
  }

  // ── Overlay-ları yenilə ───────────────────────────────────────────────────
  // FIX: 'fh-' prefiksi ilə başlayan müvəqqəti polygon-lar da təmizlənir,
  // əks halda hər rebuild-də köhnə polygon üst-üstə qalırdı.

  void rebuildOverlays(
    List<ZoneEntity> zones,
    List<AnimalEntity>? animalEntities,
    List<String>? highlightedIds,
    void Function(ZoneEntity) onZoneTap,
    void Function(AnimalEntity) onAnimalTap,
  ) {
    circles.clear();
    polygons.removeWhere((p) =>
        p.polygonId.value.startsWith('zone-poly-') ||
        p.polygonId.value
            .startsWith('fh-') || // ← FIX: müvəqqəti fh-* polygon-ları sil
        p.polygonId.value == '__fh_preview__');
    markers.removeWhere((m) =>
        m.markerId.value.startsWith('zone-') ||
        m.markerId.value.startsWith('animal-'));

    for (final z in zones) {
      addZoneOverlay(z, onZoneTap);
    }
    rebuildAnimalMarkers(animalEntities, highlightedIds, onAnimalTap);
    if (mounted) setState(() {});
  }

  void addZoneOverlay(ZoneEntity zone, void Function(ZoneEntity) onTap) {
    final color = zone.isActive ? const Color(0xFF1D9E75) : Colors.grey;

    if (zone.zoneType == ZoneType.polygon && zone.polygonPoints.length >= 3) {
      // Polygon zona — çəkildiyi kimi göstər
      final gPoints = zone.polygonPoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      polygons.add(Polygon(
        polygonId: PolygonId('zone-poly-${zone.id}'),
        points: gPoints,
        fillColor: color.withValues(alpha: 0.18),
        strokeColor: color.withValues(alpha: 0.85),
        strokeWidth: 2,
        onTap: () => onTap(zone),
      ));
    } else {
      // Dairə zona
      circles.add(Circle(
        circleId: CircleId('zone-circle-${zone.id}'),
        center: LatLng(zone.latitude, zone.longitude),
        radius: zone.radiusInMeters,
        fillColor: color.withValues(alpha: 0.18),
        strokeColor: color.withValues(alpha: 0.85),
        strokeWidth: 2,
        onTap: () => onTap(zone),
      ));
    }

    markers.add(Marker(
      markerId: MarkerId('zone-label-${zone.id}'),
      position: LatLng(zone.latitude, zone.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        zone.isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
      ),
      onTap: () => onTap(zone),
      infoWindow: InfoWindow.noText,
    ));
  }

  void rebuildAnimalMarkers(
    List<AnimalEntity>? animalEntities,
    List<String>? highlightedIds,
    void Function(AnimalEntity) onAnimalTap,
  ) {
    if (animalEntities == null) return;

    for (final a in animalEntities) {
      if (a.lastLatitude != null && a.lastLongitude != null) {
        final hl = highlightedIds?.contains(a.id) ?? false;
        markers.add(Marker(
          markerId: MarkerId('animal-${a.id}'),
          position: LatLng(a.lastLatitude!, a.lastLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              hl ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange),
          onTap: () => onAnimalTap(a),
          infoWindow: InfoWindow.noText,
        ));
      }
    }
  }

  // ── Draw helpers ──────────────────────────────────────────────────────────
  void redrawRadiusPreview(LatLng? center, double radius) {
    circles.removeWhere((c) => c.circleId.value == '__preview__');
    if (center != null) {
      circles.add(Circle(
        circleId: const CircleId('__preview__'),
        center: center,
        radius: radius,
        fillColor: const Color(0xFF1D9E75).withValues(alpha: 0.12),
        strokeColor: const Color(0xFF1D9E75).withValues(alpha: 0.7),
        strokeWidth: 2,
      ));
    }
    if (mounted) setState(() {});
  }

  void redrawFreehandPreview(List<LatLng> points) {
    polygons.removeWhere((p) => p.polygonId.value == '__fh_preview__');
    if (points.length >= 2) {
      polygons.add(Polygon(
        polygonId: const PolygonId('__fh_preview__'),
        points: points,
        fillColor: const Color(0xFF1D9E75).withValues(alpha: 0.12),
        strokeColor: const Color(0xFF1D9E75).withValues(alpha: 0.75),
        strokeWidth: 2,
      ));
    }
    if (mounted) setState(() {});
  }

  void addFinalPolygon(List<LatLng> points, String id) {
    polygons.add(Polygon(
      polygonId: PolygonId('fh-$id'),
      points: List.from(points),
      fillColor: const Color(0xFF1D9E75).withValues(alpha: 0.15),
      strokeColor: const Color(0xFF1D9E75).withValues(alpha: 0.8),
      strokeWidth: 2,
    ));
  }
}
