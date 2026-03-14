import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone.dart';
import 'package:meta_tracking/features/zones/domain/services/geofencing_service.dart';
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';
import 'package:meta_tracking/features/zones/presentation/event/zone_event.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';


class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  /// In-memory zona siyahısı.
  /// İstəyə görə Firebase/Hive ilə əvəz edilə bilər.
  final List<ZoneEntity> _zones = [];

  ZoneBloc() : super(const ZoneInitial()) {
    AppLogger.melumat('ZONE BLOC', 'ZoneBloc işə salındı');

    on<LoadZonesEvent>(_onLoad);
    on<CreateZoneEvent>(_onCreate);
    on<UpdateZoneEvent>(_onUpdate);
    on<DeleteZoneEvent>(_onDelete);
    on<ToggleZoneActiveEvent>(_onToggle);
    on<CheckAnimalInZoneEvent>(_onCheckAnimal);
  }

  // ── Yüklə ──────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadZonesEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'LoadZonesEvent');
    emit(const ZoneLoading());
    // Firebase inteqrasiyası əlavə olunduqda burada remote call ediləcək
    emit(ZonesLoaded(List.from(_zones)));
    AppLogger.ugur('ZONE BLOC', 'Zonalar yükləndi: ${_zones.length}');
  }

  // ── Yarat ──────────────────────────────────────────────────────────────────

  Future<void> _onCreate(
    CreateZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'CreateZoneEvent: ${event.name}');
    try {
      // Eyni adda zona yoxla
      final duplicate = _zones.any(
        (z) => z.name.toLowerCase() == event.name.toLowerCase(),
      );
      if (duplicate) {
        emit(ZoneError(
          message: '"${event.name}" adlı zona artıq mövcuddur',
          type: ZoneErrorType.alreadyExists,
        ));
        emit(ZonesLoaded(List.from(_zones)));
        return;
      }

      final zone = ZoneEntity(
        id: 'z-${DateTime.now().millisecondsSinceEpoch}',
        name: event.name,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusInMeters: event.radiusInMeters,
        description: event.description,
        createdAt: DateTime.now(),
        isActive: true,
      );

      _zones.add(zone);

      AppLogger.zonaEmeliyyati(
        'Zona yaradıldı',
        zone.name,
        data: 'R=${(zone.radiusInMeters / 1000).toStringAsFixed(2)}km',
      );

      emit(ZoneOperationSuccess(
        message: '"${zone.name}" uğurla yaradıldı',
        operation: ZoneOperation.create,
      ));
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta('ZONE BLOC', 'Zona yaratma xətası',
          xetaObyekti: e, yiginIzi: stack);
      emit(ZoneError(message: 'Zona yaratma uğursuz oldu: $e'));
      emit(ZonesLoaded(List.from(_zones)));
    }
  }

  // ── Yenilə ─────────────────────────────────────────────────────────────────

  Future<void> _onUpdate(
    UpdateZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'UpdateZoneEvent: ${event.zone.id}');
    try {
      final index = _zones.indexWhere((z) => z.id == event.zone.id);
      if (index == -1) {
        emit(ZoneError(
          message: 'Zona tapılmadı: ${event.zone.id}',
          type: ZoneErrorType.notFound,
        ));
        emit(ZonesLoaded(List.from(_zones)));
        return;
      }

      _zones[index] = event.zone;

      AppLogger.zonaEmeliyyati('Zona yeniləndi', event.zone.name);

      emit(ZoneOperationSuccess(
        message: '"${event.zone.name}" yeniləndi',
        operation: ZoneOperation.update,
      ));
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta('ZONE BLOC', 'Zona yeniləmə xətası',
          xetaObyekti: e, yiginIzi: stack);
      emit(ZoneError(message: 'Zona yeniləmə uğursuz oldu: $e'));
      emit(ZonesLoaded(List.from(_zones)));
    }
  }

  // ── Sil ────────────────────────────────────────────────────────────────────

  Future<void> _onDelete(
    DeleteZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'DeleteZoneEvent: ${event.zoneId}');
    try {
      final zone = _zones.firstWhere(
        (z) => z.id == event.zoneId,
        orElse: () => throw Exception('Zona tapılmadı'),
      );

      _zones.removeWhere((z) => z.id == event.zoneId);

      AppLogger.zonaEmeliyyati('Zona silindi', zone.name,
          data: 'Qalan: ${_zones.length}');

      emit(ZoneOperationSuccess(
        message: '"${zone.name}" silindi',
        operation: ZoneOperation.delete,
      ));
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta('ZONE BLOC', 'Zona silmə xətası',
          xetaObyekti: e, yiginIzi: stack);
      emit(ZoneError(message: 'Zona silmə uğursuz oldu: $e'));
      emit(ZonesLoaded(List.from(_zones)));
    }
  }

  // ── Aktiv/Deaktiv ──────────────────────────────────────────────────────────

  Future<void> _onToggle(
    ToggleZoneActiveEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'ToggleZoneActiveEvent: ${event.zoneId}');
    try {
      final index = _zones.indexWhere((z) => z.id == event.zoneId);
      if (index == -1) {
        emit(const ZoneError(
          message: 'Zona tapılmadı',
          type: ZoneErrorType.notFound,
        ));
        emit(ZonesLoaded(List.from(_zones)));
        return;
      }

      _zones[index] = _zones[index].copyWith(isActive: event.isActive);

      final statusText = event.isActive ? 'aktivləşdirildi' : 'deaktiv edildi';
      AppLogger.zonaEmeliyyati('Zona $statusText', _zones[index].name);

      emit(ZoneOperationSuccess(
        message: '"${_zones[index].name}" $statusText',
        operation: ZoneOperation.toggle,
      ));
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta('ZONE BLOC', 'Toggle xətası',
          xetaObyekti: e, yiginIzi: stack);
      emit(ZoneError(message: 'Əməliyyat uğursuz oldu: $e'));
      emit(ZonesLoaded(List.from(_zones)));
    }
  }

  // ── Heyvan zona yoxlaması ───────────────────────────────────────────────────

  Future<void> _onCheckAnimal(
    CheckAnimalInZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'CheckAnimalInZoneEvent');
    try {
      final activeZones = _zones.where((z) => z.isActive).toList();
      final updated = GeofencingService.updateAnimalStatus(
        event.location,
        activeZones,
      );

      if (updated.status != event.location.status) {
        AppLogger.geofenceHadise(
          event.location.animalName,
          updated.zoneId ?? 'Naməlum',
          updated.status == AnimalStatus.inside,
        );
      }

      Map<String, dynamic> zoneInfo = {};
      if (updated.zoneId != null) {
        final zone = activeZones.firstWhere(
          (z) => z.id == updated.zoneId,
          orElse: () => throw Exception('Zona tapılmadı'),
        );
        zoneInfo = GeofencingService.getZoneInfo(updated, zone);
      }

      emit(AnimalLocationChecked(
        location: updated,
        zoneInfo: zoneInfo,
        relevantZones: activeZones,
      ));
    } catch (e, stack) {
      AppLogger.xeta('ZONE BLOC', 'Heyvan zona yoxlama xətası',
          xetaObyekti: e, yiginIzi: stack);
      emit(ZoneError(message: 'Zona yoxlama uğursuz oldu: $e'));
    }
  }

  // ── Public helpers (UI üçün) ────────────────────────────────────────────────

  /// Cari zona siyahısı (BLoC xaricindən oxumaq üçün)
  List<ZoneEntity> get currentZones => List.unmodifiable(_zones);

  /// ID-yə görə zona tap
  ZoneEntity? findZone(String id) {
    try {
      return _zones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }
}
