import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'grouped.dart';

/// "Expenses · N". In Edit mode rows can be selected to delete together.
class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.editing,
    required this.selected,
    required this.occurrenceOf,
    required this.onToggleEditing,
    required this.onToggleSelected,
    required this.onSelectAll,
    required this.onLongPress,
  });

  /// Newest first.
  final List<Expense> expenses;
  final bool editing;

  /// Ids of the rows ticked in Edit mode.
  final Set<int> selected;

  /// Which time an expense with this name and amount was logged: 2 shows "2x".
  final int Function(Expense) occurrenceOf;
  final VoidCallback onToggleEditing;
  final ValueChanged<int> onToggleSelected;

  /// Selects every row, or clears the selection when all are selected.
  final VoidCallback onSelectAll;

  /// Long-pressing a row outside Edit mode starts it with that row selected.
  final ValueChanged<int> onLongPress;

  @override
  Widget build(BuildContext context) {
    final allSelected =
        expenses.isNotEmpty && expenses.every((e) => selected.contains(e.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              Expanded(
                child: SectionHeader(
                  'Expenses · ${expenses.length}',
                  padding: EdgeInsets.zero,
                ),
              ),
              if (expenses.isNotEmpty) ...[
                if (editing)
                  _HeaderButton(
                    label: allSelected ? 'Deselect All' : 'Select All',
                    onPressed: onSelectAll,
                  ),
                _HeaderButton(
                  label: editing ? 'Done' : 'Edit',
                  onPressed: onToggleEditing,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 2),
        if (expenses.isEmpty)
          const GroupedCard(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              children: [
                Text('No Expenses', style: AppText.headline),
                SizedBox(height: 4),
                Text(
                  'Tap Add Expense to log your first one.',
                  style: AppText.subhead,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          GroupedCard(
            child: Column(
              children: [
                for (var i = 0; i < expenses.length; i++)
                  _ExpenseRow(
                    key: ValueKey(expenses[i].id),
                    expense: expenses[i],
                    occurrence: occurrenceOf(expenses[i]),
                    divider: i > 0,
                    editing: editing,
                    selected: selected.contains(expenses[i].id),
                    onTap: () => onToggleSelected(expenses[i].id),
                    onLongPress: () => onLongPress(expenses[i].id),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        foregroundColor: AppColors.accent,
        textStyle: AppText.subheadStrong,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    super.key,
    required this.expense,
    required this.occurrence,
    required this.divider,
    required this.editing,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final Expense expense;
  final int occurrence;
  final bool divider;
  final bool editing;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: editing ? selected : null,
      child: InkWell(
        onTap: editing ? onTap : null,
        onLongPress: editing ? null : onLongPress,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              if (editing) ...[
                SelectionCircle(selected: selected),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.fromLTRB(0, 10, 16, 10),
                  decoration: divider
                      ? const BoxDecoration(border: topHairline)
                      : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    expense.name,
                                    style: AppText.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (occurrence > 1) ...[
                                  const SizedBox(width: 8),
                                  _RepeatBadge(occurrence),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              shortDate(expense.date),
                              style: AppText.subhead,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(formatMoney(expense.amount), style: AppText.amount),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "2x", "3x"… on an expense logged again.
class _RepeatBadge extends StatelessWidget {
  const _RepeatBadge(this.occurrence);

  final int occurrence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${occurrence}x',
        semanticsLabel: '${ordinal(occurrence)} time',
        style: AppText.caption.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
