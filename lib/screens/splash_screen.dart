// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ruko_mobile_app/screens/login_screen.dart';
import 'package:ruko_mobile_app/screens/task_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // Start the authentication check as soon as the screen is initialized.
    _checkAuthStatusAndNavigate();
  }

  // This function now handles potential errors and directs the user accordingly.
  Future<void> _checkAuthStatusAndNavigate() async {
    // A short delay to ensure the splash screen is visible, improving perceived performance.
    await Future.delayed(const Duration(milliseconds: 1500));

    String? token;
    try {
      // Wrap the storage read in a try-catch block to handle potential platform errors.
      token = await _storage.read(key: 'api_token');
    } catch (e) {
      print("Error reading from secure storage: $e");
      // If storage fails, it's safest to assume the user is not logged in.
      token = null;
    }

    // The 'mounted' check is crucial before performing any navigation.
    if (!mounted) return;

    // Determine the target screen based on the token's presence.
    final Widget targetScreen = (token != null && token.isNotEmpty)
        ? const TaskListScreen()
        : const LoginScreen();

    // Use a fade transition for a smoother navigation experience from the splash screen.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app's logo icon
            const Icon(
              Icons
                  .task_alt, // You can change this to a more fitting icon if you like
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),

            // ✅ THIS IS THE CHANGED LINE
            const Text(
              "AC TMGR", // Changed from "Ruko Mobile"
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2, // Added for a more modern, spaced-out look
              ),
            ),

            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
