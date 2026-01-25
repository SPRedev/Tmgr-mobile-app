// lib/widgets/filter_chip.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/main.dart'; // For AppColors

class CustomFilterChip extends StatelessWidget {
  final String? label; // Changed to nullable to handle potential nulls.
  final bool isActive;
  final VoidCallback onPressed;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Safely handle a null or empty label to prevent rendering errors.
    final String displayLabel = (label == null || label!.isEmpty)
        ? 'Filter'
        : label!;

    // Define colors and styles based on the active state to keep the UI code clean.
    final Color backgroundColor = isActive
        ? AppColors.primary
        : Colors.grey.shade200;
    final Color textColor = isActive ? Colors.white : AppColors.textSecondary;
    final BorderSide borderSide = BorderSide(
      color: isActive ? AppColors.primary : Colors.grey.shade300,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        onPressed: onPressed,
        label: Text(displayLabel),
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: borderSide,
        ),
        // Add a subtle elevation when active for better visual feedback.
        elevation: isActive ? 2.0 : 0.0,
        pressElevation: 4.0, // Elevation when the chip is being pressed.
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
    );
  }
}
