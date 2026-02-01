// lib/api/firebase_api.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ruko_mobile_app/api_service.dart'; // We need this to talk to our backend

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _apiService = ApiService(); // Get instance of our ApiService

  // This function will be called from main.dart
  Future<void> initNotifications() async {
    // 1. Request permission from the user
    await _firebaseMessaging.requestPermission();

    // 2. Get the unique device token (FCM token)
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken'); // For debugging

    // 3. Send the token to your Laravel backend
    if (fcmToken != null) {
      try {
        // We will add this 'storeFcmToken' method to ApiService next
        await _apiService.storeFcmToken(fcmToken);
      } catch (e) {
        print('Failed to store FCM token: $e');
      }
    }

    // 4. Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Here you could show an in-app notification banner if you want
      }
    });
  }
}
