// lib/widgets/task_card.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/main.dart'; // To access AppColors
import 'package:ruko_mobile_app/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  // ... (your _getPriorityColor and _getStatusColor methods remain unchanged)
  Color _getPriorityColor(String? priorityName) {
    switch (priorityName?.toLowerCase()) {
      case 'urgent':
        return AppColors.urgentPriority;
      case 'élevé': // French for 'High'
        return AppColors.highPriority;
      case 'moyen': // French for 'Medium'
        return AppColors.mediumPriority;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String? statusName) {
    switch (statusName?.toLowerCase()) {
      case 'ouvert': // French for 'Open'
        return AppColors.statusOpen;
      case 'terminé': // French for 'Done'
        return AppColors.statusDone;
      case 'en attente': // French for 'Waiting'
        return AppColors.highPriority;
      case 'nouveau': // French for 'New'
        return Colors.grey.shade600;
      case 'problème': // French for 'Problem'
        return AppColors.urgentPriority;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Safe Data Extraction ---
    final String projectName = task.projectName.isNotEmpty
        ? task.projectName
        : 'No Project';
    final String taskName = task.name.isNotEmpty ? task.name : 'Unnamed Task';
    final String statusName = task.statusName.isNotEmpty
        ? task.statusName
        : 'N/A';
    final String priorityName = task.priorityName.isNotEmpty
        ? task.priorityName
        : 'N/A';

    // ✅ NEW: Safely extract creator name
    final String creatorName = task.creatorName.isNotEmpty
        ? task.creatorName
        : 'Unknown';

    final String assignedUsers = task.assignedTo
        .map((u) => u.username)
        .join(', ');
    final String displayAssignedUsers = assignedUsers.isNotEmpty
        ? assignedUsers
        : 'Unassigned';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Project Name ---
            Text(
              projectName.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),

            // --- Task Name ---
            Text(
              taskName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // --- Tags ---
            Row(
              children: [
                _buildTag(statusName, _getStatusColor(statusName)),
                const SizedBox(width: 8),
                _buildTag(priorityName, _getPriorityColor(priorityName)),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // --- Assigned Users ---
            Row(
              children: [
                const Icon(
                  Icons.group_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayAssignedUsers,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ✅ --- ADDED CREATOR INFO ---
            const SizedBox(height: 8), // Add some space
            Row(
              children: [
                const Icon(
                  Icons
                      .person_outline, // A different icon to distinguish from 'group'
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Created by $creatorName', // Display the creator's name
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // --- END OF ADDED SECTION ---
          ],
        ),
      ),
    );
  }

  // ... (_buildTag method remains unchanged)
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.15).round()), // 15% opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
