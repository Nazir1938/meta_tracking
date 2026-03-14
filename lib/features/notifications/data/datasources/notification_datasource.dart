import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import '../models/notification_model.dart';

class NotificationDataSource {
  final FirebaseFirestore _firestore;

  NotificationDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    AppLogger.melumat('NOTIF DS', 'Bildirişlər dinlənilir: $userId');
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(NotificationModel.fromFirestore).toList();
          AppLogger.melumat('NOTIF DS', '${list.length} bildiriş alındı');
          return list;
        });
  }

  Future<void> addNotification(NotificationModel notif) async {
    await _firestore.collection('notifications').doc(notif.id).set(notif.toFirestore());
    AppLogger.ugur('NOTIF DS', 'Bildiriş əlavə edildi: ${notif.title}');
  }

  Future<void> markAsRead(String notifId) async {
    await _firestore.collection('notifications').doc(notifId).update({'isRead': true});
    AppLogger.melumat('NOTIF DS', 'Bildiriş oxundu: $notifId');
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
    AppLogger.ugur('NOTIF DS', 'Hamısı oxundu: ${snap.docs.length} bildiriş');
  }

  Future<void> deleteNotification(String notifId) async {
    await _firestore.collection('notifications').doc(notifId).delete();
    AppLogger.melumat('NOTIF DS', 'Bildiriş silindi: $notifId');
  }

  Future<void> deleteAll(String userId) async {
    final batch = _firestore.batch();
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    AppLogger.ugur('NOTIF DS', 'Hamısı silindi');
  }
}