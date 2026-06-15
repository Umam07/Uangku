import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// AppBottomNavBar — Premium Liquid Glass Floating Edition.
///
/// A floating pill-shaped navigation bar with layered glassmorphism,
/// an animated sliding active-indicator, and a spring-animated center button.
/// Inspired by Apple's liquid glass design language.
class AppBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _indicatorController;
  late AnimationController _addButtonController;
  late Animation<double> _addButtonScale;

  // Track previous index for indicator animation
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _addButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _addButtonScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _addButtonController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _indicatorController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    _addButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamically adjust system overlays to be transparent and match current theme brightness
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    // ── Glass palette ──
    final glassBase = isDark
        ? const Color(0xFF1A1208).withValues(alpha: 0.72)
        : const Color(0xFFFFFDF5).withValues(alpha: 0.55);

    final glassHighlight = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.70);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.80);

    final innerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.40);

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: AnimatedBuilder(
                animation: _indicatorController,
                builder: (context, child) {
                  return Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      // ── Multi-layer glass gradient ──
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.35, 1.0],
                        colors: [
                          glassHighlight,
                          glassBase,
                          glassBase.withValues(alpha: isDark ? 0.85 : 0.65),
                        ],
                      ),
                      // ── Outer border ──
                      border: Border.all(
                        color: borderColor,
                        width: 1.0,
                      ),
                      // ── Floating shadows ──
                      boxShadow: [
                        // Primary depth shadow
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.45 : 0.12),
                          blurRadius: 32,
                          spreadRadius: 0,
                          offset: const Offset(0, 12),
                        ),
                        // Soft ambient shadow
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.20 : 0.06),
                          blurRadius: 12,
                          spreadRadius: -2,
                          offset: const Offset(0, 4),
                        ),
                        // Inner top highlight (simulated)
                        BoxShadow(
                          color: Colors.white
                              .withValues(alpha: isDark ? 0.03 : 0.50),
                          blurRadius: 0,
                          spreadRadius: 0,
                          offset: const Offset(0, -0.5),
                        ),
                      ],
                    ),
                    // ── Inner highlight container ──
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border(
                          top: BorderSide(
                            color: innerBorderColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              // ── Animated active indicator ──
                              _buildActiveIndicator(constraints.maxWidth, isDark),
                              // ── Nav items ──
                              Row(
                                children: [
                                  _buildNavItem(context,
                                      index: 0,
                                      filledIcon: Icons.home_rounded,
                                      outlineIcon: Icons.home_outlined,
                                      label: 'Home',
                                      isDark: isDark),
                                  _buildNavItem(context,
                                      index: 1,
                                      filledIcon: Icons.history_rounded,
                                      outlineIcon: Icons.history_outlined,
                                      label: 'Riwayat',
                                      isDark: isDark),
                                  _buildAddItem(context, isDark: isDark),
                                  _buildNavItem(context,
                                      index: 3,
                                      filledIcon: Icons.analytics_rounded,
                                      outlineIcon: Icons.analytics_outlined,
                                      label: 'Laporan',
                                      isDark: isDark),
                                  _buildNavItem(context,
                                      index: 4,
                                      filledIcon: Icons.settings_rounded,
                                      outlineIcon: Icons.settings_outlined,
                                      label: 'Setelan',
                                      isDark: isDark),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Animated pill indicator that slides behind the active tab (Telegram-style icon-only hover)
  Widget _buildActiveIndicator(double maxWidth, bool isDark) {
    final itemWidth = maxWidth / 5;
    final indicatorWidth = 60.0;
    final indicatorHeight = 28.0;

    double getPositionForIndex(int idx) {
      return idx * itemWidth + (itemWidth - indicatorWidth) / 2;
    }

    final currentPos = getPositionForIndex(widget.currentIndex);
    final previousPos = getPositionForIndex(_previousIndex);

    final curvedAnimation = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeOutCubic,
    );

    final left = Tween<double>(begin: previousPos, end: currentPos)
        .animate(curvedAnimation);

    final bool isVisible = widget.currentIndex != 2;

    return AnimatedBuilder(
      animation: left,
      builder: (context, _) {
        return Positioned(
          left: left.value,
          top: 9.5, // Centered vertically on the 28dp icon container (total height 64)
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Container(
              width: indicatorWidth,
              height: indicatorHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.26)
                    : AppColors.primary.withValues(alpha: 0.20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.40 : 0.30),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Regular nav item — icon + label with animated transitions
  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData filledIcon,
    required IconData outlineIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = widget.currentIndex == index;
    final activeColor = AppColors.primary;
    final inactiveColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFFA8A29E);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap(index);
          },
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated icon with scale in a fixed 28dp container ──
                SizedBox(
                  height: 28,
                  child: Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.0)
                                  .animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          isSelected ? filledIcon : outlineIcon,
                          key: ValueKey('${index}_$isSelected'),
                          color: isSelected ? activeColor : inactiveColor,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3.0),
                // ── Animated label ──
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? activeColor : inactiveColor,
                    letterSpacing: isSelected ? 0.1 : 0.0,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Centre "Tambah" button — elevated circle with spring animation
  Widget _buildAddItem(BuildContext context, {required bool isDark}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            HapticFeedback.mediumImpact();
            _addButtonController.forward(from: 0.0);
            widget.onTap(2);
          },
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Animated spring-scale button ──
                AnimatedBuilder(
                  animation: _addButtonScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _addButtonScale.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF9F4A), // warm highlight
                          AppColors.primary,  // brand orange
                          Color(0xFFD44B00), // deep orange
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.50),
                          blurRadius: 16,
                          spreadRadius: -2,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  'Tambah',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.90),
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
