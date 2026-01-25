// lib/screens/task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart'; // For AppColors
import 'package:ruko_mobile_app/widgets/comment_card.dart';
import 'package:ruko_mobile_app/screens/edit_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _initialDataFuture;
  int _currentUserId = 0;

  final _newCommentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _newCommentController.dispose();
    super.dispose();
  }

  // --- DATA HANDLING ---

  // Centralized method to load all initial data, now with a single entry point.
  void _loadInitialData() {
    setState(() {
      _initialDataFuture = _fetchData();
    });
  }

  // The core data fetching logic, isolated for clarity and reuse.
  Future<Map<String, dynamic>> _fetchData() async {
    // Future.wait is efficient for parallel, independent API calls.
    final results = await Future.wait([
      _apiService.getTaskDetails(widget.taskId),
      _apiService.getStatuses(),
      _apiService.getUserInfo(),
    ]);

    final details = results[0] as Map<String, dynamic>;
    final statuses = results[1] as List<dynamic>;
    final userInfo = results[2] as Map<String, dynamic>;

    // Safely set the current user ID.
    if (mounted) {
      setState(() {
        _currentUserId = int.tryParse(userInfo['id']?.toString() ?? '0') ?? 0;
      });
    }

    return {'details': details, 'statuses': statuses};
  }

  // --- NAVIGATION & ACTIONS ---

  void _navigateToEditTask(Map<String, dynamic> taskDetails) async {
    final bool? wasUpdated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(taskDetails: taskDetails),
      ),
    );
    // If the edit screen returns 'true', it means the task was updated, so we refresh.
    if (wasUpdated == true && mounted) {
      _loadInitialData();
    }
  }

  void _showDeleteTaskDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'Are you sure you want to permanently delete this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteTask(dialogContext), // Extracted logic
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(BuildContext dialogContext) async {
    try {
      await _apiService.deleteTask(widget.taskId);
      if (mounted) {
        Navigator.pop(dialogContext); // Close the dialog
        Navigator.pop(
          context,
          true,
        ); // Pop the detail screen, return true to refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete task: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initialDataFuture,
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Error State with Retry
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load task details:\n${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadInitialData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 3. No Data State
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('No details found.')),
          );
        }

        // 4. Success State
        final details = snapshot.data!['details'] as Map<String, dynamic>;
        final statuses = snapshot.data!['statuses'] as List<dynamic>;

        return _buildDetailScaffold(details, statuses);
      },
    );
  }

  Scaffold _buildDetailScaffold(
    Map<String, dynamic> details,
    List<dynamic> statuses,
  ) {
    final comments = details['comments'] as List? ?? [];
    final permissions = details['permissions'] as Map<String, dynamic>? ?? {};
    final bool canUpdate = permissions['can_update'] ?? false;
    final bool canDelete = permissions['can_delete'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(details['name'] ?? 'Task Details'),
        actions: [
          if (canUpdate)
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: () => _navigateToEditTask(details),
              tooltip: 'Edit Task',
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showDeleteTaskDialog,
              tooltip: 'Delete Task',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadInitialData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details['name'] ?? 'Unnamed Task',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusSection(details, statuses),
                    const Divider(height: 32),
                    _buildDescriptionSection(details),
                    const Divider(height: 32),
                    _buildCommentsSection(comments),
                  ],
                ),
              ),
            ),
          ),
          _buildNewCommentInput(),
        ],
      ),
    );
  }

  // --- SECTION WIDGETS (Extracted for clarity) ---

  Widget _buildStatusSection(
    Map<String, dynamic> details,
    List<dynamic> statuses,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'STATUS',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              details['status_name'] ?? 'N/A',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Change'),
          onPressed: () => _showStatusChangeDialog(
            context,
            statuses,
            details['status_name'] ?? '',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Map<String, dynamic> details) {
    final String description = details['description'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          description.isNotEmpty ? description : 'No description provided.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: description.isNotEmpty
                ? AppColors.textSecondary
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(List<dynamic> comments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (comments.isEmpty)
          const Text(
            'No comments yet.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return CommentCard(
                comment: comment,
                currentUserId: _currentUserId,
                onEdit: () => _showEditCommentDialog(comment),
                onDelete: () => _showDeleteConfirmationDialog(comment),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNewCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newCommentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          _isPostingComment
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _postNewComment,
                ),
        ],
      ),
    );
  }

  // --- DIALOGS & COMMENT LOGIC (Mostly unchanged, but with cleaner error messages) ---

  void _showStatusChangeDialog(
    BuildContext context,
    List<dynamic> statuses,
    String currentStatus,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Change Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final status = statuses[index];
              return ListTile(
                title: Text(status['name']),
                trailing: status['name'] == currentStatus
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => _updateTaskStatus(status['id'], dialogContext),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTaskStatus(
    int statusId,
    BuildContext dialogContext,
  ) async {
    try {
      await _apiService.updateTaskStatus(widget.taskId, statusId);
      if (mounted) Navigator.of(dialogContext).pop();
      _loadInitialData();
    } catch (e) {
      if (mounted) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update status: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _postNewComment() async {
    if (_newCommentController.text.trim().isEmpty) return;
    setState(() => _isPostingComment = true);
    try {
      await _apiService.createComment(
        widget.taskId,
        _newCommentController.text.trim(),
      );
      _newCommentController.clear();
      FocusScope.of(context).unfocus();
      _loadInitialData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to post comment: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  void _showEditCommentDialog(Map<String, dynamic> comment) {
    final editController = TextEditingController(text: comment['description']);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.updateComment(
                  comment['id'],
                  editController.text,
                );
                if (mounted) Navigator.pop(dialogContext);
                _loadInitialData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to edit comment: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> comment) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Comment?'),
        content: const Text(
          'Are you sure you want to permanently delete this comment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.deleteComment(comment['id']);
                if (mounted) Navigator.pop(dialogContext);
                _loadInitialData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete comment: ${e.toString().replaceFirst("Exception: ", "")}',
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
