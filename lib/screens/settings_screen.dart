import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import 'login_screen.dart';
import 'widgets/custom_toast.dart';

// Global ValueNotifier to control ThemeMode from Settings
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final TransactionService _transactionService = TransactionService();
  Map<String, String>? _userData;
  bool _isLoading = true;
  String _activeThemeStr = 'System'; // System, Light, Dark
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();

    // Load theme setting
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('app_theme_mode') ?? 'System';
    final notifEnabled = prefs.getBool('daily_notifications') ?? true;

    setState(() {
      _userData = user;
      _activeThemeStr = themeStr;
      _notificationsEnabled = notifEnabled;
      _isLoading = false;
    });
  }

  Future<void> _updateTheme(String themeStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', themeStr);

    ThemeMode newMode;
    if (themeStr == 'Light') {
      newMode = ThemeMode.light;
    } else if (themeStr == 'Dark') {
      newMode = ThemeMode.dark;
    } else {
      newMode = ThemeMode.system;
    }

    themeNotifier.value = newMode;
    setState(() {
      _activeThemeStr = themeStr;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_notifications', value);
    setState(() {
      _notificationsEnabled = value;
    });
    if (mounted) {
      CustomToast.showSuccess(
        context,
        value
            ? 'Notifikasi harian diaktifkan.'
            : 'Notifikasi harian dinonaktifkan.',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _handleResetData() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reset Data Transaksi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus semua data transaksi? Tindakan ini tidak dapat dibatalkan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_transactions');

              // Trigger reload
              await _transactionService.getTransactions();

              if (mounted) {
                CustomToast.showSuccess(
                  context,
                  'Data transaksi berhasil direset!',
                );
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Keluar Aplikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari Uangku?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileBottomSheet(String currentName, String currentPhoto) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final nameController = TextEditingController(text: currentName);
    String selectedPhoto = currentPhoto;

    // List of predefined cool seeds for fun-emoji and bottts styles
    final List<String> avatarSeeds = [
      'umam',
      'guest',
      'cookie',
      'lucky',
      'sugar',
      'sparky',
      'socks',
      'playful',
      'carefree',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      'Edit Profil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avatar Preview (Large)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          backgroundImage:
                              selectedPhoto.isNotEmpty &&
                                  selectedPhoto.startsWith('http')
                              ? NetworkImage(selectedPhoto)
                              : null,
                          child:
                              selectedPhoto.isEmpty ||
                                  !selectedPhoto.startsWith('http')
                              ? Text(
                                  nameController.text.isNotEmpty
                                      ? nameController.text[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Avatar Selector Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pilih Avatar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Horizontal Avatar List
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: avatarSeeds.length,
                        itemBuilder: (context, index) {
                          final seed = avatarSeeds[index];
                          final isDefaultSeed =
                              seed == 'umam' || seed == 'guest';
                          final photoUrl = isDefaultSeed
                              ? 'https://api.dicebear.com/7.x/bottts/png?seed=$seed'
                              : 'https://api.dicebear.com/7.x/fun-emoji/png?seed=$seed';
                          final isSelected = selectedPhoto == photoUrl;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedPhoto = photoUrl;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : AppColors.primary.withValues(alpha: 0.05),
                                backgroundImage: NetworkImage(photoUrl),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Input
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nama Pengguna',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (val) {
                        if (selectedPhoto.isEmpty) {
                          setModalState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama Anda...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark.withValues(
                                  alpha: 0.5,
                                )
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) {
                          CustomToast.showError(
                            context,
                            'Nama tidak boleh kosong!',
                          );
                          return;
                        }

                        // Close BottomSheet
                        Navigator.pop(context);

                        // Save data
                        await _authService.updateUserProfile(
                          newName,
                          selectedPhoto,
                        );

                        // Reload screen data
                        await _loadSettingsData();

                        if (context.mounted) {
                          CustomToast.showSuccess(
                            context,
                            'Profil berhasil diperbarui!',
                          );
                        }
                      },
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final name = _userData?['name'] ?? 'Pengguna Uangku';
    final email = _userData?['email'] ?? 'user@uangku.id';
    final photo = _userData?['photo'] ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // Top Decorative Gradient Glow
          Positioned(
            top: -150,
            left: -50,
            right: -50,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Top Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Pengaturan',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      110,
                    ), // Space for floating navbar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Profile Card
                  _buildProfileCard(name, email, photo, isDark),
                  const SizedBox(height: 28),

                  // Theme settings section
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Tampilan Aplikasi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildThemeSelector(isDark),
                  const SizedBox(height: 28),

                  // Preferences Section
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Preferensi Sistem',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreferencesList(isDark),
                  const SizedBox(height: 28),

                  // Support & Info Section
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Dukungan & Informasi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSupportList(isDark),
                  const SizedBox(height: 28),

                  // Account / Danger actions
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Keamanan & Data',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDangerZoneList(isDark),

                  const SizedBox(height: 40),
                  // App version label
                  Center(
                    child: Text(
                      'Uangku v1.0.0 (Release)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white30 : Colors.black26,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
);
}

  Widget _buildProfileCard(
    String name,
    String email,
    String photo,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Glowing avatar border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: photo.isNotEmpty && photo.startsWith('http')
                    ? NetworkImage(photo)
                    : null,
                child: photo.isEmpty || !photo.startsWith('http')
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Interactive visual element (statically beautiful edit icon wrapper)
          GestureDetector(
            onTap: () => _showEditProfileBottomSheet(name, photo),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.edit_rounded,
                size: 16,
                color: isDark ? AppColors.textSecondaryDark : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Row(
      children: [
        _buildThemeCard(
          themeName: 'Light',
          displayName: 'Terang',
          icon: Icons.wb_sunny_rounded,
          iconColor: Colors.amber.shade700,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildThemeCard(
          themeName: 'Dark',
          displayName: 'Gelap',
          icon: Icons.nightlight_round_rounded,
          iconColor: Colors.indigo.shade300,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildThemeCard(
          themeName: 'System',
          displayName: 'Sistem',
          icon: Icons.settings_suggest_rounded,
          iconColor: Colors.blueGrey,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildThemeCard({
    required String themeName,
    required String displayName,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    final isSelected = _activeThemeStr == themeName;

    // Preview colors based on mode
    Color previewBg;
    Color previewBorder;
    Color previewAccent;
    Color previewCard;
    Color previewText;

    if (themeName == 'Light') {
      previewBg = AppColors.background;
      previewBorder = AppColors.textSecondary.withValues(alpha: 0.15);
      previewAccent = AppColors.primary;
      previewCard = AppColors.surface;
      previewText = AppColors.textPrimary;
    } else if (themeName == 'Dark') {
      previewBg = AppColors.backgroundDark;
      previewBorder = AppColors.textSecondaryDark.withValues(alpha: 0.15);
      previewAccent = AppColors.primary;
      previewCard = AppColors.surfaceDark;
      previewText = AppColors.textPrimaryDark;
    } else {
      // System split preview colors based on context dark mode
      previewBg = isDark ? AppColors.backgroundDark : AppColors.background;
      previewBorder = isDark
          ? AppColors.textSecondaryDark.withValues(alpha: 0.15)
          : AppColors.textSecondary.withValues(alpha: 0.15);
      previewAccent = AppColors.primary;
      previewCard = isDark ? AppColors.surfaceDark : AppColors.surface;
      previewText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _updateTheme(themeName),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.surfaceDark : AppColors.surface)
                : (isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.3)
                      : AppColors.surface.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // Mini Screen Preview
              Container(
                height: 45,
                width: 65,
                decoration: BoxDecoration(
                  color: previewBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: previewBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.1 : 0.03,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: themeName == 'System'
                      ? Row(
                          children: [
                            // Light half preview
                            Expanded(
                              child: Container(
                                color: AppColors.background,
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: 2.5,
                                      width: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 2,
                                            width: 12,
                                            decoration: BoxDecoration(
                                              color: AppColors.textPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Container(
                                            height: 1.5,
                                            width: 6,
                                            decoration: BoxDecoration(
                                              color: AppColors.textSecondary
                                                  .withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Dark half preview
                            Expanded(
                              child: Container(
                                color: AppColors.backgroundDark,
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: 2.5,
                                      width: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceDark,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 2,
                                            width: 12,
                                            decoration: BoxDecoration(
                                              color: AppColors.textPrimaryDark,
                                              borderRadius:
                                                  BorderRadius.circular(0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Container(
                                            height: 1.5,
                                            width: 6,
                                            decoration: BoxDecoration(
                                              color: AppColors.textSecondaryDark
                                                  .withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top indicator bar
                              Container(
                                height: 2.5,
                                width: 15,
                                decoration: BoxDecoration(
                                  color: previewAccent,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              // Simulated content card
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: previewCard,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 6,
                                      width: 6,
                                      decoration: BoxDecoration(
                                        color: previewAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 2,
                                            width: 15,
                                            decoration: BoxDecoration(
                                              color: previewText,
                                              borderRadius:
                                                  BorderRadius.circular(0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Container(
                                            height: 1.5,
                                            width: 8,
                                            decoration: BoxDecoration(
                                              color: previewText.withValues(
                                                alpha: 0.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Icon and Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary)
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Small Selection Indicator
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white24 : Colors.black26),
                    width: 1.5,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 9, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.monetization_on_rounded,
            iconColor: Colors.amber.shade700,
            title: 'Mata Uang Utama',
            subtitle: 'IDR - Rupiah (Rp)',
            isDark: isDark,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.green, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Aktif',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.textSecondary.withValues(alpha: 0.08),
          ),
          _buildSettingsTile(
            icon: Icons.notifications_active_rounded,
            iconColor: Colors.blue,
            title: 'Notifikasi Harian',
            subtitle: 'Pengingat pencatatan otomatis',
            isDark: isDark,
            trailing: Switch.adaptive(
              value: _notificationsEnabled,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
              onChanged: (val) => _toggleNotifications(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.restore_rounded,
            iconColor: Colors.orange,
            title: 'Reset Data Transaksi',
            subtitle: 'Kembalikan data ke awal',
            isDark: isDark,
            onTap: _handleResetData,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.textSecondary.withValues(alpha: 0.08),
          ),
          _buildSettingsTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.danger,
            title: 'Keluar Akun',
            subtitle: 'Keluar dari sesi Uangku',
            isDark: isDark,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.teal,
            title: 'Tentang Aplikasi',
            subtitle: 'Informasi versi dan developer',
            isDark: isDark,
            onTap: _showAboutBottomSheet,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.textSecondary.withValues(alpha: 0.08),
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.blueAccent,
            title: 'Kebijakan Privasi',
            subtitle: 'Keamanan data dan enkripsi',
            isDark: isDark,
            onTap: _showPrivacyBottomSheet,
          ),
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.textSecondary.withValues(alpha: 0.08),
          ),
          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            iconColor: Colors.green,
            title: 'Pusat Bantuan',
            subtitle: 'Hubungi WhatsApp atau Email',
            isDark: isDark,
            onTap: _showHelpBottomSheet,
          ),
        ],
      ),
    );
  }

  void _showAboutBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text('💸', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Uangku',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v1.0.0 (Stable Release)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Uangku adalah aplikasi pencatat keuangan pintar yang dirancang untuk membantu Anda melacak pendapatan, pengeluaran, dan mengelola anggaran harian dengan mudah dan menyenangkan. Dibangun dengan estetika modern, responsif, dan interaktif.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Divider(color: isDark ? Colors.white12 : Colors.black12),
              const SizedBox(height: 12),
              Text(
                '© 2026 Uangku Team. All rights reserved. 💸',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Colors.blueAccent,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Kebijakan Privasi & Keamanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Privasi Anda adalah prioritas utama kami. Aplikasi Uangku berkomitmen untuk menjaga keamanan seluruh data finansial Anda.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildPrivacyPoint(
                icon: Icons.lock_outline_rounded,
                title: 'Data Tersimpan dengan Enkripsi',
                description:
                    'Semua informasi transaksi, pendapatan, pengeluaran, serta riwayat keuangan Anda disimpan di penyimpanan lokal perangkat secara terenkripsi (AES-256 equivalent) guna mencegah akses tidak sah.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                icon: Icons.cloud_off_rounded,
                title: 'Penyimpanan Offline Lokal',
                description:
                    'Data keuangan Anda sepenuhnya berada di perangkat Anda sendiri. Kami tidak mengirimkan data transaksi Anda ke server eksternal mana pun.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                icon: Icons.cleaning_services_outlined,
                title: 'Kendali Penuh di Tangan Anda',
                description:
                    'Anda memiliki hak penuh untuk mereset seluruh data transaksi atau keluar dari sesi kapan saja melalui menu Keamanan & Data.',
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyPoint({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pusat Bantuan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hubungi kami jika Anda memiliki kendala atau pertanyaan seputar penggunaan aplikasi Uangku.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // WhatsApp Option
              _buildHelpContactOption(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: Colors.green,
                title: 'Hubungi via WhatsApp',
                subtitle: 'Chat customer support (+62 812-3456-7890)',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  CustomToast.showSuccess(
                    context,
                    'Menghubungi customer support via WhatsApp...',
                  );
                },
              ),
              const SizedBox(height: 12),

              // Email Option
              _buildHelpContactOption(
                icon: Icons.mail_outline_rounded,
                iconColor: Colors.blue,
                title: 'Kirim Email',
                subtitle: 'Hubungi kami via support@uangku.id',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  CustomToast.showSuccess(
                    context,
                    'Membuka aplikasi email...',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpContactOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
        onTap: onTap,
      ),
    );
  }
}
