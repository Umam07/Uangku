import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'history_screen.dart';
import 'add_transaction_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'widgets/glassmorphic_navbar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTransactionSaved() {
    setState(() {
      _currentIndex = 0; // Automatically switch back to HomeTab
    });
  }

  Widget _buildActiveScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          onNavigateToHistory: () => _onTabTapped(1),
        );
      case 1:
        return const HistoryScreen();
      case 2:
        return AddTransactionScreen(
          onTransactionSaved: _onTransactionSaved,
        );
      case 3:
        return const ReportScreen();
      case 4:
        return const SettingsScreen();
      default:
        return HomeTab(
          onNavigateToHistory: () => _onTabTapped(1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent keyboard from pushing up the floating glass navbar
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Active Screen Content
          _buildActiveScreen(),

          // Floating Glassmorphic Navbar Overlay at the bottom center
          Align(
            alignment: Alignment.bottomCenter,
            child: GlassmorphicNavbar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}
