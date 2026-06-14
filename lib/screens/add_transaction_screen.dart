import 'dart:async';
import 'package:flutter/material.dart';
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
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi "${newTx.title}" disimpan!'),
          backgroundColor: AppColors.accent,
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
    setState(() {
      _showScanner = true;
      _isScanning = false;
    });
  }

  void _triggerScanProcess() {
    setState(() {
      _isScanning = true;
    });

    // Simulate OCR Reading for 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tambah Transaksi',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Main Input Form
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0), // Space for floating navbar
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expense / Income Toggle Switch
                    _buildToggleSwitch(isDark),
                    const SizedBox(height: 24),

                    // Amount Input Card
                    _buildAmountCard(isDark, theme),
                    const SizedBox(height: 24),

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
                    const SizedBox(height: 24),

                    // Category Selector Label
                    Text(
                      'Pilih Kategori',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Category Emojis Grid
                    _buildCategoryGrid(categories, isDark),
                    const SizedBox(height: 32),

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
                                borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _buildToggleSwitch(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Expense Switch Tab
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggleType(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: !_isIncome ? AppColors.danger : Colors.transparent,
                  boxShadow: !_isIncome
                      ? [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pengeluaran 💸',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !_isIncome ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          // Income Switch Tab
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggleType(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _isIncome ? AppColors.accent : Colors.transparent,
                  boxShadow: _isIncome
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Pemasukan 💰',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isIncome ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(bool isDark, ThemeData theme) {
    final cardColor = _isIncome ? AppColors.accent : AppColors.danger;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final label = '${cat['emoji']} ${cat['name']}';
        final isSelected = _selectedCategory == label;
        final selectedColor = _isIncome ? AppColors.accent : AppColors.danger;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = label;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? Colors.white24 : Colors.black12),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: selectedColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
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
                  Text(
                    cat['name']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
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
                border: Border.all(color: AppColors.accent, width: 2),
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
                              SizedBox(height: 12),
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
                                color: AppColors.accent,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.8),
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
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
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


