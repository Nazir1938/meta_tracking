import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/zones/data/datasources/zone_remote_datasourche.dart';
import 'package:meta_tracking/features/zones/data/repositories/zone_repository.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';
import 'package:meta_tracking/features/zones/domain/services/geofencing_service.dart';
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';
import 'package:meta_tracking/features/zones/presentation/event/zone_event.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';


class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  late final ZoneRepositoryImpl _repo;
  StreamSubscription<List<ZoneEntity>>? _zonesSub;

  // Firestore-dan gələn canlı siyahı
  List<ZoneEntity> _zones = [];

  ZoneBloc() : super(const ZoneInitial()) {
    _repo = ZoneRepositoryImpl(ZoneRemoteDataSourceImpl());
    AppLogger.melumat('ZONE BLOC', 'ZoneBloc işə salındı (Firestore)');

    on<LoadZonesEvent>(_onLoad);
    on<CreateZoneEvent>(_onCreate);
    on<UpdateZoneEvent>(_onUpdate);
    on<DeleteZoneEvent>(_onDelete);
    on<ToggleZoneActiveEvent>(_onToggle);
    on<CheckAnimalInZoneEvent>(_onCheckAnimal);
    on<_ZonesUpdatedEvent>(_onZonesUpdated);
  }

  // ── Firestore stream-dən gələn yeniləmə (internal) ───────────────────────

  Future<void> _onZonesUpdated(
    _ZonesUpdatedEvent event,
    Emitter<ZoneState> emit,
  ) async {
    _zones = event.zones;
    emit(ZonesLoaded(List.from(_zones)));
  }

  // ── Yüklə / Stream başlat ────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadZonesEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'LoadZonesEvent: ${event.ownerId}');

    if (event.ownerId == null) {
      // ownerId yoxdursa boş emit et (giriş etməmiş user)
      emit(const ZonesLoaded.empty());
      return;
    }

    emit(const ZoneLoading());
    await _zonesSub?.cancel();

    _zonesSub = _repo.watchZones(event.ownerId!).listen(
      (zones) {
        if (!isClosed) add(_ZonesUpdatedEvent(zones));
      },
      onError: (e) {
        AppLogger.xeta('ZONE BLOC', 'Stream xətası', xetaObyekti: e);
        if (!isClosed) {
          emit(ZoneError(message: 'Zonalar yüklənmədi: $e'));
        }
      },
    );
  }

  // ── Yarat ────────────────────────────────────────────────────────────────

  Future<void> _onCreate(
    CreateZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'CreateZoneEvent: ${event.name}');

    if (event.ownerId == null) {
      emit(const ZoneError(message: 'İstifadəçi məlumatı tapılmadı'));
      return;
    }

    try {
      // Eyni adda zona yoxla (local)
      final dup =
          _zones.any((z) => z.name.toLowerCase() == event.name.toLowerCase());
      if (dup) {
        emit(ZoneError(
          message: '"${event.name}" adlı zona artıq mövcuddur',
          type: ZoneErrorType.alreadyExists,
        ));
        return;
      }

      final zone = ZoneEntity(
        id: '', // Firestore özü təyin edəcək
        name: event.name,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusInMeters: event.radiusInMeters,
        description: event.description,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _repo.createZone(zone, event.ownerId!);

      AppLogger.zonaEmeliyyati('Zona Firestore-a yazıldı', event.name);

      emit(ZoneOperationSuccess(
        message: '"${event.name}" uğurla yaradıldı',
        operation: ZoneOperation.create,
      ));
      // Stream avtomatik yeniləyəcək
    } catch (e, st) {
      AppLogger.xeta('ZONE BLOC', 'Zona yaratma xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(ZoneError(message: 'Zona yaradılmadı: $e'));
    }
  }

  // ── Yenilə ───────────────────────────────────────────────────────────────

  Future<void> _onUpdate(
    UpdateZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'UpdateZoneEvent: ${event.zone.id}');
    try {
      await _repo.updateZone(event.zone);
      emit(ZoneOperationSuccess(
        message: '"${event.zone.name}" yeniləndi',
        operation: ZoneOperation.update,
      ));
    } catch (e, st) {
      AppLogger.xeta('ZONE BLOC', 'Zona yeniləmə xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(ZoneError(message: 'Zona yenilənmədi: $e'));
    }
  }

  // ── Sil ──────────────────────────────────────────────────────────────────

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
      await _repo.deleteZone(event.zoneId);
      emit(ZoneOperationSuccess(
        message: '"${zone.name}" silindi',
        operation: ZoneOperation.delete,
      ));
    } catch (e, st) {
      AppLogger.xeta('ZONE BLOC', 'Zona silmə xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(ZoneError(message: 'Zona silinmədi: $e'));
    }
  }

  // ── Toggle aktiv/deaktiv ─────────────────────────────────────────────────

  Future<void> _onToggle(
    ToggleZoneActiveEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'ToggleZoneActiveEvent: ${event.zoneId}');
    try {
      final zone = _zones.firstWhere(
        (z) => z.id == event.zoneId,
        orElse: () => throw Exception('Zona tapılmadı'),
      );
      await _repo.updateZone(zone.copyWith(isActive: event.isActive));
      final lbl = event.isActive ? 'aktivləşdirildi' : 'deaktiv edildi';
      emit(ZoneOperationSuccess(
        message: '"${zone.name}" $lbl',
        operation: ZoneOperation.toggle,
      ));
    } catch (e, st) {
      AppLogger.xeta('ZONE BLOC', 'Toggle xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(ZoneError(message: 'Əməliyyat uğursuz oldu: $e'));
    }
  }

  // ── Heyvan zona yoxlaması ─────────────────────────────────────────────────

  Future<void> _onCheckAnimal(
    CheckAnimalInZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    try {
      final active = _zones.where((z) => z.isActive).toList();
      final updated =
          GeofencingService.updateAnimalStatus(event.location, active);

      if (updated.status != event.location.status) {
        AppLogger.geofenceHadise(
          event.location.animalName,
          updated.zoneId ?? 'Naməlum',
          updated.status == AnimalStatus.inside,
        );
      }

      Map<String, dynamic> info = {};
      if (updated.zoneId != null) {
        final z = active.firstWhere((z) => z.id == updated.zoneId,
            orElse: () => throw Exception());
        info = GeofencingService.getZoneInfo(updated, z);
      }

      emit(AnimalLocationChecked(
          location: updated, zoneInfo: info, relevantZones: active));
    } catch (e) {
      AppLogger.xeta('ZONE BLOC', 'Zona yoxlama xətası', xetaObyekti: e);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<ZoneEntity> get currentZones => List.unmodifiable(_zones);

  ZoneEntity? findZone(String id) {
    try {
      return _zones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _zonesSub?.cancel();
    return super.close();
  }
}

// Internal event — stream yeniləməsi üçün
class _ZonesUpdatedEvent extends ZoneEvent {
  final List<ZoneEntity> zones;
  const _ZonesUpdatedEvent(this.zones);
}
