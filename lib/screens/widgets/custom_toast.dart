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

class _ToastWidgetState extends State<ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      dismissWithAnimation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismissWithAnimation() async {
    _timer?.cancel();
    if (mounted) {
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
        iconData = Icons.warning_amber_rounded;
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
          constraints: const BoxConstraints(maxWidth: 480),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < -8) {
                    dismissWithAnimation();
                  }
                },
                onTap: dismissWithAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: typeColor.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 38,
                              decoration: BoxDecoration(
                                color: typeColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                iconData,
                                color: typeColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
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
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.message,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                      height: 1.3,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.actionLabel != null && widget.onActionPressed != null) ...[
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: () {
                                  widget.onActionPressed!();
                                  dismissWithAnimation();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}
