// lib/screens/create_task_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart'; // For AppColors
import 'package:file_picker/file_picker.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

// Enum for managing the state of the submit button, making it more robust.
enum _SubmitState { idle, loading }

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // We will handle the future's state explicitly inside the FutureBuilder.
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

  // ✅ FIX 1: The _selectedFiles list MUST be inside the State class.
  // It was previously a global variable, which can cause state management issues.
  final List<PlatformFile> _selectedFiles = [];

  // Use the enum for clearer state management.
  var _submitState = _SubmitState.idle;

  @override
  void initState() {
    super.initState();
    // Fetch the form data once when the screen loads.
    _formDataFuture = _apiService.getCreateTaskFormData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS ---

  void _onProjectChanged(int? projectId) {
    if (projectId == null || projectId == _selectedProjectId) return;

    final project = _projects.firstWhere(
      (p) => p['id'] == projectId,
      orElse: () => null,
    );

    setState(() {
      _selectedProjectId = projectId;
      _availableUsers = project?['users'] ?? [];
      _selectedUserIds.clear();
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: ${e.toString()}')),
      );
    }
  }

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
      final newTaskId = await _apiService.createTask(taskData);

      if (_selectedFiles.isNotEmpty) {
        for (var file in _selectedFiles) {
          try {
            await _apiService.uploadAttachment(newTaskId, file);
          } catch (e) {
            print('Failed to upload ${file.name}: $e');
          }
        }
      }

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
          content: Text(
            'Failed to create task: ${e.toString().replaceFirst("Exception: ", "")}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitState = _SubmitState.idle);
      }
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Task'),
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
                      'Error loading form data: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _formDataFuture = _apiService.getCreateTaskFormData();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Could not load form data.'));
          }

          // ✅ FIX 2: Assign data here, just once, before building the form.
          // This is safer and more efficient than doing it inside the build method.
          _projects = snapshot.data!['projects'] ?? [];
          _taskTypes = snapshot.data!['task_types'] ?? [];
          _priorities = snapshot.data!['priorities'] ?? [];

          // ✅ FIX 3: Return the single, correctly structured _buildForm method.
          return _buildForm();
        },
      ),
    );
  }

  // ✅ FIX 4: There should only be ONE _buildForm method.
  // The duplicated one has been removed.
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Project Dropdown ---
            DropdownButtonFormField<int>(
              value: _selectedProjectId,
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
              validator: (v) => v == null ? 'Please select a project' : null,
            ),
            const SizedBox(height: 16),

            // --- Task Name ---
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Task name is required' : null,
            ),
            const SizedBox(height: 16),

            // --- Description ---
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // --- Type & Priority ---
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
                          (t) => DropdownMenuItem(
                            value: t['id'],
                            child: Text(t['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTypeId = v),
                    validator: (v) => v == null ? 'Please select a type' : null,
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
                          (p) => DropdownMenuItem(
                            value: p['id'],
                            child: Text(p['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPriorityId = v),
                    validator: (v) =>
                        v == null ? 'Please select a priority' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Assign Users Button ---
            if (_selectedProjectId != null) _buildAssignUsersButton(),
            const SizedBox(height: 16),

            // --- ATTACHMENTS SECTION ---
            _buildAttachmentsSection(),
            const SizedBox(height: 32),

            // --- Submit Button ---
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignUsersButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assign To', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          icon: const Icon(Icons.person_add_alt_1_outlined),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: _showUserSelectionDialog,
          label: Text(
            _selectedUserIds.isEmpty
                ? 'Select Users (Optional)'
                : '${_selectedUserIds.length} users selected',
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachments', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: _pickFiles,
          label: const Text('Add Files'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _selectedFiles.map((file) {
            return Chip(
              label: Text(file.name, style: const TextStyle(fontSize: 12)),
              onDeleted: () {
                setState(() {
                  _selectedFiles.remove(file);
                });
              },
              deleteIcon: const Icon(Icons.close, size: 16),
            );
          }).toList(),
        ),
      ],
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
          : const Text('Create Task'),
    );
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Users'),
              content: SizedBox(
                width: double.maxFinite,
                child: _availableUsers.isEmpty
                    ? const Text('No users available for this project.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableUsers.length,
                        itemBuilder: (context, index) {
                          final user = _availableUsers[index];
                          final isSelected = _selectedUserIds.contains(
                            user['id'],
                          );
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
                    setState(() {});
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
