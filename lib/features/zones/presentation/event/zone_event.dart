import 'package:equatable/equatable.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone.dart';
import 'package:meta_tracking/features/tracking/domain/entities/animal_location.dart';

abstract class ZoneEvent extends Equatable {
  const ZoneEvent();
  @override
  List<Object?> get props => [];
}

/// Bütün zonaları yüklə / dinlə
class LoadZonesEvent extends ZoneEvent {
  const LoadZonesEvent();
}

/// Yeni zona yarat
class CreateZoneEvent extends ZoneEvent {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final String? description;

  const CreateZoneEvent({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    this.description,
  });

  @override
  List<Object?> get props => [name, latitude, longitude, radiusInMeters];
}

/// Mövcud zonayı redaktə et
class UpdateZoneEvent extends ZoneEvent {
  final ZoneEntity zone;
  const UpdateZoneEvent(this.zone);
  @override
  List<Object?> get props => [zone];
}

/// Zona sil
class DeleteZoneEvent extends ZoneEvent {
  final String zoneId;
  const DeleteZoneEvent(this.zoneId);
  @override
  List<Object?> get props => [zoneId];
}

/// Zonanın aktiv/deaktiv vəziyyətini dəyişdir
class ToggleZoneActiveEvent extends ZoneEvent {
  final String zoneId;
  final bool isActive;
  const ToggleZoneActiveEvent({required this.zoneId, required this.isActive});
  @override
  List<Object?> get props => [zoneId, isActive];
}

/// Heyvanın zona vəziyyətini yoxla
class CheckAnimalInZoneEvent extends ZoneEvent {
  final AnimalLocationEntity location;
  const CheckAnimalInZoneEvent(this.location);
  @override
  List<Object?> get props => [location];
}