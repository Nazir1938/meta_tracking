import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/core/services/local_notification_service.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meta_tracking/features/zones/domain/services/geofencing_service.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

/// Arxa planda işləyən tracking servisi
/// AnimalBloc, ZoneBloc, HerdBloc, NotificationBloc ilə əlaqəli
class TrackingService {
  final BuildContext _context;
  StreamSubscription<Position>? _locationSub;
  bool _isRunning = false;

  // Interval — hər 10 saniyə
  static const _interval = Duration(seconds: 10);
  Timer? _checkTimer;

  // Əvvəlki zona statuslarını yadda saxla (bildiriş spam-ının qarşısını al)
  final Map<String, AnimalZoneStatus> _prevZoneStatus = {};

  TrackingService(this._context);

  bool get isRunning => _isRunning;

  // ── Servisı başlat ────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_isRunning) return;
    AppLogger.melumat('TRACKING SERVICE', 'Servis başladılır...');

    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      AppLogger.xeberdarliq('TRACKING SERVICE', 'GPS icazəsi yoxdur');
      return;
    }

    _isRunning = true;

    // GPS stream-i dinlə
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // hər 10 metr dəyişiklikdə
      ),
    ).listen(
      (pos) => _onPositionUpdate(pos),
      onError: (e) {
        AppLogger.xeta('TRACKING SERVICE', 'GPS stream xətası', xetaObyekti: e);
      },
    );

    // Hər 10 saniyə geofence + naxır yoxlaması
    _checkTimer = Timer.periodic(_interval, (_) => _runChecks());

    AppLogger.ugur('TRACKING SERVICE', 'Servis başladı');
  }

  // ── Servisı dayandır ──────────────────────────────────────────────────────

  Future<void> stop() async {
    if (!_isRunning) return;
    await _locationSub?.cancel();
    _checkTimer?.cancel();
    _isRunning = false;
    _prevZoneStatus.clear();
    AppLogger.xeberdarliq('TRACKING SERVICE', 'Servis dayandırıldı');
  }

  // ── GPS yeniləməsi gəldi ──────────────────────────────────────────────────

  void _onPositionUpdate(Position pos) {
    if (!_isRunning) return;
    if (!_context.mounted) return;

    final animalState = _context.read<AnimalBloc>().state;
    if (animalState is! AnimalLoaded) return;

    // Yalnız aktiv izlənən heyvanların GPS-ini yenilə
    for (final animal in animalState.animals.where((a) => a.isTracking)) {
      _context.read<AnimalBloc>().add(UpdateLocationEvent(
            animalId: animal.id,
            lat: pos.latitude,
            lng: pos.longitude,
            speed: pos.speed,
            battery: 1.0,
          ));
    }
  }

  // ── Periyodik yoxlamalar ──────────────────────────────────────────────────

  void _runChecks() {
    if (!_isRunning) return;
    if (!_context.mounted) return;

    final animalState = _context.read<AnimalBloc>().state;
    if (animalState is! AnimalLoaded) return;

    final animals = animalState.animals;

    // 1. Geofence yoxlaması — hər heyvan üçün zona statusu
    _checkGeofence(animals);

    // 2. Naxır ayrılma yoxlaması
    _checkHerdSeparation(animals);
  }

  // ── Geofence yoxlama ──────────────────────────────────────────────────────

  void _checkGeofence(List<AnimalEntity> animals) {
    final zoneState = _context.read<ZoneBloc>().state;
    if (zoneState is! ZonesLoaded) return;

    final activeZones = zoneState.zones.where((z) => z.isActive).toList();
    if (activeZones.isEmpty) return;

    for (final animal in animals) {
      if (animal.lastLatitude == null || animal.lastLongitude == null) continue;

      final location = AnimalLocationEntity(
        animalId: animal.id,
        animalName: animal.name,
        latitude: animal.lastLatitude!,
        longitude: animal.lastLongitude!,
        timestamp: DateTime.now(),
        speed: animal.speed ?? 0,
        accuracy: 10,
        status: _toAnimalStatus(animal.zoneStatus),
        zoneId: animal.zoneId,
      );

      final updated =
          GeofencingService.updateAnimalStatus(location, activeZones);

      // Status dəyişibsə Firestore-a yaz
      final newStatus = _toZoneStatus(updated.status);

      if (newStatus != animal.zoneStatus || updated.zoneId != animal.zoneId) {
        String? newZoneName;
        if (updated.zoneId != null) {
          try {
            newZoneName =
                activeZones.firstWhere((z) => z.id == updated.zoneId).name;
          } catch (_) {}
        }

        _context.read<AnimalBloc>().add(UpdateZoneStatusEvent(
              animalId: animal.id,
              status: newStatus,
              zoneId: updated.zoneId,
              zoneName: newZoneName,
            ));

        // ── Keçid bildirişi (yalnız status həqiqətən dəyişibsə) ──────────
        final prevStatus =
            _prevZoneStatus[animal.id] ?? AnimalZoneStatus.outside;

        if (prevStatus != newStatus) {
          final entered = newStatus == AnimalZoneStatus.inside;
          final zoneName = newZoneName ?? 'Naməlum Zona';

          AppLogger.geofenceHadise(animal.name, zoneName, entered);

          // Real local bildiriş göstər
          LocalNotificationService().showGeofenceAlert(
            animalName: animal.name,
            zoneName: zoneName,
            entered: entered,
          );

          // Bildiriş Bloc-a da yaz (bildirişlər ekranında görünsün)
          _saveNotificationToBloc(
            animal: animal,
            zoneName: zoneName,
            entered: entered,
          );
        }

        _prevZoneStatus[animal.id] = newStatus;
      }
    }
  }

  // ── Bildirişi NotificationBloc-a yaz ────────────────────────────────────

  void _saveNotificationToBloc({
    required AnimalEntity animal,
    required String zoneName,
    required bool entered,
  }) {
    if (!_context.mounted) return;
    try {
      final authState = _context.read<AuthBloc>().state;
      final userId =
          authState is AuthAuthenticated ? authState.user.id : 'unknown';

      final action = entered ? 'daxil oldu' : 'çıxdı';
      final emoji = entered ? '✅' : '⚠️';

      _context.read<NotificationBloc>().add(AddNotificationEvent(
            userId: userId,
            title: '$emoji ${animal.name} zona $action',
            body: '"$zoneName" zonasına ${animal.name} $action',
            type: NotificationType.zoneAlert,
            data: {
              'animalId': animal.id,
              'zoneName': zoneName,
              'entered': entered,
            },
          ));
    } catch (e) {
      AppLogger.xeta('TRACKING SERVICE', 'Bildiriş Bloc xətası',
          xetaObyekti: e);
    }
  }

  // ── Naxır ayrılma yoxlama ─────────────────────────────────────────────────

  void _checkHerdSeparation(List<AnimalEntity> animals) {
    _context.read<HerdBloc>().add(CheckHerdSeparationEvent(animals));
  }

  // ── GPS icazəsi ───────────────────────────────────────────────────────────

  Future<bool> _requestPermission() async {
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  // ── Konversiya helpers ────────────────────────────────────────────────────

  AnimalStatus _toAnimalStatus(AnimalZoneStatus s) {
    switch (s) {
      case AnimalZoneStatus.inside:
        return AnimalStatus.inside;
      case AnimalZoneStatus.outside:
      case AnimalZoneStatus.alert:
        return AnimalStatus.outside;
    }
  }

  AnimalZoneStatus _toZoneStatus(AnimalStatus s) {
    switch (s) {
      case AnimalStatus.inside:
        return AnimalZoneStatus.inside;
      case AnimalStatus.outside:
      case AnimalStatus.alert:
        return AnimalZoneStatus.outside;
    }
  }
}
