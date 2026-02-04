// lib/api/firebase_api.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart';
import 'package:ruko_mobile_app/screens/task_detail_screen.dart';
import 'package:ruko_mobile_app/services/navigation_service.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _apiService = ApiService();

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    if (message.data.containsKey('task_id')) {
      final taskId = int.tryParse(message.data['task_id']);
      if (taskId != null) {
        NavigationService.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(taskId: taskId),
          ),
        );
      }
    }
  }

  Future<void> initNotifications() async {
    // 1. Request permission from the user
    await _firebaseMessaging.requestPermission();

    // 2. Get the unique device token (FCM token)
    // ✅ THIS IS THE FINAL, CRITICAL FIX
    // We provide the VAPID key, which is required for web push notifications.
    final fcmToken = await _firebaseMessaging.getToken(
      vapidKey:
          'BJSLsDXYXcDuFxouaVzR6tLX8kZ68Ry07DAj0g0wcZIEyhxY-pMdI-dUZMpYhKHJWKs8iJP3koDL3lA6wpwPLcQ',
    );

    if (kDebugMode) {
      print('FCM Token: $fcmToken'); // For debugging
    }

    // 3. Send the token to your Laravel backend
    if (fcmToken != null) {
      try {
        await _apiService.storeFcmToken(fcmToken);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to store FCM token: $e');
        }
      }
    }

    // Handle notification that opened the app from a terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 4. Listen for incoming messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        final notification = message.notification!;

        // Send the reload signal to update the badge count
        notificationStream.add(null);

        // Show the SnackBar for in-app notifications
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(notification.title ?? 'New Notification'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'VIEW',
              onPressed: () {
                _handleMessage(message);
              },
            ),
          ),
        );

        if (kDebugMode) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      }
    });
  }
}
