// lib/screens/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart'; // Make sure this path is correct

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _apiService = ApiService();

  // A single state variable to manage the different states of the screen.
  // This is more robust than using a simple boolean like _isLoading.
  var _buttonState = _ButtonState.idle;

  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmationObscured = true;

  // The main submission logic.
  Future<void> _submitChangePassword() async {
    // Prevent multiple submissions while a request is in progress.
    if (_buttonState == _ButtonState.loading) return;

    // First, validate the form fields (e.g., check if they are empty).
    // The '!' is safe here because we check for null before returning.
    if (_formKey.currentState?.validate() != true) {
      return; // If validation fails, do nothing.
    }

    // Set the loading state to true to show a progress indicator and disable the button.
    setState(() {
      _buttonState = _ButtonState.loading;
    });

    try {
      // Call the changePassword method from our ApiService.
      final success = await _apiService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirmation: _confirmationController.text,
      );

      // If the API call was successful and the widget is still on screen...
      if (success && mounted) {
        // Show a success message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop the screen after a short delay to allow the user to see the message.
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      // If the API call failed (e.g., wrong password, network error)...
      if (mounted) {
        // Show a user-friendly error message from the exception.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // The ApiService now provides clean error messages.
              e.toString().replaceFirst("Exception: ", ""),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // No matter what happens, set the state back to idle if the widget is still mounted.
      if (mounted) {
        setState(() {
          _buttonState = _ButtonState.idle;
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is removed from the widget tree.
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Current Password Field ---
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _isCurrentPasswordObscured,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordObscured =
                            !_isCurrentPasswordObscured;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- New Password Field ---
              TextFormField(
                controller: _newPasswordController,
                obscureText: _isNewPasswordObscured,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordObscured = !_isNewPasswordObscured;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password.';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Confirm New Password Field ---
              TextFormField(
                controller: _confirmationController,
                obscureText: _isConfirmationObscured,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmationObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmationObscured = !_isConfirmationObscured;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Submit Button ---
              // This widget builds the button based on the current state.
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // A helper widget to build the button, keeping the main build method clean.
  Widget _buildSubmitButton() {
    if (_buttonState == _ButtonState.loading) {
      // Show a loading indicator inside a disabled button.
      return ElevatedButton(
        onPressed: null, // A null onPressed callback disables the button.
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
        ),
      );
    }

    // Show the standard button.
    return ElevatedButton(
      onPressed: _submitChangePassword,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Update Password', style: TextStyle(fontSize: 16)),
    );
  }
}

// An enum to represent the possible states of the submit button/form.
// This is more descriptive and less error-prone than using a boolean.
enum _ButtonState { idle, loading }
