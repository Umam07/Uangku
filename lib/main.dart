import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart'; // import global themeNotifier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved theme preference on start
  final prefs = await SharedPreferences.getInstance();
  final themeStr = prefs.getString('app_theme_mode') ?? 'System';
  if (themeStr == 'Light') {
    themeNotifier.value = ThemeMode.light;
  } else if (themeStr == 'Dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system;
  }

  // Check login status once on startup
  final authService = AuthService();
  final isLoggedIn = await authService.checkLoginStatus();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'Uangku',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
        );
      },
    );
  }
}
