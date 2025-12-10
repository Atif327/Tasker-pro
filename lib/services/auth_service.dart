import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserName = 'userName';

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Sign up new user
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'User with this email already exists',
        };
      }

      // Create new user
      final user = User(
        email: email,
        password: password, // In production, hash the password
        name: name,
        createdAt: DateTime.now(),
      );

      final createdUser = await _dbHelper.createUser(user);

      // Save login state
      await _saveLoginState(createdUser);

      return {
        'success': true,
        'message': 'Account created successfully',
        'user': createdUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating account: $e',
      };
    }
  }

  // Sign in existing user
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dbHelper.getUserByEmail(email);

      if (user == null) {
        return {
          'success': false,
          'message': 'No account found with this email',
        };
      }

      if (user.password != password) {
        return {
          'success': false,
          'message': 'Incorrect password',
        };
      }

      // Save login state
      await _saveLoginState(user);

      return {
        'success': true,
        'message': 'Login successful',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error signing in: $e',
      };
    }
  }

  // Save login state to SharedPreferences
  Future<void> _saveLoginState(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyUserId, user.id!);
    await prefs.setString(_keyUserEmail, user.email);
    await prefs.setString(_keyUserName, user.name);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get current user ID
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Get current user email
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  // Get current user name
  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
  }


}
