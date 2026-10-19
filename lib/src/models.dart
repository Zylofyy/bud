import 'format.dart';

/// Name given to an expense logged without a description.
const unnamedExpense = 'Expense';

class Expense {
  const Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
  });

  // Saves from 0.1.0 also hold a 'cat' key, which is ignored.
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
  );

  final int id;
  final String name;
  final double amount;

  /// Local calendar date (midnight).
  final DateTime date;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'date': isoDate(date),
  };
}

/// What the New Expense sheet asks the store to add.
typedef ExpenseDraft = ({String name, double amount, DateTime date});
