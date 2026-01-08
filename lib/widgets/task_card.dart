// lib/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/main.dart'; // To access AppColors
import 'package:ruko_mobile_app/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  // Helper to get the color for the priority
  Color _getPriorityColor(String priorityName) {
    switch (priorityName.toLowerCase()) {
      case 'urgent':
        return AppColors.urgentPriority;
      case 'élevé':
        return AppColors.highPriority;
      case 'moyen':
        return AppColors.mediumPriority;
      default:
        return AppColors.textSecondary;
    }
  }

  // Helper to get the color for the status
  Color _getStatusColor(String statusName) {
    switch (statusName.toLowerCase()) {
      case 'ouvert':
        return AppColors.statusOpen;
      case 'terminé':
        return AppColors.statusDone;
      case 'en attente':
        return AppColors.highPriority; // Orange for 'Waiting'
      case 'nouveau':
        return Colors.grey.shade600; // Grey for 'New'
      case 'problème':
        return AppColors.urgentPriority; // Red for 'Problem'
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedUsers = task.assignedTo.map((u) => u.username).join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.projectName.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Use the new status color helper
                _buildTag(task.statusName, _getStatusColor(task.statusName)),
                const SizedBox(width: 8),
                // Priority tag
                _buildTag(
                  task.priorityName,
                  _getPriorityColor(task.priorityName),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
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
                    assignedUsers.isNotEmpty ? assignedUsers : 'Unassigned',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the colored tags
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.15).round()),
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
