import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/transaction_service.dart';

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
  String _selectedCategory = 'Semua';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categoriesData = [
    {'name': 'Semua', 'emoji': '🔍', 'color': AppColors.primary},
    {'name': 'Gaji', 'emoji': '💰', 'color': Colors.green},
    {'name': 'Bonus', 'emoji': '🎁', 'color': Colors.amber},
    {'name': 'Makanan', 'emoji': '🍔', 'color': AppColors.danger},
    {'name': 'Transportasi', 'emoji': '🚗', 'color': Colors.blue},
    {'name': 'Belanja', 'emoji': '🛒', 'color': AppColors.accent},
    {'name': 'Tagihan', 'emoji': '🧾', 'color': Colors.purple},
    {'name': 'Hiburan', 'emoji': '🎬', 'color': Colors.pink},
    {'name': 'Kesehatan', 'emoji': '💊', 'color': Colors.redAccent},
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
          .where((tx) => tx.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Category filter
    if (_selectedCategory != 'Semua') {
      results = results.where((tx) => tx.category.contains(_selectedCategory)).toList();
    }

    setState(() {
      _filteredTransactions = results;
    });
  }

  Future<void> _deleteTransaction(Transaction tx) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Perform Delete
    await _transactionService.deleteTransaction(tx.id);
    
    setState(() {
      _allTransactions.remove(tx);
      _applyFilters();
    });

    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('"${tx.title}" dihapus'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Batal',
          textColor: AppColors.accent,
          onPressed: () async {
            // Restore transaction
            await _transactionService.addTransaction(tx);
            // Re-load list (to place it correctly)
            _loadTransactions();
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> txs) {
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
      appBar: AppBar(
        title: Text(
          'Riwayat Keuangan',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Header (Padded to match page style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
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
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            
            // Premium Category Chips (Spans full width with internal padding)
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _categoriesData.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final cat = _categoriesData[index];
                  final catName = cat['name'] as String;
                  final catEmoji = cat['emoji'] as String;
                  final catColor = cat['color'] as Color;
                  final isSelected = _selectedCategory == catName;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = catName;
                        });
                        _applyFilters();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catColor.withValues(alpha: 0.12)
                              : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? catColor.withValues(alpha: 0.35)
                                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: catColor.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Emoji circular avatar
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? catColor.withValues(alpha: 0.25)
                                    : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  catEmoji,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Category Label
                            Text(
                              catName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected
                                    ? catColor
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Transaction List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Coba cari dengan kata kunci lain\natau ganti filter kategori.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTransactions,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Space for floating navbar
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
                                    padding: const EdgeInsets.only(left: 4, top: 18, bottom: 8),
                                    child: Text(
                                      dateKey,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  // Transactions under this date
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: txList.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                                    itemBuilder: (context, txIndex) {
                                      final tx = txList[txIndex];
                                      final isIncome = tx.isIncome;
                                      final emoji = tx.category.split(' ').first;
                                      final catName = tx.category.split(' ').skip(1).join(' ');

                                      return Dismissible(
                                        key: Key(tx.id),
                                        direction: DismissDirection.endToStart,
                                        onDismissed: (direction) => _deleteTransaction(tx),
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.danger,
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: const Icon(
                                            Icons.delete_sweep_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                            borderRadius: BorderRadius.circular(18),
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
                                              // Category Emoji Circle
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: isIncome
                                                      ? AppColors.accent.withValues(alpha: 0.12)
                                                      : AppColors.danger.withValues(alpha: 0.08),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    emoji,
                                                    style: const TextStyle(fontSize: 20),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              // Title & Subtitle
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
                                              // Amount
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${isIncome ? '+' : '-'}${_formatCurrency(tx.amount).replaceFirst('Rp ', '')}',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: isIncome ? AppColors.accent : AppColors.danger,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.textSecondary,
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
