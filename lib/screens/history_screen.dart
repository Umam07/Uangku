import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/transaction_service.dart';
import 'widgets/custom_toast.dart';

// ─── Daftar kategori (sama dengan AddTransactionScreen) ───────────────────────

const List<Map<String, String>> _kExpenseCategories = [
  {'name': 'Makanan', 'emoji': '🍔'},
  {'name': 'Transportasi', 'emoji': '🚗'},
  {'name': 'Belanja', 'emoji': '🛒'},
  {'name': 'Tagihan', 'emoji': '🧾'},
  {'name': 'Hiburan', 'emoji': '🎬'},
  {'name': 'Kesehatan', 'emoji': '💊'},
];

const List<Map<String, String>> _kIncomeCategories = [
  {'name': 'Gaji', 'emoji': '💰'},
  {'name': 'Bonus', 'emoji': '🎁'},
  {'name': 'Tabungan', 'emoji': '🐷'},
  {'name': 'Lainnya', 'emoji': '🪙'},
];

// ─── History Screen ────────────────────────────────────────────────────────────

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

    if (_searchQuery.isNotEmpty) {
      results = results
          .where(
            (tx) => tx.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

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

  // ─── Filter Bottom Sheet ─────────────────────────────────────────────────────

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

  // ─── Transaction Detail Bottom Sheet ────────────────────────────────────────

  void _showTransactionDetailSheet(Transaction tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = tx.isIncome;
    final accentColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final emoji = tx.category.split(' ').first;
    final catName = tx.category.split(' ').skip(1).join(' ');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Emoji + Type badge
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 34)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isIncome ? '+ Masuk' : '- Keluar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    tx.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Amount
                  Text(
                    '${isIncome ? '+' : '-'}${_formatCurrency(tx.amount).replaceFirst('Rp ', 'Rp ')}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Detail Rows
                  _DetailRow(
                    isDark: isDark,
                    icon: Icons.category_outlined,
                    label: 'Kategori',
                    value: catName,
                  ),
                  _DetailRow(
                    isDark: isDark,
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal',
                    value: _formatDate(tx.date),
                  ),
                  _DetailRow(
                    isDark: isDark,
                    icon: Icons.access_time_rounded,
                    label: 'Waktu',
                    value:
                        '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
                  ),
                  if (tx.note.isNotEmpty)
                    _DetailRow(
                      isDark: isDark,
                      icon: Icons.notes_rounded,
                      label: 'Catatan',
                      value: tx.note,
                    ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Delete Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showDeleteConfirmDialog(tx);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Hapus'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.expenseRed,
                            side: BorderSide(
                              color: AppColors.expenseRed.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Edit Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showEditTransactionSheet(tx);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit Transaksi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Delete Confirm Dialog ───────────────────────────────────────────────────

  void _showDeleteConfirmDialog(Transaction tx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.expenseRed.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: AppColors.expenseRed,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hapus Transaksi?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          '"${tx.title}" akan dihapus secara permanen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteTransaction(tx);
            },
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction tx) async {
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
        await _transactionService.addTransaction(tx);
        _loadTransactions();
      },
    );
  }

  // ─── Edit Transaction Sheet ──────────────────────────────────────────────────

  void _showEditTransactionSheet(Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EditTransactionSheet(
        transaction: tx,
        onSaved: (updated) async {
          await _transactionService.updateTransaction(updated);
          _loadTransactions();
          if (mounted) {
            HapticFeedback.lightImpact();
            CustomToast.showSuccess(
              this.context,
              '✏️ Transaksi berhasil diperbarui!',
            );
          }
        },
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

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

  // ─── Build ────────────────────────────────────────────────────────────────────

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
            // Search Header
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
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05),
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

            // Filter Pill
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
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _activeFilterData['color']
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _activeFilterData['color']
                              .withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedFilter != 'Semua') ...[
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _activeFilterData['color']
                                    .withValues(alpha: 0.25),
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
                  // Hint tap to see detail
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 12,
                          color: isDark
                              ? Colors.white30
                              : Colors.black26,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Tap untuk detail',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                        ),
                      ],
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: groupedMap.keys.length,
                        itemBuilder: (context, groupIndex) {
                          final dateKey =
                              groupedMap.keys.elementAt(groupIndex);
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
                              ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: txList.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, txIndex) {
                                  final tx = txList[txIndex];
                                  return _TransactionCard(
                                    tx: tx,
                                    isDark: isDark,
                                    theme: theme,
                                    formatCurrency: _formatCurrency,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      _showTransactionDetailSheet(tx);
                                    },
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

// ─── Transaction Card (stateless, tap-only, no swipe) ─────────────────────────

class _TransactionCard extends StatelessWidget {
  final Transaction tx;
  final bool isDark;
  final ThemeData theme;
  final String Function(double) formatCurrency;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.tx,
    required this.isDark,
    required this.theme,
    required this.formatCurrency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.isIncome;
    final emoji = tx.category.split(' ').first;
    final catName = tx.category.split(' ').skip(1).join(' ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category Emoji
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
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            // Title & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    catName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Amount & Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${formatCurrency(tx.amount).replaceFirst('Rp ', '')}',
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
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            // Chevron hint
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Row Helper ─────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Transaction Bottom Sheet ────────────────────────────────────────────

class _EditTransactionSheet extends StatefulWidget {
  final Transaction transaction;
  final Future<void> Function(Transaction updated) onSaved;

  const _EditTransactionSheet({
    required this.transaction,
    required this.onSaved,
  });

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late bool _isIncome;
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _isIncome = tx.isIncome;
    _selectedCategory = tx.category;
    _titleController = TextEditingController(text: tx.title);
    _amountController = TextEditingController(
      text: _formatNumberRaw(tx.amount),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatNumberRaw(double amount) {
    final value = amount.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = value.length - 1; i >= 0; i--) {
      buffer.write(value[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return buffer.toString().split('').reversed.join('');
  }

  void _onAmountChanged(String val) {
    if (val.isEmpty) return;
    final clean = val.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }
    final formatted = _formatNumberRaw(double.parse(clean));
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _onToggleType(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      final cats = isIncome ? _kIncomeCategories : _kExpenseCategories;
      _selectedCategory = '${cats[0]['emoji']} ${cats[0]['name']}';
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final clean = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(clean) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    String title = _titleController.text.trim();
    if (title.isEmpty) {
      final parts = _selectedCategory.split(' ');
      title = parts.length > 1 ? parts.skip(1).join(' ') : _selectedCategory;
    }

    setState(() => _isSaving = true);

    final updated = Transaction(
      id: widget.transaction.id,
      title: title,
      category: _selectedCategory,
      amount: amount,
      isIncome: _isIncome,
      date: widget.transaction.date,
      note: widget.transaction.note,
    );

    await widget.onSaved(updated);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = _isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final categories = _isIncome ? _kIncomeCategories : _kExpenseCategories;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
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
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Transaksi',
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
                    const SizedBox(height: 16),

                    // Type Toggle
                    _buildToggleSwitch(isDark),
                    const SizedBox(height: 20),

                    // Amount Card
                    _buildAmountCard(isDark, activeColor),
                    const SizedBox(height: 20),

                    // Title Field
                    Text(
                      'Nama Transaksi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _isIncome
                            ? 'Misal: Gaji Pokok'
                            : 'Misal: Makan Ramen',
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

                    // Category Grid
                    Text(
                      'Pilih Kategori',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryGrid(categories, isDark, activeColor),
                    const SizedBox(height: 28),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(bool isDark) {
    final trackColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF2F2F7);
    final activePill = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white;
    final inactiveText = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);
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
          AnimatedAlign(
            alignment: Alignment(alignX, 0.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: activePill,
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
          Row(
            children: [
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
                        fontWeight: selectedIndex == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedIndex == 0
                            ? AppColors.expenseRed
                            : inactiveText,
                      ),
                    ),
                  ),
                ),
              ),
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
                        fontWeight: selectedIndex == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedIndex == 1
                            ? AppColors.incomeGreen
                            : inactiveText,
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

  Widget _buildAmountCard(bool isDark, Color cardColor) {
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
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
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
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textSecondaryDark.withValues(alpha: 0.4)
                          : AppColors.textSecondary.withValues(alpha: 0.4),
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

  Widget _buildCategoryGrid(
    List<Map<String, String>> categories,
    bool isDark,
    Color activeColor,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final key = '${cat['emoji']} ${cat['name']}';
        final isSelected = _selectedCategory == key;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = key);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat['emoji']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  cat['name']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? activeColor
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
