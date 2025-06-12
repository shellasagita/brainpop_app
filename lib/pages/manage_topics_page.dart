// lib/pages/manage_topics_page.dart
import 'package:brainpop_app/models/topic_model.dart';
import 'package:brainpop_app/services/auth_service.dart';
import 'package:brainpop_app/services/database_service.dart';
import 'package:flutter/material.dart';

class ManageTopicsPage extends StatefulWidget {
  const ManageTopicsPage({super.key});

  @override
  State<ManageTopicsPage> createState() => _ManageTopicsPageState();
}

class _ManageTopicsPageState extends State<ManageTopicsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();
  List<Topic> _topics = [];
  int? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  // Loads the current user's ID and then fetches their topics.
  Future<void> _loadTopics() async {
    _currentUserId = await _authService.getCurrentUserId();
    if (_currentUserId == null) {
      if (mounted) {
        _showMessage('Error: User not logged in. Please log in again.');
        Navigator.of(context).pop(); // Go back if no user
      }
      return;
    }
    await _fetchTopics();
    setState(() {
      _isLoading = false;
    });
  }

  // Fetches all topics for the current user.
  Future<void> _fetchTopics() async {
    if (_currentUserId != null) {
      final topics = await _databaseService.getTopicsForUser(_currentUserId!);
      setState(() {
        _topics = topics;
      });
    }
  }

  // Shows a dialog to add or edit a topic.
  Future<void> _showAddEditTopicDialog({Topic? topic}) async {
    final TextEditingController titleController = TextEditingController(
      text: topic?.title,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: topic?.description,
    );
    final bool isEditing = topic != null;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Topic' : 'Add New Topic'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Topic Title',
                    hintText: 'e.g., Mathematics, History',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'A brief description of this topic',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String newTitle = titleController.text.trim();
                final String newDescription = descriptionController.text.trim();

                if (newTitle.isEmpty) {
                  _showMessage('Topic title cannot be empty.');
                  return;
                }

                if (_currentUserId == null) {
                  _showMessage('Error: User not logged in.');
                  return;
                }

                if (isEditing) {
                  final updatedTopic = Topic(
                    id: topic.id,
                    userId: _currentUserId!,
                    title: newTitle,
                    description: newDescription.isNotEmpty
                        ? newDescription
                        : null,
                  );
                  await _databaseService.updateTopic(updatedTopic);
                  _showMessage('Topic updated successfully!');
                } else {
                  // Check if topic title already exists for this user
                  if (await _databaseService.doesTopicTitleExist(
                    _currentUserId!,
                    newTitle,
                  )) {
                    _showMessage('A topic with this title already exists.');
                    return;
                  }
                  final newTopic = Topic(
                    userId: _currentUserId!,
                    title: newTitle,
                    description: newDescription.isNotEmpty
                        ? newDescription
                        : null,
                  );
                  await _databaseService.createTopic(newTopic);
                  _showMessage('Topic added successfully!');
                }
                Navigator.of(context).pop(); // Close dialog
                _fetchTopics(); // Refresh list
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  // Deletes a topic after confirmation.
  Future<void> _deleteTopic(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this topic and dissociate its flashcards?',
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
      await _databaseService.deleteTopic(id);
      _showMessage('Topic deleted!');
      _fetchTopics(); // Refresh list
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
      appBar: AppBar(title: const Text('Manage Topics'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'No topics created yet!',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditTopicDialog(),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create First Topic'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle:
                        topic.description != null &&
                            topic.description!.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              topic.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () =>
                              _showAddEditTopicDialog(topic: topic),
                          tooltip: 'Edit Topic',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteTopic(topic.id!),
                          tooltip: 'Delete Topic',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTopicDialog(),
        tooltip: 'Add Topic',
        child: const Icon(Icons.add),
      ),
    );
  }
}
