// lib/screens/task_list_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/models/task.dart';
import 'package:ruko_mobile_app/screens/create_task_screen.dart';
import 'package:ruko_mobile_app/screens/login_screen.dart';
import 'package:ruko_mobile_app/screens/notification_screen.dart';
import 'package:ruko_mobile_app/screens/task_detail_screen.dart';
import 'package:ruko_mobile_app/widgets/task_card.dart';
import 'package:ruko_mobile_app/widgets/filter_chip.dart';
import 'package:ruko_mobile_app/screens/change_password_screen.dart';
import 'package:badges/badges.dart' as badges;

// Enum to manage the screen's state, making the build method cleaner.
enum _ScreenState { loading, error, loaded, empty }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // State Management
  _ScreenState _screenState = _ScreenState.loading;
  String _errorMessage = '';

  // Data Stores
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  List<dynamic> _projects = [];
  List<dynamic> _priorities = [];
  int _notificationCount = 0;

  // User Info
  String _username = '...';
  int _currentUserId = 0;

  // Filter States
  int? _selectedProjectId;
  int? _selectedPriorityId;
  bool _assignedToMeOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_applyAllFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyAllFilters);
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA & STATE LOGIC ---

  Future<void> _fetchData() async {
    // Only show a full-screen loader on the very first fetch.
    if (_allTasks.isEmpty) {
      setState(() => _screenState = _ScreenState.loading);
    }

    try {
      final results = await Future.wait([
        _apiService.getTasks(),
        _apiService.getUserInfo(),
        _apiService.getCreateTaskFormData(),
        _apiService.getNotifications(),
      ]);

      if (!mounted) return;

      final tasks = results[0] as List<Task>;
      final userInfo = results[1] as Map<String, dynamic>;
      final formData = results[2] as Map<String, dynamic>;
      final notifications = results[3] as List<dynamic>;

      setState(() {
        _allTasks = tasks;
        _username = userInfo['username'] ?? 'User';
        _currentUserId = int.tryParse(userInfo['id']?.toString() ?? '0') ?? 0;
        _projects = formData['projects'] ?? [];
        _priorities = formData['priorities'] ?? [];
        _notificationCount = notifications.length;
        _applyAllFilters(); // Initial filter application
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
          _screenState = _ScreenState.error;
        });
      }
    }
  }

  void _applyAllFilters() {
    final query = _searchController.text.toLowerCase();
    List<Task> tempTasks = List.from(_allTasks);

    // Apply each filter sequentially for clarity.
    if (query.isNotEmpty) {
      tempTasks = tempTasks.where((task) {
        return task.name.toLowerCase().contains(query) ||
            task.projectName.toLowerCase().contains(query) ||
            task.statusName.toLowerCase().contains(query) ||
            task.assignedTo.any(
              (user) => user.username.toLowerCase().contains(query),
            );
      }).toList();
    }

    if (_selectedProjectId != null) {
      tempTasks = tempTasks
          .where((task) => task.projectId == _selectedProjectId)
          .toList();
    }

    if (_selectedPriorityId != null) {
      final priorityName = _getFilterNameById(_priorities, _selectedPriorityId);
      tempTasks = tempTasks
          .where((task) => task.priorityName == priorityName)
          .toList();
    }

    if (_assignedToMeOnly) {
      tempTasks = tempTasks
          .where(
            (task) => task.assignedTo.any((user) => user.id == _currentUserId),
          )
          .toList();
    }

    setState(() {
      _filteredTasks = tempTasks;
      // Determine the final screen state based on the filtered results.
      if (_allTasks.isEmpty && _screenState != _ScreenState.loading) {
        _screenState = _ScreenState.empty;
      } else if (_filteredTasks.isEmpty && _allTasks.isNotEmpty) {
        _screenState = _ScreenState.empty;
      } else {
        _screenState = _ScreenState.loaded;
      }
    });
  }

  String? _getFilterNameById(List<dynamic> options, int? id) {
    if (id == null) return null;
    final option = options.firstWhere((o) => o['id'] == id, orElse: () => null);
    return option?['name'];
  }

  // --- NAVIGATION & ACTIONS ---

  void _logout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _navigateTo(Widget screen) async {
    // This generic navigation method handles refreshing data on return.
    final bool? shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (shouldRefresh == true && mounted) {
      _fetchData();
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateTo(const CreateTaskScreen()),
        child: const Icon(Icons.add),
        tooltip: 'Create Task',
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Column(
          children: [
            _buildFilterBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Tasks for $_username'),
      actions: [
        // ✅ REFACTORED: The IconButton is now wrapped with the Badge widget.
        badges.Badge(
          // Show the badge only if there are notifications.
          showBadge: _notificationCount > 0,
          // Position the badge at the top-right corner of the icon.
          position: badges.BadgePosition.topEnd(top: 4, end: 4),
          // The content of the badge (the number).
          badgeContent: Text(
            _notificationCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          // The child of the badge is your original IconButton.
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _navigateTo(const NotificationScreen()),
            tooltip: 'Notifications',
          ),
        ),

        // The PopupMenuButton remains exactly the same.
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'change_password') {
              _navigateTo(const ChangePasswordScreen());
            } else if (value == 'logout') {
              _logout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'change_password',
              child: ListTile(
                leading: Icon(Icons.password),
                title: Text('Change Password'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
          tooltip: 'More Options',
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, user, status...',
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CustomFilterChip(
                label: 'Assigned to Me',
                isActive: _assignedToMeOnly,
                onPressed: () {
                  setState(() => _assignedToMeOnly = !_assignedToMeOnly);
                  _applyAllFilters();
                },
              ),
              CustomFilterChip(
                label:
                    _getFilterNameById(_projects, _selectedProjectId) ??
                    'All Projects',
                isActive: _selectedProjectId != null,
                onPressed: () => _showFilterDialog(
                  'Project',
                  _projects,
                  _selectedProjectId,
                  (id) {
                    setState(() => _selectedProjectId = id);
                    _applyAllFilters();
                  },
                ),
              ),
              CustomFilterChip(
                label:
                    _getFilterNameById(_priorities, _selectedPriorityId) ??
                    'All Priorities',
                isActive: _selectedPriorityId != null,
                onPressed: () => _showFilterDialog(
                  'Priority',
                  _priorities,
                  _selectedPriorityId,
                  (id) {
                    setState(() => _selectedPriorityId = id);
                    _applyAllFilters();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    // The body is now built based on the clean _screenState enum.
    switch (_screenState) {
      case _ScreenState.loading:
        return const Center(child: CircularProgressIndicator());
      case _ScreenState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $_errorMessage', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case _ScreenState.empty:
        // A specific state for when filters result in an empty list.
        return const Center(child: Text('No tasks match your filters.'));
      case _ScreenState.loaded:
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding for FAB
          itemCount: _filteredTasks.length,
          itemBuilder: (context, index) {
            final task = _filteredTasks[index];
            return InkWell(
              onTap: () => _navigateTo(TaskDetailScreen(taskId: task.id)),
              child: TaskCard(task: task),
            );
          },
        );
    }
  }

  void _showFilterDialog(
    String title,
    List<dynamic> options,
    int? currentSelection,
    ValueChanged<int?> onSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by $title'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: Text('All ${title}s'),
                  trailing: currentSelection == null
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    onSelected(null);
                    Navigator.of(context).pop();
                  },
                );
              }
              final option = options[index - 1];
              return ListTile(
                title: Text(option['name']),
                trailing: currentSelection == option['id']
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  onSelected(option['id']);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
