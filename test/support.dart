import 'package:bud/src/budget_store.dart';
import 'package:bud/src/models.dart';

/// The design's sample month, viewed on 12 Oct 2026.
final today = DateTime(2026, 10, 12);

final sampleExpenses = [
  Expense(
    id: 1,
    name: 'Rent share',
    category: 'Housing',
    amount: 900,
    date: DateTime(2026, 10, 1),
  ),
  Expense(
    id: 2,
    name: 'Phone plan',
    category: 'Bills',
    amount: 35,
    date: DateTime(2026, 10, 3),
  ),
  Expense(
    id: 3,
    name: 'Electricity & internet',
    category: 'Bills',
    amount: 142.75,
    date: DateTime(2026, 10, 5),
  ),
  Expense(
    id: 4,
    name: 'Concert tickets',
    category: 'Fun',
    amount: 120,
    date: DateTime(2026, 10, 7),
  ),
  Expense(
    id: 5,
    name: 'Transit card top-up',
    category: 'Transport',
    amount: 30,
    date: DateTime(2026, 10, 9),
  ),
  Expense(
    id: 6,
    name: 'Dinner with friends',
    category: 'Food',
    amount: 64.2,
    date: DateTime(2026, 10, 10),
  ),
  Expense(
    id: 7,
    name: 'Groceries',
    category: 'Food',
    amount: 86.4,
    date: DateTime(2026, 10, 11),
  ),
  Expense(
    id: 8,
    name: 'Coffee',
    category: 'Food',
    amount: 5.8,
    date: DateTime(2026, 10, 12),
  ),
];

class MemoryStorage implements BudgetStorage {
  MemoryStorage({this.budget, List<Expense> expenses = const []})
    : expenses = List.of(expenses);

  double? budget;
  List<Expense> expenses;
  int writes = 0;

  @override
  Future<StoredBudget> read() async =>
      (budget: budget, expenses: List.of(expenses));

  @override
  Future<void> write(double budget, List<Expense> expenses) async {
    this.budget = budget;
    this.expenses = List.of(expenses);
    writes++;
  }
}
