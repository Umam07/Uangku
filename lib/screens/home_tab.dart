import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import 'widgets/app_header.dart';
import 'widgets/custom_toast.dart';

/// HomeTab is the dashboard landing page of the Uangku app.
/// Completely polished under iOS HIG guidelines while preserving brand identity.
class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToHistory;
  
  const HomeTab({
    super.key,
    required this.onNavigateToHistory,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final AuthService _authService = AuthService();
  final TransactionService _transactionService = TransactionService();
  Map<String, String>? _userData;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  int _touchedIndex = -1;
  bool _obscureBalance = false;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalBalance = 0;
  Map<String, double> _categoryExpenses = {};
  Map<String, double> _categoryIncomes = {};
  bool _showIncomeChart = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    final txs = await _transactionService.getTransactions();
    
    // Calculations
    double income = 0;
    double expense = 0;
    Map<String, double> catExpenses = {};
    Map<String, double> catIncomes = {};

    for (var tx in txs) {
      if (tx.isIncome) {
        income += tx.amount;
        catIncomes[tx.category] = (catIncomes[tx.category] ?? 0) + tx.amount;
      } else {
        expense += tx.amount;
        catExpenses[tx.category] = (catExpenses[tx.category] ?? 0) + tx.amount;
      }
    }

    setState(() {
      _userData = user;
      _transactions = txs;
      _totalIncome = income;
      _totalExpense = expense;
      _totalBalance = income - expense;
      _categoryExpenses = catExpenses;
      _categoryIncomes = catIncomes;
      _isLoading = false;
    });
  }

  Color _getCategoryColor(String category) {
    if (category.contains('🍔') || category.contains('Makanan')) return AppColors.expenseRed;
    if (category.contains('🚗') || category.contains('Transport')) return AppColors.infoBlue;
    if (category.contains('🛒') || category.contains('Belanja')) return AppColors.warnOrange;
    if (category.contains('🧾') || category.contains('Tagihan')) return Colors.purple;
    if (category.contains('🎬') || category.contains('Hiburan')) return Colors.pink;
    if (category.contains('💊') || category.contains('Kesehatan')) return Colors.redAccent;
    if (category.contains('🐷') || category.contains('Tabungan')) return Colors.teal;
    if (category.contains('💰') || category.contains('Gaji')) return AppColors.incomeGreen;
    if (category.contains('🎁') || category.contains('Bonus')) return Colors.amber;
    return Colors.cyan;
  }

  /// Formats double amount to standard absolute currency string "Rp 150.000"
  String _formatCurrency(double amount) {
    final absAmount = amount.abs();
    final value = absAmount.toStringAsFixed(0);
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

    // Get top 5 transactions for preview
    final recentTransactions = _transactions.take(5).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Outer scroll padding top & bottom to prevent cut-off by notched bottom navbar
            padding: const EdgeInsets.only(top: AppSpacing.s, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar Header
                AppHeader(
                  name: _userData?['name'] ?? "Muhammad Syafi'ul Umam",
                  photoUrl: _userData?['photo'] ?? '',
                  rightActionIcon: Icons.notifications_none_rounded,
                  onRightActionPressed: () {
                    HapticFeedback.lightImpact();
                    CustomToast.showInfo(context, 'Belum ada notifikasi baru');
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.l),

                // Balance Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: _buildBalanceCard(isDark, theme),
                ),
                const SizedBox(height: AppSpacing.l),

                // Donut Chart Composition
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: _buildChartCard(isDark, theme),
                ),
                const SizedBox(height: AppSpacing.l),

                // Recent Transactions Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaksi Terbaru',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      if (_transactions.isNotEmpty)
                        TextButton(
                          onPressed: widget.onNavigateToHistory,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s),

                // Transactions List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: _buildTransactionsList(recentTransactions, isDark, theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatPanel({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark, ThemeData theme) {
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
            // Abstract decorative circles/shapes with blur for mesh gradient effect
            Positioned(
              right: -20,
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
            Positioned(
              right: 60,
              bottom: -80,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.wallet_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Total Saldo',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Uangku Pay',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _obscureBalance = !_obscureBalance;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _obscureBalance 
                                    ? Icons.visibility_off_rounded 
                                    : Icons.visibility_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _obscureBalance 
                        ? 'Rp ••••••' 
                        : '${_totalBalance < 0 ? '-' : ''}${_formatCurrency(_totalBalance)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                      fontFeatures: [FontFeature.tabularFigures()],
                      shadows: [
                        Shadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Income card
                      Expanded(
                        child: _buildGlassStatPanel(
                          title: 'Pemasukan',
                          amount: _obscureBalance ? 'Rp ••••••' : '+ ${_formatCurrency(_totalIncome)}',
                          icon: Icons.arrow_downward_rounded,
                          iconColor: const Color(0xFF34C759),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Expense card
                      Expanded(
                        child: _buildGlassStatPanel(
                          title: 'Pengeluaran',
                          amount: _obscureBalance ? 'Rp ••••••' : '- ${_formatCurrency(_totalExpense)}',
                          icon: Icons.arrow_upward_rounded,
                          iconColor: const Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector(bool isDark) {
    final trackColor = isDark ? AppColors.fillTrackDark : AppColors.fillTrack;
    final activePillColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white;
    final inactiveTextColor = isDark ? AppColors.labelTertiaryDark : AppColors.labelTertiary;
    
    final selectedIndex = _showIncomeChart ? 1 : 0;
    final double alignX = selectedIndex == 0 ? -1.0 : 1.0;
    
    return Container(
      width: 180, // compact width
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(alignX, 0.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: activePillColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_showIncomeChart) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showIncomeChart = false;
                        _touchedIndex = -1;
                      });
                    }
                  },
                  child: Center(
                    child: Text(
                      'Pengeluaran',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                        color: selectedIndex == 0 
                            ? AppColors.expenseRed 
                            : inactiveTextColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_showIncomeChart) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showIncomeChart = true;
                        _touchedIndex = -1;
                      });
                    }
                  },
                  child: Center(
                    child: Text(
                      'Pemasukan',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildChartCard(bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard), // 16
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), // shadow y:2, blur:8, rgba(0,0,0,0.06)
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.l), // padding 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _showIncomeChart ? 'Komposisi Pemasukan' : 'Komposisi Pengeluaran',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildChartTypeSelector(isDark),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Interactive Donut Chart
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: _showingSections(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              
              // Dynamic Legend
              Expanded(
                child: _buildDynamicLegend(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    final total = _showIncomeChart ? _totalIncome : _totalExpense;
    final data = _showIncomeChart ? _categoryIncomes : _categoryExpenses;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.withValues(alpha: 0.3),
          value: 100,
          title: '',
          radius: 20,
        )
      ];
    }

    int idx = 0;
    return data.entries.map((entry) {
      final isTouched = idx == _touchedIndex;
      idx++;
      final double radius = isTouched ? 26.0 : 18.0;
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 10,
        ),
      );
    }).toList();
  }

  Widget _buildDynamicLegend(bool isDark) {
    final total = _showIncomeChart ? _totalIncome : _totalExpense;
    final data = _showIncomeChart ? _categoryIncomes : _categoryExpenses;

    if (data.isEmpty) {
      return Center(
        child: Text(
          _showIncomeChart ? 'Belum ada pemasukan' : 'Belum ada pengeluaran',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        final color = _getCategoryColor(entry.key);
        
        final emoji = entry.key.split(' ').first;
        final catName = entry.key.split(' ').skip(1).join(' ');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                emoji,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      catName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${_formatCurrency(entry.value)} (${percentage.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsList(List<Transaction> recentList, bool isDark, ThemeData theme) {
    if (recentList.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard), // 16
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), // shadow y:2, blur:8, rgba(0,0,0,0.06)
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
        child: Column(
          children: const [
            Text('🪙', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Belum ada transaksi.\nTambahkan transaksi pertama Anda!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = recentList[index];
        final isIncome = tx.isIncome;
        
        // Extract Emoji
        final emoji = tx.category.split(' ').first;
        final catName = tx.category.split(' ').skip(1).join(' ');

        return Container(
          padding: const EdgeInsets.all(AppSpacing.l), // padding 16
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard), // radius 16
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), // shadow y:2, blur:8, rgba(0,0,0,0.06)
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emoji Circle 40x40 with low-opacity pastel background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppColors.incomeGreen.withValues(alpha: 0.12)
                      : AppColors.expenseRed.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name & Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      catName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Nominal with tabular figures and Apple system colors
              Text(
                '${isIncome ? '+' : '-'} ${_formatCurrency(tx.amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
