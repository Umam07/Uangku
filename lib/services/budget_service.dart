import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'transaction_service.dart';

class BudgetService {
  static const String _keyBudgets = 'user_category_budgets';
  static const String _keyGlobalBudgetEnabled = 'global_budget_enabled';

  // Singleton instance
  static final BudgetService _instance = BudgetService._internal();
  factory BudgetService() => _instance;
  BudgetService._internal();

  final TransactionService _txService = TransactionService();

  /// Checks if global budgeting is enabled
  Future<bool> isGlobalBudgetEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGlobalBudgetEnabled) ?? false;
  }

  /// Sets global budgeting enabled state
  Future<void> setGlobalBudgetEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGlobalBudgetEnabled, enabled);
  }

  /// Gets all category budget limits
  Future<Map<String, double>> getBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyBudgets);
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> decoded = json.decode(jsonStr);
      return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  /// Gets budget limit for a single category
  Future<double?> getBudgetForCategory(String category) async {
    final budgets = await getBudgets();
    return budgets[category];
  }

  /// Sets budget limit for a single category
  Future<void> setBudget(String category, double limit) async {
    final budgets = await getBudgets();
    budgets[category] = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBudgets, json.encode(budgets));
  }

  /// Deletes budget limit for a single category
  Future<void> deleteBudget(String category) async {
    final budgets = await getBudgets();
    budgets.remove(category);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBudgets, json.encode(budgets));
  }

  /// Calculates spending for the current month per category
  Future<Map<String, double>> getCurrentMonthSpendingByCategory() async {
    final txs = await _txService.getTransactions();
    final now = DateTime.now();
    final Map<String, double> spending = {};

    for (var tx in txs) {
      if (!tx.isIncome && tx.date.year == now.year && tx.date.month == now.month) {
        spending[tx.category] = (spending[tx.category] ?? 0.0) + tx.amount;
      }
    }
    return spending;
  }
}
