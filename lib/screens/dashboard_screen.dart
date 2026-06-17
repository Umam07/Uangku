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
      _currentIndex = 0;
    });
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionScreen(
        onTransactionSaved: () {
          Navigator.pop(context);
          _onTransactionSaved();
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
    // Height of the floating pill + bottom margin
    const navbarHeight = 64.0;
    const navbarBottomMargin = 20.0;
    const navbarHorizPadding = 16.0;

    return Scaffold(
      // extendBody so page content flows behind the floating navbar
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Main content (with bottom padding so last items aren't hidden) ──
          Positioned.fill(
            child: Padding(
              // Reserve space at the bottom so scrollable content can reach
              // below the floating navbar
              padding: EdgeInsets.only(
                bottom: navbarHeight + navbarBottomMargin + 8,
              ),
              child: _buildActiveScreen(),
            ),
          ),

          // ── Floating Liquid Glass Navbar ──────────────────────────────────
          Positioned(
            left: navbarHorizPadding,
            right: navbarHorizPadding,
            bottom: navbarBottomMargin,
            height: navbarHeight,
            child: AppBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}
