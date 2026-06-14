import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'history_screen.dart';
import 'add_transaction_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'widgets/app_bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  int _reloadCount = 0;

  void _onTabTapped(int index) {
    if (index == 2) {
      _showAddTransactionSheet();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onTransactionSaved() {
    setState(() {
      _reloadCount++;
      _currentIndex = 0; // Automatically switch back to HomeTab
    });
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionScreen(
        onTransactionSaved: () {
          Navigator.pop(context); // Close bottom sheet
          _onTransactionSaved(); // Refresh active screens
        },
      ),
    );
  }

  Widget _buildActiveScreen() {
    final key = ValueKey('tab_${_currentIndex}_$_reloadCount');
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          key: key,
          onNavigateToHistory: () => _onTabTapped(1),
        );
      case 1:
        return HistoryScreen(key: key);
      case 3:
        return ReportScreen(key: key);
      case 4:
        return SettingsScreen(key: key);
      default:
        return HomeTab(
          key: key,
          onNavigateToHistory: () => _onTabTapped(1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Allow content to scroll behind the translucent bottom navigation bar
      extendBody: true,
      // Prevent keyboard from pushing up the floating navbar
      resizeToAvoidBottomInset: false,
      body: _buildActiveScreen(),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
