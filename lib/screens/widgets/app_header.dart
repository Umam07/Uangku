import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// AppHeader is a clean & modern top bar widget designed under Apple HIG.
/// It displays the user profile picture (or fallback initials "MU") and an outlined action button.
class AppHeader extends StatelessWidget {
  final String name;
  final String photoUrl;
  final VoidCallback? onRightActionPressed;
  final IconData rightActionIcon;
  final bool isDark;

  const AppHeader({
    super.key,
    required this.name,
    this.photoUrl = '',
    this.onRightActionPressed,
    required this.rightActionIcon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          // CircleAvatar 44x44
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15), // soft orange background
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty && photoUrl.startsWith('http')
                  ? Image.network(
                      photoUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallback(),
                    )
                  : _buildFallback(),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          
          // Column 2 baris (Halo, & Name)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Halo,',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                Text(
                  name.isNotEmpty ? name : "Muhammad Syafi'ul Umam",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600, // SemiBold
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Right action outline button 44x44
          GestureDetector(
            onTap: onRightActionPressed,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusButton), // 12pt
                border: Border.all(
                  color: isDark ? AppColors.separatorDark : AppColors.separator,
                  width: 1.0,
                ),
              ),
              child: Icon(
                rightActionIcon,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return const Center(
      child: Text(
        'MU',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
