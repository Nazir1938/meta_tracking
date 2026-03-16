import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';

/// Real local bildiriş servisi — v3 (flutter_local_notifications ^21.0.0)
/// Fayl: lib/core/services/local_notification_service.dart
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  static const _geofenceChannelId = 'geofence_channel';
  static const _geofenceChannelName = 'Zona Bildirişləri';
  static const _batteryChannelId = 'battery_channel';
  static const _batteryChannelName = 'Batareya Xəbərdarlıqları';
  static const _generalChannelId = 'general_channel';
  static const _generalChannelName = 'Ümumi Bildirişlər';

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings: initSettings);

    if (!kIsWeb) await _createAndroidChannels();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.melumat('LOCAL NOTIF', 'İcazə: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((message) {
      if (message.notification != null) {
        showGeneralNotification(
          title: message.notification!.title ?? 'Meta Tracking',
          body: message.notification!.body ?? '',
        );
      }
    });

    _initialized = true;
    AppLogger.ugur('LOCAL NOTIF', 'Bildiriş servisi başladıldı');
  }

  // ── Kanallar ──────────────────────────────────────────────────────────────
  Future<void> _createAndroidChannels() async {
    final ap = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (ap == null) return;

    // FIX v21: deleteNotificationChannel artıq named parametr istəyir
    await ap.deleteNotificationChannel(channelId: _geofenceChannelId);
    await ap.deleteNotificationChannel(channelId: _batteryChannelId);
    await ap.deleteNotificationChannel(channelId: _generalChannelId);

    // Geofence — maksimum önəm, güclü vibrasiya
    await ap.createNotificationChannel(AndroidNotificationChannel(
      _geofenceChannelId,
      _geofenceChannelName,
      description: 'Heyvanların zona giriş/çıxış bildirişləri',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      enableLights: true,
      ledColor: const Color(0xFF1D9E75),
    ));

    // Batareya
    await ap.createNotificationChannel(AndroidNotificationChannel(
      _batteryChannelId,
      _batteryChannelName,
      description: 'GPS cihazı batareya xəbərdarlıqları',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 300]),
    ));

    // Ümumi
    await ap.createNotificationChannel(const AndroidNotificationChannel(
      _generalChannelId,
      _generalChannelName,
      description: 'Ümumi bildirişlər',
      importance: Importance.defaultImportance,
      playSound: true,
    ));

    AppLogger.ugur('LOCAL NOTIF', 'Android kanalları yaradıldı');
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> showGeofenceAlert({
    required String animalName,
    required String zoneName,
    required bool entered,
  }) async {
    final emoji = entered ? '✅' : '⚠️';
    final action = entered ? 'daxil oldu' : 'çıxdı';
    AppLogger.geofenceHadise(animalName, zoneName, entered);
    await _show(
      id: (animalName.hashCode ^ zoneName.hashCode).abs(),
      title: '$emoji $animalName zona $action',
      body: '"$zoneName" zonasına $animalName $action',
      channelId: _geofenceChannelId,
      channelName: _geofenceChannelName,
      importance: Importance.max,
      priority: Priority.max,
      vibPattern: [0, 500, 200, 500],
    );
  }

  Future<void> showBatteryAlert({
    required String animalName,
    required int batteryPercent,
  }) async {
    await _show(
      id: (animalName.hashCode ^ batteryPercent).abs(),
      title: '🔋 Batareya Azdır',
      body: '$animalName cihazının batareyası $batteryPercent%-dir',
      channelId: _batteryChannelId,
      channelName: _batteryChannelName,
      importance: Importance.high,
      priority: Priority.high,
      vibPattern: [0, 300],
    );
  }

  Future<void> showGeneralNotification({
    required String title,
    required String body,
  }) async {
    await _show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      channelId: _generalChannelId,
      channelName: _generalChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      vibPattern: [0, 200],
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    AppLogger.melumat('LOCAL NOTIF', 'Bildirişlər ləğv edildi');
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required Importance importance,
    required Priority priority,
    required List<int> vibPattern,
  }) async {
    if (kIsWeb) {
      AppLogger.melumat('LOCAL NOTIF', '[WEB] $title');
      return;
    }
    try {
      final android = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: priority,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(vibPattern),
        showWhen: true,
        ticker: title,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        enableLights: true,
        ledColor: const Color(0xFF1D9E75),
        ledOnMs: 1000,
        ledOffMs: 500,
      );
      const ios = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: android, iOS: ios),
      );
      AppLogger.ugur('LOCAL NOTIF', 'Göstərildi: $title');
    } catch (e) {
      AppLogger.xeta('LOCAL NOTIF', 'Xəta', xetaObyekti: e);
    }
  }
}
