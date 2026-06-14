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
      return decoded.map((item) => Transaction.fromJson(item)).toList();
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

  // Generate default initial transactions
  List<Transaction> _getDefaultTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'tx1',
        title: 'Makan Siang Ramen',
        category: '🍔 Makanan',
        amount: 75000,
        isIncome: false,
        date: now.subtract(const Duration(minutes: 30)),
      ),
      Transaction(
        id: 'tx2',
        title: 'Grab Car Ongkos',
        category: '🚗 Transportasi',
        amount: 45000,
        isIncome: false,
        date: now.subtract(const Duration(hours: 4)),
      ),
      Transaction(
        id: 'tx3',
        title: 'Gaji Bulanan',
        category: '💰 Gaji',
        amount: 15000000,
        isIncome: true,
        date: now.subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: 'tx4',
        title: 'Supermarket Bulanan',
        category: '🛒 Belanja',
        amount: 430000,
        isIncome: false,
        date: now.subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: 'tx5',
        title: 'Bayar Tagihan Listrik',
        category: '🧾 Tagihan',
        amount: 150000,
        isIncome: false,
        date: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}
