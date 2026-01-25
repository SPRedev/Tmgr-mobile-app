// lib/models/user.dart

// A helper function to safely parse dynamic values into integers.
// It handles nulls, strings, and any other type by attempting to parse.
// Returns a default value (0) if parsing fails or the value is null.
int _safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) {
    return defaultValue;
  }
  return int.tryParse(value.toString()) ?? defaultValue;
}

class User {
  final int id;
  final String username;

  User({required this.id, required this.username});

  // The factory constructor is now resilient to nulls and incorrect data types from the API.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Use the safe parsing helper for the integer ID.
      // This handles cases where the ID is a string (e.g., "123") or null.
      id: _safeParseInt(json['id']),

      // Provide a default value for the username in case it is null.
      username: json['username'] ?? 'Unnamed User',
    );
  }
}
