import 'package:equatable/equatable.dart';

enum NotificationType { alert, enter, exit, battery, info }

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? animalId;
  final String? animalName;
  final String? animalEmoji;
  final String? zoneId;
  final String? zoneName;
  final String userId;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.userId,
    this.isRead = false,
    this.animalId,
    this.animalName,
    this.animalEmoji,
    this.zoneId,
    this.zoneName,
  });

  @override
  List<Object?> get props => [id, title, message, type, timestamp, isRead, userId];

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? userId,
    String? animalId,
    String? animalName,
    String? animalEmoji,
    String? zoneId,
    String? zoneName,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      animalEmoji: animalEmoji ?? this.animalEmoji,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
    );
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.alert:    return 'ALERT';
      case NotificationType.enter:    return 'DAXİL OLDU';
      case NotificationType.exit:     return 'ÇIXDI';
      case NotificationType.battery:  return 'BATAREYA';
      case NotificationType.info:     return 'MƏLUMAT';
    }
  }
}