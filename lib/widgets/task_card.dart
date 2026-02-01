// lib/widgets/task_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ruko_mobile_app/main.dart';
import 'package:ruko_mobile_app/models/task.dart';
import 'package:ruko_mobile_app/util/color_helpers.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

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
    final String creatorName = task.creatorName.isNotEmpty
        ? task.creatorName
        : 'Unknown';
    final String assignedUsers = task.assignedTo
        .map((u) => u.username)
        .join(', ');
    final String displayAssignedUsers = assignedUsers.isNotEmpty
        ? assignedUsers
        : 'Unassigned';

    // --- Color Parsing ---
    final statusColor = hexToColor(task.statusColor, defaultColor: Colors.blue);
    final priorityColor = hexToColor(
      task.priorityColor,
      defaultColor: Colors.grey,
    );

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
                _buildTag(statusName, statusColor),
                const SizedBox(width: 8),
                _buildTag(priorityName, priorityColor),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),

            // --- Info Rows ---
            _buildInfoRow(
              icon: Icons.person_outline,
              text: 'Created by $creatorName',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.group_outlined,
              text: displayAssignedUsers,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              text:
                  'Created on ${DateFormat('MMM d, yyyy').format(task.createdAt)}',
            ),
          ],
        ),
      ),
    );
  }

  // This method builds the colored status/priority tags.
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

  // ✅ REVERTED: This helper widget now only needs to handle an IconData.
  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
