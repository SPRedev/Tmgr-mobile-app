// lib/main.dart
import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/screens/splash_screen.dart';

// --- Define our "Monday.com" inspired color palette ---
class AppColors {
  static const Color primary = Color(
    0xFF6C63FF,
  ); // A vibrant purple for primary actions
  static const Color background = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF676767);
  static const Color highPriority = Color(0xFFFDAB3D); // Orange for 'Elevated'
  static const Color urgentPriority = Color(0xFFE2445C); // Red for 'Urgent'
  static const Color mediumPriority = Color(0xFF00C875); // Green for 'Medium'
  static const Color statusOpen = Color(0xFF0073EA); // Blue for 'Open'
  static const Color statusDone = Color(0xFF00C875); // Green for 'Terminé'
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rukovoditel Tasks',
      debugShowCheckedModeBanner: false, // Hide the debug banner
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto', // A clean, modern font (add to pubspec if needed)
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardBackground,
          elevation: 1,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          // <-- CORRECT (const removed)
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        useMaterial3: true,
      ),
      // This is the corrected line. 'const' has been removed because SplashScreen
      // is a stateful widget and cannot be a compile-time constant.
      home: SplashScreen(),
    );
  }
}
