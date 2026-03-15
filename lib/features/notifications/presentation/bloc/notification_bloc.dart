import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';

// ─── Entity ───────────────────────────────────────────────────────────────────

enum NotificationType { zoneAlert, separation, system }

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        data: data,
      );

  @override
  List<Object?> get props => [id, isRead];
}

// ─── Events ───────────────────────────────────────────────────────────────────

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

class MarkNotificationReadEvent extends NotificationEvent {
  final String notifId;
  const MarkNotificationReadEvent(this.notifId);
  @override
  List<Object?> get props => [notifId];
}

class MarkAllAsReadEvent extends NotificationEvent {
  const MarkAllAsReadEvent();
}

class AddNotificationEvent extends NotificationEvent {
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;

  const AddNotificationEvent({
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
  });
  @override
  List<Object?> get props => [userId, title, type];
}

class _NotificationsUpdatedEvent extends NotificationEvent {
  final List<NotificationEntity> notifications;
  const _NotificationsUpdatedEvent(this.notifications);
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;

  const NotificationLoaded(this.notifications);

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  List<NotificationEntity> get unread =>
      notifications.where((n) => !n.isRead).toList();

  @override
  List<Object?> get props => [notifications];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class NotificationBloc
    extends Bloc<NotificationEvent, NotificationState> {
  final FirebaseFirestore _db;
  StreamSubscription<List<NotificationEntity>>? _sub;

  NotificationBloc({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance,
        super(const NotificationInitial()) {
    AppLogger.melumat('NOTIF BLOC', 'NotificationBloc işə salındı');

    on<WatchNotificationsEvent>(_onWatch);
    on<_NotificationsUpdatedEvent>(_onUpdated);
    on<MarkNotificationReadEvent>(_onMarkRead);
    on<MarkAllAsReadEvent>(_onMarkAll);
    on<AddNotificationEvent>(_onAdd);
  }

  // ── Watch ─────────────────────────────────────────────────────────────────

  Future<void> _onWatch(
      WatchNotificationsEvent event, Emitter<NotificationState> emit) async {
    AppLogger.blocHadise('NotifBloc', 'WatchNotificationsEvent: ${event.userId}');
    await _sub?.cancel();

    _sub = _db
        .collection('notifications')
        .where('userId', isEqualTo: event.userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => _fromFirestore(doc))
            .whereType<NotificationEntity>()
            .toList())
        .listen(
      (notifs) {
        if (!isClosed) add(_NotificationsUpdatedEvent(notifs));
      },
      onError: (e) => AppLogger.xeta('NOTIF BLOC', 'Stream xətası', xetaObyekti: e),
    );
  }

  Future<void> _onUpdated(
      _NotificationsUpdatedEvent event,
      Emitter<NotificationState> emit) async {
    emit(NotificationLoaded(event.notifications));
  }

  // ── Mark read ─────────────────────────────────────────────────────────────

  Future<void> _onMarkRead(
      MarkNotificationReadEvent event,
      Emitter<NotificationState> emit) async {
    try {
      await _db
          .collection('notifications')
          .doc(event.notifId)
          .update({'isRead': true});
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Mark read xətası', xetaObyekti: e);
    }
  }

  Future<void> _onMarkAll(
      MarkAllAsReadEvent event,
      Emitter<NotificationState> emit) async {
    final state = this.state;
    if (state is! NotificationLoaded) return;

    final batch = _db.batch();
    for (final n in state.unread) {
      batch.update(
          _db.collection('notifications').doc(n.id), {'isRead': true});
    }
    try {
      await batch.commit();
      AppLogger.ugur('NOTIF BLOC', 'Hamısı oxundu');
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Mark all read xətası', xetaObyekti: e);
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> _onAdd(
      AddNotificationEvent event,
      Emitter<NotificationState> emit) async {
    try {
      await _db.collection('notifications').add({
        'userId': event.userId,
        'title': event.title,
        'body': event.body,
        'type': event.type.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (event.data != null) 'data': event.data,
      });
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Bildiriş əlavə xətası', xetaObyekti: e);
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  NotificationEntity? _fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final d = doc.data()!;
      return NotificationEntity(
        id: doc.id,
        userId: d['userId'] as String? ?? '',
        title: d['title'] as String? ?? '',
        body: d['body'] as String? ?? '',
        type: _parseType(d['type'] as String?),
        isRead: d['isRead'] as bool? ?? false,
        createdAt:
            (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        data: d['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      AppLogger.xeta('NOTIF BLOC', 'Parse xətası', xetaObyekti: e);
      return null;
    }
  }

  NotificationType _parseType(String? t) {
    switch (t) {
      case 'zoneAlert':  return NotificationType.zoneAlert;
      case 'separation': return NotificationType.separation;
      default:           return NotificationType.system;
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}