import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../services/transaction_service.dart';
import '../services/ocr_service.dart';
import 'widgets/custom_toast.dart';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback onTransactionSaved;

  const AddTransactionScreen({
    super.key,
    required this.onTransactionSaved,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TransactionService _transactionService = TransactionService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isIncome = false; // False = Pengeluaran, True = Pemasukan
  String _selectedCategory = '';
  
  // OCR Scanner Animation States
  bool _showScanner = false;
  bool _isScanning = false;
  Timer? _scanTimer;
  late AnimationController _animationController;
  File? _scannedImageFile;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  // Camera State
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitializing = false;
  FlashMode _flashMode = FlashMode.off;

  final List<Map<String, String>> _expenseCategories = [
    {'name': 'Makanan', 'emoji': '🍔'},
    {'name': 'Transportasi', 'emoji': '🚗'},
    {'name': 'Belanja', 'emoji': '🛒'},
    {'name': 'Tagihan', 'emoji': '🧾'},
    {'name': 'Hiburan', 'emoji': '🎬'},
    {'name': 'Kesehatan', 'emoji': '💊'},
  ];

  final List<Map<String, String>> _incomeCategories = [
    {'name': 'Gaji', 'emoji': '💰'},
    {'name': 'Bonus', 'emoji': '🎁'},
    {'name': 'Tabungan', 'emoji': '🐷'},
    {'name': 'Lainnya', 'emoji': '🪙'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Default selected category
    _selectedCategory = '🍔 Makanan';
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _amountController.dispose();
    _scanTimer?.cancel();
    _animationController.dispose();
    _ocrService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed before we are initialized or if camera isn't active
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _onToggleType(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      // Reset selected category to the first one in the new list
      _selectedCategory = isIncome
          ? '${_incomeCategories[0]['emoji']} ${_incomeCategories[0]['name']}'
          : '${_expenseCategories[0]['emoji']} ${_expenseCategories[0]['name']}';
    });
  }

  // Currency Auto-Formatter logic
  void _onAmountChanged(String val) {
    if (val.isEmpty) return;
    
    // Clean non-digits
    final cleanString = val.replaceAll(RegExp(r'\D'), '');
    if (cleanString.isEmpty) {
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }

    final doubleValue = double.parse(cleanString);
    final formatted = _formatNumberToIndonesian(doubleValue);
    
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumberToIndonesian(double amount) {
    final value = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = value.length - 1; i >= 0; i--) {
      buffer.write(value[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      // Extract the name part of the category (e.g. from "🍔 Makanan" to "Makanan")
      final parts = _selectedCategory.split(' ');
      title = parts.length > 1 ? parts.skip(1).join(' ') : _selectedCategory;
    }
    final cleanAmount = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(cleanAmount) ?? 0.0;
    
    if (amount <= 0) {
      CustomToast.showWarning(
        context,
        'Nominal harus lebih dari 0',
      );
      return;
    }

    final newTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: _selectedCategory,
      amount: amount,
      isIncome: _isIncome,
      date: DateTime.now(),
    );

    await _transactionService.addTransaction(newTx);
    HapticFeedback.lightImpact();
    
    if (mounted) {
      CustomToast.showSuccess(
        context,
        'Transaksi "${newTx.title}" disimpan!',
      );
      
      // Reset Form
      _titleController.clear();
      _amountController.clear();
      
      widget.onTransactionSaved();
    }
  }

  Future<void> _checkPermissionsAndStartCamera() async {
    final cameraStatus = await Permission.camera.status;
    final photoStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;
    
    bool hasCamera = cameraStatus.isGranted;
    bool hasPhotos = photoStatus.isGranted || storageStatus.isGranted;
    
    if (!hasCamera || !hasPhotos) {
      if (mounted) {
        final result = await [
          Permission.camera,
          Permission.photos,
          Permission.storage,
        ].request();
        
        hasCamera = result[Permission.camera]?.isGranted ?? false;
        hasPhotos = (result[Permission.photos]?.isGranted ?? false) || 
                    (result[Permission.storage]?.isGranted ?? false);
        
        if (!hasCamera && !hasPhotos) {
          if (mounted) {
            _showPermissionDeniedDialog();
          }
          return;
        }
      }
    }
    
    setState(() {
      _showScanner = true;
      _scannedImageFile = null;
      _isScanning = false;
    });
    
    if (hasCamera) {
      _initializeCamera();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
          title: Text(
            'Akses Ditolak',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Uangku memerlukan izin kamera dan galeri untuk memindai struk. Harap aktifkan di Pengaturan Sistem.',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitializing) return;
    setState(() {
      _isCameraInitializing = true;
    });
    
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isCameraInitializing = false;
        });
        return;
      }
      
      final backCamera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      
      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      _cameraController = controller;
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    
    HapticFeedback.lightImpact();
    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _takePictureAndProcess() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      CustomToast.showWarning(context, 'Kamera belum siap');
      return;
    }
    
    if (controller.value.isTakingPicture) return;
    HapticFeedback.mediumImpact();
    
    try {
      final XFile image = await controller.takePicture();
      final imageFile = File(image.path);
      
      setState(() {
        _scannedImageFile = imageFile;
        _isScanning = true;
      });
      
      await _cameraController?.dispose();
      _cameraController = null;
      
      _processReceiptImage(imageFile);
    } catch (e) {
      if (mounted) {
        CustomToast.showWarning(context, 'Gagal mengambil foto: $e');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (image == null) return;
      
      final imageFile = File(image.path);
      
      await _cameraController?.dispose();
      _cameraController = null;
      
      setState(() {
        _scannedImageFile = imageFile;
        _showScanner = true;
        _isScanning = true;
      });
      
      _processReceiptImage(imageFile);
    } catch (e) {
      if (mounted) {
        CustomToast.showWarning(context, 'Gagal memilih gambar dari galeri: $e');
      }
    }
  }

  void _closeScanner() {
    _scanTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
    setState(() {
      _showScanner = false;
      _isScanning = false;
      _scannedImageFile = null;
      _isCameraInitializing = false;
    });
  }

  Future<void> _processReceiptImage(File imageFile) async {
    try {
      final ocrResult = await _ocrService.scanReceipt(imageFile);
      
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      
      setState(() {
        _showScanner = false;
        _isScanning = false;
        _scannedImageFile = null;
        
        if (ocrResult.title.isNotEmpty) {
          _titleController.text = ocrResult.title;
        } else {
          _titleController.text = 'Struk Belanja';
        }
        
        if (ocrResult.amount > 0) {
          _amountController.text = _formatNumberToIndonesian(ocrResult.amount);
        } else {
          _amountController.text = '';
        }
        
        _isIncome = ocrResult.isIncome;
        _selectedCategory = ocrResult.category;
      });

      CustomToast.showSuccess(
        context,
        '📸 OCR Struk Belanja Berhasil! Data diisi otomatis.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _showScanner = false;
        _isScanning = false;
        _scannedImageFile = null;
      });
      CustomToast.showWarning(
        context,
        'Gagal memproses struk belanja: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = _isIncome ? _incomeCategories : _expenseCategories;
    final activeColor = _isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Stack(
            children: [
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 40.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grabber
                        Center(
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Header Title & Cancel Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tambah Transaksi',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Expense / Income Toggle Switch
                        _buildToggleSwitch(isDark),
                        const SizedBox(height: 20),

                        // Amount Input Card
                        _buildAmountCard(isDark, theme),
                        const SizedBox(height: 20),

                        // Title Input
                        Text(
                          'Nama Transaksi (Opsional)',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: _isIncome ? 'Misal: Gaji Pokok' : 'Misal: Makan Ramen',
                            prefixIcon: Icon(
                              Icons.edit_note_rounded,
                              color: activeColor.withValues(alpha: 0.7),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.03),
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                                  : AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.05),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: activeColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Category Selector Label
                        Text(
                          'Pilih Kategori',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Category Emojis Grid
                        _buildCategoryGrid(categories, isDark),
                        const SizedBox(height: 28),

                        // Action buttons (Save & Scan Struk)
                        Row(
                          children: [
                            // Scan receipt button
                            Expanded(
                              flex: 2,
                              child: OutlinedButton(
                                onPressed: _checkPermissionsAndStartCamera,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(
                                    color: activeColor.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_rounded, color: activeColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Scan Struk',
                                      style: TextStyle(color: activeColor, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Save Button
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                onPressed: _saveTransaction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeColor,
                                  foregroundColor: Colors.white,
                                  shadowColor: activeColor.withValues(alpha: 0.4),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // OCR Scan Camera Overlay Mode
              if (_showScanner) _buildCameraOverlay(isDark, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(bool isDark) {
    final trackColor = isDark ? AppColors.fillTrackDark : AppColors.fillTrack;
    final activePillColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white;
    final inactiveTextColor = isDark ? AppColors.labelTertiaryDark : AppColors.labelTertiary;
    
    final selectedIndex = _isIncome ? 1 : 0;
    final double alignX = selectedIndex == 0 ? -1.0 : 1.0;
    
    return Container(
      width: double.infinity,
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Active sliding pill
          AnimatedAlign(
            alignment: Alignment(alignX, 0.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: activePillColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Interactive Text Labels Row
          Row(
            children: [
              // Pengeluaran Tab
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isIncome) {
                      HapticFeedback.lightImpact();
                      _onToggleType(false);
                    }
                  },
                  child: Center(
                    child: Text(
                      'Pengeluaran 💸',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selectedIndex == 0 ? FontWeight.w600 : FontWeight.w400,
                        color: selectedIndex == 0 
                            ? AppColors.expenseRed 
                            : inactiveTextColor,
                      ),
                    ),
                  ),
                ),
              ),
              // Pemasukan Tab
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_isIncome) {
                      HapticFeedback.lightImpact();
                      _onToggleType(true);
                    }
                  },
                  child: Center(
                    child: Text(
                      'Pemasukan 💰',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selectedIndex == 1 ? FontWeight.w600 : FontWeight.w400,
                        color: selectedIndex == 1 
                            ? AppColors.incomeGreen 
                            : inactiveTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(bool isDark, ThemeData theme) {
    final cardColor = _isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.12),
            cardColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.20),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'NOMINAL (${_isIncome ? 'PEMASUKAN' : 'PENGELUARAN'})',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: cardColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rp',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: _onAmountChanged,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    if (value == null || value.replaceAll('.', '').isEmpty) {
                      return 'Nominal tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<Map<String, String>> categories, bool isDark) {
    final trackColor = isDark ? AppColors.fillTrackDark : AppColors.fillTrack;
    final activeColor = _isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.3,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final label = '${cat['emoji']} ${cat['name']}';
        final isSelected = _selectedCategory == label;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedCategory = label;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : trackColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cat['emoji']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cat['name']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? activeColor
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraOverlay(bool isDark, ThemeData theme) {
    final activeColor = _isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // 1. Camera preview or image preview
            if (_scannedImageFile != null)
              Positioned.fill(
                child: Image.file(
                  _scannedImageFile!,
                  fit: BoxFit.cover,
                ),
              )
            else if (_cameraController != null && _cameraController!.value.isInitialized)
              Positioned.fill(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: _isCameraInitializing
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Membuka kamera...',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_rounded, color: Colors.white30, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'Kamera tidak tersedia',
                                style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Gunakan tombol di kanan atas untuk memuat dari galeri',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
              ),

            // 2. Viewfinder cutout overlay
            if (_scannedImageFile == null)
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.55),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 280,
                          height: 380,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Viewfinder borders and pulsing laser animation
            if (_scannedImageFile == null)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 280,
                  height: 380,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        if (_cameraController != null && _cameraController!.value.isInitialized)
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Positioned(
                                top: _animationController.value * 370,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: activeColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // 4. Viewfinder Corners decoration (high tech)
            if (_scannedImageFile == null)
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 280,
                  height: 380,
                  child: Stack(
                    children: [
                      // Top Left
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: activeColor, width: 4),
                              left: BorderSide(color: activeColor, width: 4),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // Top Right
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: activeColor, width: 4),
                              right: BorderSide(color: activeColor, width: 4),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // Bottom Left
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: activeColor, width: 4),
                              left: BorderSide(color: activeColor, width: 4),
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      // Bottom Right
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: activeColor, width: 4),
                              right: BorderSide(color: activeColor, width: 4),
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 5. OCR Scanning overlay (laser + text)
            if (_isScanning)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Membaca Data Struk...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mengekstrak nominal & kategori belanja',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 6. Header/Top Bar (glassmorphic gradient)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 16,
                  left: 8,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                      onPressed: _closeScanner,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Scan Struk',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    if (_cameraController != null && _cameraController!.value.isInitialized && _scannedImageFile == null)
                      IconButton(
                        icon: Icon(
                          _flashMode == FlashMode.torch
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: _flashMode == FlashMode.torch
                              ? Colors.amber
                              : Colors.white,
                          size: 24,
                        ),
                        onPressed: _toggleFlash,
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Masukkan Gambar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 7. Bottom Controls (Shutter & Instruction)
            if (_scannedImageFile == null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(
                    bottom: 36,
                    top: 24,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Arahkan struk belanja ke dalam bingkai untuk memindai nominal secara otomatis',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_cameraController != null && _cameraController!.value.isInitialized)
                        GestureDetector(
                          onTap: _isScanning ? null : _takePictureAndProcess,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.white10,
                            ),
                            child: Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
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
    );
  }
}


