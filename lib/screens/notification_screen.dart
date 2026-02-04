// lib/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:intl/intl.dart';
import 'package:ruko_mobile_app/screens/task_detail_screen.dart';

// Enum to manage the screen's state for cleaner UI logic.
enum _ScreenState { loading, loaded, error, empty }

// Helper function remains the same, it's good practice.
int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) {
    return defaultValue;
  }
  return int.tryParse(value.toString()) ?? defaultValue;
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _apiService = ApiService();

  // State Management Variables
  _ScreenState _screenState = _ScreenState.loading;
  String _errorMessage = '';
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // --- DATA HANDLING & STATE MANAGEMENT ---

  Future<void> _loadNotifications({bool isRefresh = false}) async {
    // On a manual refresh, we don't need to show the full loading spinner.
    if (!isRefresh) {
      setState(() => _screenState = _ScreenState.loading);
    }

    try {
      final fetchedNotifications = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = fetchedNotifications;
          _screenState = _notifications.isEmpty
              ? _ScreenState.empty
              : _ScreenState.loaded;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
          _screenState = _ScreenState.error;
        });
      }
    }
  }

  // ✅ THIS IS THE CORRECTED METHOD
  Future<void> _handleNotificationTap(int index) async {
    final notification = _notifications[index];
    final int taskId = _safeParseInt(notification['task_id']);
    final int notificationId = _safeParseInt(notification['id']);

    if (taskId == 0) {
      _showErrorSnackBar('This notification is not linked to a valid task.');
      return;
    }

    // Immediately delete the notification from the server in the background.
    // We use .catchError so it doesn't crash the app if it fails.
    _apiService.deleteNotification(notificationId).catchError((e) {
      print("Failed to delete notification $notificationId from server: $e");
    });

    // Remove the notification from the local list so the UI updates instantly.
    setState(() {
      _notifications.removeAt(index);
      if (_notifications.isEmpty) {
        _screenState = _ScreenState.empty;
      }
    });

    // 1. Navigate to the Task Detail Screen and WAIT for it to be closed.
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: taskId)),
    );

    // 2. After the user comes back from the Task Detail Screen,
    //    pop THIS screen (NotificationScreen) and send the "true" signal
    //    back to the TaskListScreen, telling it to refresh.
    if (mounted) {
      Navigator.of(context).pop(true); // Send the "refresh" signal
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(isRefresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case _ScreenState.loading:
        return const Center(child: CircularProgressIndicator());
      case _ScreenState.error:
        return _buildErrorWidget();
      case _ScreenState.empty:
        return _buildEmptyStateWidget();
      case _ScreenState.loaded:
        return _buildNotificationList();
    }
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final String name = notification['name'] ?? 'No Title';

        return ListTile(
          leading: Icon(
            Icons.notifications,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(name),
          subtitle: Text(_formatTimestamp(notification['date_added'])),
          onTap: () => _handleNotificationTap(index),
        );
      },
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Icon(
            Icons.notifications_off_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'You have no new notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadNotifications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'No date';
    final int ts = _safeParseInt(timestamp);
    if (ts == 0) return 'Invalid date';

    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return DateFormat.yMMMd().add_jm().format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
