// lib/services/web_socket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  // --- CONFIGURATION ---
  // Replace these with your actual Pusher credentials
  static const String _appKey = '7247190dc83ad53b5182';
  static const String _cluster = 'eu';
  static const String _channelName = 'tasks';

  // --- INTERNAL STATE ---
  WebSocketChannel? _channel;
  final StreamController<void> _eventStreamController =
      StreamController.broadcast();

  // --- PUBLIC INTERFACE ---
  Stream<void> get events => _eventStreamController.stream;

  void connect() {
    final uri = Uri.parse(
      'wss://ws-$_cluster.pusher.com/app/$_appKey?protocol=7&client=flutter&version=1.0.0',
    );

    if (kDebugMode) {
      print("Attempting to connect to WebSocket: $uri");
    }

    try {
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          if (kDebugMode) {
            print("--- WebSocket channel closed by server. ---");
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print("XXX WebSocket Error: $error");
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print("XXX Failed to connect to WebSocket: $e");
      }
    }
  }

  void _handleMessage(String message) {
    if (kDebugMode) {
      print("<<< RECEIVED: $message");
    }

    final decodedMessage = json.decode(message);
    final eventName = decodedMessage['event'];

    if (eventName == 'pusher:connection_established') {
      final socketId = json.decode(decodedMessage['data'])['socket_id'];
      _subscribeToChannel(socketId);
    } else if (eventName == 'pusher:error') {
      final errorMessage = decodedMessage['data']['message'];
      if (kDebugMode) {
        print("XXX Pusher Error Received: $errorMessage");
      }
    } else if (eventName == 'TaskCreated') {
      if (kDebugMode) {
        print("✅ Real-time event 'TaskCreated' received!");
      }
      // This is the signal that the TaskListScreen is listening for.
      _eventStreamController.add(null);
    }
  }

  void _subscribeToChannel(String socketId) {
    if (_channel != null) {
      final subscriptionMessage = json.encode({
        'event': 'pusher:subscribe',
        'data': {'channel': _channelName},
      });
      if (kDebugMode) {
        print(">>> SENDING: $subscriptionMessage");
      }
      _channel!.sink.add(subscriptionMessage);
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
    }
    _eventStreamController.close();
  }
}
