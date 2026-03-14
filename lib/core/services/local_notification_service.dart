import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // iOS/Android icazə sorğusu
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    AppLogger.melumat(
        'LOCAL NOTIF', 'Bildiriş icazəsi: ${settings.authorizationStatus}');

    // Foreground mesaj handler
    FirebaseMessaging.onMessage.listen((message) {
      AppLogger.melumat(
          'LOCAL NOTIF', 'Foreground mesaj: ${message.notification?.title}');
    });

    _initialized = true;
    AppLogger.ugur('LOCAL NOTIF', 'Bildiriş servisi başladıldı');
  }

  // Geofence bildirişi — Firebase in-app mesajı kimi log olunur
  Future<void> showGeofenceAlert({
    required String animalName,
    required String zoneName,
    required bool entered,
  }) async {
    final action = entered ? 'daxil oldu' : 'çıxdı';
    AppLogger.geofenceHadise(animalName, zoneName, entered);
    AppLogger.melumat(
        'LOCAL NOTIF', '$animalName "$zoneName" zonasına $action');
  }

  Future<void> showBatteryAlert({
    required String animalName,
    required int batteryPercent,
  }) async {
    AppLogger.melumat(
        'LOCAL NOTIF', '$animalName batareyası azdır: $batteryPercent%');
  }

  Future<void> cancelAll() async {
    AppLogger.melumat('LOCAL NOTIF', 'Bildirişlər ləğv edildi');
  }
}
