import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'budget_store.dart';
import 'format.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets/add_expense_sheet.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/expense_list.dart';
import 'widgets/month_section.dart';
import 'widgets/stroke_icon.dart';
import 'widgets/summary_card.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key, required this.store});

  final BudgetStore store;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with WidgetsBindingObserver {
  bool _editingList = false;
  int? _pendingDeleteId;
  String _lastCategory = defaultCategory;

  BudgetStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The month and days left depend on today's date, which may have changed
  // while the app was in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  Future<void> _openSheet(MonthSummary summary) async {
    setState(() {
      _editingList = false;
      _pendingDeleteId = null;
    });
    final result = await showAddExpenseSheet(
      context,
      initialDate: summary.today,
      firstDate: summary.firstDay,
      lastDate: summary.lastDay,
      initialCategory: _lastCategory,
    );
    if (result == null) return;
    _lastCategory = result.category;
    _store.addExpense(
      name: result.name,
      category: result.category,
      amount: result.amount,
      date: result.date,
    );
  }

  void _delete(int id) {
    _store.removeExpense(id);
    setState(() {
      _pendingDeleteId = null;
      if (_store.thisMonth.expenses.isEmpty) _editingList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final summary = _store.thisMonth;
            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(month: monthTitle(summary.today)),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            124 + bottomPadding,
                          ),
                          children: [
                            SummaryCard(summary: summary),
                            const SizedBox(height: 28),
                            MonthSection(
                              summary: summary,
                              onBudgetChanged: _store.setBudget,
                            ),
                            const SizedBox(height: 28),
                            CategoryBreakdown(totals: summary.categoryTotals),
                            const SizedBox(height: 28),
                            ExpenseList(
                              expenses: summary.expenses,
                              editing: _editingList,
                              pendingId: _pendingDeleteId,
                              onToggleEditing: () => setState(() {
                                _editingList = !_editingList;
                                _pendingDeleteId = null;
                              }),
                              onTogglePending: (id) => setState(() {
                                _pendingDeleteId = _pendingDeleteId == id
                                    ? null
                                    : id;
                              }),
                              onDelete: _delete,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!keyboardOpen)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24 + bottomPadding,
                    child: Center(
                      child: _AddExpenseButton(
                        onPressed: () => _openSheet(summary),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.month});

  final String month;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Text('Budget', style: AppText.largeTitle),
          ),
          const SizedBox(height: 2),
          Text(month, style: AppText.subhead),
        ],
      ),
    );
  }
}

class _AddExpenseButton extends StatelessWidget {
  const _AddExpenseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 26),
          shape: const StadiumBorder(),
          textStyle: AppText.headline,
        ),
        icon: const StrokeIcon(
          AppIcons.plus,
          color: Colors.white,
          size: Size.square(18),
          strokeWidth: 2.8,
        ),
        label: const Text('Add Expense'),
      ),
    );
  }
}
