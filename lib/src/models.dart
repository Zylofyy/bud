import 'package:flutter/painting.dart';

import 'format.dart';

class Category {
  const Category(this.name, this.color, this.iconPath);

  final String name;
  final Color color;

  /// SVG path data drawn as a stroke in a 24×24 box.
  final String iconPath;
}

const categories = <Category>[
  Category(
    'Housing',
    Color(0xFF5856D6),
    'M3 11 12 3.5 21 11M5.5 9v11h13V9M10 20v-5.5h4V20',
  ),
  Category(
    'Food',
    Color(0xFF34C759),
    'M6 3v5a3 3 0 0 0 6 0V3M9 3v18M18 21V3c-2.2 1.2-3.5 4-3.5 7.5V14H18',
  ),
  Category(
    'Transport',
    Color(0xFF007AFF),
    'M7 3.5h10a2.5 2.5 0 0 1 2.5 2.5v9a2.5 2.5 0 0 1-2.5 2.5H7A2.5 2.5 0 0 1 '
        '4.5 15V6A2.5 2.5 0 0 1 7 3.5ZM4.5 11h15M8 14.5h.01M16 14.5h.01M8 '
        '17.5l-1.5 3M16 17.5l1.5 3',
  ),
  Category(
    'Bills',
    Color(0xFFFF9500),
    'M13 2.5 4.5 13.5H11l-1 8 9.5-11.5H13l1-7.5Z',
  ),
  Category(
    'Fun',
    Color(0xFFFF2D55),
    'M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.3-4.1 5.9-.9Z',
  ),
  Category(
    'Other',
    Color(0xFF8E8E93),
    'M3.5 12.5V4.5a1 1 0 0 1 1-1h8l8 8a1 1 0 0 1 0 1.4l-7.6 7.6a1 1 0 0 1-1.4 '
        '0ZM8 8h.01',
  ),
];

const defaultCategory = 'Food';

Category categoryNamed(String name) =>
    categories.firstWhere((c) => c.name == name, orElse: () => categories.last);

class Expense {
  const Expense({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    category: json['cat'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
  );

  final int id;
  final String name;
  final String category;
  final double amount;

  /// Local calendar date (midnight).
  final DateTime date;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'cat': category,
    'amount': amount,
    'date': isoDate(date),
  };
}
