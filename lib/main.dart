// lib/main.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/screens/splash_screen.dart';

// --- AppColors Class ---
// This class provides a centralized, static, and constant source for all theme colors.
// Using 'const' ensures these color values are compile-time constants for performance.
class AppColors {
  // Private constructor to prevent instantiation of this class.
  AppColors._();

  // --- Brand & Core Colors ---
  static const Color primary = Color(
    0xFF6C63FF,
  ); // Vibrant purple for primary actions
  static const Color background = Color(
    0xFFF5F5F7,
  ); // A slightly off-white for less glare
  static const Color cardBackground = Color(0xFFFFFFFF);

  // --- Text Colors ---
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF676767);

  // --- Semantic Colors for Priorities ---
  static const Color urgentPriority = Color(0xFFE2445C); // Red
  static const Color highPriority = Color(0xFFFDAB3D); // Orange
  static const Color mediumPriority = Color(0xFF00C875); // Green

  // --- Semantic Colors for Statuses ---
  static const Color statusOpen = Color(0xFF0073EA); // Blue
  static const Color statusDone = Color(0xFF00C875); // Green
}

void main() {
  // It's good practice to ensure Flutter bindings are initialized,
  // especially for apps that might use platform channels before runApp.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruko Mobile', // A more concise app title
      debugShowCheckedModeBanner: false,

      // --- Centralized App Theme ---
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto', // Ensure this font is added to your pubspec.yaml
        // --- AppBar Theme ---
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardBackground,
          foregroundColor:
              AppColors.textPrimary, // Sets color for icons and title
          elevation: 1,
          surfaceTintColor: Colors.transparent, // Prevents M3 tinting on scroll
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto', // Explicitly define font family
          ),
        ),

        // --- Card Theme ---
        cardTheme: CardThemeData(
          // ✅ CORRECTED: Use CardThemeData
          elevation: 1,
          color: AppColors.cardBackground,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),

        // --- FloatingActionButton Theme ---
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),

        // --- ElevatedButton Theme ---
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      // The home property points to the SplashScreen, which handles the initial auth check.
      home: const SplashScreen(),
    );
  }
}
