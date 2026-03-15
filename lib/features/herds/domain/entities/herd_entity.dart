import 'package:equatable/equatable.dart';

/// Naxır — bir qrup heyvanın birlikdə idarə edilməsi üçün
class HerdEntity extends Equatable {
  final String id;
  final String name;
  final String ownerId;

  /// Bu naxıra aid heyvan ID-ləri
  final List<String> animalIds;

  /// Naxırın əsas heyvan növü (informativ)
  final String? animalType;

  /// Naxır aktiv izlənirmi?
  final bool isTracking;

  /// Naxırın təsviri
  final String? description;

  /// Sürüdən ayrılma üçün məsafə həddi (metr)
  /// Default: 500 metr
  final double separationThresholdMeters;

  /// Yaradılma tarixi
  final DateTime createdAt;

  const HerdEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.animalIds,
    this.animalType,
    this.isTracking = false,
    this.description,
    this.separationThresholdMeters = 500,
    required this.createdAt,
  });

  int get animalCount => animalIds.length;

  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        animalIds,
        isTracking,
        separationThresholdMeters,
      ];

  HerdEntity copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<String>? animalIds,
    String? animalType,
    bool? isTracking,
    String? description,
    double? separationThresholdMeters,
    DateTime? createdAt,
  }) {
    return HerdEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      animalIds: animalIds ?? this.animalIds,
      animalType: animalType ?? this.animalType,
      isTracking: isTracking ?? this.isTracking,
      description: description ?? this.description,
      separationThresholdMeters:
          separationThresholdMeters ?? this.separationThresholdMeters,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}