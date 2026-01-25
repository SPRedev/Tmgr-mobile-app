// lib/models/task.dart

// A helper function to safely parse dynamic values into integers.
// It handles nulls, strings, and any other type by attempting to parse.
// Returns a default value (0) if parsing fails or the value is null.
int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) {
    return defaultValue;
  }
  return int.tryParse(value.toString()) ?? defaultValue;
}

class Task {
  final int id;
  final String name;
  final int projectId;
  final String projectName;
  final String statusName;
  final String priorityName;
  final List<AssignedUser> assignedTo;
  final String creatorName;

  Task({
    required this.id,
    required this.name,
    required this.projectId,
    required this.projectName,
    required this.statusName,
    required this.priorityName,
    required this.assignedTo,
    required this.creatorName,
  });

  // The factory constructor is now resilient to nulls and incorrect data types from the API.
  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle the list of assigned users safely.
    // If 'assigned_to' is null or not a list, it defaults to an empty list.
    var assignedToList = <AssignedUser>[];
    if (json['assigned_to'] is List) {
      assignedToList = (json['assigned_to'] as List)
          .map((userJson) => AssignedUser.fromJson(userJson))
          .toList();
    }

    return Task(
      // Use the safe parsing helper for all integer fields.
      id: _safeParseInt(json['id']),
      projectId: _safeParseInt(json['project_id']),

      // Provide default values for strings in case they are null.
      name: json['name'] ?? 'No Name',
      projectName: json['project_name'] ?? 'No Project',
      statusName: json['status_name'] ?? 'N/A',
      priorityName: json['priority_name'] ?? 'N/A',
      creatorName: json['creator_name'] ?? 'Unknown',

      // Assign the safely processed list.
      assignedTo: assignedToList,
    );
  }
}

// This class is also refactored for resilience.
class AssignedUser {
  final int id;
  final String username;

  AssignedUser({required this.id, required this.username});

  // The factory constructor now safely handles data from the API.
  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      // Use the same safe parsing helper for the integer ID.
      id: _safeParseInt(json['id']),

      // Provide a default value for the username if it's null.
      username: json['username'] ?? 'Unknown User',
    );
  }
}
