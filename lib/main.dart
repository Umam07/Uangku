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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'Uangku',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          home: FutureBuilder<bool>(
            future: authService.checkLoginStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                );
              }
              
              if (snapshot.hasData && snapshot.data == true) {
                return const DashboardScreen();
              }
              
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
