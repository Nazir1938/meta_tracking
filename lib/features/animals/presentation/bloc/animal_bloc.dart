import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/data/datasources/animal_remote_datasource.dart';
import 'package:meta_tracking/features/animals/data/repositories/animal_repository_impl.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

abstract class AnimalEvent extends Equatable {
  const AnimalEvent();
  @override
  List<Object?> get props => [];
}

class WatchAnimalsEvent extends AnimalEvent {
  final String ownerId;
  const WatchAnimalsEvent(this.ownerId);
  @override
  List<Object?> get props => [ownerId];
}

class AddAnimalEvent extends AnimalEvent {
  final String name;
  final AnimalType type;
  final String ownerId;
  final String? chipId;
  final String? notes;
  final String? zoneId;
  final String? zoneName;

  const AddAnimalEvent({
    required this.name,
    required this.type,
    required this.ownerId,
    this.chipId,
    this.notes,
    this.zoneId,
    this.zoneName,
  });

  @override
  List<Object?> get props => [name, type, ownerId];
}

class EditAnimalEvent extends AnimalEvent {
  final String animalId;
  final String name;
  final AnimalType type;
  final String? chipId;
  final String? notes;
  final String? zoneId;
  final String? zoneName;

  const EditAnimalEvent({
    required this.animalId,
    required this.name,
    required this.type,
    this.chipId,
    this.notes,
    this.zoneId,
    this.zoneName,
  });

  @override
  List<Object?> get props => [animalId, name, type];
}

class DeleteAnimalEvent extends AnimalEvent {
  final String animalId;
  const DeleteAnimalEvent(this.animalId);
  @override
  List<Object?> get props => [animalId];
}

/// GPS izləməni Firestore-da aktiv et (isTracking = true)
class StartTrackingEvent extends AnimalEvent {
  final String animalId;
  const StartTrackingEvent(this.animalId);
  @override
  List<Object?> get props => [animalId];
}

/// GPS izləməni Firestore-da dayandır (isTracking = false)
class StopTrackingEvent extends AnimalEvent {
  final String animalId;
  const StopTrackingEvent(this.animalId);
  @override
  List<Object?> get props => [animalId];
}

class UpdateLocationEvent extends AnimalEvent {
  final String animalId;
  final double lat;
  final double lng;
  final double speed;
  final double battery;

  const UpdateLocationEvent({
    required this.animalId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.battery,
  });

  @override
  List<Object?> get props => [animalId, lat, lng];
}

class UpdateZoneStatusEvent extends AnimalEvent {
  final String animalId;
  final AnimalZoneStatus status;
  final String? zoneId;
  final String? zoneName;

  const UpdateZoneStatusEvent({
    required this.animalId,
    required this.status,
    this.zoneId,
    this.zoneName,
  });

  @override
  List<Object?> get props => [animalId, status, zoneId];
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

abstract class AnimalState extends Equatable {
  const AnimalState();
  @override
  List<Object?> get props => [];
}

class AnimalInitial extends AnimalState {
  const AnimalInitial();
}

class AnimalLoading extends AnimalState {
  const AnimalLoading();
}

class AnimalLoaded extends AnimalState {
  final List<AnimalEntity> animals;
  const AnimalLoaded(this.animals);
  @override
  List<Object?> get props => [animals];
}

class AnimalError extends AnimalState {
  final String message;
  const AnimalError(this.message);
  @override
  List<Object?> get props => [message];
}

class AnimalOperationSuccess extends AnimalState {
  final String message;
  const AnimalOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLoC
// ─────────────────────────────────────────────────────────────────────────────

class AnimalBloc extends Bloc<AnimalEvent, AnimalState> {
  late final AnimalRepositoryImpl _repo;

  AnimalBloc() : super(const AnimalInitial()) {
    _repo = AnimalRepositoryImpl(AnimalRemoteDataSourceImpl());
    AppLogger.melumat('ANIMAL BLOC', 'AnimalBloc işə salındı');

    on<WatchAnimalsEvent>(_onWatch);
    on<AddAnimalEvent>(_onAdd);
    on<EditAnimalEvent>(_onEdit);
    on<DeleteAnimalEvent>(_onDelete);
    on<StartTrackingEvent>(_onStartTracking);
    on<StopTrackingEvent>(_onStopTracking);
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<UpdateZoneStatusEvent>(_onUpdateZoneStatus);
  }

  // ── Watch ─────────────────────────────────────────────────────────────────

  Future<void> _onWatch(
      WatchAnimalsEvent event, Emitter<AnimalState> emit) async {
    AppLogger.blocHadise('AnimalBloc', 'WatchAnimalsEvent: ${event.ownerId}');
    emit(const AnimalLoading());

    await emit.forEach<List<AnimalEntity>>(
      _repo.watchAnimals(event.ownerId),
      onData: (animals) {
        AppLogger.ugur('ANIMAL BLOC', '${animals.length} heyvan yükləndi');
        return AnimalLoaded(animals);
      },
      onError: (e, _) {
        AppLogger.xeta('ANIMAL BLOC', 'Stream xətası', xetaObyekti: e);
        return AnimalError(e.toString());
      },
    );
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> _onAdd(AddAnimalEvent event, Emitter<AnimalState> emit) async {
    AppLogger.blocHadise('AnimalBloc', 'AddAnimalEvent: ${event.name}');
    try {
      await _repo.addAnimal(
        name: event.name,
        type: event.type,
        ownerId: event.ownerId,
        chipId: event.chipId,
        notes: event.notes,
        zoneId: event.zoneId,
        zoneName: event.zoneName,
      );
      AppLogger.ugur('ANIMAL BLOC', '"${event.name}" əlavə edildi');
    } catch (e, st) {
      AppLogger.xeta('ANIMAL BLOC', 'Əlavə etmə xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(AnimalError(e.toString()));
    }
  }

 // Fayl: lib/features/animals/presentation/bloc/animal_bloc.dart
// Yalnız _onEdit metodunu aşağıdakı ilə əvəz edin:

  Future<void> _onEdit(EditAnimalEvent event, Emitter<AnimalState> emit) async {
    AppLogger.blocHadise('AnimalBloc', 'EditAnimalEvent: ${event.animalId}');
    try {
      final current = state;
      if (current is! AnimalLoaded) return;

      final existing = current.animals.firstWhere(
        (a) => a.id == event.animalId,
        orElse: () => throw Exception('Heyvan tapılmadı: ${event.animalId}'),
      );

      // FIX: event.zoneId == null olduqda clearZone: true göndər.
      // Əks halda Dart-ın ?. operatoru köhnə zoneId-ni saxlayır,
      // Firestore-a FieldValue.delete() getmir, heyvan zonada qalır.
      final updated = existing.copyWith(
        name:      event.name,
        type:      event.type,
        chipId:    event.chipId,
        notes:     event.notes,
        zoneId:    event.zoneId,
        zoneName:  event.zoneName,
        clearZone: event.zoneId == null, // ← BU SƏTIR ƏLAVİ EDİLDİ
      );

      await _repo.updateAnimal(updated);
      AppLogger.ugur('ANIMAL BLOC', '"${event.name}" yeniləndi');
    } catch (e, st) {
      AppLogger.xeta('ANIMAL BLOC', 'Redaktə xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(AnimalError(e.toString()));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDelete(
      DeleteAnimalEvent event, Emitter<AnimalState> emit) async {
    AppLogger.blocHadise('AnimalBloc', 'DeleteAnimalEvent: ${event.animalId}');
    try {
      await _repo.deleteAnimal(event.animalId);
      AppLogger.ugur('ANIMAL BLOC', 'Heyvan silindi: ${event.animalId}');
    } catch (e, st) {
      AppLogger.xeta('ANIMAL BLOC', 'Silmə xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(AnimalError(e.toString()));
    }
  }

  // ── Start Tracking ────────────────────────────────────────────────────────

  Future<void> _onStartTracking(
      StartTrackingEvent event, Emitter<AnimalState> emit) async {
    AppLogger.blocHadise('AnimalBloc', 'StartTrackingEvent: ${event.animalId}');
    try {
      await _repo.startTracking(event.animalId);
      AppLogger.ugur('ANIMAL BLOC', 'İzləmə başladı: ${event.animalId}');
    } catch (e) {
      AppLogger.xeta('ANIMAL BLOC', 'İzləmə başlatma xətası', xetaObyekti: e);
    }
  }

  // ── Stop Tracking ─────────────────────────────────────────────────────────

  Future<void> _onStopTracking(
      StopTrackingEvent event, Emitter<AnimalState> emit) async {
    AppLogger.blocHadise('AnimalBloc', 'StopTrackingEvent: ${event.animalId}');
    try {
      await _repo.stopTracking(event.animalId);
      AppLogger.ugur('ANIMAL BLOC', 'İzləmə dayandırıldı: ${event.animalId}');
    } catch (e) {
      AppLogger.xeta('ANIMAL BLOC', 'İzləmə dayandırma xətası', xetaObyekti: e);
    }
  }

  // ── Update Location ───────────────────────────────────────────────────────

  Future<void> _onUpdateLocation(
      UpdateLocationEvent event, Emitter<AnimalState> emit) async {
    try {
      await _repo.updateLocation(
        event.animalId,
        event.lat,
        event.lng,
        event.speed,
        event.battery,
      );
    } catch (e) {
      AppLogger.xeta('ANIMAL BLOC', 'Mövqe yeniləmə xətası', xetaObyekti: e);
    }
  }

  // ── Update Zone Status ────────────────────────────────────────────────────

  Future<void> _onUpdateZoneStatus(
      UpdateZoneStatusEvent event, Emitter<AnimalState> emit) async {
    AppLogger.blocHadise(
        'AnimalBloc', 'UpdateZoneStatusEvent: ${event.animalId}');
    try {
      await _repo.updateZoneStatus(
        event.animalId,
        event.status,
        event.zoneId,
        event.zoneName,
      );
    } catch (e) {
      AppLogger.xeta('ANIMAL BLOC', 'Zona status xətası', xetaObyekti: e);
    }
  }
}
