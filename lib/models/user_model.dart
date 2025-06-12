// lib/models/user.dart
class User {
  final int? id; // Unique identifier for the user (optional for new users)
  final String username; // User's unique username
  final String
  password; // User's password (in a real app, store hashed passwords)

  // Constructor for creating a User object.
  User({this.id, required this.username, required this.password});

  // Factory method to create a User object from a map (e.g., from a database query result).
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }

  // Converts a User object to a map, suitable for inserting into a database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password, // Remember: In production, hash passwords!
    };
  }

  // For debugging and logging purposes.
  @override
  String toString() {
    return 'User{id: $id, username: $username, password: $password}';
  }
}
