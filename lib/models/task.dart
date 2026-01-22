// lib/models/task.dart
// Use your project name

// In lib/models/task.dart

class Task {
  final int id;
  final String name;
  final int projectId;
  final String projectName; // ✅ NEW
  final String statusName;
  final String priorityName;
  final List<AssignedUser> assignedTo; // Assuming AssignedUser is defined

  Task({
    required this.id,
    required this.name,
    required this.projectId,
    required this.projectName, // ✅ NEW
    required this.statusName,
    required this.priorityName,
    required this.assignedTo,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'No Name',
      projectId: json['project_id'] ?? 0,
      projectName: json['project_name'] ?? 'No Project', // ✅ NEW
      statusName: json['status_name'] ?? 'N/A',
      priorityName: json['priority_name'] ?? 'N/A',
      // This part might cause errors if AssignedUser is not defined.
      // We can temporarily comment it out if needed.
      assignedTo: (json['assigned_to'] as List? ?? [])
          .map((userJson) => AssignedUser.fromJson(userJson))
          .toList(),
    );
  }
}

// Make sure this class is defined at the bottom of the file
class AssignedUser {
  final int id;
  final String username;
  AssignedUser({required this.id, required this.username});
  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(id: json['id'] ?? 0, username: json['username'] ?? 'Unknown');
  }
}
