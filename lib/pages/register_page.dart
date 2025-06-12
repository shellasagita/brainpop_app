// lib/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:brainpop_app/services/database_service.dart';
import 'package:brainpop_app/models/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService.instance;

  // Handles the user registration process.
  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('All fields are required.', Colors.redAccent);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.', Colors.redAccent);
      return;
    }

    // Check if username already exists
    if (await _databaseService.doesUsernameExist(username)) {
      _showMessage(
        'Username already exists. Please choose another.',
        Colors.redAccent,
      );
      return;
    }

    final newUser = User(
      username: username,
      password: password,
    ); // In production, hash passwords!
    final id = await _databaseService.createUser(newUser);

    if (id > 0) {
      if (!mounted) return;
      _showMessage(
        'Registration successful! Please login.',
        Colors.greenAccent,
      );
      Navigator.of(context).pop(); // Go back to login page
    } else {
      _showMessage('Registration failed. Please try again.', Colors.redAccent);
    }
  }

  // Displays a snackbar message.
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.person_add,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 30),
              // Username Input Field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Choose a username',
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              // Password Input Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Create a password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              // Confirm Password Input Field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              // Register Button
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Register', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              // Back to Login Button
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(); // Go back to the previous screen (Login)
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
