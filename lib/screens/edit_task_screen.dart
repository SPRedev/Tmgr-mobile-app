// lib/screens/edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
// Assuming AppColors is defined, otherwise replace with Theme.of(context).primaryColor
import 'package:ruko_mobile_app/main.dart';

class EditTaskScreen extends StatefulWidget {
  final Map<String, dynamic> taskDetails;
  const EditTaskScreen({super.key, required this.taskDetails});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

// Enum for clearer state management of the submit button.
enum _SubmitState { idle, loading }

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controllers are initialized in initState.
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late Future<Map<String, dynamic>> _formDataFuture;

  // Data from API
  List<dynamic> _projects = [];
  List<dynamic> _taskTypes = [];
  List<dynamic> _priorities = [];
  List<dynamic> _availableUsers = [];

  // Selected form values
  int? _selectedProjectId;
  int? _selectedTypeId;
  int? _selectedPriorityId;
  List<int> _selectedUserIds = [];

  _SubmitState _submitState = _SubmitState.idle;
  bool _isFormInitialized =
      false; // Prevents re-initializing the form on rebuilds.

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data from the widget.
    _nameController = TextEditingController(
      text: widget.taskDetails['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.taskDetails['description'] ?? '',
    );

    // Fetch static form data needed for dropdowns.
    _formDataFuture = _apiService.getCreateTaskFormData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS ---

  // Safely initializes the form's state from the fetched form data and the initial task details.
  void _initializeFormState(Map<String, dynamic> formData) {
    if (_isFormInitialized) return;

    // Helper for safely parsing string or int values.
    int? safeParse(dynamic value) {
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    // Populate data for dropdowns.
    _projects = formData['projects'] ?? [];
    _taskTypes = formData['task_types'] ?? [];
    _priorities = formData['priorities'] ?? [];

    // --- Initialize selected values from widget.taskDetails with safe parsing ---
    _selectedProjectId = safeParse(widget.taskDetails['project_id']);
    _selectedTypeId = safeParse(widget.taskDetails['type_id']);
    _selectedPriorityId = safeParse(widget.taskDetails['priority_id']);

    // Safely parse the assigned user IDs, which might be a comma-separated string or a list.
    final dynamic assigned =
        widget.taskDetails['assigned_to'] ??
        widget.taskDetails['assigned_to_ids'];
    if (assigned is List) {
      _selectedUserIds = List<int>.from(
        assigned.map((e) => safeParse(e)).where((id) => id != null),
      );
    } else if (assigned is String && assigned.isNotEmpty) {
      _selectedUserIds = assigned
          .split(',')
          .map((id) => safeParse(id.trim()))
          .whereType<int>()
          .toList();
    }

    // After setting the project ID, determine the available users for that project.
    if (_selectedProjectId != null) {
      final selectedProject = _projects.firstWhere(
        (p) => p['id'] == _selectedProjectId,
        orElse: () => null,
      );
      if (selectedProject != null) {
        _availableUsers = selectedProject['users'] ?? [];
      }
    }

    _isFormInitialized = true;
  }

  // Handles logic when the user selects a different project.
  void _onProjectChanged(int? projectId) {
    if (projectId == null || projectId == _selectedProjectId) return;

    final selectedProject = _projects.firstWhere(
      (p) => p['id'] == projectId,
      orElse: () => null,
    );

    setState(() {
      _selectedProjectId = projectId;
      _availableUsers = selectedProject?['users'] ?? [];
      // When project changes, the old user assignments are no longer valid.
      _selectedUserIds.clear();
    });
  }

  // Handles the form submission.
  Future<void> _submitForm() async {
    if (_submitState == _SubmitState.loading) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _submitState = _SubmitState.loading);

    final taskData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'project_id': _selectedProjectId,
      'type_id': _selectedTypeId,
      'priority_id': _selectedPriorityId,
      'assigned_to': _selectedUserIds,
    };

    try {
      await _apiService.updateTask(widget.taskDetails['id'], taskData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Pop with 'true' to signal a refresh.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update task: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitState = _SubmitState.idle);
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _formDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _formDataFuture = _apiService.getCreateTaskFormData();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Could not load form data.'));
          }

          // Initialize the form state once the future is complete.
          _initializeFormState(snapshot.data!);

          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Using 'value' instead of 'initialValue' ensures the dropdown updates correctly on state changes.
            DropdownButtonFormField<int>(
              value: _selectedProjectId,
              decoration: const InputDecoration(
                labelText: 'Project',
                border: OutlineInputBorder(),
              ),
              items: _projects
                  .map<DropdownMenuItem<int>>(
                    (p) => DropdownMenuItem<int>(
                      value: p['id'],
                      child: Text(p['name']),
                    ),
                  )
                  .toList(),
              onChanged: _onProjectChanged,
              validator: (v) => v == null ? 'Please select a project' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please enter a task name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _taskTypes
                        .map<DropdownMenuItem<int>>(
                          (t) => DropdownMenuItem<int>(
                            value: t['id'],
                            child: Text(t['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTypeId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedPriorityId,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: _priorities
                        .map<DropdownMenuItem<int>>(
                          (p) => DropdownMenuItem<int>(
                            value: p['id'],
                            child: Text(p['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPriorityId = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedProjectId != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.group_add_outlined),
                onPressed: _showUserSelectionDialog,
                label: Text(
                  _selectedUserIds.isEmpty
                      ? 'Assign Users'
                      : '${_selectedUserIds.length} users assigned',
                ),
              ),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool isLoading = _submitState == _SubmitState.loading;
    return ElevatedButton(
      onPressed: isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: isLoading
            ? Colors.grey
            : (AppColors.primary ?? Theme.of(context).primaryColor),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text('Save Changes'),
    );
  }

  void _showUserSelectionDialog() {
    // This dialog implementation is solid, with a temporary list to handle cancellations.
    showDialog(
      context: context,
      builder: (context) {
        // The temporary list correctly holds integers.
        List<int> tempSelectedUserIds = List<int>.from(_selectedUserIds);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Users'),
              content: SizedBox(
                width: double.maxFinite,
                child: _availableUsers.isEmpty
                    ? const Center(
                        child: Text("No users available for this project."),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableUsers.length,
                        itemBuilder: (context, index) {
                          final user = _availableUsers[index];

                          // ✅ --- THE FIX IS HERE ---
                          // Safely parse the user's ID from the available list to ensure
                          // we are comparing an integer with our list of integer IDs.
                          final int? currentUserId = int.tryParse(
                            user['id']?.toString() ?? '',
                          );

                          // Now, the 'contains' check will work correctly.
                          final bool isSelected =
                              currentUserId != null &&
                              tempSelectedUserIds.contains(currentUserId);

                          return CheckboxListTile(
                            title: Text(user['username'] ?? 'Unknown User'),
                            value: isSelected,
                            onChanged: (bool? checked) {
                              // Ensure we only add/remove valid integer IDs.
                              if (currentUserId == null) return;

                              setDialogState(() {
                                if (checked == true) {
                                  tempSelectedUserIds.add(currentUserId);
                                } else {
                                  tempSelectedUserIds.remove(currentUserId);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedUserIds = tempSelectedUserIds);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
