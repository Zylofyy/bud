import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'budget_store.dart';
import 'format.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets/add_expense_sheet.dart';
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
  final _selectedIds = <int>{};

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
    _stopEditing();
    final drafts = await showAddExpenseSheet(
      context,
      initialDate: summary.today,
      firstDate: summary.firstDay,
      lastDate: summary.lastDay,
      previous: _store.repeatable,
    );
    if (drafts != null) _store.addExpenses(drafts);
  }

  void _stopEditing() => setState(() {
    _editingList = false;
    _selectedIds.clear();
  });

  void _toggleSelected(int id) => setState(() {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
  });

  void _selectAll(List<Expense> expenses) => setState(() {
    final ids = {for (final e in expenses) e.id};
    if (_selectedIds.containsAll(ids)) {
      _selectedIds.clear();
    } else {
      _selectedIds.addAll(ids);
    }
  });

  void _deleteSelected() {
    final removed = _store.removeExpenses(_selectedIds);
    _stopEditing();
    if (removed.isEmpty) return;
    final count = removed.length;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            count == 1 ? '1 expense deleted' : '$count expenses deleted',
          ),
          behavior: SnackBarBehavior.floating,
          // Clear of the Add Expense button.
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          persist: false,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _store.restoreExpenses(removed),
          ),
        ),
      );
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
      child: PopScope(
        // Back leaves Edit mode before it leaves the app.
        canPop: !_editingList,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _stopEditing();
        },
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
                              ExpenseList(
                                expenses: summary.expenses,
                                editing: _editingList,
                                selected: _selectedIds,
                                onToggleEditing: _editingList
                                    ? _stopEditing
                                    : () => setState(() => _editingList = true),
                                onToggleSelected: _toggleSelected,
                                onSelectAll: () => _selectAll(summary.expenses),
                                onLongPress: (id) => setState(() {
                                  _editingList = true;
                                  _selectedIds.add(id);
                                }),
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
                        child: _editingList
                            ? _PillButton(
                                label: _deleteLabel(_selectedIds.length),
                                icon: AppIcons.trash,
                                color: AppColors.destructive,
                                onPressed: _selectedIds.isEmpty
                                    ? null
                                    : _deleteSelected,
                              )
                            : _PillButton(
                                label: 'Add Expense',
                                icon: AppIcons.plus,
                                color: AppColors.accent,
                                onPressed: () => _openSheet(summary),
                              ),
                      ),
                    ),
                ],
              );
            },
          ),
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

String _deleteLabel(int count) => switch (count) {
  0 => 'Delete',
  1 => 'Delete 1 Expense',
  _ => 'Delete $count Expenses',
};

/// The floating pill at the bottom: Add Expense, or Delete in Edit mode.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final List<String> icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = onPressed == null
        ? AppColors.disabledLabel
        : Colors.white;
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
          backgroundColor: color,
          foregroundColor: foreground,
          disabledBackgroundColor: AppColors.buttonFill,
          disabledForegroundColor: foreground,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 26),
          shape: const StadiumBorder(),
          textStyle: AppText.headline,
        ),
        icon: StrokeIcon(
          icon,
          color: foreground,
          size: const Size.square(18),
          strokeWidth: icon == AppIcons.plus ? 2.8 : 2.2,
        ),
        label: Text(label),
      ),
    );
  }
}
