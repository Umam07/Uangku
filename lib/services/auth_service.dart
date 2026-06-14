import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPhoto = 'user_photo';
  static const String _keyLoginType = 'login_type';

  // Check if user is already logged in
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get current logged-in user data
  Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (!isLoggedIn) return null;

    return {
      'name': prefs.getString(_keyUserName) ?? 'Pengguna Uangku',
      'email': prefs.getString(_keyUserEmail) ?? 'user@uangku.id',
      'photo': prefs.getString(_keyUserPhoto) ?? '',
      'type': prefs.getString(_keyLoginType) ?? 'guest',
    };
  }

  // Update user profile data
  Future<void> updateUserProfile(String name, String photo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserPhoto, photo);
  }

  // Simulate Google Sign-In (Bypassed)
  Future<bool> loginWithGoogleMock() async {
    // Simulate API network call delay (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, "Muhammad Syafi'ul Umam");
    await prefs.setString(_keyUserEmail, "msyafiul.umam@gmail.com");
    await prefs.setString(_keyUserPhoto, "https://api.dicebear.com/7.x/bottts/png?seed=umam");
    await prefs.setString(_keyLoginType, "google");

    return true;
  }

  // Simulate Guest/Demo Sign-In
  Future<bool> loginAsGuest() async {
    // Simulate light delay (500ms)
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, "Tamu Uangku");
    await prefs.setString(_keyUserEmail, "tamu@uangku.id");
    await prefs.setString(_keyUserPhoto, "https://api.dicebear.com/7.x/bottts/png?seed=guest");
    await prefs.setString(_keyLoginType, "guest");

    return true;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
