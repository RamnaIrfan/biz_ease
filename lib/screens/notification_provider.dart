import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  StreamSubscription? _subscription;
  String? _userId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _subscription = _notificationService.getNotifications(userId).listen((data) {
      _notifications = data;
      notifyListeners();
    });
  }

  void clear() {
    _subscription?.cancel();
    _notifications = [];
    _userId = null;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    if (_userId != null) {
      await _notificationService.markAllAsRead(_userId!);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(notificationId);
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    if (_userId != null) {
      await _notificationService.createNotification(
        userId: _userId!,
        title: title,
        message: message,
        type: type,
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
