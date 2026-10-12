import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';
import 'models.dart';
import 'theme.dart';

typedef StoredBudget = ({double? budget, List<Expense> expenses});

abstract interface class BudgetStorage {
  Future<StoredBudget> read();
  Future<void> write(double budget, List<Expense> expenses);
}

class PrefsBudgetStorage implements BudgetStorage {
  PrefsBudgetStorage([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _budgetKey = 'budget';
  static const _expensesKey = 'expenses';

  final SharedPreferencesAsync _prefs;

  @override
  Future<StoredBudget> read() async {
    final budget = await _prefs.getDouble(_budgetKey);
    final raw = await _prefs.getString(_expensesKey);
    var expenses = <Expense>[];
    if (raw != null) {
      try {
        expenses = [
          for (final e in jsonDecode(raw) as List)
            Expense.fromJson(e as Map<String, dynamic>),
        ];
      } on Object catch (e) {
        debugPrint('Ignoring unreadable saved expenses: $e');
      }
    }
    return (budget: budget, expenses: expenses);
  }

  @override
  Future<void> write(double budget, List<Expense> expenses) async {
    await _prefs.setDouble(_budgetKey, budget);
    await _prefs.setString(
      _expensesKey,
      jsonEncode([for (final e in expenses) e.toJson()]),
    );
  }
}

/// The monthly budget and every logged expense, saved on each change.
class BudgetStore extends ChangeNotifier {
  BudgetStore({
    required this._storage,
    this._budget = defaultMonthlyBudget,
    List<Expense> expenses = const [],
    this._clock = DateTime.now,
  }) : _expenses = List.of(expenses);

  static Future<BudgetStore> load(
    BudgetStorage storage, {
    DateTime Function() clock = DateTime.now,
  }) async {
    final saved = await storage.read();
    return BudgetStore(
      storage: storage,
      budget: saved.budget ?? defaultMonthlyBudget,
      expenses: saved.expenses,
      clock: clock,
    );
  }

  final BudgetStorage _storage;
  final DateTime Function() _clock;
  double _budget;
  final List<Expense> _expenses;

  double get budget => _budget;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  DateTime get today => dateOnly(_clock());

  MonthSummary get thisMonth =>
      MonthSummary.of(_expenses, budget: _budget, today: today);

  void setBudget(double value) {
    _budget = roundCents(value);
    _changed();
  }

  Expense addExpense({
    required String name,
    required String category,
    required double amount,
    required DateTime date,
  }) {
    final trimmed = name.trim();
    final expense = Expense(
      id: _nextId(),
      name: trimmed.isEmpty ? category : trimmed,
      category: category,
      amount: roundCents(amount),
      date: dateOnly(date),
    );
    _expenses.add(expense);
    _changed();
    return expense;
  }

  void removeExpense(int id) {
    _expenses.removeWhere((e) => e.id == id);
    _changed();
  }

  int _nextId() {
    final now = _clock().microsecondsSinceEpoch;
    final maxId = _expenses.fold(0, (m, e) => math.max(m, e.id));
    return math.max(now, maxId + 1);
  }

  void _changed() {
    notifyListeners();
    _storage.write(_budget, _expenses).catchError((Object e) {
      debugPrint('Could not save budget: $e');
    });
  }
}

class CategoryTotal {
  const CategoryTotal(this.category, this.total, this.share);

  final Category category;
  final double total;

  /// Percentage of the month's spending, 0–100.
  final double share;

  String get shareLabel => share > 0 && share < 1 ? '<1%' : '${share.round()}%';
}

/// Everything the overview shows for the month containing [today].
class MonthSummary {
  MonthSummary._({
    required this.today,
    required this.budget,
    required this.expenses,
    required this.spent,
    required this.categoryTotals,
  });

  factory MonthSummary.of(
    Iterable<Expense> all, {
    required double budget,
    required DateTime today,
  }) {
    final expenses =
        all
            .where(
              (e) => e.date.year == today.year && e.date.month == today.month,
            )
            .toList()
          ..sort((a, b) {
            final byDate = b.date.compareTo(a.date);
            return byDate != 0 ? byDate : b.id.compareTo(a.id);
          });
    final spent = roundCents(expenses.fold(0.0, (sum, e) => sum + e.amount));
    final totals = <CategoryTotal>[
      for (final c in categories)
        if (_sum(expenses, c.name) case final t when t > 0)
          CategoryTotal(c, t, spent > 0 ? t / spent * 100 : 0),
    ];
    return MonthSummary._(
      today: today,
      budget: budget,
      expenses: expenses,
      spent: spent,
      categoryTotals: totals,
    );
  }

  static double _sum(List<Expense> expenses, String category) => roundCents(
    expenses
        .where((e) => categoryNamed(e.category).name == category)
        .fold(0.0, (sum, e) => sum + e.amount),
  );

  final DateTime today;
  final double budget;

  /// Newest first.
  final List<Expense> expenses;
  final double spent;
  final List<CategoryTotal> categoryTotals;

  DateTime get firstDay => DateTime(today.year, today.month);
  DateTime get lastDay => DateTime(today.year, today.month + 1, 0);

  /// Days remaining in the month, today included.
  int get daysLeft => lastDay.day - today.day + 1;

  double get left => budget - spent;
  bool get isOver => left < 0;

  double get percentUsed =>
      budget > 0 ? spent / budget * 100 : (spent > 0 ? 100 : 0);

  double get dailyAllowance => math.max(0, left) / daysLeft;
}
