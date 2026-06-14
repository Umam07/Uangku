import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/transaction_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback onTransactionSaved;

  const AddTransactionScreen({
    super.key,
    required this.onTransactionSaved,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
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
    // Default selected category
    _selectedCategory = '🍔 Makanan';
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _scanTimer?.cancel();
    _animationController.dispose();
    super.dispose();
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
    
    final title = _titleController.text.trim();
    final cleanAmount = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(cleanAmount) ?? 0.0;
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi "${newTx.title}" disimpan!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Reset Form
      _titleController.clear();
      _amountController.clear();
      
      widget.onTransactionSaved();
    }
  }

  // Trigger Mock Camera OCR Scanner
  void _startMockScanner() {
    HapticFeedback.lightImpact();
    setState(() {
      _showScanner = true;
      _isScanning = false;
    });
  }

  void _triggerScanProcess() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isScanning = true;
    });

    // Simulate OCR Reading for 2.5 seconds (satisfies design guide loading <= 5s)
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _showScanner = false;
        _isScanning = false;
        
        // Auto-fill mock receipt content
        _titleController.text = 'Supermarket Indo';
        _amountController.text = '185.000';
        _isIncome = false;
        _selectedCategory = '🛒 Belanja';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 OCR Struk Belanja Berhasil! Data diisi otomatis.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = _isIncome ? _incomeCategories : _expenseCategories;

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
                          'Nama Transaksi',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: _isIncome ? 'Misal: Gaji Pokok' : 'Misal: Makan Ramen',
                            prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama transaksi tidak boleh kosong';
                            }
                            return null;
                          },
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
                                onPressed: _startMockScanner,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Scan Struk',
                                      style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
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
                                child: const Text('Simpan'),
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
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
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
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : trackColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
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
                            ? AppColors.primary
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
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Column(
          children: [
            // Camera top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showScanner = false;
                      });
                    },
                  ),
                  const Text(
                    'Pindai Struk Belanja',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 48), // Spacer
                ],
              ),
            ),

            const Expanded(
              child: SizedBox(),
            ),

            // Camera Viewfinder Screen Area
            Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Mock Receipt Image Drawing
                    Positioned.fill(
                      child: Container(
                        color: Colors.white12,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.receipt_rounded, color: Colors.white38, size: 72),
                              const SizedBox(height: 12),
                              Text(
                                'Arahkan struk belanja\nke dalam bingkai',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Laser scan animation line
                    if (_isScanning)
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
                                color: AppColors.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Loading overlay if scanning
                    if (_isScanning)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Membaca data OCR struk...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ekstraksi item & total belanja',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const Expanded(
              child: SizedBox(),
            ),

            // Camera Controls bottom bar
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isScanning ? null : _triggerScanProcess,
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
          ],
        ),
      ),
    );
  }
}


