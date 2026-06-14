import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import 'widgets/app_header.dart';

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

    for (var tx in txs) {
      if (tx.isIncome) {
        income += tx.amount;
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
                  rightActionIcon: _obscureBalance 
                      ? Icons.visibility_off_outlined 
                      : Icons.visibility_outlined,
                  onRightActionPressed: () {
                    setState(() {
                      _obscureBalance = !_obscureBalance;
                    });
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

  Widget _buildBalanceCard(bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFF97316), AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard), // 16
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), // shadow y:2, blur:8, rgba(0,0,0,0.06)
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard - 1.5),
        child: Stack(
          children: [
            // Abstract decorative circles for premium design
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Card Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l), // padding 16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Total Saldo',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _obscureBalance 
                        ? 'Rp ••••••' 
                        : '${_totalBalance < 0 ? '-' : ''}${_formatCurrency(_totalBalance)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Income card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusButton), // 12
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text('💰', style: TextStyle(fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pemasukan',
                                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _obscureBalance ? 'Rp ••••••' : '+ ${_formatCurrency(_totalIncome)}',
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Expense card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusButton), // 12
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text('💸', style: TextStyle(fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pengeluaran',
                                      style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _obscureBalance ? 'Rp ••••••' : '- ${_formatCurrency(_totalExpense)}',
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
          Text(
            'Komposisi Pengeluaran',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
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
    if (_totalExpense == 0) {
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
    return _categoryExpenses.entries.map((entry) {
      final isTouched = idx == _touchedIndex;
      idx++;
      final double radius = isTouched ? 26.0 : 18.0;
      final percentage = (entry.value / _totalExpense) * 100;

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
    if (_categoryExpenses.isEmpty) {
      return Center(
        child: Text(
          'Belum ada pengeluaran',
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
      children: _categoryExpenses.entries.map((entry) {
        final percentage = (entry.value / _totalExpense) * 100;
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
