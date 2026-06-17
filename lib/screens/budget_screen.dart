import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/budget_service.dart';
import 'widgets/custom_toast.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();
  bool _isGlobalEnabled = false;
  Map<String, double> _budgets = {};
  Map<String, double> _spending = {};
  bool _isLoading = true;

  final List<Map<String, String>> _categories = [
    {'name': 'Makanan', 'emoji': '🍔'},
    {'name': 'Belanja', 'emoji': '🛒'},
    {'name': 'Transportasi', 'emoji': '🚗'},
    {'name': 'Tagihan', 'emoji': '🧾'},
    {'name': 'Hiburan', 'emoji': '🎬'},
    {'name': 'Kesehatan', 'emoji': '💊'},
    {'name': 'Tabungan', 'emoji': '🐷'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() => _isLoading = true);
    final isEnabled = await _budgetService.isGlobalBudgetEnabled();
    final budgetLimits = await _budgetService.getBudgets();
    final currentSpending = await _budgetService.getCurrentMonthSpendingByCategory();

    setState(() {
      _isGlobalEnabled = isEnabled;
      _budgets = budgetLimits;
      _spending = currentSpending;
      _isLoading = false;
    });
  }

  Future<void> _toggleGlobalBudget(bool value) async {
    HapticFeedback.mediumImpact();
    await _budgetService.setGlobalBudgetEnabled(value);
    setState(() {
      _isGlobalEnabled = value;
    });
    if (mounted) {
      CustomToast.showSuccess(
        context,
        value ? 'Fitur Anggaran diaktifkan.' : 'Fitur Anggaran dinonaktifkan.',
      );
    }
  }

  double _getCategorySpent(String categoryName) {
    return _spending[categoryName] ?? 0.0;
  }

  double _getCategoryLimit(String categoryName) {
    return _budgets[categoryName] ?? 0.0;
  }

  String _formatCurrency(double amount) {
    final value = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = value.length - 1; i >= 0; i--) {
      buffer.write(value[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return 'Rp $formatted';
  }

  void _showSetLimitBottomSheet(String emoji, String categoryName, String fullCategoryKey) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final currentLimit = _getCategoryLimit(fullCategoryKey);
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toInt().toString() : '',
    );
    final focusNode = FocusNode();

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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pull grabber
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
                  const SizedBox(height: 20),
                  
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atur Anggaran $categoryName',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Batas pengeluaran per bulan',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Text Input
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      if (currentLimit > 0)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger, width: 1.5),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context);
                              await _budgetService.deleteBudget(fullCategoryKey);
                              await _loadBudgetData();
                              if (context.mounted) {
                                CustomToast.showSuccess(context, 'Anggaran $categoryName dihapus.');
                              }
                            },
                            child: const Text(
                              'Hapus Batas',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (currentLimit > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) {
                              CustomToast.showError(context, 'Nominal tidak boleh kosong!');
                              return;
                            }
                            final val = double.tryParse(text);
                            if (val == null || val <= 0) {
                              CustomToast.showError(context, 'Masukkan nominal yang valid!');
                              return;
                            }
                            
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            await _budgetService.setBudget(fullCategoryKey, val);
                            await _loadBudgetData();
                            if (context.mounted) {
                              CustomToast.showSuccess(
                                context,
                                'Anggaran $categoryName disetel ke ${_formatCurrency(val)}.',
                              );
                            }
                          },
                          child: const Text(
                            'Simpan',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
      },
    );
  }

  Color _getProgressColor(double ratio) {
    if (ratio >= 1.0) return AppColors.danger;
    if (ratio >= 0.8) return AppColors.warnOrange;
    return AppColors.accent; // green
  }

  Widget _buildSummaryCard(bool isDark, double totalLimit, double totalSpent) {
    final double ratio = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toInt();
    final remaining = totalLimit - totalSpent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            const Color(0xFFF97316),
            const Color(0xFFEC4899),
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.5),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.transparent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ringkasan Anggaran Bulanan',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$percentage% terpakai',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Remaining money or budget status
                  Text(
                    remaining < 0
                        ? 'Lebih ${_formatCurrency(remaining.abs())}'
                        : 'Sisa ${_formatCurrency(remaining)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'dari limit total ${_formatCurrency(totalLimit)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Elegant linear progress bar
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
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

    // Calculate totals
    double totalLimit = 0.0;
    double totalSpent = 0.0;

    _budgets.forEach((category, limit) {
      if (limit > 0) {
        totalLimit += limit;
        totalSpent += _getCategorySpent(category);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Stack(
        children: [
          // Background Glow
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kelola Anggaran',
                        style: TextStyle(
                          fontSize: 22,
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle Card
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.04 : 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SwitchListTile.adaptive(
                            title: Text(
                              'Aktifkan Fitur Anggaran',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Bantu batasi pengeluaran bulanan Anda.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                            value: _isGlobalEnabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.primary,
                            onChanged: _toggleGlobalBudget,
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        if (_isGlobalEnabled) ...[
                          // Overall Glassmorphic Card
                          if (totalLimit > 0) ...[
                            _buildSummaryCard(isDark, totalLimit, totalSpent),
                            const SizedBox(height: 28),
                          ],

                          // Title List
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'Batas Kategori Pengeluaran',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // List of categories
                          Container(
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
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _categories.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                indent: 68,
                                endIndent: 16,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : AppColors.textSecondary.withValues(alpha: 0.08),
                              ),
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final name = cat['name']!;
                                final emoji = cat['emoji']!;
                                final fullKey = '$emoji $name';
                                
                                final limit = _getCategoryLimit(fullKey);
                                final spent = _getCategorySpent(fullKey);
                                final double ratio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _showSetLimitBottomSheet(emoji, name, fullKey);
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        // Emoji bubble
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: isDark ? 0.12 : 0.06,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Category Detail
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  Text(
                                                    limit > 0
                                                        ? '${_formatCurrency(spent)} / ${_formatCurrency(limit)}'
                                                        : 'Belum diatur',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: limit > 0 ? FontWeight.bold : FontWeight.normal,
                                                      color: limit > 0
                                                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                                                      fontFeatures: const [FontFeature.tabularFigures()],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              if (limit > 0) ...[
                                                // Category limit progress bar
                                                Container(
                                                  height: 6,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: FractionallySizedBox(
                                                    alignment: Alignment.centerLeft,
                                                    widthFactor: ratio,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: _getProgressColor(ratio),
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  ratio >= 1.0
                                                      ? '⚠️ Melewati batas anggaran!'
                                                      : ratio >= 0.8
                                                          ? '⚠️ Mendekati batas anggaran!'
                                                          : 'Sisa ${_formatCurrency(limit - spent)}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: ratio >= 0.8 ? FontWeight.bold : FontWeight.normal,
                                                    color: ratio >= 1.0
                                                        ? AppColors.danger
                                                        : ratio >= 0.8
                                                            ? AppColors.warnOrange
                                                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                                                  ),
                                                ),
                                              ] else ...[
                                                Text(
                                                  'Tap untuk menyetel batas anggaran',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? Colors.white30 : Colors.black26,
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          // Explanatory empty state or placeholder info
                          const SizedBox(height: 40),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.insights_rounded,
                                    size: 64,
                                    color: isDark ? Colors.white24 : Colors.black12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Fitur Anggaran Tidak Aktif',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    'Aktifkan fitur anggaran di atas untuk memantau limit pengeluaran bulanan Anda agar keuangan tetap sehat.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
