// lib/models/task.dart

// A helper function to safely parse dynamic values into integers.
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

  // ✅ Properties for date and color remain
  final DateTime createdAt;
  final String? statusColor;
  final String? priorityColor;

  Task({
    required this.id,
    required this.name,
    required this.projectId,
    required this.projectName,
    required this.statusName,
    required this.priorityName,
    required this.assignedTo,
    required this.creatorName,
    // ✅ Constructor for date and color remains
    required this.createdAt,
    this.statusColor,
    this.priorityColor,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    var assignedToList = <AssignedUser>[];
    if (json['assigned_to'] is List) {
      assignedToList = (json['assigned_to'] as List)
          .map((userJson) => AssignedUser.fromJson(userJson))
          .toList();
    }

    // The 'date_added' is a Unix timestamp (in seconds). We multiply by 1000 for milliseconds.
    final int dateAddedTimestamp = _safeParseInt(json['date_added']);
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      dateAddedTimestamp * 1000,
    );

    return Task(
      id: _safeParseInt(json['id']),
      projectId: _safeParseInt(json['project_id']),
      name: json['name'] ?? 'No Name',
      projectName: json['project_name'] ?? 'No Project',
      statusName: json['status_name'] ?? 'N/A',
      priorityName: json['priority_name'] ?? 'N/A',
      creatorName: json['creator_name'] ?? 'Unknown',
      assignedTo: assignedToList,

      // ✅ Assignment for date and color remains
      createdAt: createdAt,
      statusColor: json['status_color'] as String?,
      priorityColor: json['priority_color'] as String?,
    );
  }
}

// ✅ REVERTED AssignedUser to its simpler form
class AssignedUser {
  final int id;
  final String username;

  AssignedUser({required this.id, required this.username});

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      id: _safeParseInt(json['id']),
      username: json['username'] ?? 'Unknown User',
    );
  }
}
