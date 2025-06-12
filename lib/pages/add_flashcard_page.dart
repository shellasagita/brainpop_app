// lib/pages/add_flashcard_page.dart
import 'package:brainpop_app/models/flashcard_model.dart';
import 'package:brainpop_app/models/topic_model.dart';
import 'package:brainpop_app/services/auth_service.dart';
import 'package:brainpop_app/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:file_picker/file_picker.dart'; // For picking audio
// import 'dart:io'; // For File class

class AddFlashcardPage extends StatefulWidget {
  final Flashcard? flashcard; // Optional: If provided, means we are editing
  final int? initialTopicId; // Optional: To pre-select a topic when adding

  const AddFlashcardPage({super.key, this.flashcard, this.initialTopicId});

  @override
  State<AddFlashcardPage> createState() => _AddFlashcardPageState();
}

class _AddFlashcardPageState extends State<AddFlashcardPage> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  int? _currentUserId;
  bool _isEditing = false;
  List<Topic> _availableTopics = [];
  Topic? _selectedTopic;

  // New controllers/variables for image and audio paths
  String? _imagePathQuestion;
  String? _imagePathAnswer;
  String? _audioPathAnswer;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndTopics();
    if (widget.flashcard != null) {
      _isEditing = true;
      _questionController.text = widget.flashcard!.question;
      _answerController.text = widget.flashcard!.answer;
      _imagePathQuestion =
          widget.flashcard!.imageUrlQuestion; // Load existing image
      _imagePathAnswer =
          widget.flashcard!.imageUrlAnswer; // Load existing image
      _audioPathAnswer =
          widget.flashcard!.audioUrlAnswer; // Load existing audio
    }
  }

  // Loads the current user's ID and then fetches available topics.
  Future<void> _loadUserDataAndTopics() async {
    _currentUserId = await _authService.getCurrentUserId();
    if (_currentUserId == null) {
      if (mounted) {
        _showMessage('Error: User not logged in. Please log in again.');
        Navigator.of(context).pop();
      }
      return;
    }

    await _fetchTopics();
    _setInitialSelectedTopic();
  }

  // Fetches topics for the current user.
  Future<void> _fetchTopics() async {
    if (_currentUserId != null) {
      final topics = await _databaseService.getTopicsForUser(_currentUserId!);
      setState(() {
        _availableTopics = topics;
      });
    }
  }

  // Sets the initial selected topic based on editing or initialTopicId.
  void _setInitialSelectedTopic() {
    if (_isEditing && widget.flashcard!.topicId != null) {
      _selectedTopic = _availableTopics.firstWhere(
        (topic) => topic.id == widget.flashcard!.topicId,
        orElse: () => Topic(id: -1, userId: -1, title: 'Invalid Topic'),
      );
      if (_selectedTopic?.id == -1) {
        _selectedTopic = null;
      }
    } else if (widget.initialTopicId != null) {
      _selectedTopic = _availableTopics.firstWhere(
        (topic) => topic.id == widget.initialTopicId,
        orElse: () => Topic(id: -1, userId: -1, title: 'Invalid Topic'),
      );
      if (_selectedTopic?.id == -1) {
        _selectedTopic = null;
      }
    }
    setState(() {});
  }

  // Helper to pick an image from gallery or camera
  Future<void> _pickImage(
    ImageSource source, {
    required bool isQuestionSide,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (isQuestionSide) {
          _imagePathQuestion = pickedFile.path;
        } else {
          _imagePathAnswer = pickedFile.path;
        }
      });
    }
  }

  // Helper to pick an audio file
  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioPathAnswer = result.files.single.path;
      });
    }
  }

  // Handles saving or updating a flashcard.
  Future<void> _saveFlashcard() async {
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty && _imagePathQuestion == null) {
      _showMessage(
        'Question text or an image for the question side is required.',
      );
      return;
    }
    if (answer.isEmpty &&
        _imagePathAnswer == null &&
        _audioPathAnswer == null) {
      _showMessage(
        'Answer text, an image, or an audio file for the answer side is required.',
      );
      return;
    }

    if (_currentUserId == null) {
      _showMessage('Error: User ID not found. Please log in again.');
      return;
    }

    if (_isEditing) {
      // Update existing flashcard
      final updatedFlashcard = Flashcard(
        id: widget.flashcard!.id,
        userId: _currentUserId!,
        topicId: _selectedTopic?.id,
        question: question,
        answer: answer,
        imageUrlQuestion: _imagePathQuestion,
        imageUrlAnswer: _imagePathAnswer,
        audioUrlAnswer: _audioPathAnswer,
        correctCount: widget.flashcard!.correctCount,
        incorrectCount: widget.flashcard!.incorrectCount,
        lastReviewed: widget.flashcard!.lastReviewed,
      );
      await _databaseService.updateFlashcard(updatedFlashcard);
      _showMessage('Flashcard updated successfully!');
    } else {
      // Create new flashcard
      final newFlashcard = Flashcard(
        userId: _currentUserId!,
        topicId: _selectedTopic?.id,
        question: question,
        answer: answer,
        imageUrlQuestion: _imagePathQuestion,
        imageUrlAnswer: _imagePathAnswer,
        audioUrlAnswer: _audioPathAnswer,
      );
      await _databaseService.createFlashcard(newFlashcard);
      _showMessage('Flashcard added successfully!');
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // Go back to the previous screen (Home)
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
        title: Text(_isEditing ? 'Edit Flashcard' : 'Add New Flashcard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Topic selection dropdown
            DropdownButtonFormField<Topic?>(
              decoration: const InputDecoration(
                labelText: 'Topic (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
              value: _selectedTopic,
              hint: const Text('Select a topic or leave blank'),
              onChanged: (Topic? newValue) {
                setState(() {
                  _selectedTopic = newValue;
                });
              },
              items: [
                const DropdownMenuItem<Topic?>(
                  value: null,
                  child: Text('No Topic'),
                ),
                ..._availableTopics.map((topic) {
                  return DropdownMenuItem<Topic>(
                    value: topic,
                    child: Text(topic.title),
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 20),

            // Question Section
            _buildSectionHeader('Question Side'),
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question Text (Optional)',
                hintText: 'Enter your question text here',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.help_outline),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 10),
            _buildImagePickerRow(
              imagePath: _imagePathQuestion,
              onPickImage: (source) => _pickImage(source, isQuestionSide: true),
              onClearImage: () => setState(() => _imagePathQuestion = null),
              label: 'Question Image (Optional)',
            ),
            const SizedBox(height: 20),

            // Answer Section
            _buildSectionHeader('Answer Side'),
            TextFormField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Answer Text (Optional)',
                hintText: 'Enter the answer text here',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.lightbulb_outline),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 10),
            _buildImagePickerRow(
              imagePath: _imagePathAnswer,
              onPickImage: (source) =>
                  _pickImage(source, isQuestionSide: false),
              onClearImage: () => setState(() => _imagePathAnswer = null),
              label: 'Answer Image (Optional)',
            ),
            const SizedBox(height: 10),
            _buildAudioPickerRow(
              audioPath: _audioPathAnswer,
              onPickAudio: _pickAudio,
              onClearAudio: () => setState(() => _audioPathAnswer = null),
              label: 'Answer Audio (Optional)',
            ),
            const SizedBox(height: 30),

            // Save Button
            ElevatedButton.icon(
              onPressed: _saveFlashcard,
              icon: Icon(_isEditing ? Icons.save : Icons.add_card),
              label: Text(
                _isEditing ? 'Save Changes' : 'Add Flashcard',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  // Helper widget to build image picker row
  Widget _buildImagePickerRow({
    String? imagePath,
    required Function(ImageSource) onPickImage,
    required VoidCallback onClearImage,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onPickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onPickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (imagePath != null && imagePath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected: ${imagePath.split('/').last}', // Show just the file name
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: onClearImage,
                  tooltip: 'Clear Image',
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper widget to build audio picker row
  Widget _buildAudioPickerRow({
    String? audioPath,
    required VoidCallback onPickAudio,
    required VoidCallback onClearAudio,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPickAudio,
                icon: const Icon(Icons.audiotrack),
                label: const Text('Pick Audio'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (audioPath != null && audioPath.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected: ${audioPath.split('/').last}', // Show just the file name
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red),
                  onPressed: onClearAudio,
                  tooltip: 'Clear Audio',
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }
}
