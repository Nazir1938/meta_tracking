import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final String type; // 'alert', 'info', 'warning'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data; // extra info like animalId, zoneId

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    type,
    timestamp,
    isRead,
    data,
  ];

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class GeofenceNotification extends NotificationEntity {
  final String animalName;
  final String zoneName;
  final String status; // 'entered', 'exited', 'alert'
  final double latitude;
  final double longitude;

  GeofenceNotification({
    required String id,
    required this.animalName,
    required this.zoneName,
    required this.status,
    required this.latitude,
    required this.longitude,
    required DateTime timestamp,
    bool isRead = false,
  }) : super(
         id: id,
         title: 'Geofence Rəvani',
         message: _buildMessage(animalName, zoneName, status),
         type: 'alert',
         timestamp: timestamp,
         isRead: isRead,
         data: {
           'animalName': animalName,
           'zoneName': zoneName,
           'status': status,
           'latitude': latitude,
           'longitude': longitude,
         },
       );

  static String _buildMessage(String animal, String zone, String status) {
    switch (status) {
      case 'entered':
        return '$animal zonanı daxil etdi: $zone';
      case 'exited':
        return '$animal zondı çıxdı: $zone';
      case 'alert':
        return '$animal vasitəsilə xəbərdarlıq: $zone';
      default:
        return '$animal üçün xəbərdarlıq: $zone';
    }
  }
}
