// lib/services/database_service.dart
import 'package:brainpop_app/models/flashcard_model.dart';
import 'package:brainpop_app/models/topic_model.dart';
import 'package:brainpop_app/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database; // Private database instance

  DatabaseService._init(); // Private constructor

  // Getter for the database. If it's null, initialize it.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flashcard_app.db'); // Initialize the database
    return _database!;
  }

  // Initializes the database, creating tables if they don't exist.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath(); // Get the default database path
    final path = join(
      dbPath,
      filePath,
    ); // Join path with the database file name
    return await openDatabase(
      path,
      version: 1, // Increment database version for schema changes
      onCreate:
          _createDB, // Callback to create tables when the database is first opened
      // _onUpgrade method removed as requested for simplicity
    );
  }

  // Creates the database tables.
  Future _createDB(Database db, int version) async {
    // Create Users table
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL
)
''');

    // Create Topics table
    await db.execute('''
CREATE TABLE topics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  title TEXT UNIQUE NOT NULL, -- Ensure topic titles are unique per user for simplicity
  description TEXT,
  FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
)
''');

    // Create Flashcards table with topicId, imageUrlQuestion, imageUrlAnswer, and audioUrlAnswer foreign keys
    await db.execute('''
CREATE TABLE flashcards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER NOT NULL,
  topicId INTEGER,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  imageUrlQuestion TEXT, -- New column for image URL on question side
  imageUrlAnswer TEXT,   -- New column for image URL on answer side
  audioUrlAnswer TEXT,   -- New column for audio URL on answer side
  correctCount INTEGER DEFAULT 0,
  incorrectCount INTEGER DEFAULT 0,
  lastReviewed TEXT, -- Store as ISO 8601 string
  FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
  FOREIGN KEY (topicId) REFERENCES topics (id) ON DELETE SET NULL -- If topic is deleted, set topicId to NULL
)
''');
  }

  // --- User Operations ---

  // Inserts a new user into the database.
  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Authenticates a user by username and password.
  // Returns the User object if credentials are valid, otherwise null.
  Future<User?> getUserByUsernameAndPassword(
    String username,
    String password,
  ) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'username', 'password'],
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Checks if a username already exists.
  Future<bool> doesUsernameExist(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }

  // --- Topic Operations ---

  // Creates a new topic in the database.
  Future<int> createTopic(Topic topic) async {
    final db = await instance.database;
    return await db.insert('topics', topic.toMap());
  }

  // Retrieves all topics for a specific user.
  Future<List<Topic>> getTopicsForUser(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'topics',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'title ASC', // Order by title
    );
    return List.generate(maps.length, (i) {
      return Topic.fromMap(maps[i]);
    });
  }

  // Updates an existing topic.
  Future<int> updateTopic(Topic topic) async {
    final db = await instance.database;
    return await db.update(
      'topics',
      topic.toMap(),
      where: 'id = ?',
      whereArgs: [topic.id],
    );
  }

  // Deletes a topic by its ID.
  Future<int> deleteTopic(int id) async {
    final db = await instance.database;
    // When a topic is deleted, flashcards associated with it will have topicId set to NULL
    return await db.delete('topics', where: 'id = ?', whereArgs: [id]);
  }

  // Checks if a topic title already exists for the given user.
  Future<bool> doesTopicTitleExist(int userId, String title) async {
    final db = await instance.database;
    final maps = await db.query(
      'topics',
      columns: ['id'],
      where: 'userId = ? AND title = ?',
      whereArgs: [userId, title],
    );
    return maps.isNotEmpty;
  }

  // --- Flashcard Operations ---

  // Creates a new flashcard in the database.
  Future<int> createFlashcard(Flashcard flashcard) async {
    final db = await instance.database;
    return await db.insert('flashcards', flashcard.toMap());
  }

  // Retrieves all flashcards for a specific user, optionally filtered by topic.
  Future<List<Flashcard>> getFlashcardsForUser(
    int userId, {
    int? topicId,
  }) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps;

    if (topicId != null) {
      maps = await db.query(
        'flashcards',
        where: 'userId = ? AND topicId = ?',
        whereArgs: [userId, topicId],
        orderBy: 'id DESC',
      );
    } else {
      maps = await db.query(
        'flashcards',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'id DESC', // Order by ID descending to show newest first
      );
    }

    return List.generate(maps.length, (i) {
      return Flashcard.fromMap(maps[i]);
    });
  }

  // Updates an existing flashcard.
  Future<int> updateFlashcard(Flashcard flashcard) async {
    final db = await instance.database;
    return await db.update(
      'flashcards',
      flashcard.toMap(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
  }

  // Deletes a flashcard by its ID.
  Future<int> deleteFlashcard(int id) async {
    final db = await instance.database;
    return await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }

  // Closes the database connection.
  Future close() async {
    final db = await instance.database;
    _database = null; // Clear the database instance
    db.close();
  }
}
