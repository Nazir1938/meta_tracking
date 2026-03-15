import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/herds/data/datasources/herd_remote_datasource.dart';
import 'package:meta_tracking/features/herds/domain/entities/herd_entity.dart';
import 'package:meta_tracking/features/herds/domain/entities/separation_alert.dart';
import 'package:meta_tracking/features/herds/domain/services/herd_tracking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

abstract class HerdEvent extends Equatable {
  const HerdEvent();
  @override
  List<Object?> get props => [];
}

class WatchHerdsEvent extends HerdEvent {
  final String ownerId;
  const WatchHerdsEvent(this.ownerId);
  @override
  List<Object?> get props => [ownerId];
}

class CreateHerdEvent extends HerdEvent {
  final String name;
  final String ownerId;
  final List<String> animalIds;
  final String? animalType;
  final String? description;
  final double separationThresholdMeters;

  const CreateHerdEvent({
    required this.name,
    required this.ownerId,
    required this.animalIds,
    this.animalType,
    this.description,
    this.separationThresholdMeters = 500,
  });

  @override
  List<Object?> get props => [name, ownerId, animalIds];
}

class UpdateHerdEvent extends HerdEvent {
  final HerdEntity herd;
  const UpdateHerdEvent(this.herd);
  @override
  List<Object?> get props => [herd];
}

class DeleteHerdEvent extends HerdEvent {
  final String herdId;
  const DeleteHerdEvent(this.herdId);
  @override
  List<Object?> get props => [herdId];
}

/// Naxıra tək heyvan əlavə et
class AddAnimalToHerdEvent extends HerdEvent {
  final String herdId;
  final String animalId;
  const AddAnimalToHerdEvent({required this.herdId, required this.animalId});
  @override
  List<Object?> get props => [herdId, animalId];
}

/// Naxıra çoxlu heyvan əlavə et
class AddAnimalsToHerdEvent extends HerdEvent {
  final String herdId;
  final List<String> animalIds;
  const AddAnimalsToHerdEvent({required this.herdId, required this.animalIds});
  @override
  List<Object?> get props => [herdId, animalIds];
}

/// Naxırdan heyvan çıxar
class RemoveAnimalFromHerdEvent extends HerdEvent {
  final String herdId;
  final String animalId;
  const RemoveAnimalFromHerdEvent(
      {required this.herdId, required this.animalId});
  @override
  List<Object?> get props => [herdId, animalId];
}

/// Naxır izləməni başlat/dayandır
class ToggleHerdTrackingEvent extends HerdEvent {
  final String herdId;
  final bool isTracking;
  const ToggleHerdTrackingEvent(
      {required this.herdId, required this.isTracking});
  @override
  List<Object?> get props => [herdId, isTracking];
}

/// Yeni GPS məlumatı gəldi — sürüdən ayrılma yoxla
class CheckHerdSeparationEvent extends HerdEvent {
  final List<AnimalEntity> animals;
  const CheckHerdSeparationEvent(this.animals);
  @override
  List<Object?> get props => [animals];
}

/// Alertu oxundu kimi işarələ
class MarkAlertReadEvent extends HerdEvent {
  final String alertId;
  const MarkAlertReadEvent(this.alertId);
  @override
  List<Object?> get props => [alertId];
}

/// Bütün alertları sil
class ClearAlertsEvent extends HerdEvent {
  const ClearAlertsEvent();
}

// Internal
class _HerdsUpdatedEvent extends HerdEvent {
  final List<HerdEntity> herds;
  const _HerdsUpdatedEvent(this.herds);
}

// ─────────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────────

abstract class HerdState extends Equatable {
  const HerdState();
  @override
  List<Object?> get props => [];
}

class HerdInitial extends HerdState {
  const HerdInitial();
}

class HerdLoading extends HerdState {
  const HerdLoading();
}

class HerdsLoaded extends HerdState {
  final List<HerdEntity> herds;
  final List<SeparationAlert> activeAlerts;
  final Map<String, HerdSeparationResult> separationResults;

  const HerdsLoaded({
    required this.herds,
    this.activeAlerts = const [],
    this.separationResults = const {},
  });

  int get unreadAlertCount => activeAlerts.where((a) => !a.isRead).length;

  HerdsLoaded copyWith({
    List<HerdEntity>? herds,
    List<SeparationAlert>? activeAlerts,
    Map<String, HerdSeparationResult>? separationResults,
  }) {
    return HerdsLoaded(
      herds: herds ?? this.herds,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      separationResults: separationResults ?? this.separationResults,
    );
  }

  @override
  List<Object?> get props => [herds, activeAlerts, separationResults];
}

class HerdOperationSuccess extends HerdState {
  final String message;
  const HerdOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class HerdError extends HerdState {
  final String message;
  const HerdError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLoC
// ─────────────────────────────────────────────────────────────────────────────

class HerdBloc extends Bloc<HerdEvent, HerdState> {
  final HerdRemoteDataSourceImpl _ds;
  StreamSubscription<List<HerdEntity>>? _herdsSub;

  List<HerdEntity> _herds = [];
  List<SeparationAlert> _alerts = [];
  Map<String, HerdSeparationResult> _separationResults = {};

  // Alert-ın spam etməməsi üçün son alert vaxtları
  final Map<String, DateTime> _lastAlertTime = {};
  static const _alertCooldown = Duration(minutes: 5);

  HerdBloc()
      : _ds = HerdRemoteDataSourceImpl(),
        super(const HerdInitial()) {
    AppLogger.melumat('HERD BLOC', 'HerdBloc işə salındı');

    on<WatchHerdsEvent>(_onWatch);
    on<_HerdsUpdatedEvent>(_onHerdsUpdated);
    on<CreateHerdEvent>(_onCreate);
    on<UpdateHerdEvent>(_onUpdate);
    on<DeleteHerdEvent>(_onDelete);
    on<AddAnimalToHerdEvent>(_onAddAnimal);
    on<AddAnimalsToHerdEvent>(_onAddAnimals);
    on<RemoveAnimalFromHerdEvent>(_onRemoveAnimal);
    on<ToggleHerdTrackingEvent>(_onToggleTracking);
    on<CheckHerdSeparationEvent>(_onCheckSeparation);
    on<MarkAlertReadEvent>(_onMarkAlertRead);
    on<ClearAlertsEvent>(_onClearAlerts);
  }

  // ── Watch ─────────────────────────────────────────────────────────────────

  Future<void> _onWatch(
      WatchHerdsEvent event, Emitter<HerdState> emit) async {
    AppLogger.blocHadise('HerdBloc', 'WatchHerdsEvent: ${event.ownerId}');
    emit(const HerdLoading());
    await _herdsSub?.cancel();

    _herdsSub = _ds.watchHerds(event.ownerId).listen(
      (herds) {
        if (!isClosed) add(_HerdsUpdatedEvent(herds));
      },
      onError: (e) {
        AppLogger.xeta('HERD BLOC', 'Stream xətası', xetaObyekti: e);
        if (!isClosed) emit(HerdError(e.toString()));
      },
    );
  }

  Future<void> _onHerdsUpdated(
      _HerdsUpdatedEvent event, Emitter<HerdState> emit) async {
    _herds = event.herds;
    emit(HerdsLoaded(
      herds: _herds,
      activeAlerts: _alerts,
      separationResults: _separationResults,
    ));
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<void> _onCreate(
      CreateHerdEvent event, Emitter<HerdState> emit) async {
    AppLogger.blocHadise('HerdBloc', 'CreateHerdEvent: ${event.name}');
    try {
      final herd = HerdEntity(
        id: '',
        name: event.name,
        ownerId: event.ownerId,
        animalIds: event.animalIds,
        animalType: event.animalType,
        description: event.description,
        separationThresholdMeters: event.separationThresholdMeters,
        createdAt: DateTime.now(),
      );
      await _ds.createHerd(herd);
      AppLogger.ugur('HERD BLOC', '"${event.name}" naxırı yaradıldı');
      emit(HerdOperationSuccess('"${event.name}" naxırı yaradıldı'));
    } catch (e, st) {
      AppLogger.xeta('HERD BLOC', 'Naxır yaratma xətası',
          xetaObyekti: e, yiginIzi: st);
      emit(HerdError(e.toString()));
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> _onUpdate(
      UpdateHerdEvent event, Emitter<HerdState> emit) async {
    try {
      await _ds.updateHerd(event.herd);
      emit(HerdOperationSuccess('"${event.herd.name}" yeniləndi'));
    } catch (e) {
      emit(HerdError(e.toString()));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDelete(
      DeleteHerdEvent event, Emitter<HerdState> emit) async {
    try {
      final herd = _herds.firstWhere((h) => h.id == event.herdId,
          orElse: () => throw Exception('Naxır tapılmadı'));
      await _ds.deleteHerd(event.herdId);
      emit(HerdOperationSuccess('"${herd.name}" silindi'));
    } catch (e) {
      emit(HerdError(e.toString()));
    }
  }

  // ── Animal management ─────────────────────────────────────────────────────

  Future<void> _onAddAnimal(
      AddAnimalToHerdEvent event, Emitter<HerdState> emit) async {
    try {
      await _ds.addAnimalToHerd(event.herdId, event.animalId);
      AppLogger.ugur('HERD BLOC',
          'Heyvan naxıra əlavə edildi: ${event.animalId}');
    } catch (e) {
      emit(HerdError(e.toString()));
    }
  }

  Future<void> _onAddAnimals(
      AddAnimalsToHerdEvent event, Emitter<HerdState> emit) async {
    try {
      await _ds.addAnimalsToHerd(event.herdId, event.animalIds);
      AppLogger.ugur('HERD BLOC',
          '${event.animalIds.length} heyvan naxıra əlavə edildi');
      emit(HerdOperationSuccess(
          '${event.animalIds.length} heyvan naxıra əlavə edildi'));
    } catch (e) {
      emit(HerdError(e.toString()));
    }
  }

  Future<void> _onRemoveAnimal(
      RemoveAnimalFromHerdEvent event, Emitter<HerdState> emit) async {
    try {
      await _ds.removeAnimalFromHerd(event.herdId, event.animalId);
    } catch (e) {
      emit(HerdError(e.toString()));
    }
  }

  // ── Toggle tracking ───────────────────────────────────────────────────────

  Future<void> _onToggleTracking(
      ToggleHerdTrackingEvent event, Emitter<HerdState> emit) async {
    try {
      final herd = _herds.firstWhere((h) => h.id == event.herdId,
          orElse: () => throw Exception('Naxır tapılmadı'));
      await _ds.updateHerd(herd.copyWith(isTracking: event.isTracking));
      final label = event.isTracking ? 'izlənir' : 'izlənmir';
      AppLogger.ugur('HERD BLOC', '"${herd.name}" $label');
      emit(HerdOperationSuccess('"${herd.name}" $label'));
    } catch (e) {
      emit(HerdError(e.toString()));
    }
  }

  // ── Check separation ──────────────────────────────────────────────────────
  // Bu metod GPS yeniləməsi gəldikdə çağırılır
  // Yalnız isTracking == true olan naxırları yoxlayır

  Future<void> _onCheckSeparation(
      CheckHerdSeparationEvent event, Emitter<HerdState> emit) async {
    final trackingHerds = _herds.where((h) => h.isTracking).toList();
    if (trackingHerds.isEmpty) return;

    final newResults = Map<String, HerdSeparationResult>.from(_separationResults);
    final newAlerts = List<SeparationAlert>.from(_alerts);

    for (final herd in trackingHerds) {
      final result = HerdTrackingService.checkSeparation(
        herd: herd,
        animals: event.animals,
      );

      newResults[herd.id] = result;

      if (result.hasSeparation) {
        // Alert cooldown yoxla — hər 5 dəqiqədə bir alert göndər
        final alerts = HerdTrackingService.generateAlerts(
          herd: herd,
          result: result,
        );

        for (final alert in alerts) {
          final cooldownKey = '${herd.id}-${alert.animalId}';
          final lastTime = _lastAlertTime[cooldownKey];
          final now = DateTime.now();

          if (lastTime == null ||
              now.difference(lastTime) > _alertCooldown) {
            newAlerts.add(alert);
            _lastAlertTime[cooldownKey] = now;

            AppLogger.xeberdarliq('HERD BLOC',
                '⚠️ ${alert.animalName} sürüdən ayrıldı! '
                'Məsafə: ${alert.distanceLabel}');
          }
        }
      }
    }

    // Köhnə alertları təmizlə (24 saatdan köhnə)
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    newAlerts.removeWhere((a) => a.timestamp.isBefore(cutoff));

    _separationResults = newResults;
    _alerts = newAlerts;

    if (state is HerdsLoaded) {
      emit((state as HerdsLoaded).copyWith(
        activeAlerts: _alerts,
        separationResults: _separationResults,
      ));
    }
  }

  // ── Alert management ──────────────────────────────────────────────────────

  Future<void> _onMarkAlertRead(
      MarkAlertReadEvent event, Emitter<HerdState> emit) async {
    _alerts = _alerts.map((a) {
      return a.id == event.alertId ? a.copyWith(isRead: true) : a;
    }).toList();

    if (state is HerdsLoaded) {
      emit((state as HerdsLoaded).copyWith(activeAlerts: _alerts));
    }
  }

  Future<void> _onClearAlerts(
      ClearAlertsEvent event, Emitter<HerdState> emit) async {
    _alerts = [];
    _lastAlertTime.clear();
    if (state is HerdsLoaded) {
      emit((state as HerdsLoaded).copyWith(activeAlerts: []));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<HerdEntity> get currentHerds => List.unmodifiable(_herds);
  List<SeparationAlert> get activeAlerts => List.unmodifiable(_alerts);

  @override
  Future<void> close() async {
    await _herdsSub?.cancel();
    return super.close();
  }
}