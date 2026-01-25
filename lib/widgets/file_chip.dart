// lib/widgets/file_chip.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/main.dart'; // To access AppColors

class FileChip extends StatelessWidget {
  final String?
  filename; // Changed to nullable to handle potential nulls from the API.
  final VoidCallback onTap;

  const FileChip({super.key, required this.filename, required this.onTap});

  // Helper to get a relevant icon based on file extension.
  // Now safely handles null or malformed filenames.
  IconData _getFileIcon(String? filename) {
    // If filename is null, empty, or has no extension, return a default icon.
    if (filename == null || filename.isEmpty || !filename.contains('.')) {
      return Icons.attach_file_rounded;
    }

    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely handle a null or empty filename.
    final String displayFilename = (filename == null || filename!.isEmpty)
        ? 'Unnamed File'
        : filename!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            // The icon function is now safe.
            Icon(_getFileIcon(filename), color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayFilename, // Use the safe display name.
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.download_for_offline_outlined,
              color: AppColors.textSecondary,
              size: 22,
              semanticLabel: 'Download file', // Added for accessibility.
            ),
          ],
        ),
      ),
    );
  }
}
