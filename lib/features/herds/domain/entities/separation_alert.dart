import 'package:equatable/equatable.dart';

/// Sürüdən ayrılma alert növü
enum SeparationAlertType {
  /// Heyvan sürünün mərkəzindən uzaqlaşdı
  farFromHerd,

  /// Heyvan GPS siqnalı itirdi
  signalLost,

  /// Heyvan zona xaricinə çıxdı
  outOfZone,
}

/// Sürüdən ayrılma alert
class SeparationAlert extends Equatable {
  final String id;
  final String herdId;
  final String herdName;
  final String animalId;
  final String animalName;
  final String animalEmoji;
  final SeparationAlertType type;

  /// Sürünün mərkəzindən məsafə (metr)
  final double distanceFromCenter;

  /// Sürünün mərkəzi (lat)
  final double herdCenterLat;

  /// Sürünün mərkəzi (lng)
  final double herdCenterLng;

  /// Heyvanın son mövqeyi (lat)
  final double animalLat;

  /// Heyvanın son mövqeyi (lng)
  final double animalLng;

  /// Alert vaxtı
  final DateTime timestamp;

  /// Alert oxunubmu?
  final bool isRead;

  const SeparationAlert({
    required this.id,
    required this.herdId,
    required this.herdName,
    required this.animalId,
    required this.animalName,
    required this.animalEmoji,
    required this.type,
    required this.distanceFromCenter,
    required this.herdCenterLat,
    required this.herdCenterLng,
    required this.animalLat,
    required this.animalLng,
    required this.timestamp,
    this.isRead = false,
  });

  String get typeLabel {
    switch (type) {
      case SeparationAlertType.farFromHerd:
        return 'Sürüdən ayrıldı';
      case SeparationAlertType.signalLost:
        return 'Siqnal itdi';
      case SeparationAlertType.outOfZone:
        return 'Zona xaricindədir';
    }
  }

  String get distanceLabel {
    if (distanceFromCenter < 1000) {
      return '${distanceFromCenter.toStringAsFixed(0)} m';
    }
    return '${(distanceFromCenter / 1000).toStringAsFixed(2)} km';
  }

  @override
  List<Object?> get props => [id, animalId, herdId, timestamp];

  SeparationAlert copyWith({bool? isRead}) => SeparationAlert(
        id: id,
        herdId: herdId,
        herdName: herdName,
        animalId: animalId,
        animalName: animalName,
        animalEmoji: animalEmoji,
        type: type,
        distanceFromCenter: distanceFromCenter,
        herdCenterLat: herdCenterLat,
        herdCenterLng: herdCenterLng,
        animalLat: animalLat,
        animalLng: animalLng,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );
}