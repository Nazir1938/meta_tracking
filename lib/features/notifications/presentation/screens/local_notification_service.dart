import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';

/// Real local bildiriş servisi.
/// pubspec.yaml-a əlavə edin:
///   flutter_local_notifications: ^17.2.4
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  // ── Android bildiriş kanalları ────────────────────────────────────────────
  static const _geofenceChannelId = 'geofence_channel';
  static const _geofenceChannelName = 'Zona Bildirişləri';
  static const _batteryChannelId = 'battery_channel';
  static const _batteryChannelName = 'Batareya Xəbərdarlıqları';
  static const _generalChannelId = 'general_channel';
  static const _generalChannelName = 'Ümumi Bildirişlər';

  Future<void> initialize() async {
    if (_initialized) return;

    // ── Android konfiqurasiyası ───────────────────────────────────────────
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ── iOS konfiqurasiyası ───────────────────────────────────────────────
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    // flutter_local_notifications v17+ → named parameter: settings:
    await _plugin.initialize(settings: initSettings);

    // ── Android kanallarını yarat ─────────────────────────────────────────
    if (!kIsWeb) {
      await _createAndroidChannels();
    }

    // ── Firebase icazəsi ──────────────────────────────────────────────────
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    AppLogger.melumat(
        'LOCAL NOTIF', 'Bildiriş icazəsi: ${settings.authorizationStatus}');

    // ── Firebase foreground handler ───────────────────────────────────────
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.melumat(
          'LOCAL NOTIF', 'FCM mesaj: ${message.notification?.title}');
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

  // ── Android kanallarını yarat ─────────────────────────────────────────────
  Future<void> _createAndroidChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _geofenceChannelId,
        _geofenceChannelName,
        description: 'Heyvanların zona giriş/çıxış bildirişləri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _batteryChannelId,
        _batteryChannelName,
        description: 'GPS cihazı batareya xəbərdarlıqları',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _generalChannelId,
        _generalChannelName,
        description: 'Ümumi bildirişlər',
        importance: Importance.defaultImportance,
      ),
    );
  }

  // ── Geofence bildirişi ────────────────────────────────────────────────────
  Future<void> showGeofenceAlert({
    required String animalName,
    required String zoneName,
    required bool entered,
  }) async {
    final action = entered ? 'daxil oldu' : 'çıxdı';
    final emoji = entered ? '✅' : '⚠️';
    final title = '$emoji $animalName zona $action';
    final body = '"$zoneName" zonasına $animalName $action';

    AppLogger.geofenceHadise(animalName, zoneName, entered);

    await _showNotification(
      id: (animalName.hashCode ^ zoneName.hashCode).abs(),
      title: title,
      body: body,
      channelId: _geofenceChannelId,
      channelName: _geofenceChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  // ── Batareya bildirişi ────────────────────────────────────────────────────
  Future<void> showBatteryAlert({
    required String animalName,
    required int batteryPercent,
  }) async {
    AppLogger.melumat(
        'LOCAL NOTIF', '$animalName batareyası azdır: $batteryPercent%');

    await _showNotification(
      id: (animalName.hashCode ^ batteryPercent).abs(),
      title: '🔋 Batareya Azdır',
      body: '$animalName cihazının batareyası $batteryPercent%-dir',
      channelId: _batteryChannelId,
      channelName: _batteryChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  // ── Ümumi bildiriş ────────────────────────────────────────────────────────
  Future<void> showGeneralNotification({
    required String title,
    required String body,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      channelId: _generalChannelId,
      channelName: _generalChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  // ── Əsas göstərmə metodu ──────────────────────────────────────────────────
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required Importance importance,
    required Priority priority,
  }) async {
    if (kIsWeb) {
      AppLogger.melumat('LOCAL NOTIF', '[WEB] $title: $body');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: priority,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // flutter_local_notifications v17+ → bütün parametrlər named:
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
      AppLogger.ugur('LOCAL NOTIF', 'Bildiriş göstərildi: $title');
    } catch (e) {
      AppLogger.xeta('LOCAL NOTIF', 'Bildiriş xətası', xetaObyekti: e);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    AppLogger.melumat('LOCAL NOTIF', 'Bildirişlər ləğv edildi');
  }
}
