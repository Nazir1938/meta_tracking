import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/core/services/local_notification_service.dart';
import 'package:meta_tracking/features/notifications/data/datasources/notification_datasource.dart';
import 'package:meta_tracking/features/notifications/data/models/notification_model.dart';
import 'package:meta_tracking/features/notifications/domain/entities/notification_entity.dart';
import 'package:uuid/uuid.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class WatchNotificationsEvent extends NotificationEvent {
  final String userId;
  const WatchNotificationsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class MarkAsReadEvent extends NotificationEvent {
  final String notificationId;
  const MarkAsReadEvent(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class MarkAllAsReadEvent extends NotificationEvent {
  final String userId;
  const MarkAllAsReadEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;
  const DeleteNotificationEvent(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class AddGeofenceNotificationEvent extends NotificationEvent {
  final String userId;
  final String animalId;
  final String animalName;
  final String animalEmoji;
  final String zoneId;
  final String zoneName;
  final bool entered;
  const AddGeofenceNotificationEvent({
    required this.userId,
    required this.animalId,
    required this.animalName,
    required this.animalEmoji,
    required this.zoneId,
    required this.zoneName,
    required this.entered,
  });
}

class AddBatteryNotificationEvent extends NotificationEvent {
  final String userId;
  final String animalId;
  final String animalName;
  final String animalEmoji;
  final int batteryPercent;
  const AddBatteryNotificationEvent({
    required this.userId,
    required this.animalId,
    required this.animalName,
    required this.animalEmoji,
    required this.batteryPercent,
  });
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  const NotificationLoaded(this.notifications);
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  @override
  List<Object?> get props => [notifications];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationDataSource _ds = NotificationDataSource();
  final LocalNotificationService _localNotif = LocalNotificationService();
  final _uuid = const Uuid();
  StreamSubscription? _sub;

  NotificationBloc() : super(const NotificationInitial()) {
    AppLogger.melumat('NOTIFICATION BLOC', 'NotificationBloc işə salındı');
    _localNotif.initialize();

    on<WatchNotificationsEvent>(_onWatch);
    on<MarkAsReadEvent>(_onMarkRead);
    on<MarkAllAsReadEvent>(_onMarkAllRead);
    on<DeleteNotificationEvent>(_onDelete);
    on<AddGeofenceNotificationEvent>(_onAddGeofence);
    on<AddBatteryNotificationEvent>(_onAddBattery);
  }

  Future<void> _onWatch(
      WatchNotificationsEvent event, Emitter<NotificationState> emit) async {
    AppLogger.blocHadise(
        'NotificationBloc', 'WatchNotificationsEvent: ${event.userId}');
    emit(const NotificationLoading());
    await _sub?.cancel();

    await emit.forEach(
      _ds.watchNotifications(event.userId),
      onData: (notifications) {
        AppLogger.ugur(
            'NOTIF BLOC', '${notifications.length} bildiriş yükləndi');
        return NotificationLoaded(notifications);
      },
      onError: (e, _) {
        AppLogger.xeta('NOTIF BLOC', 'Bildiriş xətası', xetaObyekti: e);
        // Index xətası olarsa boş siyahı göstər
        return const NotificationLoaded([]);
      },
    );
  }

  Future<void> _onMarkRead(
      MarkAsReadEvent event, Emitter<NotificationState> emit) async {
    try {
      await _ds.markAsRead(event.notificationId);
      AppLogger.bildirisEmeliyyati('Oxundu: ${event.notificationId}');
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Oxundu xətası', xetaObyekti: e);
    }
  }

  Future<void> _onMarkAllRead(
      MarkAllAsReadEvent event, Emitter<NotificationState> emit) async {
    try {
      await _ds.markAllAsRead(event.userId);
      AppLogger.bildirisEmeliyyati('Hamısı oxundu');
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Hamısı oxundu xətası', xetaObyekti: e);
    }
  }

  Future<void> _onDelete(
      DeleteNotificationEvent event, Emitter<NotificationState> emit) async {
    try {
      await _ds.deleteNotification(event.notificationId);
      AppLogger.bildirisEmeliyyati('Silindi: ${event.notificationId}');
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Silmə xətası', xetaObyekti: e);
    }
  }

  Future<void> _onAddGeofence(AddGeofenceNotificationEvent event,
      Emitter<NotificationState> emit) async {
    try {
      final action = event.entered ? 'daxil oldu' : 'çıxdı';
      final notif = NotificationModel(
        id: _uuid.v4(),
        title: event.entered ? '✅ Zonaya daxil oldu' : '⚠️ Zonadan çıxdı',
        message: '${event.animalName} "${event.zoneName}" zonasına $action',
        type: event.entered ? NotificationType.enter : NotificationType.exit,
        timestamp: DateTime.now(),
        userId: event.userId,
        animalId: event.animalId,
        animalName: event.animalName,
        animalEmoji: event.animalEmoji,
        zoneName: event.zoneName,
      );
      await _ds.addNotification(notif);
      await _localNotif.showGeofenceAlert(
        animalName: event.animalName,
        zoneName: event.zoneName,
        entered: event.entered,
      );
      AppLogger.geofenceHadise(event.animalName, event.zoneName, event.entered);
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Geofence bildiriş xətası', xetaObyekti: e);
    }
  }

  Future<void> _onAddBattery(AddBatteryNotificationEvent event,
      Emitter<NotificationState> emit) async {
    try {
      final notif = NotificationModel(
        id: _uuid.v4(),
        title: '🔋 Batareya Xəbərdarlığı',
        message:
            '${event.animalName} cihazının batareyası azdır: ${event.batteryPercent}%',
        type: NotificationType.battery,
        timestamp: DateTime.now(),
        userId: event.userId,
        animalId: event.animalId,
        animalName: event.animalName,
        animalEmoji: event.animalEmoji,
      );
      await _ds.addNotification(notif);
      await _localNotif.showBatteryAlert(
        animalName: event.animalName,
        batteryPercent: event.batteryPercent,
      );
      AppLogger.bildirisEmeliyyati(
          'Batareya bildirişi göndərildi: ${event.animalName}');
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Batareya bildiriş xətası', xetaObyekti: e);
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
