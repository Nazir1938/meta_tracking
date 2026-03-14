import 'package:equatable/equatable.dart';
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone.dart';

abstract class ZoneState extends Equatable {
  const ZoneState();
  @override
  List<Object?> get props => [];
}

/// İlkin vəziyyət
class ZoneInitial extends ZoneState {
  const ZoneInitial();
}

/// Yüklənir
class ZoneLoading extends ZoneState {
  const ZoneLoading();
}

/// Zonalar uğurla yükləndi — əsas state, hər zaman bu aktiv olmalıdır
class ZonesLoaded extends ZoneState {
  final List<ZoneEntity> zones;

  const ZonesLoaded(this.zones);

  /// Boş siyahı ilə başlanğıc
  const ZonesLoaded.empty() : zones = const [];

  /// Xəritədə göstərmək üçün yalnız aktiv zonalar
  List<ZoneEntity> get activeZones => zones.where((z) => z.isActive).toList();

  /// Zona adına görə tap
  ZoneEntity? findById(String id) {
    try {
      return zones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [zones];
}

/// Zona əməliyyatı uğurlu oldu (create/update/delete)
/// ZonesLoaded ilə birlikdə emit edilir
class ZoneOperationSuccess extends ZoneState {
  final String message;
  final ZoneOperation operation;

  const ZoneOperationSuccess({
    required this.message,
    required this.operation,
  });

  @override
  List<Object?> get props => [message, operation];
}

enum ZoneOperation { create, update, delete, toggle }

/// Xəta
class ZoneError extends ZoneState {
  final String message;
  final ZoneErrorType type;

  const ZoneError({
    required this.message,
    this.type = ZoneErrorType.general,
  });

  @override
  List<Object?> get props => [message, type];
}

enum ZoneErrorType { general, notFound, alreadyExists }

/// Heyvan zona vəziyyəti yoxlanıldı
class AnimalLocationChecked extends ZoneState {
  final AnimalLocationEntity location;
  final Map<String, dynamic> zoneInfo;
  final List<ZoneEntity> relevantZones;

  const AnimalLocationChecked({
    required this.location,
    required this.zoneInfo,
    required this.relevantZones,
  });

  @override
  List<Object?> get props => [location, zoneInfo, relevantZones];
}