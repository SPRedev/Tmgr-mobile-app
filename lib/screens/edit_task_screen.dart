// lib/screens/edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart';

class EditTaskScreen extends StatefulWidget {
  final Map<String, dynamic> taskDetails;
  const EditTaskScreen({super.key, required this.taskDetails});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late Future<Map<String, dynamic>> _formDataFuture;
  List<dynamic> _projects = [];
  List<dynamic> _taskTypes = [];
  List<dynamic> _priorities = [];
  List<dynamic> _availableUsers = [];

  int? _selectedProjectId;
  int? _selectedTypeId;
  int? _selectedPriorityId;
  List<int> _selectedUserIds = [];

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.taskDetails['name']);
    _descriptionController = TextEditingController(
      text: widget.taskDetails['description'],
    );
    _formDataFuture = _apiService.getCreateTaskFormData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ THIS IS THE CORE FIX: This method now correctly initializes all form fields
  void _initializeForm(Map<String, dynamic> formData) {
    if (_isInitialized) return;

    _projects = formData['projects'];
    _taskTypes = formData['task_types'];
    _priorities = formData['priorities'];

    // --- ✅ MODIFIED: Safely parse all incoming values ---

    // Project ID is already an integer, so it's safe.
    _selectedProjectId = widget.taskDetails['project_id'];

    // Safely parse type_id and priority_id from string to int
    _selectedTypeId = int.tryParse(
      widget.taskDetails['type_id']?.toString() ?? '',
    );
    _selectedPriorityId = int.tryParse(
      widget.taskDetails['priority_id']?.toString() ?? '',
    );

    // Safely parse the assigned_to_ids string
    final assignedIdsString = widget.taskDetails['assigned_to_ids'] as String?;
    if (assignedIdsString != null && assignedIdsString.isNotEmpty) {
      _selectedUserIds = assignedIdsString
          .split(',')
          .map((id) => int.tryParse(id.trim()) ?? 0)
          .where((id) => id != 0)
          .toList();
    }

    // Populate available users (no change here)
    if (_selectedProjectId != null) {
      final selectedProject = _projects.firstWhere(
        (p) => p['id'] == _selectedProjectId,
        orElse: () => null,
      );
      if (selectedProject != null) {
        _availableUsers = selectedProject['users'] ?? [];
      }
    }

    _isInitialized = true;
  }

  void _onProjectChanged(int? projectId) {
    if (projectId == null) return;
    final selectedProject = _projects.firstWhere(
      (p) => p['id'] == projectId,
      orElse: () => null,
    );
    setState(() {
      _selectedProjectId = projectId;
      _availableUsers = selectedProject?['users'] ?? [];
      _selectedUserIds =
          []; // Always clear user selections when project changes
    });
  }

  void _showUserSelectionDialog() {
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        // Use a temporary list to handle cancellation
        List<int> tempSelectedUserIds = List<int>.from(_selectedUserIds);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Users'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = _availableUsers[index];
                    final bool isSelected = tempSelectedUserIds.contains(
                      user['id'],
                    );
                    return CheckboxListTile(
                      title: Text(user['username']),
                      value: isSelected,
                      onChanged: (bool? checked) {
                        setDialogState(() {
                          if (checked == true) {
                            tempSelectedUserIds.add(user['id']);
                          } else {
                            tempSelectedUserIds.remove(user['id']);
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
                    setState(() {
                      _selectedUserIds = tempSelectedUserIds;
                    });
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
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
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _formDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading form data: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Could not load form data.'));
          }

          _initializeForm(snapshot.data!);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: _selectedProjectId,
                    hint: const Text('Select a Project'),
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      border: OutlineInputBorder(),
                    ),
                    items: _projects.map<DropdownMenuItem<int>>((project) {
                      return DropdownMenuItem<int>(
                        value: project['id'],
                        child: Text(project['name']),
                      );
                    }).toList(),
                    onChanged: _onProjectChanged,
                    validator: (value) =>
                        value == null ? 'Please select a project' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter a task name'
                        : null,
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
                          hint: const Text('Type'),
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: _taskTypes.map<DropdownMenuItem<int>>((type) {
                            return DropdownMenuItem<int>(
                              value: type['id'],
                              child: Text(type['name']),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedTypeId = value),
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedPriorityId,
                          hint: const Text('Priority'),
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                          ),
                          items: _priorities.map<DropdownMenuItem<int>>((p) {
                            return DropdownMenuItem<int>(
                              value: p['id'],
                              child: Text(p['name']),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedPriorityId = value),
                          validator: (value) =>
                              value == null ? 'Required' : null,
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
                            ? 'Select Users'
                            : '${_selectedUserIds.length} users selected',
                      ),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
