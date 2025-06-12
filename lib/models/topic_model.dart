// lib/models/topic.dart
class Topic {
  final int? id; // Unique identifier for the topic
  final int userId; // Foreign key linking to the User who created this topic
  String title; // Title of the topic
  String? description; // Optional description for the topic

  // Constructor for creating a Topic object.
  Topic({this.id, required this.userId, required this.title, this.description});

  // Factory method to create a Topic object from a map (e.g., from a database query result).
  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
    );
  }

  // Converts a Topic object to a map, suitable for inserting into a database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
    };
  }

  // For debugging and logging purposes.
  @override
  String toString() {
    return 'Topic{id: $id, userId: $userId, title: $title, description: $description}';
  }
}
