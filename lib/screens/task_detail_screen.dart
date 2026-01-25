// lib/screens/task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart'; // For AppColors
import 'package:ruko_mobile_app/widgets/comment_card.dart';
// The 'edit_task_screen.dart' import is now removed.

// Enum to manage the screen's state, making the build method cleaner.
enum _ScreenState { loading, loaded, error }

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService _apiService = ApiService();
  final _newCommentController = TextEditingController();

  // State Management Variables
  _ScreenState _screenState = _ScreenState.loading;
  String _errorMessage = '';
  bool _isPostingComment = false;
  bool _hasChanges = false; // Tracks if status changes or comments are made.

  // Data Stores
  int _currentUserId = 0;
  Map<String, dynamic> _taskDetails = {};
  List<dynamic> _statuses = [];

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

  Future<void> _loadInitialData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() => _screenState = _ScreenState.loading);
    }

    try {
      final results = await Future.wait([
        _apiService.getTaskDetails(widget.taskId),
        _apiService.getStatuses(),
        _apiService.getUserInfo(),
      ]);

      if (!mounted) return;

      setState(() {
        _taskDetails = results[0] as Map<String, dynamic>;
        _statuses = results[1] as List<dynamic>;
        final userInfo = results[2] as Map<String, dynamic>;
        _currentUserId = int.tryParse(userInfo['id']?.toString() ?? '0') ?? 0;
        _screenState = _ScreenState.loaded;
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

  // --- ASYNCHRONOUS ACTIONS ---

  Future<void> _updateTaskStatus(int statusId) async {
    try {
      await _apiService.updateTaskStatus(widget.taskId, statusId);
      if (mounted) {
        _hasChanges = true;
        _loadInitialData(isRefresh: true);
      }
    } catch (e) {
      if (mounted)
        _showErrorSnackBar(
          'Failed to update status: ${e.toString().replaceFirst("Exception: ", "")}',
        );
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
      if (mounted) {
        _hasChanges = true;
        _loadInitialData(isRefresh: true);
      }
    } catch (e) {
      if (mounted)
        _showErrorSnackBar(
          'Failed to post comment: ${e.toString().replaceFirst("Exception: ", "")}',
        );
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _deleteTask() async {
    try {
      await _apiService.deleteTask(widget.taskId);
      if (mounted) {
        Navigator.pop(context, true); // Pop screen, return true to refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        _showErrorSnackBar(
          'Failed to delete task: ${e.toString().replaceFirst("Exception: ", "")}',
        );
    }
  }

  // NOTE: All comment-related API calls are kept as they are part of the desired functionality.
  Future<void> _editComment(
    int commentId,
    String newDescription,
    BuildContext dialogContext,
  ) async {
    Navigator.pop(dialogContext);
    try {
      await _apiService.updateComment(commentId, newDescription);
      if (mounted) {
        _hasChanges = true;
        _loadInitialData(isRefresh: true);
      }
    } catch (e) {
      if (mounted)
        _showErrorSnackBar(
          'Failed to edit comment: ${e.toString().replaceFirst("Exception: ", "")}',
        );
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await _apiService.deleteComment(commentId);
      if (mounted) {
        _hasChanges = true;
        _loadInitialData(isRefresh: true);
      }
    } catch (e) {
      if (mounted)
        _showErrorSnackBar(
          'Failed to delete comment: ${e.toString().replaceFirst("Exception: ", "")}',
        );
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(appBar: _buildAppBar(), body: _buildBody()),
    );
  }

  AppBar _buildAppBar() {
    if (_screenState == _ScreenState.loaded) {
      // final permissions = _taskDetails['permissions'] as Map<String, dynamic>? ?? {};
      // final bool canUpdate = permissions['can_update'] ?? false; // No longer needed
      final bool canDelete =
          (_taskDetails['permissions'] as Map<String, dynamic>? ??
              {})['can_delete'] ??
          false;

      return AppBar(
        title: Text(_taskDetails['name'] ?? 'Task Details'),
        actions: [
          // ✅ THE EDIT BUTTON IS NOW REMOVED.
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showDeleteTaskDialog,
              tooltip: 'Delete Task',
            ),
        ],
      );
    }
    return AppBar(
      title: Text(
        _screenState == _ScreenState.loading ? 'Loading...' : 'Error',
      ),
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
                  onPressed: () => _loadInitialData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case _ScreenState.loaded:
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadInitialData(isRefresh: true),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _taskDetails['name'] ?? 'Unnamed Task',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusSection(),
                      const Divider(height: 32),
                      _buildDescriptionSection(),
                      const Divider(height: 32),
                      _buildCommentsSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildNewCommentInput(),
          ],
        );
    }
  }

  // --- SECTION WIDGETS ---

  Widget _buildStatusSection() {
    final String currentStatus = _taskDetails['status_name'] ?? 'N/A';
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
              currentStatus,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Change'),
          onPressed: () => _showStatusChangeDialog(currentStatus),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    final String description = _taskDetails['description'] ?? '';
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

  Widget _buildCommentsSection() {
    final List<dynamic> comments = _taskDetails['comments'] as List? ?? [];
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
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No comments yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
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

  // --- DIALOGS & HELPERS ---

  void _showStatusChangeDialog(String currentStatus) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _statuses.length,
            itemBuilder: (context, index) {
              final status = _statuses[index];
              return ListTile(
                title: Text(status['name']),
                trailing: status['name'] == currentStatus
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  final int? statusId = int.tryParse(status['id'].toString());
                  if (statusId != null) {
                    _updateTaskStatus(statusId);
                  }
                },
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
            onPressed: () =>
                _editComment(comment['id'], editController.text, dialogContext),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTaskDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'Are you sure you want to permanently delete this task?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteTask();
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
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteComment(comment['id']);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ✅ The _navigateToEditTask method has been removed.
}
