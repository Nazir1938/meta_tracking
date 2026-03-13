import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone.dart';
import 'package:meta_tracking/features/zones/domain/services/geofencing_service.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';

// --- Hadiseler ---------------------------------------------------------------

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

// --- Veziyyetler -------------------------------------------------------------

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

// --- BLoC --------------------------------------------------------------------

class ZoneBloc extends Bloc<ZoneEvent, ZoneState> {
  final List<ZoneEntity> _zones = [];

  ZoneBloc() : super(const ZoneInitial()) {
    AppLogger.melumat('ZONE BLOC', 'ZoneBloc ise salindi');

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
      'Zona yaradilir',
      event.zone.name,
      data: 'Radius: ${event.zone.radiusInMeters}m',
    );
    try {
      emit(const ZoneLoading());
      _zones.add(event.zone);
      AppLogger.ugur(
        'ZONE BLOC',
        '"${event.zone.name}" zonasi ugurla yaradildi. Cemi zona: ${_zones.length}',
      );
      emit(ZoneCreated(event.zone));
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Zona yaratma ugursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Zona yaratma ugursuz oldu: $e'));
    }
  }

  Future<void> _onFetchZones(
    FetchZonesEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'FetchZonesEvent');
    try {
      emit(const ZoneLoading());
      AppLogger.melumat(
        'ZONE BLOC',
        'Zonalar yuklenir. Movcud zona sayi: ${_zones.length}',
      );
      emit(ZonesLoaded(List.from(_zones)));
      AppLogger.ugur('ZONE BLOC', 'Zonalar ugurla yuklendi');
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Zonalari yuklemek ugursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Zonalari yuklemek ugursuz oldu: $e'));
    }
  }

  Future<void> _onDeleteZone(
    DeleteZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'DeleteZoneEvent');
    AppLogger.zonaEmeliyyati('Zona silinir', 'ID: ${event.zoneId}');
    try {
      final oncekiSay = _zones.length;
      _zones.removeWhere((zone) => zone.id == event.zoneId);
      if (_zones.length < oncekiSay) {
        AppLogger.ugur(
          'ZONE BLOC',
          'Zona silindi. Qalan zona sayi: ${_zones.length}',
        );
      } else {
        AppLogger.xeberdarliq(
          'ZONE BLOC',
          'Silinecek zona tapilmadi. ID: ${event.zoneId}',
        );
      }
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Zona silme ugursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Zona silme ugursuz oldu: $e'));
    }
  }

  Future<void> _onUpdateZone(
    UpdateZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'UpdateZoneEvent');
    AppLogger.zonaEmeliyyati('Zona yenilenir', event.zone.name);
    try {
      final index = _zones.indexWhere((z) => z.id == event.zone.id);
      if (index != -1) {
        _zones[index] = event.zone;
        AppLogger.ugur(
          'ZONE BLOC',
          '"${event.zone.name}" zonasi ugurla yenilendi',
        );
      } else {
        AppLogger.xeberdarliq(
          'ZONE BLOC',
          'Yenilenecek zona tapilmadi. ID: ${event.zone.id}',
        );
      }
      emit(ZonesLoaded(List.from(_zones)));
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Zona yenilemesi ugursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Zona yenilemesi ugursuz oldu: $e'));
    }
  }

  Future<void> _onCheckAnimalInZone(
    CheckAnimalInZoneEvent event,
    Emitter<ZoneState> emit,
  ) async {
    AppLogger.blocHadise('ZoneBloc', 'CheckAnimalInZoneEvent');
    AppLogger.melumat(
      'ZONE BLOC',
      '"${event.location.animalName}" heyvaninin zona veziyyeti yoxlanilir',
    );
    try {
      final aktivZonalar = _zones.where((z) => z.isActive).toList();
      AppLogger.debug('ZONE BLOC', 'Aktiv zona sayi: ${aktivZonalar.length}');

      final yenilenmisMovqe = GeofencingService.updateAnimalStatus(
        event.location,
        aktivZonalar,
      );

      if (yenilenmisMovqe.status != event.location.status) {
        AppLogger.geofenceHadise(
          event.location.animalName,
          yenilenmisMovqe.zoneId ?? 'Namelum zona',
          yenilenmisMovqe.status == AnimalStatus.inside,
        );
      }

      final zonaInfo = yenilenmisMovqe.zoneId != null
          ? GeofencingService.getZoneInfo(
              yenilenmisMovqe,
              aktivZonalar.firstWhere((z) => z.id == yenilenmisMovqe.zoneId),
            )
          : <String, dynamic>{};

      AppLogger.ugur(
        'ZONE BLOC',
        '"${event.location.animalName}" veziyyeti: ${yenilenmisMovqe.status.name}',
      );

      emit(AnimalLocationChecked(yenilenmisMovqe, zonaInfo, aktivZonalar));
    } catch (e, stack) {
      AppLogger.xeta(
        'ZONE BLOC',
        'Movqe yoxlamasi ugursuz oldu',
        xetaObyekti: e,
        yiginIzi: stack,
      );
      emit(ZoneError('Movqe yoxlamasi ugursuz oldu: $e'));
    }
  }
}
