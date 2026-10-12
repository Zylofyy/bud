import 'package:flutter/material.dart';

import '../budget_store.dart';
import '../format.dart';
import '../theme.dart';
import 'grouped.dart';
import 'stroke_icon.dart';

/// "This Month": the editable monthly budget, daily allowance and days left.
class MonthSection extends StatelessWidget {
  const MonthSection({
    super.key,
    required this.summary,
    required this.onBudgetChanged,
  });

  final MonthSummary summary;
  final ValueChanged<double> onBudgetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('This Month'),
        const SizedBox(height: 7),
        GroupedCard(
          child: Column(
            children: [
              _BudgetRow(budget: summary.budget, onChanged: onBudgetChanged),
              _ValueRow(
                label: 'Daily Allowance',
                value: formatMoney(summary.dailyAllowance),
              ),
              _ValueRow(label: 'Days Left', value: '${summary.daysLeft}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GroupedRow(
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.body)),
            const SizedBox(width: 12),
            Text(value, style: AppText.bodySecondary),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatefulWidget {
  const _BudgetRow({required this.budget, required this.onChanged});

  final double budget;
  final ValueChanged<double> onChanged;

  @override
  State<_BudgetRow> createState() => _BudgetRowState();
}

class _BudgetRowState extends State<_BudgetRow> {
  final _draft = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _startEdit() {
    _draft.text = editableAmount(widget.budget);
    _draft.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _draft.text.length,
    );
    setState(() => _editing = true);
  }

  void _save() {
    final value = parseAmount(_draft.text);
    if (value != null && value >= 0) widget.onChanged(value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: _startEdit,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Monthly Budget', style: AppText.body),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatMoney(widget.budget),
                    style: AppText.bodySecondary,
                  ),
                  const SizedBox(width: 8),
                  const StrokeIcon(
                    AppIcons.chevron,
                    color: AppColors.chevron,
                    size: Size(8, 14),
                    viewBox: Size(8, 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.only(left: 16, right: 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Monthly Budget',
              style: AppText.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          const Text(currencySymbol, style: AppText.bodySecondary),
          const SizedBox(width: 6),
          SizedBox(
            width: 92,
            child: Semantics(
              label: 'Monthly Budget',
              child: TextField(
                controller: _draft,
                autofocus: true,
                textAlign: TextAlign.right,
                style: AppText.amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [AmountInputFormatter()],
                decoration: const InputDecoration.collapsed(hintText: null),
                onSubmitted: (_) => _save(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: AppColors.accent,
              textStyle: AppText.headline,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
