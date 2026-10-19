import 'dart:convert';

import 'package:bud/src/budget_store.dart';
import 'package:bud/src/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

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
          Expense(id: 9, name: 'Old', amount: 50, date: DateTime(2026, 9, 30)),
          Expense(
            id: 10,
            name: 'Last year',
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

    test('numbers expenses logged again with the same name and amount', () {
      final all = [
        Expense(
          id: 0,
          name: 'Phone plan',
          amount: 35,
          date: DateTime(2026, 9, 3),
        ),
        ...sampleExpenses,
        Expense(
          id: 20,
          name: 'Coffee',
          amount: 5.8,
          date: DateTime(2026, 10, 13),
        ),
        // Logged after the others but dated earlier: still the third.
        Expense(
          id: 21,
          name: 'coffee',
          amount: 5.8,
          date: DateTime(2026, 10, 2),
        ),
        Expense(id: 22, name: 'Coffee', amount: 4.5, date: today),
      ];
      int occurrence(List<Expense> all, int id) => MonthSummary.of(
        all,
        budget: 2400,
        today: today,
      ).occurrenceOf(all.firstWhere((e) => e.id == id));

      expect(occurrence(all, 8), 1);
      expect(occurrence(all, 20), 2);
      expect(occurrence(all, 21), 3);
      expect(occurrence(all, 22), 1); // different amount
      expect(occurrence(all, 1), 1);
      expect(occurrence(all, 2), 2); // September's counts too

      // Without the first Coffee, the copies move up one.
      final withoutFirst = [...all]..removeWhere((e) => e.id == 8);
      expect(occurrence(withoutFirst, 20), 1);
      expect(occurrence(withoutFirst, 21), 2);
    });

    test('days left includes today and handles month lengths', () {
      int daysLeft(DateTime d) =>
          MonthSummary.of(const [], budget: 1, today: d).daysLeft;
      expect(daysLeft(DateTime(2026, 10, 31)), 1);
      expect(daysLeft(DateTime(2026, 2, 1)), 28);
      expect(daysLeft(DateTime(2028, 2, 1)), 29);
      expect(daysLeft(DateTime(2026, 12, 15)), 17);
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
        amount: 12.345,
        date: DateTime(2026, 10, 12, 18, 30),
      );
      expect(added.name, 'Expense');
      expect(added.amount, 12.35);
      expect(added.date, today);

      store.removeExpenses([1]);
      await Future<void>.delayed(Duration.zero);

      expect(notified, 3);
      expect(storage.writes, 3);
      expect(storage.budget, 1200.46);
      expect(storage.expenses.map((e) => e.id), isNot(contains(1)));
      expect(storage.expenses.last.name, 'Expense');
    });

    test('adds several expenses as one change with unique ids', () async {
      final storage = MemoryStorage();
      final store = BudgetStore(storage: storage, clock: () => today);
      var notified = 0;
      store.addListener(() => notified++);

      final added = store.addExpenses([
        (name: 'Rent share', amount: 900, date: today),
        (name: 'Phone plan', amount: 35, date: today),
        (name: 'Coffee', amount: 5.8, date: today),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(added.map((e) => e.id).toSet(), hasLength(3));
      expect(notified, 1);
      expect(storage.writes, 1);
      expect(store.thisMonth.spent, 940.8);

      expect(store.addExpenses(const []), isEmpty);
      expect(notified, 1);
    });

    test('removes several expenses as one change and restores them', () async {
      final storage = MemoryStorage(expenses: sampleExpenses);
      final store = await BudgetStore.load(storage, clock: () => today);
      var notified = 0;
      store.addListener(() => notified++);

      final removed = store.removeExpenses([2, 8, 99]);
      await Future<void>.delayed(Duration.zero);
      expect(removed.map((e) => e.name), ['Phone plan', 'Coffee']);
      expect(store.thisMonth.expenses, hasLength(6));
      expect(notified, 1);
      expect(storage.writes, 1);

      store.restoreExpenses(removed);
      await Future<void>.delayed(Duration.zero);
      expect(store.thisMonth.expenses, hasLength(8));
      expect(store.thisMonth.expenses.first.id, 8);
      expect(storage.expenses, hasLength(8));

      // Restoring again doesn't duplicate, and removing nothing is no change.
      store.restoreExpenses(removed);
      expect(store.removeExpenses(const []), isEmpty);
      expect(store.expenses, hasLength(8));
      expect(notified, 2);
    });

    test('offers each earlier expense once, most recent first', () {
      final store = BudgetStore(
        storage: MemoryStorage(),
        expenses: [
          ...sampleExpenses,
          Expense(
            id: 20,
            name: 'Coffee',
            amount: 5.8,
            date: DateTime(2026, 10, 2),
          ),
          Expense(
            id: 21,
            name: 'coffee',
            amount: 4.5,
            date: DateTime(2026, 9, 28),
          ),
          Expense(
            id: 22,
            name: 'Rent share',
            amount: 900,
            date: DateTime(2026, 9, 1),
          ),
        ],
        clock: () => today,
      );
      final repeatable = store.repeatable;
      expect(repeatable.map((e) => '${e.name} ${e.amount}'), [
        'Coffee 5.8',
        'Groceries 86.4',
        'Dinner with friends 64.2',
        'Transit card top-up 30.0',
        'Concert tickets 120.0',
        'Electricity & internet 142.75',
        'Phone plan 35.0',
        'Rent share 900.0',
        'coffee 4.5',
      ]);
      // The latest Coffee and Rent share, not the older copies.
      expect(repeatable.first.id, 8);
      expect(repeatable[7].id, 1);
    });

    test('starts with the default budget and no expenses', () async {
      final store = await BudgetStore.load(MemoryStorage(), clock: () => today);
      expect(store.budget, 2400);
      expect(store.expenses, isEmpty);
      expect(store.repeatable, isEmpty);
    });
  });

  group('PrefsBudgetStorage', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('round-trips through shared preferences', () async {
      final storage = PrefsBudgetStorage();
      expect((await storage.read()).budget, isNull);

      await storage.write(1234.5, sampleExpenses);
      final read = await storage.read();
      expect(read.budget, 1234.5);
      expect(read.expenses, hasLength(8));
      final electricity = read.expenses[2];
      expect(electricity.name, 'Electricity & internet');
      expect(electricity.amount, 142.75);
      expect(electricity.date, DateTime(2026, 10, 5));
    });

    test('reads expenses saved with categories by 0.1.0', () async {
      await SharedPreferencesAsyncPlatform.instance!.setString(
        'expenses',
        jsonEncode([
          {
            'id': 1,
            'name': 'Rent share',
            'cat': 'Housing',
            'amount': 900,
            'date': '2026-10-01',
          },
        ]),
        const SharedPreferencesOptions(),
      );
      final read = await PrefsBudgetStorage().read();
      expect(read.expenses.single.name, 'Rent share');
      expect(read.expenses.single.amount, 900);
    });
  });
}
