import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Future<Map<String, dynamic>> _formDataFuture;

  // Data lists
  List<dynamic> _projects = [];
  List<dynamic> _taskTypes = [];
  List<dynamic> _priorities = [];
  List<dynamic> _availableUsers = [];

  // Selected values
  int? _selectedProjectId;
  int? _selectedTypeId;
  int? _selectedPriorityId;
  final List<int> _selectedUserIds = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formDataFuture = _apiService.getCreateTaskFormData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---------------- PROJECT CHANGE ----------------

  void _onProjectChanged(int? projectId) {
    if (projectId == null) return;

    final project = _projects.firstWhere((p) => p['id'] == projectId);

    setState(() {
      _selectedProjectId = projectId;
      _availableUsers = project['users'] ?? [];
      _selectedUserIds.clear();
    });
  }

  // ---------------- USER SELECTION DIALOG ----------------

  void _showUserSelectionDialog() {
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Users'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = _availableUsers[index];
                    final isSelected = _selectedUserIds.contains(user['id']);

                    return CheckboxListTile(
                      title: Text(user['username']),
                      value: isSelected,
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            _selectedUserIds.add(user['id']);
                          } else {
                            _selectedUserIds.remove(user['id']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    setState(() {}); // refresh label count
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

  // ---------------- SUBMIT ----------------

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

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
      await _apiService.createTask(taskData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Task')),
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

          _projects = snapshot.data!['projects'];
          _taskTypes = snapshot.data!['task_types'];
          _priorities = snapshot.data!['priorities'];

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // -------- PROJECT --------
                  DropdownButtonFormField<int>(
                    initialValue: _selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      border: OutlineInputBorder(),
                    ),
                    items: _projects
                        .map<DropdownMenuItem<int>>(
                          (p) => DropdownMenuItem(
                            value: p['id'],
                            child: Text(p['name']),
                          ),
                        )
                        .toList(),
                    onChanged: _onProjectChanged,
                    validator: (v) =>
                        v == null ? 'Please select a project' : null,
                  ),
                  const SizedBox(height: 16),

                  // -------- NAME --------
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // -------- DESCRIPTION --------
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // -------- TYPE & PRIORITY --------
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedTypeId,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                          items: _taskTypes
                              .map<DropdownMenuItem<int>>(
                                (t) => DropdownMenuItem(
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
                          initialValue: _selectedPriorityId,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                          ),
                          items: _priorities
                              .map<DropdownMenuItem<int>>(
                                (p) => DropdownMenuItem(
                                  value: p['id'],
                                  child: Text(p['name']),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedPriorityId = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // -------- ✅ ASSIGN USERS --------
                  if (_selectedProjectId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assign To (Optional)',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _showUserSelectionDialog,
                          child: Text(
                            _selectedUserIds.isEmpty
                                ? 'Select Users'
                                : '${_selectedUserIds.length} users selected',
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // -------- SUBMIT --------
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Task'),
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
