// lib/screens/task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/models/task.dart';
import 'package:ruko_mobile_app/screens/create_task_screen.dart'; // ✅ NEW: Import the create screen
import 'package:ruko_mobile_app/screens/login_screen.dart';
import 'package:ruko_mobile_app/screens/notification_screen.dart';
import 'package:ruko_mobile_app/screens/task_detail_screen.dart';
import 'package:ruko_mobile_app/widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _apiService = ApiService();
  String _username = '...';

  final TextEditingController _searchController = TextEditingController();
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];

  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterTasks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    // Don't show loader on pull-to-refresh, only on initial load
    if (_allTasks.isEmpty) {
      setState(() => _isLoading = true);
    }
    _error = '';

    try {
      final tasks = await _apiService.getTasks();
      final userInfo = await _apiService.getUserInfo();

      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _filteredTasks = _allTasks; // Initially show all tasks
          _filterTasks(); // Apply search filter if text is already there
          _username = userInfo['username'] ?? 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load tasks. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        return task.name.toLowerCase().contains(query) ||
            task.statusName.toLowerCase().contains(query) ||
            task.priorityName.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _refreshTasks() async {
    await _fetchData();
  }

  void _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  // ✅ NEW: Method to navigate to the create task screen
  void _navigateToCreateTask() async {
    // We wait for the result of the new screen.
    // It will return 'true' if a task was successfully created.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
    );

    // If a task was created, refresh the list to show it.
    if (result == true && mounted) {
      _refreshTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks for $_username'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      // ✅ NEW: Add the Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTask,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(child: Text(_error))
                  : _filteredTasks.isEmpty
                  ? const Center(child: Text('No tasks found.'))
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return InkWell(
                          onTap: () async {
                            // Also refresh when returning from detail screen
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskDetailScreen(taskId: task.id),
                              ),
                            );
                            _refreshTasks();
                          },
                          child: TaskCard(task: task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
