// lib/main.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ ADD
import 'package:ruko_mobile_app/api/firebase_api.dart'; // ✅ ADD
import 'firebase_options.dart';
import 'dart:async';
import 'package:ruko_mobile_app/services/navigation_service.dart';

// --- AppColors Class ---
// This class provides a centralized, static, and constant source for all theme colors.
// Using 'const' ensures these color values are compile-time constants for performance.

final StreamController<void> notificationStream = StreamController.broadcast();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppColors {
  // Private constructor to prevent instantiation of this class.

  AppColors._();

  // --- Brand & Core Colors ---
  // A deep, strong teal from the darker part of your logo. Excellent for primary elements.
  static const Color primary = Color(0xFF0D5D6E);

  // A lighter, vibrant cyan from the logo, perfect for accents or highlights.
  static const Color secondary = Color(0xFF25A4A6);

  static const Color background = Color(
    0xFFF5F5F7,
  ); // A clean, neutral background
  static const Color cardBackground = Color(0xFFFFFFFF);

  // --- Text Colors ---
  static const Color textPrimary = Color(0xFF212121); // A slightly softer black
  static const Color textSecondary = Color(
    0xFF757575,
  ); // A standard grey for subtitles

  // --- Semantic Colors (chosen to complement the new teal theme) ---
  static const Color urgentPriority = Color(
    0xFFD32F2F,
  ); // A deep red for 'Urgent'
  static const Color highPriority = Color(
    0xFFFFA000,
  ); // A strong amber for 'High'
  static const Color mediumPriority = Color(
    0xFF388E3C,
  ); // A clear green for 'Medium'

  // --- Semantic Colors for Statuses ---
  static const Color statusOpen = Color(
    0xFF1976D2,
  ); // A standard blue for 'Open'
  static const Color statusDone = Color(0xFF388E3C); // A clear green for 'Done'
}

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseApi().initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Ruko Mobile',
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
