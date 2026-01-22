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

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _apiService = ApiService();
  String _username = '...';
  int _currentUserId = 0;

  final TextEditingController _searchController = TextEditingController();
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];

  List<dynamic> _projects = [];
  List<dynamic> _taskTypes = [];
  List<dynamic> _priorities = [];

  int? _selectedProjectId;
  int? _selectedPriorityId;
  bool _assignedToMeOnly = false;

  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_applyAllFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_allTasks.isEmpty) setState(() => _isLoading = true);
    _error = '';

    try {
      final results = await Future.wait([
        _apiService.getTasks(),
        _apiService.getUserInfo(),
        _apiService.getCreateTaskFormData(),
      ]);

      final tasks = results[0] as List<Task>;
      final userInfo = results[1] as Map<String, dynamic>;
      final formData = results[2] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _username = userInfo['username'] ?? 'User';
          _currentUserId = userInfo['id'] ?? 0;
          _projects = formData['projects'];
          _taskTypes = formData['task_types'];
          _priorities = formData['priorities'];
          _isLoading = false;
          _applyAllFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data. Pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  // ✅ MODIFIED: The search logic is now enhanced
  void _applyAllFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        // --- Search Filter ---
        // Check if any assigned user's name contains the query
        final matchesAssignedUser = task.assignedTo.any(
          (user) => user.username.toLowerCase().contains(query),
        );

        final matchesSearch =
            query.isEmpty ||
            task.name.toLowerCase().contains(query) ||
            task.statusName.toLowerCase().contains(query) ||
            task.priorityName.toLowerCase().contains(query) ||
            matchesAssignedUser; // ✅ NEW: Add the user search condition

        // --- Dropdown & Toggle Filters ---
        final matchesProject =
            _selectedProjectId == null || task.projectId == _selectedProjectId;
        final matchesPriority =
            _selectedPriorityId == null ||
            task.priorityName ==
                _getFilterNameById(_priorities, _selectedPriorityId);
        final matchesAssignment =
            !_assignedToMeOnly ||
            task.assignedTo.any((user) => user.id == _currentUserId);

        // Return true only if all filter conditions are met
        return matchesSearch &&
            matchesProject &&
            matchesPriority &&
            matchesAssignment;
      }).toList();
    });
  }

  String? _getFilterNameById(List<dynamic> options, int? id) {
    if (id == null) return null;
    return options.firstWhere((o) => o['id'] == id, orElse: () => {})['name'];
  }

  void _showFilterDialog(
    String title,
    List<dynamic> options,
    int? currentSelection,
    ValueChanged<int?> onSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
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

  void _navigateToCreateTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
    );
    if (result == true && mounted) {
      _refreshTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The NEW, improved AppBar
      appBar: AppBar(
        title: Text('Tasks for $_username'),
        actions: [
          // --- Notification Button (Stays the same) ---
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            ),
          ),

          // --- NEW: Settings/Profile Menu ---
          PopupMenuButton<String>(
            onSelected: (value) {
              // This function is called when a menu item is tapped.
              if (value == 'change_password') {
                // Navigate to the Change Password screen
                // The CORRECTED line...
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangePasswordScreen(), // <-- REMOVED 'const'
                  ),
                );
              } else if (value == 'logout') {
                // Call your existing logout method
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // --- Menu Item 1: Change Password ---
              const PopupMenuItem<String>(
                value: 'change_password',
                child: ListTile(
                  leading: Icon(Icons.password),
                  title: Text('Change Password'),
                ),
              ),
              // --- Menu Item 2: Logout ---
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
            // This sets the icon for the menu button (the three dots)
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTask,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  // ✅ MODIFIED: Updated hint text
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(child: Text(_error))
                  : _filteredTasks.isEmpty
                  ? const Center(child: Text('No tasks match your filters.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return InkWell(
                          onTap: () async {
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
