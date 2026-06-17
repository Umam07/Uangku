import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _completeWelcome(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  Future<void> _requestPermissionsAndNavigate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check if permissions are already granted
    final cameraStatus = await Permission.camera.status;
    final photoStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    
    final hasCamera = cameraStatus.isGranted;
    final hasPhotos = photoStatus.isGranted || storageStatus.isGranted;
    
    if (hasCamera && hasPhotos) {
      if (context.mounted) {
        await _completeWelcome(context);
      }
    } else {
      if (context.mounted) {
        _showPermissionRequestSheet(context, isDark);
      }
    }
  }

  void _showPermissionRequestSheet(BuildContext context, bool isDark) {
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
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Izin Akses Fitur',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Untuk menggunakan fitur pindaian struk belanja (OCR) secara maksimal, Uangku membutuhkan beberapa izin akses berikut:',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _buildPrivacyPoint(
                context,
                Icons.camera_alt_outlined,
                'Kamera',
                'Digunakan untuk mengambil foto struk belanja secara langsung untuk dianalisis nominalnya secara otomatis.',
                isDark,
              ),
              const SizedBox(height: 16),
              _buildPrivacyPoint(
                context,
                Icons.photo_library_outlined,
                'Galeri Foto / Penyimpanan',
                'Digunakan untuk memilih gambar struk belanja yang sudah tersimpan di galeri foto perangkat Anda.',
                isDark,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _completeWelcome(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Nanti Saja',
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (Platform.isAndroid) {
                          await [
                            Permission.camera,
                            Permission.photos,
                            Permission.storage,
                          ].request();
                        } else {
                          await [
                            Permission.camera,
                            Permission.photos,
                          ].request();
                        }
                        if (context.mounted) {
                          _completeWelcome(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Aktifkan Izin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context, bool isDark) {
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
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Privasi & Keamanan Data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Uangku dirancang untuk memberikan kontrol penuh atas data finansial Anda:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                context,
                Icons.cloud_off_rounded,
                'Penyimpanan Lokal-Utama',
                'Semua data pencatatan transaksi Anda disimpan secara aman di perangkat Anda secara lokal untuk kecepatan akses dan privasi maksimal.',
                isDark,
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                context,
                Icons.lock_outline_rounded,
                'Tanpa Pelacakan Pihak Ketiga',
                'Uangku tidak pernah menjual, menganalisis, atau membagikan riwayat keuangan Anda kepada pihak luar atau pengiklan.',
                isDark,
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                context,
                Icons.document_scanner_outlined,
                'Pemindaian Struk Aman',
                'Proses ekstraksi data dari struk belanja dilakukan dengan mematuhi standar keamanan data perangkat untuk mendeteksi nominal transaksi.',
                isDark,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Saya Mengerti'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyPoint(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
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
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.backgroundDark,
                        const Color(0xFF1E1E1E),
                      ]
                    : [
                        AppColors.background,
                        const Color(0xFFFEEAD2),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Floating Abstract Shapes
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: isDark ? 0.08 : 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.1),
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 70),
                        // Logo Container (same size/look as LoginScreen)
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '💸',
                              style: TextStyle(fontSize: 48),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Welcome text
                        Text(
                          'Selamat Datang\ndi Uangku',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // App description
                        Text(
                          'Kelola pengeluaran harian, catat transaksi secara otomatis dengan scan struk, dan pantau analisis keuangan Anda dengan mudah.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            height: 1.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
                // Privacy Badge & Continue Button Area (Always at bottom)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Privacy Icon (Dual Handshake layout inspired by Apple Music screenshot)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.handshake_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Privacy description
                      Text(
                        'Pencatatan, pemindaian struk, dan riwayat transaksi Anda diproses secara aman untuk menjaga privasi. Uangku berkomitmen penuh melindungi data finansial Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Privacy link
                      InkWell(
                        onTap: () => _showPrivacyPolicy(context, isDark),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                          child: Text(
                            'Lihat bagaimana data Anda dikelola...',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.accent : AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Continue Button (Premium red/orange Apple Style)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _requestPermissionsAndNavigate(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Lanjutkan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
