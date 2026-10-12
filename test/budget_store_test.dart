import 'package:bud/src/budget_store.dart';
import 'package:bud/src/models.dart';
import 'package:bud/src/widgets/category_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support.dart';

void main() {
  group('MonthSummary', () {
    test('matches the design for the sample month', () {
      final s = MonthSummary.of(sampleExpenses, budget: 2400, today: today);
      expect(s.spent, 1384.15);
      expect(s.left, closeTo(1015.85, 1e-9));
      expect(s.isOver, isFalse);
      expect(s.percentUsed.round(), 58);
      expect(s.daysLeft, 20);
      expect(s.dailyAllowance, closeTo(50.79, 0.005));
      expect(s.expenses.map((e) => e.name).take(3), [
        'Coffee',
        'Groceries',
        'Dinner with friends',
      ]);
      expect(
        [
          for (final t in s.categoryTotals)
            '${t.category.name} ${t.total} ${t.shareLabel}',
        ],
        [
          'Housing 900.0 65%',
          'Food 156.4 11%',
          'Transport 30.0 2%',
          'Bills 177.75 13%',
          'Fun 120.0 9%',
        ],
      );
    });

    test('over budget', () {
      final s = MonthSummary.of(sampleExpenses, budget: 1200, today: today);
      expect(s.isOver, isTrue);
      expect(-s.left, closeTo(184.15, 1e-9));
      expect(s.percentUsed.round(), 115);
      expect(s.dailyAllowance, 0);
    });

    test('a zero budget with spending reads as 100%', () {
      final s = MonthSummary.of(sampleExpenses, budget: 0, today: today);
      expect(s.percentUsed, 100);
      expect(MonthSummary.of(const [], budget: 0, today: today).percentUsed, 0);
    });

    test('counts only the current month', () {
      final s = MonthSummary.of(
        [
          ...sampleExpenses,
          Expense(
            id: 9,
            name: 'Old',
            category: 'Fun',
            amount: 50,
            date: DateTime(2026, 9, 30),
          ),
          Expense(
            id: 10,
            name: 'Last year',
            category: 'Fun',
            amount: 50,
            date: DateTime(2025, 10, 12),
          ),
        ],
        budget: 2400,
        today: today,
      );
      expect(s.expenses, hasLength(8));
      expect(s.spent, 1384.15);
    });

    test('days left includes today and handles month lengths', () {
      int daysLeft(DateTime d) =>
          MonthSummary.of(const [], budget: 1, today: d).daysLeft;
      expect(daysLeft(DateTime(2026, 10, 31)), 1);
      expect(daysLeft(DateTime(2026, 2, 1)), 28);
      expect(daysLeft(DateTime(2028, 2, 1)), 29);
      expect(daysLeft(DateTime(2026, 12, 15)), 17);
    });

    test('a tiny category shows <1%', () {
      final s = MonthSummary.of(
        [
          Expense(
            id: 1,
            name: 'Rent',
            category: 'Housing',
            amount: 1000,
            date: today,
          ),
          Expense(id: 2, name: 'Gum', category: 'Food', amount: 1, date: today),
        ],
        budget: 2000,
        today: today,
      );
      expect(s.categoryTotals.last.shareLabel, '<1%');
    });
  });

  group('BudgetStore', () {
    test('loads, changes and saves', () async {
      final storage = MemoryStorage(budget: 1800, expenses: sampleExpenses);
      final store = await BudgetStore.load(storage, clock: () => today);
      var notified = 0;
      store.addListener(() => notified++);

      expect(store.budget, 1800);
      expect(store.thisMonth.expenses, hasLength(8));

      store.setBudget(1200.456);
      expect(store.budget, 1200.46);

      final added = store.addExpense(
        name: '  ',
        category: 'Transport',
        amount: 12.345,
        date: DateTime(2026, 10, 12, 18, 30),
      );
      expect(added.name, 'Transport');
      expect(added.amount, 12.35);
      expect(added.date, today);

      store.removeExpense(1);
      await Future<void>.delayed(Duration.zero);

      expect(notified, 3);
      expect(storage.writes, 3);
      expect(storage.budget, 1200.46);
      expect(storage.expenses.map((e) => e.id), isNot(contains(1)));
      expect(storage.expenses.last.name, 'Transport');
    });

    test('starts with the default budget and no expenses', () async {
      final store = await BudgetStore.load(MemoryStorage(), clock: () => today);
      expect(store.budget, 2400);
      expect(store.expenses, isEmpty);
    });

    test('ids stay unique when added in the same instant', () {
      final store = BudgetStore(storage: MemoryStorage(), clock: () => today);
      final a = store.addExpense(
        name: 'a',
        category: 'Food',
        amount: 1,
        date: today,
      );
      final b = store.addExpense(
        name: 'b',
        category: 'Food',
        amount: 1,
        date: today,
      );
      expect(a.id, isNot(b.id));
    });
  });

  test('PrefsBudgetStorage round-trips through shared preferences', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final storage = PrefsBudgetStorage();
    expect((await storage.read()).budget, isNull);

    await storage.write(1234.5, sampleExpenses);
    final read = await storage.read();
    expect(read.budget, 1234.5);
    expect(read.expenses, hasLength(8));
    final electricity = read.expenses[2];
    expect(electricity.name, 'Electricity & internet');
    expect(electricity.category, 'Bills');
    expect(electricity.amount, 142.75);
    expect(electricity.date, DateTime(2026, 10, 5));
  });

  group('segmentWidths', () {
    test('splits proportionally', () {
      expect(segmentWidths([1, 3], 100), [25, 75]);
    });

    test('keeps tiny segments visible', () {
      final w = segmentWidths([1000, 1], 104);
      expect(w[1], 4);
      expect(w[0], 100);
    });
  });
}
