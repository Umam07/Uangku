import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  final String id;
  final String title;
  final String category; // Format: "🍔 Makanan"
  final double amount;
  final bool isIncome;
  final DateTime date;
  final String note;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        category: json['category'],
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'],
        date: DateTime.parse(json['date']),
        note: json['note'] ?? '',
      );
}

class TransactionService {
  static const String _keyTransactions = 'user_transactions';

  // Singleton instance
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // Get all transactions
  Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? txJson = prefs.getString(_keyTransactions);
    
    if (txJson == null) {
      // Pre-populate with default data
      final defaultList = _getDefaultTransactions();
      await saveTransactions(defaultList);
      return defaultList;
    }

    try {
      final List<dynamic> decoded = json.decode(txJson);
      final list = decoded.map((item) => Transaction.fromJson(item)).toList();
      
      // Auto-inject last year's historical data for comparison if missing
      final now = DateTime.now();
      final hasLastYear = list.any((tx) => tx.date.year == now.year - 1);
      if (!hasLastYear) {
        final defaults = _getDefaultTransactions();
        final historical = defaults.where((tx) => 
          tx.date.year == now.year - 1 || 
          (tx.date.year == now.year && tx.date.month < now.month)
        );
        list.addAll(historical);
        await saveTransactions(list);
      }
      
      return list;
    } catch (e) {
      // Reset if corruption occurs
      return [];
    }
  }

  // Save all transactions
  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(transactions.map((tx) => tx.toJson()).toList());
    await prefs.setString(_keyTransactions, encoded);
  }

  // Add a transaction
  Future<void> addTransaction(Transaction tx) async {
    final list = await getTransactions();
    // Add to the front of the list so it appears as the newest
    list.insert(0, tx);
    await saveTransactions(list);
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    final list = await getTransactions();
    list.removeWhere((tx) => tx.id == id);
    await saveTransactions(list);
  }

  // Update a transaction (by id)
  Future<void> updateTransaction(Transaction updatedTx) async {
    final list = await getTransactions();
    final index = list.indexWhere((tx) => tx.id == updatedTx.id);
    if (index != -1) {
      list[index] = updatedTx;
      await saveTransactions(list);
    }
  }

  // Generate default initial transactions
  List<Transaction> _getDefaultTransactions() {
    final now = DateTime.now();
    final List<Transaction> list = [];

    // 1. Current month's recent transactions
    list.addAll([
      Transaction(
        id: 'tx_c1',
        title: 'Makan Siang Ramen',
        category: '🍔 Makanan',
        amount: 75000,
        isIncome: false,
        date: now.subtract(const Duration(minutes: 30)),
      ),
      Transaction(
        id: 'tx_c2',
        title: 'Grab Car Ongkos',
        category: '🚗 Transportasi',
        amount: 45000,
        isIncome: false,
        date: now.subtract(const Duration(hours: 4)),
      ),
      Transaction(
        id: 'tx_c3',
        title: 'Gaji Bulanan',
        category: '💰 Gaji',
        amount: 15000000,
        isIncome: true,
        date: now.subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: 'tx_c4',
        title: 'Supermarket Bulanan',
        category: '🛒 Belanja',
        amount: 430000,
        isIncome: false,
        date: now.subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: 'tx_c5',
        title: 'Bayar Tagihan Listrik',
        category: '🧾 Tagihan',
        amount: 150000,
        isIncome: false,
        date: now.subtract(const Duration(days: 3)),
      ),
    ]);

    // 2. Procedural transactions for earlier months of the current year (months 1 to currentMonth - 1)
    final currentYear = now.year;
    for (int month = 1; month < now.month; month++) {
      final baseDate = DateTime(currentYear, month, 15);
      
      // Income
      list.add(Transaction(
        id: 'tx_${currentYear}_${month}_inc',
        title: 'Gaji Bulanan',
        category: '💰 Gaji',
        amount: 15000000,
        isIncome: true,
        date: baseDate,
      ));

      // Expenses
      list.add(Transaction(
        id: 'tx_${currentYear}_${month}_exp1',
        title: 'Belanja Bulanan',
        category: '🛒 Belanja',
        amount: 8000000 + (month % 3) * 500000,
        isIncome: false,
        date: baseDate.add(const Duration(days: 2)),
      ));

      list.add(Transaction(
        id: 'tx_${currentYear}_${month}_exp2',
        title: 'Bayar Tagihan',
        category: '🧾 Tagihan',
        amount: 1200000 + (month % 2) * 200000,
        isIncome: false,
        date: baseDate.subtract(const Duration(days: 5)),
      ));

      list.add(Transaction(
        id: 'tx_${currentYear}_${month}_exp3',
        title: 'Kulineran',
        category: '🍔 Makanan',
        amount: 800000 + (month % 4) * 100000,
        isIncome: false,
        date: baseDate.add(const Duration(days: 4)),
      ));
    }

    // 3. Procedural transactions for last year (2025, months 1 to 12)
    final lastYear = currentYear - 1;
    for (int month = 1; month <= 12; month++) {
      final baseDate = DateTime(lastYear, month, 15);

      // Income
      list.add(Transaction(
        id: 'tx_${lastYear}_${month}_inc',
        title: 'Gaji Bulanan',
        category: '💰 Gaji',
        amount: 12000000,
        isIncome: true,
        date: baseDate,
      ));

      // Expenses
      list.add(Transaction(
        id: 'tx_${lastYear}_${month}_exp1',
        title: 'Belanja Bulanan',
        category: '🛒 Belanja',
        amount: 7000000 + (month % 3) * 400000,
        isIncome: false,
        date: baseDate.add(const Duration(days: 2)),
      ));

      list.add(Transaction(
        id: 'tx_${lastYear}_${month}_exp2',
        title: 'Bayar Tagihan',
        category: '🧾 Tagihan',
        amount: 1000000 + (month % 2) * 150000,
        isIncome: false,
        date: baseDate.subtract(const Duration(days: 5)),
      ));
    }

    return list;
  }
}
