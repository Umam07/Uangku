import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// AppBottomNavBar — Liquid Glass edition.
/// All five items (including "Tambah") sit in the same frosted-glass pill so
/// they are perfectly aligned and equally sized.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass colours tuned for light / dark backgrounds
    final glassBase = isDark
        ? const Color(0xFF2C1F0E).withValues(alpha: 0.55)
        : const Color(0xFFFFFDF5).withValues(alpha: 0.60);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.70);

    final topHighlight = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.55);

    return Container(
      // SafeArea bottom padding + pill height
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  // Layered gradient for the liquid-glass look
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      topHighlight,
                      glassBase,
                    ],
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.50),
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildNavItem(context,
                        index: 0,
                        filledIcon: Icons.home_rounded,
                        outlineIcon: Icons.home_outlined,
                        label: 'Home'),
                    _buildNavItem(context,
                        index: 1,
                        filledIcon: Icons.history_rounded,
                        outlineIcon: Icons.history_outlined,
                        label: 'Riwayat'),
                    _buildAddItem(context, isDark: isDark),
                    _buildNavItem(context,
                        index: 3,
                        filledIcon: Icons.analytics_rounded,
                        outlineIcon: Icons.analytics_outlined,
                        label: 'Laporan'),
                    _buildNavItem(context,
                        index: 4,
                        filledIcon: Icons.settings_rounded,
                        outlineIcon: Icons.settings_outlined,
                        label: 'Setelan'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Regular nav item — icon + label, equally spaced
  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData filledIcon,
    required IconData outlineIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = AppColors.primary;
    const inactiveColor = Color(0xFFA8A29E);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(index);
          },
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? filledIcon : outlineIcon,
                    key: ValueKey(isSelected),
                    color: isSelected ? activeColor : inactiveColor,
                    size: 24.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Centre "Tambah" item — same Expanded slot, small accent circle for icon
  Widget _buildAddItem(BuildContext context, {required bool isDark}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap(2);
          },
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF8C38), // lighter orange
                        AppColors.primary, // brand orange
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'Tambah',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
