import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// AppBottomNavBar is a custom notched bottom navigation bar styled ala iOS HIG.
/// It uses BackdropFilter for soft translucent blur and follows brand guidelines.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: (isDark ? AppColors.surfaceDark : AppColors.surface).withValues(alpha: 0.85),
      elevation: 0,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias, // Ensures the background blur and color clip to the notch
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64.0,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.separatorDark : AppColors.separator,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                filledIcon: Icons.home_rounded,
                outlineIcon: Icons.home_outlined,
                label: 'Home',
              ),
              _buildNavItem(
                context,
                index: 1,
                filledIcon: Icons.history_rounded,
                outlineIcon: Icons.history_outlined,
                label: 'Riwayat',
              ),
              // Empty space placeholder for the notched FAB in the center
              const SizedBox(width: 56),
              _buildNavItem(
                context,
                index: 3,
                filledIcon: Icons.analytics_rounded,
                outlineIcon: Icons.analytics_outlined,
                label: 'Laporan',
              ),
              _buildNavItem(
                context,
                index: 4,
                filledIcon: Icons.settings_rounded,
                outlineIcon: Icons.settings_outlined,
                label: 'Setelan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData filledIcon,
    required IconData outlineIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = AppColors.primary;
    final inactiveColor = const Color(0xFFA8A29E); // #A8A29E as per spec

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick(); // light selection click haptic
            onTap(index);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? filledIcon : outlineIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24.0,
              ),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
