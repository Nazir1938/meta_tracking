import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    required super.timestamp,
    required super.userId,
    super.isRead,
    super.animalId,
    super.animalName,
    super.animalEmoji,
    super.zoneId,
    super.zoneName,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: d['title'] ?? '',
      message: d['message'] ?? '',
      type: _parseType(d['type']),
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] ?? false,
      userId: d['userId'] ?? '',
      animalId: d['animalId'],
      animalName: d['animalName'],
      animalEmoji: d['animalEmoji'],
      zoneId: d['zoneId'],
      zoneName: d['zoneName'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'message': message,
    'type': type.name,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
    'userId': userId,
    'animalId': animalId,
    'animalName': animalName,
    'animalEmoji': animalEmoji,
    'zoneId': zoneId,
    'zoneName': zoneName,
  };

  static NotificationType _parseType(String? t) {
    return NotificationType.values.firstWhere(
      (e) => e.name == t,
      orElse: () => NotificationType.info,
    );
  }
}