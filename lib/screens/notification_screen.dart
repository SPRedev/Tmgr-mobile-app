// lib/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:intl/intl.dart'; // For date formatting

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Centralized method to fetch notifications.
  void _loadNotifications() {
    setState(() {
      _notificationsFuture = _apiService.getNotifications();
    });
  }

  // A more robust date formatting function that handles potential data errors.
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    // Safely parse the timestamp whether it's an int or a string.
    final int? ts = int.tryParse(timestamp.toString());
    if (ts == null) return 'Invalid date';

    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      // Example format: "Jan 7, 2026, 3:55 PM"
      return DateFormat.yMMMd().add_jm().format(dateTime);
    } catch (e) {
      // Catch potential errors if the timestamp is out of the valid range.
      print('Date formatting error: $e');
      return 'Invalid date';
    }
  }

  // The refresh logic for the pull-to-refresh indicator.
  Future<void> _onRefresh() async {
    // This triggers a new API call and rebuilds the FutureBuilder.
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State (with a "Retry" button)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load notifications:\n${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadNotifications, // Retry the API call
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Empty or No Data State
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You have no notifications.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 4. Success State (with data)
          final notifications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _onRefresh, // Hook up the refresh logic.
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                // Safely access data with null-coalescing operators.
                final String name = notification['name'] ?? 'No Title';

                return ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(name),
                  subtitle: Text(_formatTimestamp(notification['date_added'])),
                  onTap: () {
                    // Optional: Handle notification tap, e.g., navigate to a detail screen.
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
