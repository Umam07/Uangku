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
  int _homeReloadCount = 0;

  late final PageController _pageController;

  /// Mapping: pageIndex → tabIndex (tab 2 = modal, bukan page nyata)
  /// Page 0 → Tab 0 (Home)
  /// Page 1 → Tab 1 (Riwayat)
  /// Page 2 → Tab 3 (Laporan)
  /// Page 3 → Tab 4 (Setelan)
  static const List<int> _pageToTab = [0, 1, 3, 4];

  int _tabIndexToPage(int tabIndex) {
    final page = _pageToTab.indexOf(tabIndex);
    return page == -1 ? 0 : page;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Tab Tambah → tampilkan modal, jangan pindah halaman
      _showAddTransactionSheet();
      return;
    }

    final pageIndex = _tabIndexToPage(index);
    setState(() => _currentIndex = index);

    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int pageIndex) {
    // Sinkronkan navbar saat user swipe manual
    setState(() {
      _currentIndex = _pageToTab[pageIndex];
    });
  }

  void _onTransactionSaved() {
    setState(() {
      _homeReloadCount++;
      _currentIndex = 0;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
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

  @override
  Widget build(BuildContext context) {
    const navbarHeight = 64.0;
    const navbarBottomMargin = 20.0;
    const navbarHorizPadding = 16.0;

    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── PageView: swipeable screens ──────────────────────────────────
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              // ClampingScrollPhysics agar tidak overlap dengan scroll vertikal child
              physics: const ClampingScrollPhysics(),
              children: [
                // Page 0 → Home
                HomeTab(
                  key: ValueKey('home_$_homeReloadCount'),
                  onNavigateToHistory: () => _onTabTapped(1),
                ),
                // Page 1 → Riwayat
                const HistoryScreen(),
                // Page 2 → Laporan
                const ReportScreen(),
                // Page 3 → Setelan
                const SettingsScreen(),
              ],
            ),
          ),

          // ── Floating Liquid Glass Navbar ──────────────────────────────────
          Positioned(
            left: navbarHorizPadding,
            right: navbarHorizPadding,
            bottom: navbarBottomMargin + bottomSafeArea,
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
