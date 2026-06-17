import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/transaction_service.dart';
import 'widgets/custom_toast.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TransactionService _transactionService = TransactionService();
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _filterOptionsData = [
    {'name': 'Semua', 'emoji': '🔍', 'color': AppColors.primary},
    {'name': 'Pemasukan', 'emoji': '💰', 'color': AppColors.incomeGreen},
    {'name': 'Pengeluaran', 'emoji': '💸', 'color': AppColors.expenseRed},
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final txs = await _transactionService.getTransactions();
    setState(() {
      _allTransactions = txs;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Transaction> results = List.from(_allTransactions);

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      results = results
          .where(
            (tx) => tx.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Filter by transaction type
    if (_selectedFilter == 'Pemasukan') {
      results = results.where((tx) => tx.isIncome).toList();
    } else if (_selectedFilter == 'Pengeluaran') {
      results = results.where((tx) => !tx.isIncome).toList();
    }

    setState(() {
      _filteredTransactions = results;
    });
  }

  Map<String, dynamic> get _activeFilterData {
    return _filterOptionsData.firstWhere(
      (filter) => filter['name'] == _selectedFilter,
      orElse: () => _filterOptionsData[0],
    );
  }

  void _showFilterBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Transaksi',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filterOptionsData.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final opt = _filterOptionsData[index];
                      final optName = opt['name'] as String;
                      final optEmoji = opt['emoji'] as String;
                      final optColor = opt['color'] as Color;
                      final isSelected = _selectedFilter == optName;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = optName;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.05)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? optColor.withValues(alpha: 0.15)
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(alpha: 0.04)),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: optName == 'Semua'
                                      ? Icon(
                                          Icons.tune_rounded,
                                          size: 16,
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark
                                                  ? Colors.white70
                                                  : Colors.black54),
                                        )
                                      : Text(
                                          optEmoji,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  optName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimary)
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? Colors.white30
                                            : Colors.black12),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteTransaction(Transaction tx) async {
    // Perform Delete
    await _transactionService.deleteTransaction(tx.id);

    setState(() {
      _allTransactions.remove(tx);
      _applyFilters();
    });

    if (!mounted) return;

    CustomToast.showSuccess(
      context,
      '"${tx.title}" dihapus',
      actionLabel: 'Batal',
      onActionPressed: () async {
        // Restore transaction
        await _transactionService.addTransaction(tx);
        // Re-load list (to place it correctly)
        _loadTransactions();
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(
    List<Transaction> txs,
  ) {
    final Map<String, List<Transaction>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var tx in txs) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String dateString;

      if (txDate == today) {
        dateString = 'Hari Ini';
      } else if (txDate == yesterday) {
        dateString = 'Kemarin';
      } else {
        dateString = _formatDate(tx.date);
      }

      if (!groups.containsKey(dateString)) {
        groups[dateString] = [];
      }
      groups[dateString]!.add(tx);
    }
    return groups;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final groupedMap = _groupTransactionsByDate(_filteredTransactions);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Search Header (Padded to match page style)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Modern Pill Dropdown Trigger (Padded to match Search Bar alignment)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Dropdown button pill
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _activeFilterData['color'].withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeFilterData['color'].withValues(
                            alpha: 0.35,
                          ),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _activeFilterData['color'].withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedFilter != 'Semua') ...[
                            // Emoji circle avatar
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _activeFilterData['color'].withValues(
                                  alpha: 0.25,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _activeFilterData['emoji'] as String,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Filter Name
                          Text(
                            _selectedFilter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _activeFilterData['color'] as Color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: _activeFilterData['color'] as Color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Transaction List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _filteredTransactions.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada transaksi ditemukan',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Coba cari dengan kata kunci lain\natau ganti filter kategori.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          100,
                        ), // Space for floating navbar
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: groupedMap.keys.length,
                        itemBuilder: (context, groupIndex) {
                          final dateKey = groupedMap.keys.elementAt(groupIndex);
                          final txList = groupedMap[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Header
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  top: 18,
                                  bottom: 8,
                                ),
                                child: Text(
                                  dateKey,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              // Transactions under this date
                              ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: txList.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, txIndex) {
                                  final tx = txList[txIndex];
                                  final isIncome = tx.isIncome;
                                  final emoji = tx.category.split(' ').first;
                                  final catName = tx.category.split(' ').skip(1).join(' ');

                                  return Dismissible(
                                    key: Key(tx.id),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) =>
                                        _deleteTransaction(tx),
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.expenseRed,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.delete_sweep_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceDark
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: isDark ? 0.05 : 0.02,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Category Emoji Circle 40x40 with low-opacity pastel background
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isIncome
                                                  ? AppColors.incomeGreen.withValues(
                                                      alpha: 0.12,
                                                    )
                                                  : AppColors.expenseRed.withValues(
                                                      alpha: 0.08,
                                                    ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                emoji,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // Title & Subtitle
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tx.title,
                                                  style: theme
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isDark
                                                            ? AppColors
                                                                  .textPrimaryDark
                                                            : AppColors
                                                                  .textPrimary,
                                                      ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  catName,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontSize: 12,
                                                        color: isDark
                                                            ? AppColors
                                                                  .textSecondaryDark
                                                            : AppColors
                                                                  .textSecondary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Amount with tabular figures
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${isIncome ? '+' : '-'}${_formatCurrency(tx.amount).replaceFirst('Rp ', '')}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isIncome
                                                      ? AppColors.incomeGreen
                                                      : AppColors.expenseRed,
                                                  fontFeatures: const [FontFeature.tabularFigures()],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
