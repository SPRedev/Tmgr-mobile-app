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

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

// Enum to manage the different states of the screen's body.
enum _ScreenState { loading, error, loaded, empty }

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // Data stores
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  List<dynamic> _projects = [];
  List<dynamic> _priorities = [];

  // User info
  String _username = '...';
  int _currentUserId = 0;

  // Filter states
  int? _selectedProjectId;
  int? _selectedPriorityId;
  bool _assignedToMeOnly = false;

  // State management
  _ScreenState _screenState = _ScreenState.loading;
  String _errorMessage = '';

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
    // Only show full-screen loader on initial fetch.
    if (_allTasks.isEmpty) {
      setState(() => _screenState = _ScreenState.loading);
    }

    try {
      // Use Future.wait for efficient parallel fetching.
      final results = await Future.wait([
        _apiService.getTasks(),
        _apiService.getUserInfo(),
        _apiService.getCreateTaskFormData(),
      ]);

      if (!mounted) return;

      final tasks = results[0] as List<Task>;
      final userInfo = results[1] as Map<String, dynamic>;
      final formData = results[2] as Map<String, dynamic>;

      setState(() {
        _allTasks = tasks;
        _username = userInfo['username'] ?? 'User';
        _currentUserId = int.tryParse(userInfo['id']?.toString() ?? '0') ?? 0;
        _projects = formData['projects'] ?? [];
        _priorities = formData['priorities'] ?? [];
        _screenState = _ScreenState.loaded;
        _applyAllFilters(); // Apply filters to the newly fetched data.
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

    // Start with the full list of tasks.
    List<Task> tempTasks = List.from(_allTasks);

    // Apply each filter sequentially.
    tempTasks = tempTasks.where((task) {
      final matchesSearch =
          query.isEmpty ||
          task.name.toLowerCase().contains(query) ||
          task.projectName.toLowerCase().contains(query) ||
          task.statusName.toLowerCase().contains(query) ||
          task.assignedTo.any(
            (user) => user.username.toLowerCase().contains(query),
          );

      final matchesProject =
          _selectedProjectId == null || task.projectId == _selectedProjectId;

      final matchesPriority =
          _selectedPriorityId == null ||
          task.priorityName ==
              _getFilterNameById(_priorities, _selectedPriorityId);

      final matchesAssignment =
          !_assignedToMeOnly ||
          task.assignedTo.any((user) => user.id == _currentUserId);

      return matchesSearch &&
          matchesProject &&
          matchesPriority &&
          matchesAssignment;
    }).toList();

    setState(() {
      _filteredTasks = tempTasks;
      // If the screen was loaded but now the filtered list is empty, update the state.
      if (_screenState == _ScreenState.loaded &&
          _filteredTasks.isEmpty &&
          _allTasks.isNotEmpty) {
        _screenState = _ScreenState.empty;
      } else if (_screenState == _ScreenState.empty &&
          _filteredTasks.isNotEmpty) {
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

  void _navigateToCreateTask() async {
    final bool? wasTaskCreated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
    );
    if (wasTaskCreated == true && mounted) {
      _fetchData();
    }
  }

  Future<void> _navigateToDetail(Task task) async {
    final bool? wasTaskModified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    );
    if (wasTaskModified == true && mounted) {
      _fetchData();
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTask,
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
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationScreen()),
          ),
          tooltip: 'Notifications',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'change_password') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
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
        return const Center(child: Text('No tasks match your filters.'));
      case _ScreenState.loaded:
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding for FAB
          itemCount: _filteredTasks.length,
          itemBuilder: (context, index) {
            final task = _filteredTasks[index];
            return InkWell(
              onTap: () => _navigateToDetail(task),
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
