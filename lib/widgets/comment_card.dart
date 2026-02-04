// lib/widgets/comment_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ruko_mobile_app/main.dart'; // For AppColors

class CommentCard extends StatelessWidget {
  final Map<String, dynamic> comment;
  final int currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  // A more robust date formatting function that safely handles various data types.
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    // Safely parse the timestamp whether it's an int or a string.
    final int? ts = int.tryParse(timestamp.toString());
    if (ts == null) return 'Invalid date';

    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dateTime);
    } catch (e) {
      // Catch potential errors if the timestamp is out of the valid range.
      print('Date formatting error in CommentCard: $e');
      return 'Invalid date';
    }
  }

  // Helper to safely parse the user ID from the comment data.
  int _getAuthorId(Map<String, dynamic> commentData) {
    final dynamic authorId = commentData['created_by'];
    if (authorId == null) return 0;
    return int.tryParse(authorId.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    // --- Safe Data Extraction ---
    // Use null-coalescing operators to provide default values and prevent null errors.
    final String authorUsername = comment['author_username'] ?? 'Unknown User';
    final String description = comment['description'] ?? 'No content';
    final String authorInitial = authorUsername.isNotEmpty
        ? authorUsername[0].toUpperCase()
        : 'U';

    // Determine if the current user is the author using the safe parsing helper.
    final bool isAuthor = currentUserId == _getAuthorId(comment);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Avatar ---
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withAlpha(50),
            child: Text(
              authorInitial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // --- Comment Content ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorUsername,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(comment['date_added']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // --- Action Menu ---
          // if (isAuthor)

          //   PopupMenuButton<String>(
          //     icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
          //     tooltip: 'Comment Actions',
          //     onSelected: (value) {
          //       if (value == 'edit') {
          //         onEdit();
          //       } else if (value == 'delete') {
          //         onDelete();
          //       }
          //     },
          //     itemBuilder: (BuildContext context) => [
          //       const PopupMenuItem<String>(
          //         value: 'edit',
          //         child: ListTile(
          //           leading: Icon(Icons.edit, size: 20),
          //           title: Text('Edit'),
          //         ),
          //       ),
          //       const PopupMenuItem<String>(
          //         value: 'delete',
          //         child: ListTile(
          //           leading: Icon(
          //             Icons.delete_outline,
          //             size: 20,
          //             color: Colors.red,
          //           ),
          //           title: Text('Delete', style: TextStyle(color: Colors.red)),
          //         ),
          //       ),
          //     ],
          //   ),
        ],
      ),
    );
  }
}
