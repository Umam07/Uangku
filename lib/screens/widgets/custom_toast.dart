import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum ToastType { success, error, warning, info }

class CustomToast {
  static OverlayEntry? _currentEntry;
  static GlobalKey<_ToastWidgetState>? _currentKey;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    // Dismiss active toast with animation first if it exists
    if (_currentKey != null && _currentKey!.currentState != null) {
      _currentKey!.currentState!.dismissWithAnimation().then((_) {
        // Only build the new toast if the context is still mounted
        if (context.mounted) {
          _createNewToast(context, message, type, duration, actionLabel, onActionPressed);
        }
      });
    } else {
      _createNewToast(context, message, type, duration, actionLabel, onActionPressed);
    }
  }

  static void _createNewToast(
    BuildContext context,
    String message,
    ToastType type,
    Duration duration,
    String? actionLabel,
    VoidCallback? onActionPressed,
  ) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.of(context);
    final key = GlobalKey<_ToastWidgetState>();
    _currentKey = key;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return ToastWidget(
          key: key,
          message: message,
          type: type,
          duration: duration,
          actionLabel: actionLabel,
          onActionPressed: onActionPressed,
          onRemove: () {
            if (_currentEntry == entry) {
              _currentEntry?.remove();
              _currentEntry = null;
              _currentKey = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  static void dismiss() {
    if (_currentKey != null && _currentKey!.currentState != null) {
      _currentKey!.currentState!.dismissWithAnimation();
    } else if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
      _currentKey = null;
    }
  }

  // Helper methods
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    show(
      context,
      message,
      type: ToastType.success,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: ToastType.error, duration: duration);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: ToastType.warning, duration: duration);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: ToastType.info, duration: duration);
  }
}

class ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback onRemove;

  const ToastWidget({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onActionPressed,
    required this.onRemove,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _progressController;
  late final AnimationController _dragRecoveryController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  double _dragOffset = 0.0;
  double _dragStartOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _dragRecoveryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _dragRecoveryController.addListener(() {
      setState(() {
        _dragOffset = Tween<double>(begin: _dragStartOffset, end: 0.0)
            .evaluate(CurvedAnimation(
              parent: _dragRecoveryController,
              curve: Curves.easeOutCubic,
            ));
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (mounted && !_isDragging) {
          dismissWithAnimation();
        }
      }
    });

    _controller.forward().then((_) {
      if (mounted) {
        _progressController.reverse(from: 1.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    _dragRecoveryController.dispose();
    super.dispose();
  }

  Future<void> dismissWithAnimation() async {
    if (mounted) {
      _progressController.stop();
      _dragRecoveryController.stop();
      await _controller.reverse();
      widget.onRemove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData iconData;
    Color typeColor;
    String titleText;

    switch (widget.type) {
      case ToastType.success:
        iconData = Icons.check_circle_rounded;
        typeColor = isDark ? AppColors.incomeGreenDark : AppColors.incomeGreen;
        titleText = 'Sukses';
        break;
      case ToastType.error:
        iconData = Icons.error_rounded;
        typeColor = isDark ? AppColors.expenseRedDark : AppColors.expenseRed;
        titleText = 'Gagal';
        break;
      case ToastType.warning:
        iconData = Icons.warning_rounded;
        typeColor = isDark ? AppColors.warnOrangeDark : AppColors.warnOrange;
        titleText = 'Peringatan';
        break;
      case ToastType.info:
        iconData = Icons.info_rounded;
        typeColor = isDark ? AppColors.infoBlueDark : AppColors.infoBlue;
        titleText = 'Informasi';
        break;
    }

    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onVerticalDragStart: (_) {
                    _isDragging = true;
                    _progressController.stop();
                  },
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      if (details.primaryDelta! < 0) {
                        _dragOffset += details.primaryDelta!;
                      } else {
                        _dragOffset += details.primaryDelta! * 0.25;
                      }
                    });
                  },
                  onVerticalDragEnd: (details) {
                    _isDragging = false;
                    if (_dragOffset < -25 || (details.primaryVelocity ?? 0) < -80) {
                      dismissWithAnimation();
                    } else {
                      _dragStartOffset = _dragOffset;
                      _dragRecoveryController.forward(from: 0.0).then((_) {
                        if (mounted && !_isDragging) {
                          _progressController.reverse(from: _progressController.value);
                        }
                      });
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(0, _dragOffset),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withValues(alpha: isDark ? 0.18 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        Color.lerp(const Color(0xFF1E1E22), typeColor, 0.05)!.withValues(alpha: 0.85),
                                        const Color(0xFF121214).withValues(alpha: 0.85),
                                      ]
                                    : [
                                        Color.lerp(Colors.white, typeColor, 0.03)!.withValues(alpha: 0.92),
                                        const Color(0xFFF9F9FB).withValues(alpha: 0.92),
                                      ],
                              ),
                              border: Border.all(
                                color: typeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                width: 1.2,
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: isDark ? 0.15 : 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: typeColor.withValues(alpha: isDark ? 0.3 : 0.2),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          iconData,
                                          color: typeColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            titleText,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: typeColor,
                                              fontFamily: 'Poppins',
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.message,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: textColor,
                                              height: 1.35,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.actionLabel != null && widget.onActionPressed != null) ...[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          widget.onActionPressed!();
                                          dismissWithAnimation();
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          backgroundColor: typeColor.withValues(alpha: 0.12),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          widget.actionLabel!,
                                          style: TextStyle(
                                            color: typeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: dismissWithAnimation,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 12,
                                          color: textColor.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  left: -16,
                                  right: -16,
                                  bottom: -14,
                                  child: Container(
                                    height: 3,
                                    color: typeColor.withValues(alpha: isDark ? 0.08 : 0.04),
                                  ),
                                ),
                                Positioned(
                                  left: -16,
                                  right: -16,
                                  bottom: -14,
                                  child: AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (context, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _progressController.value,
                                        child: Container(
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: typeColor.withValues(alpha: 0.85),
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(1.5),
                                              bottomRight: Radius.circular(1.5),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
