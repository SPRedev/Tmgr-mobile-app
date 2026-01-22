// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ruko_mobile_app/models/task.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.100.11/larapi/public/api';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'api_token');
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {'Accept': 'application/json'},
            body: {'email': email, 'password': password},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        if (token != null) {
          await _storage.write(key: 'api_token', value: token);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login Error: ${e.toString()}');
      return false;
    }
  }

  Future<Map<String, dynamic>> getCreateTaskFormData() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/form-data/create-task'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load form data');
    }
  }

  Future<void> createTask(Map<String, dynamic> taskData) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(taskData),
    );

    if (response.statusCode != 201) {
      print('Failed to create task. Status: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Failed to create task. Check console for details.');
    }
  }

  // ✅ --- NEW: UPDATE A TASK ---
  Future<void> updateTask(int taskId, Map<String, dynamic> taskData) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(taskData),
    );

    if (response.statusCode != 200) {
      print('Failed to update task. Status: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Failed to update task. Check console for details.');
    }
  }

  Future<List<Task>> getTasks() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$_baseUrl/tasks'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Task.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<Map<String, dynamic>> getTaskDetails(int taskId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load task details');
    }
  }

  Future<List<dynamic>> getStatuses() async {
    final response = await http.get(Uri.parse('$_baseUrl/statuses'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load statuses');
    }
  }

  Future<void> updateTaskStatus(int taskId, int statusId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks/$taskId/update-status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status_id': statusId}),
    );
    if (response.statusCode != 200) {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update status');
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$_baseUrl/user'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user info');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'api_token');
  }

  Future<Map<String, dynamic>> createComment(
    int taskId,
    String description,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks/$taskId/comments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'description': description}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      print('Failed to create comment. Status Code: ${response.statusCode}');
      print('Server Response: ${response.body}');
      throw Exception('Failed to create comment. Check console for details.');
    }
  }

  Future<void> updateComment(int commentId, String description) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.put(
      Uri.parse('$_baseUrl/comments/$commentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({'description': description}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update comment.');
    }
  }

  Future<void> deleteComment(int commentId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.delete(
      Uri.parse('$_baseUrl/comments/$commentId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete comment.');
    }
  }
  // In lib/api_service.dart, inside the ApiService class

  // ✅ --- NEW: DELETE A TASK ---
  Future<void> deleteTask(int taskId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      print('Failed to delete task. Status: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Failed to delete task. Check console for details.');
    }
  }
  // In lib/api_service.dart

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User is not authenticated.');
    }

    // We will wrap only the http call in a try...catch block
    // to handle network failures.
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_baseUrl/user/manual-change-password'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'current_password': currentPassword,
              'new_password': newPassword,
              'new_password_confirmation': newPasswordConfirmation,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          ); // Add a timeout for good measure
    } catch (e) {
      // This catch block now ONLY handles network errors (e.g., no internet, server down).
      print('Change Password Network Error: ${e.toString()}');
      throw Exception(
        'Failed to connect to the server. Please check your connection.',
      );
    }

    // Now, we handle the response outside the try...catch block.
    if (response.statusCode == 200) {
      // Success!
      return true;
    } else {
      // This is an API error (e.g., wrong password, validation fail).
      // We decode the body and throw the specific message from the server.
      final errorBody = json.decode(response.body);
      final errorMessage =
          errorBody['error'] ??
          errorBody['message'] ??
          'An unknown error occurred.';
      throw Exception(errorMessage);
    }
  }
}
