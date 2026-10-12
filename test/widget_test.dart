import 'package:bud/main.dart';
import 'package:bud/src/budget_store.dart';
import 'package:bud/src/models.dart';
import 'package:bud/src/widgets/add_expense_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

Future<MemoryStorage> pumpApp(
  WidgetTester tester, {
  double? budget,
  List<Expense>? expenses,
}) async {
  // A phone-width screen tall enough that the whole overview is on screen.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 2000);
  addTearDown(tester.view.reset);

  final storage = MemoryStorage(
    budget: budget,
    expenses: expenses ?? sampleExpenses,
  );
  final store = await BudgetStore.load(storage, clock: () => today);
  await tester.pumpWidget(BudgetApp(store: store));
  await tester.pumpAndSettle();
  return storage;
}

Finder inSheet(Finder finder) =>
    find.descendant(of: find.byType(AddExpenseSheet), matching: finder);

void main() {
  testWidgets('shows the month overview', (tester) async {
    await pumpApp(tester);

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Left to Spend'), findsOneWidget);
    expect(find.text(r'$1,015.85'), findsOneWidget);
    expect(find.text(r'Spent $1,384.15 of $2,400.00'), findsOneWidget);
    expect(find.text('58%'), findsOneWidget);
    expect(find.text(r'$2,400.00'), findsOneWidget);
    expect(find.text(r'$50.79'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text(r'$900.00 · 65%'), findsOneWidget);
    expect(find.text('EXPENSES · 8'), findsOneWidget);
    expect(find.text('Electricity & internet'), findsOneWidget);
    expect(find.text('Bills · 5 Oct'), findsOneWidget);
  });

  testWidgets('editing the budget can put the month over budget', (
    tester,
  ) async {
    final storage = await pumpApp(tester);

    await tester.tap(find.text('Monthly Budget'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1200');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Over Budget By'), findsOneWidget);
    expect(find.text(r'$184.15'), findsOneWidget);
    expect(find.text('115%'), findsOneWidget);
    expect(find.text(r'$0.00'), findsOneWidget); // daily allowance
    expect(storage.budget, 1200);
  });

  testWidgets('clearing the budget field keeps the old budget', (tester) async {
    final storage = await pumpApp(tester, budget: 1800);

    await tester.tap(find.text('Monthly Budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text(r'$1,800.00'), findsOneWidget);
    expect(storage.writes, 0);
  });

  testWidgets('adds an expense from the sheet', (tester) async {
    final storage = await pumpApp(tester);

    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();
    expect(find.text('New Expense'), findsOneWidget);
    expect(find.text('12 Oct 2026'), findsOneWidget);

    IconButton addButton() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Add expense'),
        matching: find.byType(IconButton),
      ),
    );
    expect(addButton().onPressed, isNull);

    await tester.enterText(inSheet(find.byType(TextField)).first, '12.5');
    await tester.enterText(inSheet(find.byType(TextField)).last, 'Taxi');
    await tester.tap(inSheet(find.text('Transport')));
    await tester.pumpAndSettle();
    expect(addButton().onPressed, isNotNull);

    await tester.tap(find.byTooltip('Add expense'));
    await tester.pumpAndSettle();

    expect(find.text('New Expense'), findsNothing);
    expect(find.text('Taxi'), findsOneWidget);
    expect(find.text(r'$12.50'), findsOneWidget);
    expect(find.text('Transport · 12 Oct'), findsOneWidget);
    expect(find.text('EXPENSES · 9'), findsOneWidget);
    expect(find.text(r'$1,003.35'), findsOneWidget);
    expect(storage.expenses, hasLength(9));
  });

  testWidgets('cancelling the sheet adds nothing', (tester) async {
    final storage = await pumpApp(tester);

    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();
    await tester.enterText(inSheet(find.byType(TextField)).first, '40');
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('New Expense'), findsNothing);
    expect(find.text('EXPENSES · 8'), findsOneWidget);
    expect(storage.writes, 0);
  });

  testWidgets('deletes an expense in Edit mode', (tester) async {
    final storage = await pumpApp(tester);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Delete Coffee'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Delete Coffee'));
    await tester.pumpAndSettle();
    expect(find.text(r'$5.80'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsNothing);
    expect(find.text('EXPENSES · 7'), findsOneWidget);
    expect(storage.expenses.map((e) => e.name), isNot(contains('Coffee')));

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('shows empty states with no expenses', (tester) async {
    await pumpApp(tester, expenses: const []);

    expect(find.text('No Expenses'), findsOneWidget);
    expect(
      find.text('Add an expense to see where your money goes.'),
      findsOneWidget,
    );
    expect(find.text('Edit'), findsNothing);
    expect(find.text(r'$2,400.00'), findsNWidgets(2));
    expect(find.text('0%'), findsOneWidget);
  });
}
