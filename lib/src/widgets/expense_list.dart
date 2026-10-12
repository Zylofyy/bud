import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'grouped.dart';
import 'stroke_icon.dart';

/// "Expenses · N" with an Edit mode for deleting rows.
class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.editing,
    required this.pendingId,
    required this.onToggleEditing,
    required this.onTogglePending,
    required this.onDelete,
  });

  /// Newest first.
  final List<Expense> expenses;
  final bool editing;

  /// The row whose Delete button is showing.
  final int? pendingId;
  final VoidCallback onToggleEditing;
  final ValueChanged<int> onTogglePending;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionHeader(
                'Expenses · ${expenses.length}',
                padding: EdgeInsets.zero,
              ),
              if (expenses.isNotEmpty)
                TextButton(
                  onPressed: onToggleEditing,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: AppColors.accent,
                    textStyle: AppText.subheadStrong,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(editing ? 'Done' : 'Edit'),
                ),
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
                    divider: i > 0,
                    editing: editing,
                    pending: editing && pendingId == expenses[i].id,
                    onTogglePending: () => onTogglePending(expenses[i].id),
                    onDelete: () => onDelete(expenses[i].id),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    super.key,
    required this.expense,
    required this.divider,
    required this.editing,
    required this.pending,
    required this.onTogglePending,
    required this.onDelete,
  });

  final Expense expense;
  final bool divider;
  final bool editing;
  final bool pending;
  final VoidCallback onTogglePending;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = categoryNamed(expense.category);
    return Padding(
      // In Edit mode the 44px minus button overhangs the inset by 10px.
      padding: EdgeInsets.only(left: editing ? 6 : 16),
      child: Row(
        children: [
          if (editing) ...[
            _MinusButton(
              label: 'Delete ${expense.name}',
              selected: pending,
              onPressed: onTogglePending,
            ),
            const SizedBox(width: 4),
          ],
          IconTile(
            color: category.color,
            iconPath: category.iconPath,
            size: 36,
            radius: 10,
            iconSize: 20,
            strokeWidth: 2.1,
          ),
          const SizedBox(width: 12),
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
                    child: MergeSemantics(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.name,
                                  style: AppText.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${category.name} · ${shortDate(expense.date)}',
                                  style: AppText.subhead,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!pending) ...[
                            const SizedBox(width: 10),
                            Text(
                              formatMoney(expense.amount),
                              style: AppText.amount,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (pending) ...[
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: onDelete,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.destructive,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: AppText.subheadStrong,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        semanticsLabel: 'Delete ${expense.name}, confirm',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The red minus circle shown on each row in Edit mode.
class _MinusButton extends StatelessWidget {
  const _MinusButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.destructive,
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 10,
                height: 2.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
