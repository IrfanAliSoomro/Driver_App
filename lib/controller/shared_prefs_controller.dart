import 'package:shared_preferences/shared_preferences.dart';

class PrefsController {
  static const String _isLoggedInKey = "isLoggedIn";
  static const String _userEmailKey = "userEmail";

  /// Save login status and user email
  Future<void> saveLoginStatus(bool isLoggedIn, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, isLoggedIn);
      await prefs.setString(_userEmailKey, email);
    } catch (e) {
      print("Error saving login status: $e");
    }
  }

  /// Get login status (returns `false` if not found)
  Future<bool> getLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool? status = prefs.getBool(_isLoggedInKey);
      print("Login status retrieved: $status"); // Debugging
      return status ?? false;
    } catch (e) {
      print("Error retrieving login status: $e");
      return false;
    }
  }

  /// Get saved user email (returns `null` if not found)
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      print("Error retrieving user email: $e");
      return null;
    }
  }

  /// Logout function (clears all stored preferences)
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print("Error during logout: $e");
    }
  }
}
