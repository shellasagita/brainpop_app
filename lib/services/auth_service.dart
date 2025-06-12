// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _currentUserIdKey = 'currentUserId';
  static const String _currentUsernameKey =
      'currentUsername'; // To store username for display

  // Checks if a user is currently logged in.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ??
        false; // Default to false if not set
  }

  // Logs in a user by saving their ID and login status.
  Future<void> login(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_currentUserIdKey, userId);
    await prefs.setString(_currentUsernameKey, username);
  }

  // Logs out the current user by clearing login status and user ID.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentUserIdKey);
    await prefs.remove(_currentUsernameKey);
  }

  // Retrieves the ID of the currently logged-in user.
  // Returns null if no user is logged in.
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentUserIdKey);
  }

  // Retrieves the username of the currently logged-in user.
  // Returns null if no user is logged in.
  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUsernameKey);
  }
}
