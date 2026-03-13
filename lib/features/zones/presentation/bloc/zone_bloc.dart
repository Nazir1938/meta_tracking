import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone.dart';
import 'package:meta_tracking/features/zones/domain/services/geofencing_service.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class ZoneEvent extends Equatable {
  const ZoneEvent();
  @override
  List<Object?> get props => [];
}

class CreateZoneEvent extends ZoneEvent {
  final ZoneEntity zone;
  const CreateZoneEvent(this.zone);
  @override
  List<Object?> get props => [zone];
}

class FetchZonesEvent extends ZoneEvent {
  const FetchZonesEvent();
}

class DeleteZoneEvent extends ZoneEvent {
  final String zoneId;
  const DeleteZoneEvent(this.zoneId);
  @override
  List<Object?> get props => [zoneId];
}

class UpdateZoneEvent extends ZoneEvent {
  final ZoneEntity zone;
  const UpdateZoneEvent(this.zone);
  @override
  List<Object?> get props => [zone];
}

class CheckAnimalInZoneEvent extends ZoneEvent {
  final AnimalLocationEntity location;
  const CheckAnimalInZoneEvent(this.location);
  @override
  List<Object?> get props => [location];
}

// ─── States ──────────────────────────────────────────────────────────────────
abstract class ZoneState extends Equatable {
  const ZoneState();
  @override
  List<Object?> get props => [];
}

class ZoneInitial extends ZoneState {
  const ZoneInitial();
}

class ZoneLoading extends ZoneState {
  const ZoneLoading();
}

class ZonesLoaded extends ZoneState {
  final List<ZoneEntity> zones;
  const ZonesLoaded(this.zones);
  @override
  List<Object?> get props => [zones];
}

class ZoneCreated extends ZoneState {
  final ZoneEntity zone;
  const ZoneCreated(this.zone);
  @override
  List<Object?> get props => [zone];
}

class AnimalLocationChecked extends ZoneState {
  final AnimalLocationEntity location;
  final Map<String, dynamic> zoneInfo;
  final List<ZoneEntity> relevantZones;
  const AnimalLocationChecked(this.location, this.zoneInfo, this.relevantZones);
  @override
  List<Object?> get props => [location, zoneInfo, relevantZones];
}

class ZoneError extends ZoneState {
  final String message;
  const ZoneError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────
class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  final List<ZoneEntity> _zones = [];

  ZoneBloc() : super(const ZoneInitial()) {
    AppLogger.melumat('ZONE BLOC', 'ZoneBloc işə salındı');
    on<CreateZoneEvent>(_onCreateZone);
    on<FetchZonesEvent>(_onFetchZones);
    on<DeleteZoneEvent>(_onDeleteZone);
    on<UpdateZoneEvent>(_onUpdateZone);
    on<CheckAnimalInZoneEvent>(_onCheckAnimalInZone);
  }

  Future<void> _onCreateZone(
    CreateZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'CreateZoneEvent');
    AppLogger.zonaEmeliyyati(
      'Zona yaradılır',
      event.zone.name,
      data: 'Radius: ${event.zone.radiusInMeters}m',
    );
    try {
      emit(const ZoneLoading());
      _zones.add(event.zone);
      AppLogger.ugur(
        'ZONE BLOC',
        '"${event.zone.name}" zonası uğurla yaradıldı. Cəmi zona: ${_zones.length}',
      );
      emit(ZoneCreated(event.zone));
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Zona yaratma uğursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Zona yaratma uğursuz oldu: $e'));
    }
  }

  Future<void> _onFetchZones(
    FetchZonesEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'FetchZonesEvent');
    try {
      emit(const ZoneLoading());
      emit(ZonesLoaded(List.from(_zones)));
      AppLogger.ugur('ZONE BLOC', 'Zonalar uğurla yükləndi');
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Zonaları yükləmək uğursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Zonaları yükləmək uğursuz oldu: $e'));
    }
  }

  Future<void> _onDeleteZone(
    DeleteZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'DeleteZoneEvent');
    try {
      final oncekiSay = _zones.length;
      _zones.removeWhere((zone) => zone.id == event.zoneId);
      if (_zones.length < oncekiSay) {
        AppLogger.ugur(
          'ZONE BLOC',
          'Zona silindi. Qalan zona sayı: ${_zones.length}',
        );
      } else {
        AppLogger.xeberdarliq(
          'ZONE BLOC',
          'Silinəcək zona tapılmadı. ID: ${event.zoneId}',
        );
      }
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Zona silmə uğursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Zona silmə uğursuz oldu: $e'));
    }
  }

  Future<void> _onUpdateZone(
    UpdateZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'UpdateZoneEvent');
    try {
      final index = _zones.indexWhere((z) => z.id == event.zone.id);
      if (index != -1) {
        _zones[index] = event.zone;
        AppLogger.ugur(
          'ZONE BLOC',
          '"${event.zone.name}" zonası uğurla yeniləndi',
        );
      } else {
        AppLogger.xeberdarliq(
          'ZONE BLOC',
          'Yenilənəcək zona tapılmadı. ID: ${event.zone.id}',
        );
      }
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Zona yeniləməsi uğursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Zona yeniləməsi uğursuz oldu: $e'));
    }
  }

  Future<void> _onCheckAnimalInZone(
    CheckAnimalInZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'CheckAnimalInZoneEvent');
    try {
      final aktivZonalar = _zones.where((z) => z.isActive).toList();
      final yenilenmisMovqe = GeofencingService.updateAnimalStatus(
        event.location,
        aktivZonalar,
      );

      if (yenilenmisMovqe.status != event.location.status) {
        AppLogger.geofenceHadise(
          event.location.animalName,
          yenilenmisMovqe.zoneId ?? 'Naməlum zona',
          yenilenmisMovqe.status == AnimalStatus.inside,
        );
      }

      final zonaInfo = yenilenmisMovqe.zoneId != null
          ? GeofencingService.getZoneInfo(
              yenilenmisMovqe,
              aktivZonalar.firstWhere((z) => z.id == yenilenmisMovqe.zoneId),
            )
          : <String, dynamic>{};

      emit(AnimalLocationChecked(yenilenmisMovqe, zonaInfo, aktivZonalar));
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Mövqe yoxlaması uğursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Mövqe yoxlaması uğursuz oldu: $e'));
    }
  }
}
