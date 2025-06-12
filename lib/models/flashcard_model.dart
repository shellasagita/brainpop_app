// lib/models/flashcard.dart
class Flashcard {
  final int?
  id; // Unique identifier for the flashcard (optional for new flashcards)
  final int
  userId; // Foreign key linking to the User who created this flashcard
  int? topicId; // Foreign key linking to the Topic (can be null)
  String question; // The text question part of the flashcard
  String answer; // The text answer part of the flashcard
  String?
  imageUrlQuestion; // Optional: URL or path for an image on the question side
  String?
  imageUrlAnswer; // Optional: URL or path for an image on the answer side
  String?
  audioUrlAnswer; // Optional: URL or path for an audio file on the answer side
  int correctCount; // How many times this flashcard was answered correctly
  int incorrectCount; // How many times this flashcard was answered incorrectly
  DateTime? lastReviewed; // The last time this flashcard was reviewed

  // Constructor for creating a Flashcard object.
  Flashcard({
    this.id,
    required this.userId,
    this.topicId,
    required this.question,
    required this.answer,
    this.imageUrlQuestion, // Include new image fields in constructor
    this.imageUrlAnswer, // Include new image fields in constructor
    this.audioUrlAnswer, // Include new audio field in constructor
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.lastReviewed,
  });

  // Factory method to create a Flashcard object from a map (e.g., from a database query result).
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      userId: map['userId'],
      topicId: map['topicId'],
      question: map['question'],
      answer: map['answer'],
      imageUrlQuestion: map['imageUrlQuestion'], // Map new image fields
      imageUrlAnswer: map['imageUrlAnswer'], // Map new image fields
      audioUrlAnswer: map['audioUrlAnswer'], // Map new audio field
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      lastReviewed: map['lastReviewed'] != null
          ? DateTime.parse(map['lastReviewed'])
          : null,
    );
  }

  // Converts a Flashcard object to a map, suitable for inserting into a database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'topicId': topicId,
      'question': question,
      'answer': answer,
      'imageUrlQuestion': imageUrlQuestion, // Include new image fields in map
      'imageUrlAnswer': imageUrlAnswer, // Include new image fields in map
      'audioUrlAnswer': audioUrlAnswer, // Include new audio field in map
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'lastReviewed': lastReviewed
          ?.toIso8601String(), // Store DateTime as ISO 8601 string
    };
  }

  // For debugging and logging purposes.
  @override
  String toString() {
    return 'Flashcard{id: $id, userId: $userId, topicId: $topicId, question: $question, answer: $answer, '
        'imageUrlQuestion: $imageUrlQuestion, imageUrlAnswer: $imageUrlAnswer, '
        'audioUrlAnswer: $audioUrlAnswer, correctCount: $correctCount, incorrectCount: $incorrectCount, '
        'lastReviewed: $lastReviewed}';
  }
}
