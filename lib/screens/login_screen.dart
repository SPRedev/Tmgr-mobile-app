// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:ruko_mobile_app/api_service.dart';
import 'package:ruko_mobile_app/screens/task_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();
  final _emailController = TextEditingController(text: 'admin@sarlpro.com');
  final _passwordController = TextEditingController(text: 'password');
  bool _isLoading = false;

  void _performLogin() async {
    setState(() => _isLoading = true);
    bool success = await _apiService.login(
      _emailController.text,
      _passwordController.text,
    );
    // The loading indicator should also be dismissed after the await
    setState(() => _isLoading = false);

    if (success && mounted) {
      // The 'mounted' check is crucial
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TaskListScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _performLogin,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
