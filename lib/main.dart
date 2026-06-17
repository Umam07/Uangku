import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart'; // import global themeNotifier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Make system bars completely transparent and enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
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
  final seenWelcome = prefs.getBool('seen_welcome') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn, seenWelcome: seenWelcome));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool seenWelcome;
  const MyApp({super.key, this.isLoggedIn = false, this.seenWelcome = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, _) {
        Widget homeWidget;
        if (isLoggedIn) {
          homeWidget = const DashboardScreen();
        } else if (!seenWelcome) {
          homeWidget = const WelcomeScreen();
        } else {
          homeWidget = const LoginScreen();
        }

        return MaterialApp(
          title: 'Uangku',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          home: homeWidget,
        );
      },
    );
  }
}
