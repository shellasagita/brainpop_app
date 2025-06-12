// lib/pages/statistics_page.dart
import 'package:brainpop_app/models/flashcard_model.dart';
import 'package:brainpop_app/models/topic_model.dart';
import 'package:brainpop_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class StatisticsPage extends StatefulWidget {
  final int userId;

  const StatisticsPage({super.key, required this.userId});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Flashcard> _allFlashcards = []; // All flashcards for the user
  List<Topic> _topics = []; // All topics for the user
  Topic? _selectedTopic; // Currently selected topic for filtering
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllDataAndStatistics();
  }

  // Loads all topics and flashcards for the user.
  Future<void> _loadAllDataAndStatistics() async {
    await _fetchTopics();
    await _fetchAllFlashcards(); // Fetch all flashcards initially
    setState(() {
      _isLoading = false;
    });
  }

  // Fetches all topics for the current user.
  Future<void> _fetchTopics() async {
    final topics = await _databaseService.getTopicsForUser(widget.userId);
    setState(() {
      _topics = topics;
    });
  }

  // Fetches all flashcards for the current user.
  Future<void> _fetchAllFlashcards() async {
    final cards = await _databaseService.getFlashcardsForUser(widget.userId);
    setState(() {
      _allFlashcards = cards;
    });
  }

  // Handles topic selection from the dropdown.
  void _onTopicChanged(Topic? newTopic) {
    setState(() {
      _selectedTopic = newTopic;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter flashcards based on selected topic
    final List<Flashcard> filteredFlashcards = _selectedTopic != null
        ? _allFlashcards
              .where((card) => card.topicId == _selectedTopic!.id)
              .toList()
        : _allFlashcards;

    // Calculate statistics for the filtered set
    final totalFlashcards = filteredFlashcards.length;
    int totalCorrectAnswers = 0;
    int totalIncorrectAnswers = 0;
    int reviewedCards = 0;

    // Sort flashcards by lastReviewed date to show recently reviewed first
    final sortedFlashcards = List<Flashcard>.from(filteredFlashcards);
    sortedFlashcards.sort((a, b) {
      if (a.lastReviewed == null && b.lastReviewed == null) return 0;
      if (a.lastReviewed == null) return 1;
      if (b.lastReviewed == null) return -1;
      return b.lastReviewed!.compareTo(a.lastReviewed!);
    });

    for (var card in filteredFlashcards) {
      totalCorrectAnswers += card.correctCount;
      totalIncorrectAnswers += card.incorrectCount;
      if (card.correctCount > 0 || card.incorrectCount > 0) {
        reviewedCards++;
      }
    }

    final totalAttempts = totalCorrectAnswers + totalIncorrectAnswers;
    final correctPercentage = totalAttempts == 0
        ? 0.0
        : (totalCorrectAnswers / totalAttempts) * 100;

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<Topic?>(
            value: _selectedTopic,
            hint: const Text(
              'All Topics',
              style: TextStyle(color: Colors.white),
            ),
            onChanged: _onTopicChanged,
            items:
                [
                      const DropdownMenuItem<Topic?>(
                        value: null,
                        child: Text('All Topics'),
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
                const Text('All Topics', style: TextStyle(color: Colors.white)),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(
              icon: Icons.grid_on,
              title: 'Total Flashcards',
              value: '$totalFlashcards',
              color: Colors.blueGrey,
            ),
            _buildStatCard(
              icon: Icons.check_circle_outline,
              title: 'Total Correct Answers',
              value: '$totalCorrectAnswers',
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.cancel_outlined,
              title: 'Total Incorrect Answers',
              value: '$totalIncorrectAnswers',
              color: Colors.red,
            ),
            _buildStatCard(
              icon: Icons.trending_up,
              title: 'Correct Answer Rate',
              value: '${correctPercentage.toStringAsFixed(1)}%',
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.book,
              title: 'Flashcards Reviewed',
              value: '$reviewedCards / $totalFlashcards',
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            Text(
              'Recently Reviewed Flashcards:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            if (reviewedCards == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    _selectedTopic == null
                        ? 'No flashcards have been reviewed yet.'
                        : 'No flashcards in this topic have been reviewed yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap:
                    true, // Important for ListView inside SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling of inner ListView
                itemCount: sortedFlashcards
                    .where((f) => f.lastReviewed != null)
                    .length,
                itemBuilder: (context, index) {
                  final card = sortedFlashcards
                      .where((f) => f.lastReviewed != null)
                      .toList()[index];
                  // Find the topic title for the flashcard
                  final topicTitle = card.topicId != null
                      ? _topics
                            .firstWhere(
                              (topic) => topic.id == card.topicId,
                              orElse: () => Topic(
                                id: -1,
                                userId: -1,
                                title: 'Unknown Topic',
                              ),
                            )
                            .title
                      : 'No Topic';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ListTile(
                      title: Text(
                        card.question,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Topic: $topicTitle'), // Display topic
                          Text(
                            'Correct: ${card.correctCount} | Incorrect: ${card.incorrectCount}',
                          ),
                          Text(
                            'Last Reviewed: ${card.lastReviewed != null ? DateFormat('MMM dd, yyyy HH:mm').format(card.lastReviewed!) : 'N/A'}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a consistent stat card.
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
