// lib/screens/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart'; // Assuming ApiService is here
import 'package:intl/intl.dart';
import 'package:ruko_mobile_app/screens/task_detail_screen.dart';

// Enum to manage the screen's state for cleaner UI logic.
enum _ScreenState { loading, loaded, error, empty }

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

  /// Fetches notifications from the server.
  Future<void> _loadNotifications({bool isRefresh = false}) async {
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

  /// ✅ ***CORRECTION 4: NEW CORE LOGIC***
  /// Handles the entire interaction flow when a notification is tapped.
  void _handleNotificationTap(int index) {
    final notification = _notifications[index];
    final int? taskId = int.tryParse(notification['task_id']?.toString() ?? '');
    final int notificationId = notification['id'];

    if (taskId == null) {
      _showErrorSnackBar('This notification is not linked to a valid task.');
      return;
    }

    // 1. Instantly remove the notification from the UI.
    setState(() {
      _notifications.removeAt(index);
      // If the list becomes empty, update the screen state.
      if (_notifications.isEmpty) {
        _screenState = _ScreenState.empty;
      }
    });

    // 2. In the background, send the delete request to the server.
    _apiService.deleteNotification(notificationId).catchError((e) {
      // If deletion fails, we don't bother the user, but we log it for debugging.
      // In a real app, you might want to add the notification back to the list
      // or implement a more robust retry mechanism.
      print("Failed to delete notification $notificationId from server: $e");
    });

    // 3. Immediately navigate to the Task Detail Screen.
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(taskId: taskId)),
    );
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
          // ✅ ***CORRECTION 5: UPDATED onTap***
          onTap: () => _handleNotificationTap(index),
        );
      },
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: ListView(
        // Use ListView to allow pulling to refresh even on an empty screen
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
    final int? ts = int.tryParse(timestamp.toString());
    if (ts == null) return 'Invalid date';

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
