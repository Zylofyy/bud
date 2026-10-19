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
  int _lastId = 0;

  double get budget => _budget;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  DateTime get today => dateOnly(_clock());

  MonthSummary get thisMonth =>
      MonthSummary.of(_expenses, budget: _budget, today: today);

  /// Expenses to offer for adding again: one per name and amount, most
  /// recently logged first.
  List<Expense> get repeatable {
    final seen = <String>{};
    return [
      for (final e in newestFirst(_expenses))
        if (seen.add('${e.name.toLowerCase()}|${e.amount.toStringAsFixed(2)}'))
          e,
    ];
  }

  void setBudget(double value) {
    _budget = roundCents(value);
    _changed();
  }

  /// Adds every draft in one change; blank names become [unnamedExpense].
  List<Expense> addExpenses(Iterable<ExpenseDraft> drafts) {
    final added = [
      for (final d in drafts)
        Expense(
          id: _nextId(),
          name: d.name.trim().isEmpty ? unnamedExpense : d.name.trim(),
          amount: roundCents(d.amount),
          date: dateOnly(d.date),
        ),
    ];
    if (added.isEmpty) return added;
    _expenses.addAll(added);
    _changed();
    return added;
  }

  Expense addExpense({
    required String name,
    required double amount,
    required DateTime date,
  }) => addExpenses([(name: name, amount: amount, date: date)]).single;

  /// Removes the expenses with [ids] in one change and returns them, so they
  /// can be put back with [restoreExpenses].
  List<Expense> removeExpenses(Iterable<int> ids) {
    final remove = ids.toSet();
    final removed = [
      for (final e in _expenses)
        if (remove.contains(e.id)) e,
    ];
    if (removed.isEmpty) return removed;
    _expenses.removeWhere((e) => remove.contains(e.id));
    _changed();
    return removed;
  }

  /// Puts back expenses taken out by [removeExpenses], keeping their ids.
  void restoreExpenses(Iterable<Expense> expenses) {
    final present = {for (final e in _expenses) e.id};
    final missing = [
      for (final e in expenses)
        if (!present.contains(e.id)) e,
    ];
    if (missing.isEmpty) return;
    _expenses.addAll(missing);
    _changed();
  }

  int _nextId() {
    final now = _clock().microsecondsSinceEpoch;
    final maxId = math.max(
      _lastId,
      _expenses.fold(0, (m, e) => math.max(m, e.id)),
    );
    return _lastId = math.max(now, maxId + 1);
  }

  void _changed() {
    notifyListeners();
    _storage.write(_budget, _expenses).catchError((Object e) {
      debugPrint('Could not save budget: $e');
    });
  }
}

/// Everything the overview shows for the month containing [today].
class MonthSummary {
  MonthSummary._({
    required this.today,
    required this.budget,
    required this.expenses,
    required this.spent,
  });

  factory MonthSummary.of(
    Iterable<Expense> all, {
    required double budget,
    required DateTime today,
  }) {
    final expenses = newestFirst(
      all.where(
        (e) => e.date.year == today.year && e.date.month == today.month,
      ),
    );
    return MonthSummary._(
      today: today,
      budget: budget,
      expenses: expenses,
      spent: roundCents(expenses.fold(0.0, (sum, e) => sum + e.amount)),
    );
  }

  final DateTime today;
  final double budget;

  /// Newest first.
  final List<Expense> expenses;
  final double spent;

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

/// Sorted by date, newest first; the later-logged first within a day.
List<Expense> newestFirst(Iterable<Expense> expenses) =>
    expenses.toList()..sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    });
