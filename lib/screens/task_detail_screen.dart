// lib/screens/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/main.dart';
import 'package:ruko_mobile_app/widgets/comment_card.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService _apiService = ApiService();
  // ✅ MODIFIED: We will now use a single Future to manage all initial data.
  late Future<Map<String, dynamic>> _initialDataFuture;
  int _currentUserId = 0;

  final _newCommentController = TextEditingController();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    // ✅ MODIFIED: Call a single method to load all data.
    _initialDataFuture = _loadInitialData();
  }

  @override
  void dispose() {
    _newCommentController.dispose();
    super.dispose();
  }

  // ✅ MODIFIED: This method now returns a Future and combines all API calls.
  Future<Map<String, dynamic>> _loadInitialData() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _apiService.getTaskDetails(widget.taskId),
        _apiService.getStatuses(),
        _apiService.getUserInfo(),
      ]);

      // Process the results
      final details = results[0] as Map<String, dynamic>;
      final statuses = results[1] as List<dynamic>;
      final userInfo = results[2] as Map<String, dynamic>;

      // Set the user ID and return the combined data for the FutureBuilder
      if (mounted) {
        setState(() {
          _currentUserId = userInfo['id'] ?? 0;
        });
      }

      return {
        'details': details,
        'statuses': statuses,
      };
    } catch (e) {
      // Re-throw the error to be caught by the FutureBuilder
      throw Exception('Failed to load initial data: $e');
    }
  }

  // ✅ MODIFIED: Refreshing now re-calls the combined data loading method.
  void _refreshData() {
    setState(() {
      _initialDataFuture = _loadInitialData();
    });
  }

  // --- Status Change Logic (no changes needed here) ---
  void _showStatusChangeDialog(BuildContext context, List<dynamic> statuses, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
                  trailing: status['name'] == currentStatus ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () => _updateTaskStatus(status['id'], dialogContext),
                );
              },
            ),
          ),
          actions: [TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop())],
        );
      },
    );
  }

  void _updateTaskStatus(int statusId, BuildContext dialogContext) async {
    try {
      await _apiService.updateTaskStatus(widget.taskId, statusId);
      if (mounted) Navigator.of(dialogContext).pop();
      _refreshData();
    } catch (e) {
      if (mounted) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  // --- Comment Logic (no changes needed here) ---
  void _postNewComment() async {
    if (_newCommentController.text.trim().isEmpty) return;
    setState(() => _isPostingComment = true);
    try {
      await _apiService.createComment(widget.taskId, _newCommentController.text);
      _newCommentController.clear();
      FocusScope.of(context).unfocus();
      _refreshData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
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
        content: TextField(controller: editController, autofocus: true, maxLines: null),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.updateComment(comment['id'], editController.text);
                if (mounted) Navigator.pop(dialogContext);
                _refreshData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to edit comment: $e')));
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
        content: const Text('Are you sure you want to permanently delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.deleteComment(comment['id']);
                if (mounted) Navigator.pop(dialogContext);
                _refreshData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      // ✅ MODIFIED: The main body now uses the single _initialDataFuture
      body: FutureBuilder<Map<String, dynamic>>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No details found.'));
          }

          // Unpack the data from our combined future
          final details = snapshot.data!['details'] as Map<String, dynamic>;
          final statuses = snapshot.data!['statuses'] as List<dynamic>;
          final comments = details['comments'] as List;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(details['name'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STATUS', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(details['status_name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          // The change button now gets its data from the combined future
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Change'),
                            onPressed: () => _showStatusChangeDialog(context, statuses, details['status_name']),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Text('Description', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        (details['description'] != null && details['description'].isNotEmpty) ? details['description'] : 'No description provided.',
                        style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 32),
                      Text('Comments', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (comments.isEmpty)
                        const Text('No comments yet.', style: TextStyle(color: AppColors.textSecondary))
                      else
                        // This ListView is now guaranteed to have the correct _currentUserId
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
                  ),
                ),
              ),
              _buildNewCommentInput(),
            ],
          );
        },
      ),
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
              ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3)))
              : IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _postNewComment,
                ),
        ],
      ),
    );
  }
}
