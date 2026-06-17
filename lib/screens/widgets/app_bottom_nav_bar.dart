import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// AppBottomNavBar — Apple-style Floating Liquid Glass Pill Navbar.
///
/// Designed to be placed inside a Stack as a Positioned widget so it truly
/// floats above the screen content, matching the liquid glass aesthetic from
/// Apple's visionOS / iOS 26 design language.
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
    with SingleTickerProviderStateMixin {
  // Stores the GlobalKey for each item so we can measure its position
  final List<GlobalKey> _itemKeys = List.generate(5, (_) => GlobalKey());

  // Indicator animation
  late AnimationController _indicatorController;
  late Animation<double> _indicatorLeft;
  late Animation<double> _indicatorWidth;

  double _targetLeft = 0;
  double _targetWidth = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateIndicatorToIndex(widget.currentIndex);
    }
  }

  void _animateIndicatorToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _itemKeys[index].currentContext;
      if (keyContext == null) return;

      final RenderBox itemBox =
          keyContext.findRenderObject() as RenderBox;
      final RenderBox navBox =
          context.findRenderObject() as RenderBox;

      final itemOffset = itemBox.localToGlobal(Offset.zero, ancestor: navBox);
      final newLeft = itemOffset.dx;
      final newWidth = itemBox.size.width;

      if (!_initialized) {
        // Snap directly on first frame
        setState(() {
          _targetLeft = newLeft;
          _targetWidth = newWidth;
          _initialized = true;
        });
        _indicatorLeft = Tween<double>(begin: newLeft, end: newLeft)
            .animate(_indicatorController);
        _indicatorWidth = Tween<double>(begin: newWidth, end: newWidth)
            .animate(_indicatorController);
        return;
      }

      final prevLeft = _targetLeft;
      final prevWidth = _targetWidth;

      setState(() {
        _targetLeft = newLeft;
        _targetWidth = newWidth;
      });

      _indicatorLeft = Tween<double>(begin: prevLeft, end: newLeft).animate(
        CurvedAnimation(
          parent: _indicatorController,
          curve: Curves.easeOutCubic,
        ),
      );
      _indicatorWidth = Tween<double>(begin: prevWidth, end: newWidth).animate(
        CurvedAnimation(
          parent: _indicatorController,
          curve: Curves.easeOutCubic,
        ),
      );

      _indicatorController.forward(from: 0);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize indicator on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _animateIndicatorToIndex(widget.currentIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass colors
    final glassColor = isDark
        ? const Color(0xFF2C2018).withValues(alpha: 0.78)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.75);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.80);

    final indicatorColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.92);

    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6E6E73);

    final items = [
      _NavItem(label: 'Home', activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined),
      _NavItem(label: 'Riwayat', activeIcon: Icons.history_rounded, inactiveIcon: Icons.history_outlined),
      _NavItem(label: 'Tambah', activeIcon: Icons.add_circle_rounded, inactiveIcon: Icons.add_circle_outline_rounded),
      _NavItem(label: 'Laporan', activeIcon: Icons.analytics_rounded, inactiveIcon: Icons.analytics_outlined),
      _NavItem(label: 'Setelan', activeIcon: Icons.settings_rounded, inactiveIcon: Icons.settings_outlined),
    ];

    return AnimatedBuilder(
      animation: _indicatorController,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: borderColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.14),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                  // Top inner highlight
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.35),
                    blurRadius: 0,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated sliding indicator background
                  if (_initialized)
                    AnimatedBuilder(
                      animation: _indicatorController,
                      builder: (context, _) {
                        final left = _indicatorController.isAnimating
                            ? _indicatorLeft.value
                            : _targetLeft;
                        final width = _indicatorController.isAnimating
                            ? _indicatorWidth.value
                            : _targetWidth;
                        return Positioned(
                          left: left + 4,
                          top: 4,
                          bottom: 4,
                          width: width - 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: indicatorColor,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Nav items row
                  Row(
                    children: List.generate(items.length, (i) {
                      final item = items[i];
                      final isSelected = widget.currentIndex == i;
                      final color = isSelected ? AppColors.primary : inactiveColor;

                      return Expanded(
                        key: _itemKeys[i],
                        child: _NavItemWidget(
                          item: item,
                          isSelected: isSelected,
                          color: color,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onTap(i);
                          },
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

// ─── Single nav item with press + icon pop animation ─────────────────────────

class _NavItemWidget extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_NavItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger icon pop when becoming selected
    if (!oldWidget.isSelected && widget.isSelected) {
      _scaleController.forward().then((_) => _scaleController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isSelected ? widget.item.activeIcon : widget.item.inactiveIcon,
              color: widget.color,
              size: 24,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                color: widget.color,
                letterSpacing: -0.1,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}
