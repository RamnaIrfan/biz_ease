import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    }

    // 2. Local Notifications Setup (for action buttons)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? payload = response.payload;
        final String? actionId = response.actionId;

        if (payload != null) {
          if (actionId == 'confirm_order') {
             await _handleOrderVerification(payload, true);
          } else if (actionId == 'cancel_order') {
             await _handleOrderVerification(payload, false);
          }
        }
      },
    );

    // 3. Create Android Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_verification',
      'Order Verification',
      description: 'Used for order confirmation buttons',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Listen for messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  static Future<String?> getToken() async {
    try {
      // Only request token if permissions are likely granted
      return await _fcm.getToken();
    } catch (e) {
      // Silence permission errors to avoid console noise
      if (e.toString().contains('permission-blocked')) return null;
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  static Future<void> updateTokenInFirestore(String userId) async {
    String? token = await getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static void _showLocalNotification(RemoteMessage message) async {
    final orderId = message.data['orderId'];
    final type = message.data['type'];

    if (type == 'order_verification' && orderId != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'order_verification',
        'Order Verification',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'confirm_order',
            'Confirm Order',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'cancel_order',
            'Cancel Order',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        0,
        message.notification?.title,
        message.notification?.body,
        platformChannelSpecifics,
        payload: orderId,
      );
    }
  }

  static Future<void> _handleOrderVerification(String orderId, bool confirmed) async {
    final orderService = OrderService();
    if (confirmed) {
      await orderService.updateOrderStatus(orderId, OrderStatus.confirmed);
      debugPrint('Order $orderId confirmed via notification');
    } else {
      await orderService.updateOrderStatus(orderId, OrderStatus.cancelled);
      debugPrint('Order $orderId cancelled via notification');
    }
  }
}
