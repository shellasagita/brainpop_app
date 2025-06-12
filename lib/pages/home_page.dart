// lib/pages/home_page.dart
import 'package:brainpop_app/models/flashcard_model.dart';
import 'package:brainpop_app/models/topic_model.dart';
import 'package:brainpop_app/pages/add_flashcard_page.dart';
import 'package:brainpop_app/pages/login_page.dart';
import 'package:brainpop_app/pages/manage_topics_page.dart';
import 'package:brainpop_app/pages/review_page.dart';
import 'package:brainpop_app/pages/statistics_page.dart';
import 'package:brainpop_app/services/auth_service.dart';
import 'package:brainpop_app/services/database_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Flashcard> _flashcards = [];
  List<Topic> _topics = []; // List to store topics
  Topic? _selectedTopic; // Currently selected topic for filtering
  int? _currentUserId;
  String? _currentUsername;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFlashcardsAndTopics(); // Updated load method
  }

  // Loads the current user's ID and username, then fetches their topics and flashcards.
  Future<void> _loadUserDataAndFlashcardsAndTopics() async {
    _currentUserId = await _authService.getCurrentUserId();
    _currentUsername = await _authService.getCurrentUsername();

    if (_currentUserId != null) {
      await _fetchTopics(); // Fetch topics first
      await _fetchFlashcards(
        topicId: _selectedTopic?.id,
      ); // Then fetch flashcards, possibly filtered
    } else {
      // If no user ID, navigate back to login page (shouldn't happen if isLoggedIn is true)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Fetches all topics for the current user from the database.
  Future<void> _fetchTopics() async {
    if (_currentUserId != null) {
      final topics = await _databaseService.getTopicsForUser(_currentUserId!);
      setState(() {
        _topics = topics;
        // If a previously selected topic no longer exists, clear the selection
        if (_selectedTopic != null &&
            !_topics.any((t) => t.id == _selectedTopic!.id)) {
          _selectedTopic = null;
        }
      });
    }
  }

  // Fetches all flashcards for the current user from the database, optionally filtered by topic.
  Future<void> _fetchFlashcards({int? topicId}) async {
    if (_currentUserId != null) {
      final cards = await _databaseService.getFlashcardsForUser(
        _currentUserId!,
        topicId: topicId,
      );
      setState(() {
        _flashcards = cards;
      });
    }
  }

  // Handles topic selection from the dropdown.
  void _onTopicChanged(Topic? newTopic) {
    setState(() {
      _selectedTopic = newTopic;
      _fetchFlashcards(
        topicId: newTopic?.id,
      ); // Refetch flashcards based on new topic
    });
  }

  // Handles logging out the user.
  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    // Navigate to Login Page and remove all previous routes from the stack.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  // Navigates to the Add Flashcard page.
  void _navigateToAddFlashcard() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AddFlashcardPage(initialTopicId: _selectedTopic?.id),
      ),
    );
    // Refresh flashcards after returning from Add/Edit page, maintaining current topic filter
    _fetchFlashcards(topicId: _selectedTopic?.id);
  }

  // Navigates to the Review page.
  void _navigateToReview() async {
    List<Flashcard> cardsToReview = _selectedTopic != null
        ? _flashcards
              .where((card) => card.topicId == _selectedTopic!.id)
              .toList()
        : _flashcards;

    if (cardsToReview.isEmpty) {
      _showMessage(
        'No flashcards in this topic (or overall) to start reviewing!',
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ReviewPage(flashcards: cardsToReview, userId: _currentUserId!),
      ),
    );
    // Refresh flashcards after review to update stats, maintaining current topic filter
    _fetchFlashcards(topicId: _selectedTopic?.id);
  }

  // Navigates to the Statistics page.
  void _navigateToStatistics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatisticsPage(userId: _currentUserId!),
      ),
    );
  }

  // Navigates to the Manage Topics page.
  void _navigateToManageTopics() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ManageTopicsPage()));
    // Refresh topics and flashcards after managing topics, to reflect changes
    _loadUserDataAndFlashcardsAndTopics();
  }

  // Edits an existing flashcard.
  void _editFlashcard(Flashcard flashcard) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddFlashcardPage(flashcard: flashcard),
      ),
    );
    _fetchFlashcards(topicId: _selectedTopic?.id); // Refresh list after editing
  }

  // Deletes a flashcard after confirmation.
  Future<void> _deleteFlashcard(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this flashcard?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _databaseService.deleteFlashcard(id);
      _showMessage('Flashcard deleted!');
      _fetchFlashcards(
        topicId: _selectedTopic?.id,
      ); // Refresh list after deleting
    }
  }

  // Displays a snackbar message.
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? const Text('Loading...')
            : DropdownButtonHideUnderline(
                child: DropdownButton<Topic?>(
                  value: _selectedTopic,
                  hint: const Text(
                    'All Flashcards',
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: _onTopicChanged,
                  items:
                      [
                            const DropdownMenuItem<Topic?>(
                              value: null,
                              child: Text('All Flashcards'),
                            ),
                            ..._topics.map((topic) {
                              return DropdownMenuItem<Topic>(
                                value: topic,
                                child: Text(topic.title),
                              );
                            }).toList(),
                          ]
                          .whereType<DropdownMenuItem<Topic?>>()
                          .toList(), // Filter out null if any
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  dropdownColor: Colors.blueGrey.shade700,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  selectedItemBuilder: (BuildContext context) {
                    return [
                      const Text(
                        'All Flashcards',
                        style: TextStyle(color: Colors.white),
                      ),
                      ..._topics.map((topic) {
                        return Text(
                          topic.title,
                          style: const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ];
                  },
                ),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Statistics',
            onPressed: _navigateToStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.person, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    _currentUsername != null
                        ? 'Welcome, $_currentUsername!'
                        : 'Flashcard App',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add New Flashcard'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _navigateToAddFlashcard();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.folder_open,
              ), // New: Icon for Manage Topics
              title: const Text(
                'Manage Topics',
              ), // New: Entry for Manage Topics
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _navigateToManageTopics();
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Start Review'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _navigateToReview();
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _navigateToStatistics();
              },
            ),
            const Divider(), // A separator
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _logout();
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flashcards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notes, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    _selectedTopic == null
                        ? 'No flashcards yet! Add some to get started.'
                        : 'No flashcards in the selected topic.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddFlashcard,
                    icon: const Icon(Icons.add_card),
                    label: const Text('Add Flashcard'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: _flashcards.length,
              itemBuilder: (context, index) {
                final flashcard = _flashcards[index];
                // Find the topic title for the flashcard if topicId is not null
                final topicTitle = flashcard.topicId != null
                    ? _topics
                          .firstWhere(
                            (topic) => topic.id == flashcard.topicId,
                            orElse: () => Topic(
                              id: -1,
                              userId: -1,
                              title: 'Unknown Topic',
                            ),
                          )
                          .title
                    : 'No Topic';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flashcard.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          flashcard.answer,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Chip(
                            label: Text(topicTitle),
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                ),
                                onPressed: () => _editFlashcard(flashcard),
                                tooltip: 'Edit Flashcard',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    _deleteFlashcard(flashcard.id!),
                                tooltip: 'Delete Flashcard',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddFlashcard,
        tooltip: 'Add Flashcard',
        child: const Icon(Icons.add),
      ),
    );
  }
}
