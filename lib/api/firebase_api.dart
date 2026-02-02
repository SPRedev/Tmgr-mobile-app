// lib/api/firebase_api.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // ✅ 1. ADD THIS IMPORT
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _apiService = ApiService();

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
              label: 'OK',
              onPressed: () {
                // This is where the action for the button goes.
                // It should be empty if you just want it to dismiss.
              },
            ), // ✅ 2. CORRECTED THE CLOSING PARENTHESIS
          ),
        );

        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
      }
    });
  }
}
