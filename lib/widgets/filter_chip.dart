// lib/widgets/filter_chip.dart
import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/main.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        onPressed: onPressed,
        label: Text(label),
        labelStyle: TextStyle(
          color: isActive ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: isActive ? AppColors.primary : Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
