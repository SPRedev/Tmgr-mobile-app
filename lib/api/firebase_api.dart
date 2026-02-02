// lib/api/firebase_api.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // ✅ 1. ADD THIS IMPORT
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart';
import 'package:ruko_mobile_app/screens/task_detail_screen.dart'; // ✅ 1. IMPORT
import 'package:ruko_mobile_app/services/navigation_service.dart'; // ✅ 2. IMPORT

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _apiService = ApiService();

  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    // Check if the message data contains a task_id
    if (message.data.containsKey('task_id')) {
      final taskId = int.tryParse(message.data['task_id']);
      if (taskId != null) {
        // Use the NavigationService to navigate to the TaskDetailScreen
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
    final fcmToken = await _firebaseMessaging.getToken();
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
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    // 4. Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        final notification = message.notification!;

        // Send the reload signal
        notificationStream.add(null);

        // Show the SnackBar
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(notification.title ?? 'New Notification'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'VIEW', // ✅ 5. CHANGE LABEL TO "VIEW"
              onPressed: () {
                // ✅ 6. NAVIGATE WHEN THE SNACKBAR ACTION IS TAPPED
                _handleMessage(message);
              },
            ), // ✅ 2. CORRECTED THE CLOSING PARENTHESIS
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
