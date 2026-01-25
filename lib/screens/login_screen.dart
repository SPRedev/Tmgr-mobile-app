// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/screens/task_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Enum for managing the login button's state, preventing double-taps and providing clear UI feedback.
enum _LoginState { idle, loading }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Initialize with default values for easier testing/debugging.
  final _emailController = TextEditingController(text: 'admin@sarlpro.com');
  final _passwordController = TextEditingController(text: 'password');

  _LoginState _loginState = _LoginState.idle;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // The primary login logic, now with robust error handling and state management.
  Future<void> _performLogin() async {
    // 1. Prevent multiple submissions while a request is in progress.
    if (_loginState == _LoginState.loading) return;

    // 2. Validate the form fields.
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _loginState = _LoginState.loading);

    try {
      // 3. Call the API within a try-catch block.
      final bool success = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // On success, navigate to the main app screen.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TaskListScreen()),
        );
      } else if (mounted) {
        // This case handles if login returns false without an exception (a fallback).
        _showErrorSnackBar('Login failed. Please check your credentials.');
      }
    } catch (e) {
      // 4. Catch any exceptions from the ApiService (network error, CORS, etc.).
      if (mounted) {
        // Display the clean error message from the exception.
        _showErrorSnackBar(e.toString().replaceFirst("Exception: ", ""));
      }
    } finally {
      // 5. Always reset the state, regardless of success or failure.
      if (mounted) {
        setState(() => _loginState = _LoginState.idle);
      }
    }
  }

  // Helper method to show a standardized error SnackBar.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Login'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Email Field ---
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    // Basic email format validation
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Password Field ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- Login Button ---
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the login button based on the current state.
  Widget _buildLoginButton() {
    final bool isLoading = _loginState == _LoginState.loading;

    return ElevatedButton(
      onPressed: isLoading ? null : _performLogin,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: isLoading
            ? Colors.grey
            : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text('Login'),
    );
  }
}
