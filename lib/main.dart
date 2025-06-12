// lib/main.dart
import 'package:flutter/material.dart';
import 'package:brainpop_app/services/auth_service.dart';
import 'package:brainpop_app/pages/login_page.dart';
import 'package:brainpop_app/pages/home_page.dart';
import 'package:brainpop_app/services/database_service.dart'; // Import for database initialization

void main() async {
  // Ensure Flutter widgets are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database connection.
  await DatabaseService.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Checks if a user is already logged in using AuthService.
  Future<void> _checkLoginStatus() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard App',
      debugShowCheckedModeBanner:
          false, // Set to false to remove the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // A nice subtle color
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          // Changed from CardTheme to CardThemeData
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Rounded card corners
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded button corners
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Rounded input borders
          ),
          filled: true,
          fillColor: Colors.blueGrey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
        ),
      ),
      // Use a ternary operator to decide the initial route based on login status.
      home: _isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}
