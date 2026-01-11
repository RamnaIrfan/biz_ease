import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Get notifications for a user (including global notifications)
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', whereIn: [userId, 'all'])
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory because whereIn and orderBy in Firestore might require complex index
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  // Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    try {
      final docId = const Uuid().v4();
      await _firestore.collection(_collection).doc(docId).set({
        ...notification.toMap(),
        'id': docId,
      });
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
  
  // Create notification helper
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    );
    await addNotification(notification);
  }
}
