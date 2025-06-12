// lib/pages/review_page.dart
import 'package:brainpop_app/models/flashcard_model.dart';
import 'package:brainpop_app/models/topic_model.dart';
import 'package:brainpop_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // For playing audio
import 'dart:io'; // For File class to check if path exists

class ReviewPage extends StatefulWidget {
  final List<Flashcard> flashcards;
  final int userId;
  final Topic? topic; // Optional: The topic being reviewed

  const ReviewPage({
    super.key,
    required this.flashcards,
    required this.userId,
    this.topic,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  List<Flashcard> _reviewFlashcards = [];
  final DatabaseService _databaseService = DatabaseService.instance;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio player instance

  @override
  void initState() {
    super.initState();
    // Shuffle the flashcards for a randomized review experience.
    _reviewFlashcards = List<Flashcard>.from(widget.flashcards)..shuffle();
    _audioPlayer.setReleaseMode(ReleaseMode.stop); // Stop audio when finished
  }

  // Moves to the next flashcard.
  void _nextFlashcard() {
    setState(() {
      _showAnswer = false; // Hide answer for the next card
      _audioPlayer.stop(); // Stop any currently playing audio
      if (_currentIndex < _reviewFlashcards.length - 1) {
        _currentIndex++;
      } else {
        // End of review session
        _showReviewCompleteDialog();
      }
    });
  }

  // Toggles the visibility of the answer and plays audio if available.
  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
      if (_showAnswer) {
        // Play audio when answer is revealed
        _playAudio();
      } else {
        _audioPlayer.stop(); // Stop audio if flipping back to question
      }
    });
  }

  // Plays audio if an audio path is available for the current flashcard's answer.
  Future<void> _playAudio() async {
    final currentCard = _reviewFlashcards[_currentIndex];
    if (currentCard.audioUrlAnswer != null &&
        currentCard.audioUrlAnswer!.isNotEmpty) {
      final file = File(currentCard.audioUrlAnswer!);
      if (await file.exists()) {
        try {
          await _audioPlayer.play(DeviceFileSource(file.path));
        } catch (e) {
          _showMessage('Error playing audio: $e');
        }
      } else {
        _showMessage('Audio file not found at path: ${file.path}');
      }
    }
  }

  // Records an incorrect answer and updates the flashcard in the database.
  Future<void> _markIncorrect() async {
    Flashcard currentCard = _reviewFlashcards[_currentIndex];
    currentCard.incorrectCount++;
    currentCard.lastReviewed = DateTime.now();
    await _databaseService.updateFlashcard(currentCard);
    _nextFlashcard();
  }

  // Records a correct answer and updates the flashcard in the database.
  Future<void> _markCorrect() async {
    Flashcard currentCard = _reviewFlashcards[_currentIndex];
    currentCard.correctCount++;
    currentCard.lastReviewed = DateTime.now();
    await _databaseService.updateFlashcard(currentCard);
    _nextFlashcard();
  }

  // Shows a dialog when the review session is complete.
  void _showReviewCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Review Complete!'),
          content: const Text('You have reviewed all available flashcards.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to Home Page
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
    if (_reviewFlashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.topic != null
                ? 'Review: ${widget.topic!.title}'
                : 'Review Flashcards',
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Text(
                widget.topic != null
                    ? 'No flashcards in this topic to review!'
                    : 'No flashcards to review!',
                style: TextStyle(fontSize: 20, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Text(
                'Please add flashcards on the home page.',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to home
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentFlashcard = _reviewFlashcards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic != null
              ? 'Review: ${widget.topic!.title}'
              : 'Review Flashcards',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _reviewFlashcards.length,
              backgroundColor: Colors.grey[300],
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 10),
            Text(
              'Card ${_currentIndex + 1} of ${_reviewFlashcards.length}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            // Flashcard content area
            Expanded(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: InkWell(
                  onTap:
                      _toggleAnswer, // Tap anywhere on the card to reveal/hide answer
                  borderRadius: BorderRadius.circular(20.0),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Center(
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                // Scale transition for flipping effect
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                          child: _showAnswer
                              ? Column(
                                  // Answer side
                                  key: const ValueKey<bool>(true),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (currentFlashcard.imageUrlAnswer !=
                                            null &&
                                        currentFlashcard
                                            .imageUrlAnswer!
                                            .isNotEmpty)
                                      _buildImageWidget(
                                        currentFlashcard.imageUrlAnswer!,
                                      ),
                                    if (currentFlashcard.answer.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          currentFlashcard.answer,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                    if (currentFlashcard.audioUrlAnswer !=
                                            null &&
                                        currentFlashcard
                                            .audioUrlAnswer!
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 16.0,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.volume_up,
                                            size: 40,
                                            color: Colors.blueAccent,
                                          ),
                                          onPressed: _playAudio,
                                          tooltip: 'Play Audio',
                                        ),
                                      ),
                                  ],
                                )
                              : Column(
                                  // Question side
                                  key: const ValueKey<bool>(false),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (currentFlashcard.imageUrlQuestion !=
                                            null &&
                                        currentFlashcard
                                            .imageUrlQuestion!
                                            .isNotEmpty)
                                      _buildImageWidget(
                                        currentFlashcard.imageUrlQuestion!,
                                      ),
                                    if (currentFlashcard.question.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          currentFlashcard.question,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markIncorrect,
                    icon: const Icon(Icons.close),
                    label: const Text('Incorrect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markCorrect,
                    icon: const Icon(Icons.check),
                    label: const Text('Correct'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to display an image from a file path.
  Widget _buildImageWidget(String imagePath) {
    final file = File(imagePath);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              file,
              height: 200,
              fit: BoxFit.contain, // Adjust fit as needed
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 100, color: Colors.grey),
            );
          } else {
            return const Icon(
              Icons.image_not_supported,
              size: 100,
              color: Colors.grey,
            );
          }
        }
        return const CircularProgressIndicator(); // Show loading while checking file existence
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Dispose the audio player
    super.dispose();
  }
}
