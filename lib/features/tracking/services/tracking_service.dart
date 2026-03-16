import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class TrackingService {
  final BuildContext _context;
  StreamSubscription<Position>? _locationSub;
  bool _isRunning = false;

  static const _interval = Duration(seconds: 10);
  Timer? _checkTimer;

  final Map<String, AnimalZoneStatus> _prevZoneStatus = {};

  // Batareya — platform channel vasitəsilə oxunur
  static const _batteryChannel =
      MethodChannel('com.example.meta_tracking/battery');

  TrackingService(this._context);

  bool get isRunning => _isRunning;

  // ── Telefon batareyasını oxu ───────────────────────────────────────────────
  // Android BatteryManager vasitəsilə. Xəta olarsa 1.0 qaytarır.
  static Future<double> _readBatteryLevel() async {
    try {
      final int level = await _batteryChannel.invokeMethod('getBatteryLevel');
      return level / 100.0;
    } catch (_) {
      // Platform channel mövcud deyilsə → fallback 1.0
      return 1.0;
    }
  }

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

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (pos) => _onPositionUpdate(pos),
      onError: (e) {
        AppLogger.xeta('TRACKING SERVICE', 'GPS stream xətası', xetaObyekti: e);
      },
    );

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

  // ── GPS yeniləməsi ────────────────────────────────────────────────────────
  // FIX: pos.speed neqativ ola bilər (Android emulator / statik) → max(0, speed)
  // FIX: batareyani real olaraq oxuyuruq

  void _onPositionUpdate(Position pos) async {
    if (!_isRunning) return;
    if (!_context.mounted) return;

    final animalState = _context.read<AnimalBloc>().state;
    if (animalState is! AnimalLoaded) return;

    // Batareyani bir dəfə oxu (bütün heyvanlar üçün eyni dəyər)
    final battery = await _readBatteryLevel();

    if (!_context.mounted) return;

    for (final animal in animalState.animals.where((a) => a.isTracking)) {
      _context.read<AnimalBloc>().add(UpdateLocationEvent(
            animalId: animal.id,
            lat: pos.latitude,
            lng: pos.longitude,
            speed: pos.speed < 0 ? 0.0 : pos.speed, // ← FIX: negatif speed
            battery: battery, // ← FIX: real batareya
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
    _checkGeofence(animals);
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

        final prevStatus =
            _prevZoneStatus[animal.id] ?? AnimalZoneStatus.outside;

        if (prevStatus != newStatus) {
          final entered = newStatus == AnimalZoneStatus.inside;
          final zoneName = newZoneName ?? 'Naməlum Zona';

          AppLogger.geofenceHadise(animal.name, zoneName, entered);

          LocalNotificationService().showGeofenceAlert(
            animalName: animal.name,
            zoneName: zoneName,
            entered: entered,
          );

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

  void _checkHerdSeparation(List<AnimalEntity> animals) {
    _context.read<HerdBloc>().add(CheckHerdSeparationEvent(animals));
  }

  Future<bool> _requestPermission() async {
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

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
