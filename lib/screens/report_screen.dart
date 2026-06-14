import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../services/transaction_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TransactionService _transactionService = TransactionService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Mingguan'; // 'Harian', 'Mingguan', 'Bulanan'
  int _touchedPieIndex = -1;

  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _categoryExpenses = {};
  Map<String, int> _categoryTransactionCount = {};

  // YoY Savings & monthly savings trend variables
  double _currentYearSavings = 0;
  double _lastYearSavings = 0;
  double _savingsPercentageChange = 0;
  bool _isSavingsIncreased = true;
  List<double> _monthlySavingsData = List.filled(12, 0.0);
  bool _showSavingsGraph = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final txs = await _transactionService.getTransactions();
    
    // 1. Calculate historical savings data
    final now = DateTime.now();
    final currentYear = now.year;
    final lastYear = currentYear - 1;

    double currentYearIncome = 0;
    double currentYearExpense = 0;
    double lastYearIncome = 0;
    double lastYearExpense = 0;

    final List<double> monthlySavings = List.filled(12, 0.0);

    for (var tx in txs) {
      if (tx.date.year == currentYear) {
        if (tx.isIncome) {
          currentYearIncome += tx.amount;
        } else {
          currentYearExpense += tx.amount;
        }

        final monthIdx = tx.date.month - 1;
        if (monthIdx >= 0 && monthIdx < 12) {
          if (tx.isIncome) {
            monthlySavings[monthIdx] += tx.amount;
          } else {
            monthlySavings[monthIdx] -= tx.amount;
          }
        }
      } else if (tx.date.year == lastYear) {
        if (tx.isIncome) {
          lastYearIncome += tx.amount;
        } else {
          lastYearExpense += tx.amount;
        }
      }
    }

    final currentYearSavings = currentYearIncome - currentYearExpense;
    final lastYearSavings = lastYearIncome - lastYearExpense;

    double percentageChange = 0;
    bool increased = true;

    if (lastYearSavings != 0) {
      percentageChange = ((currentYearSavings - lastYearSavings) / lastYearSavings.abs()) * 100;
      increased = currentYearSavings >= lastYearSavings;
    } else if (currentYearSavings != 0) {
      percentageChange = 100.0;
      increased = currentYearSavings > 0;
    }

    // 2. Filter based on selected period
    final filteredTxs = _filterTransactionsByPeriod(txs);
    
    double income = 0;
    double expense = 0;
    Map<String, double> catExpenses = {};
    Map<String, int> catCounts = {};

    for (var tx in filteredTxs) {
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expense += tx.amount;
        catExpenses[tx.category] = (catExpenses[tx.category] ?? 0) + tx.amount;
        catCounts[tx.category] = (catCounts[tx.category] ?? 0) + 1;
      }
    }

    setState(() {
      _transactions = filteredTxs;
      _totalIncome = income;
      _totalExpense = expense;
      _categoryExpenses = catExpenses;
      _categoryTransactionCount = catCounts;

      _currentYearSavings = currentYearSavings;
      _lastYearSavings = lastYearSavings;
      _savingsPercentageChange = percentageChange.abs();
      _isSavingsIncreased = increased;
      _monthlySavingsData = monthlySavings;
      _isLoading = false;
    });
  }

  List<Transaction> _filterTransactionsByPeriod(List<Transaction> allTxs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_selectedPeriod == 'Harian') {
      // Only today
      return allTxs.where((tx) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        return txDate == today;
      }).toList();
    } else if (_selectedPeriod == 'Mingguan') {
      // Last 7 days
      final sevenDaysAgo = today.subtract(const Duration(days: 6));
      return allTxs.where((tx) => tx.date.isAfter(sevenDaysAgo) || tx.date.isAtSameMomentAs(sevenDaysAgo)).toList();
    } else {
      // Bulanan (this month)
      final startOfMonth = DateTime(now.year, now.month, 1);
      return allTxs.where((tx) => tx.date.isAfter(startOfMonth) || tx.date.isAtSameMomentAs(startOfMonth)).toList();
    }
  }

  Color _getCategoryColor(String category) {
    if (category.contains('🍔') || category.contains('Makanan')) return AppColors.danger;
    if (category.contains('🚗') || category.contains('Transport')) return Colors.blue;
    if (category.contains('🛒') || category.contains('Belanja')) return AppColors.accent;
    if (category.contains('🧾') || category.contains('Tagihan')) return Colors.purple;
    if (category.contains('🎬') || category.contains('Hiburan')) return Colors.pink;
    if (category.contains('💊') || category.contains('Kesehatan')) return Colors.redAccent;
    if (category.contains('🐷') || category.contains('Tabungan')) return Colors.teal;
    return Colors.cyan;
  }

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
    return '${amount < 0 ? '-' : ''}Rp $formatted';
  }

  String _getDayName(int index) {
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final now = DateTime.now();
    // Get correct day of week for the index representing days ago
    final targetDate = now.subtract(Duration(days: 6 - index));
    return days[targetDate.weekday % 7];
  }

  List<BarChartGroupData> _getWeeklyBarGroups() {
    final List<BarChartGroupData> groups = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 6; i >= 0; i--) {
      final targetDate = today.subtract(Duration(days: i));
      double dayExpense = 0;
      double dayIncome = 0;

      for (var tx in _transactions) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        if (txDate == targetDate) {
          if (tx.isIncome) {
            dayIncome += tx.amount;
          } else {
            dayExpense += tx.amount;
          }
        }
      }

      groups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: dayExpense,
              color: AppColors.danger,
              width: 8,
              borderRadius: BorderRadius.circular(3),
            ),
            BarChartRodData(
              toY: dayIncome,
              color: AppColors.accent,
              width: 8,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  String _getMonthNameShort(int index) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (index >= 0 && index < 12) {
      return months[index];
    }
    return '';
  }

  Widget _buildSavingsComparisonCard(bool isDark, ThemeData theme) {
    final now = DateTime.now();
    final currentYear = now.year;
    final lastYear = currentYear - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Perbandingan Tabungan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Graph Toggle Pill
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showSavingsGraph = !_showSavingsGraph;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showSavingsGraph 
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showSavingsGraph ? Icons.show_chart_rounded : Icons.legend_toggle_rounded,
                        size: 14,
                        color: _showSavingsGraph ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showSavingsGraph ? 'Sembunyikan Grafik' : 'Tampilkan Grafik',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _showSavingsGraph ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // This Year savings
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tabungan Tahun Ini ($currentYear)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_currentYearSavings),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _currentYearSavings >= 0 ? AppColors.primary : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              // Separator line
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : Colors.black12,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              // Last Year savings
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tabungan Tahun Lalu ($lastYear)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_lastYearSavings),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Comparison Pill Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performa tabungan:',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isSavingsIncreased 
                          ? Colors.green.withValues(alpha: 0.12)
                          : AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSavingsIncreased 
                              ? Icons.arrow_upward_rounded 
                              : Icons.arrow_downward_rounded,
                          size: 13,
                          color: _isSavingsIncreased ? Colors.green : AppColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_savingsPercentageChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isSavingsIncreased ? Colors.green : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSavingsIncreased ? 'Meningkat' : 'Menurun',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isSavingsIncreased ? Colors.green : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsChart(bool isDark, ThemeData theme) {
    final now = DateTime.now();
    final currentYear = now.year;
    
    final List<FlSpot> spots = [];
    int maxMonth = now.month;
    for (int i = 0; i < maxMonth; i++) {
      spots.add(FlSpot(i.toDouble(), _monthlySavingsData[i]));
    }

    if (spots.isEmpty) return const SizedBox();

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    
    final yRange = (maxY - minY).abs();
    if (yRange == 0) {
      minY = minY - 1000000;
      maxY = maxY + 1000000;
    } else {
      minY = minY - (yRange * 0.15);
      maxY = maxY + (yRange * 0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tren Tabungan Bulanan ($currentYear)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              Text(
                'Dalam Rupiah (IDR)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (maxMonth - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    final isZero = value.abs() < 100;
                    return FlLine(
                      color: isZero 
                          ? (isDark ? Colors.white38 : Colors.black38) 
                          : (isDark ? Colors.white10 : Colors.black12),
                      strokeWidth: isZero ? 1.5 : 0.8,
                      dashArray: isZero ? null : [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            _getMonthNameShort(value.toInt()),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: isDark 
                        ? AppColors.surfaceDark.withValues(alpha: 0.95) 
                        : Colors.white.withValues(alpha: 0.95),
                    tooltipBorder: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final monthStr = _getMonthNameShort(spot.x.toInt());
                        final valStr = _formatCurrency(spot.y);
                        return LineTooltipItem(
                          '$monthStr: $valStr',
                          TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4.5,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Laporan Keuangan',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadReportData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Space for floating navbar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sliding Tab Period Selector
                      _buildPeriodSelector(isDark),
                      const SizedBox(height: 20),

                      // Income & Expense Summary Widget
                      _buildSummaryCards(isDark),
                      const SizedBox(height: 24),

                      // Weekly Bar Chart (only relevant if weekly/monthly selected, let's show weekly trend)
                      if (_selectedPeriod == 'Mingguan') ...[
                        _buildBarChartCard(isDark, theme),
                        const SizedBox(height: 24),
                      ],

                      // Monthly Savings Trend Chart and Comparison (only relevant if Monthly selected)
                      if (_selectedPeriod == 'Bulanan') ...[
                        _buildSavingsComparisonCard(isDark, theme),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: _showSavingsGraph ? _buildSavingsChart(isDark, theme) : const SizedBox(),
                        ),
                      ],

                      // Category breakdown donut chart
                      _buildDonutChartCard(isDark, theme),
                      const SizedBox(height: 24),

                      // Top spending categories list
                      _buildTopCategoriesCard(isDark, theme),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    final periods = ['Harian', 'Mingguan', 'Bulanan'];
    return Container(
      width: double.infinity,
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEFEFF0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadReportData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: isSelected 
                      ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white) 
                      : Colors.transparent,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    final saving = _totalIncome - _totalExpense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
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
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Pemasukan',
                  _totalIncome,
                  AppColors.accent,
                  '💰',
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: isDark ? Colors.white12 : Colors.black12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Pengeluaran',
                  _totalExpense,
                  AppColors.danger,
                  '💸',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sisa Anggaran (Net)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatCurrency(saving),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: saving >= 0 ? Colors.green : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, String icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(icon, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                _formatCurrency(amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartCard(bool isDark, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren Mingguan (Expense vs Income)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: _getWeeklyBarGroups(),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _getDayName(value.toInt()),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChartCard(bool isDark, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribusi Pengeluaran',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _categoryExpenses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Column(
                        children: const [
                          Text('📊', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 8),
                          Text(
                            'Tidak ada pengeluaran\npada periode ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4,
                            centerSpaceRadius: 38,
                            sections: _getPieSections(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPieLegend(isDark)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieSections() {
    int idx = 0;
    return _categoryExpenses.entries.map((entry) {
      final isTouched = idx == _touchedPieIndex;
      idx++;
      final double radius = isTouched ? 24.0 : 16.0;
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

  Widget _buildPieLegend(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _categoryExpenses.entries.map((entry) {
        final percentage = (entry.value / _totalExpense) * 100;
        final color = _getCategoryColor(entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.key} (${percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCategoriesCard(bool isDark, ThemeData theme) {
    final sortedCategories = _categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Kategori Teratas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            sortedCategories.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'Belum ada data belanja.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedCategories.length,
                    separatorBuilder: (context, index) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final item = sortedCategories[index];
                      final category = item.key;
                      final totalAmount = item.value;
                      final txCount = _categoryTransactionCount[category] ?? 0;
                      
                      final emoji = category.split(' ').first;
                      final catName = category.split(' ').skip(1).join(' ');

                      return Row(
                        children: [
                          // Category Avatar Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Category text details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  catName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$txCount Transaksi',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Spent amount
                          Text(
                            _formatCurrency(totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
