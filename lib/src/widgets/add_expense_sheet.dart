import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'grouped.dart';
import 'stroke_icon.dart';

/// Shows the "New Expense" sheet. Dates are limited to [firstDate]–[lastDate].
///
/// [previous] are earlier expenses the user can tick to add again. Returns
/// everything to add — the ticked expenses plus the typed one, if any — all
/// on the chosen date, or null if the sheet was dismissed.
Future<List<ExpenseDraft>?> showAddExpenseSheet(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  List<Expense> previous = const [],
}) {
  return showModalBottomSheet<List<ExpenseDraft>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    barrierColor: const Color(0x52000000),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.94,
    ),
    builder: (_) => AddExpenseSheet(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      previous: previous,
    ),
  );
}

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.previous = const [],
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<Expense> previous;

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _selected = <int>{};
  late DateTime _date = widget.initialDate;

  double? get _validAmount {
    final v = parseAmount(_amount.text);
    return v != null && v > 0 ? v : null;
  }

  List<ExpenseDraft> get _drafts => [
    for (final e in widget.previous)
      if (_selected.contains(e.id))
        (name: e.name, amount: e.amount, date: _date),
    if (_validAmount case final amount?)
      (name: _name.text, amount: amount, date: _date),
  ];

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final drafts = _drafts;
    if (drafts.isNotEmpty) Navigator.of(context).pop(drafts);
  }

  void _toggle(int id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final count = _drafts.length;
    final canAdd = count > 0;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          30 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grabber,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _CircleButton(
                  tooltip: 'Cancel',
                  icon: AppIcons.close,
                  iconSize: 16,
                  strokeWidth: 2.6,
                  background: AppColors.buttonFill,
                  foreground: AppColors.closeIcon,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: const Text(
                      'New Expense',
                      textAlign: TextAlign.center,
                      style: AppText.headline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CircleButton(
                  tooltip: count > 1 ? 'Add $count expenses' : 'Add expense',
                  icon: AppIcons.check,
                  iconSize: 18,
                  strokeWidth: 2.8,
                  background: canAdd ? AppColors.accent : AppColors.buttonFill,
                  foreground: canAdd ? Colors.white : AppColors.disabledLabel,
                  onPressed: canAdd ? _submit : null,
                ),
              ],
            ),
            const SizedBox(height: 18),
            GroupedCard(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amount', style: AppText.subhead),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencySymbol,
                        style: AppText.hero.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          inputFormatters: [AmountInputFormatter()],
                          style: AppText.hero.copyWith(
                            fontSize: 44,
                            color: AppColors.label,
                          ),
                          decoration: InputDecoration.collapsed(
                            hintText: '0.00',
                            hintStyle: AppText.hero.copyWith(
                              fontSize: 44,
                              color: AppColors.placeholder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GroupedCard(
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Description', style: AppText.body),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _name,
                            textAlign: TextAlign.right,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            style: AppText.body,
                            decoration: InputDecoration.collapsed(
                              hintText: 'Optional',
                              hintStyle: AppText.body.copyWith(
                                color: AppColors.placeholder,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GroupedRow(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date', style: AppText.body),
                        Material(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(9),
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                longDate(_date),
                                style: AppText.body,
                                semanticsLabel: 'Date, ${longDate(_date)}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.previous.isNotEmpty) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionHeader('Add Again', padding: EdgeInsets.zero),
                    if (_selected.isNotEmpty)
                      Text(
                        '${_selected.length} selected',
                        style: AppText.sectionHeader.copyWith(letterSpacing: 0),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              GroupedCard(
                child: Column(
                  children: [
                    for (var i = 0; i < widget.previous.length; i++)
                      _RepeatOption(
                        expense: widget.previous[i],
                        selected: _selected.contains(widget.previous[i].id),
                        divider: i > 0,
                        showYear:
                            widget.previous[i].date.year !=
                            widget.initialDate.year,
                        onTap: () => _toggle(widget.previous[i].id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Selected expenses are added with the date above.',
                  style: AppText.caption,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An earlier expense with a selection circle, in the "Add Again" list.
class _RepeatOption extends StatelessWidget {
  const _RepeatOption({
    required this.expense,
    required this.selected,
    required this.divider,
    required this.showYear,
    required this.onTap,
  });

  final Expense expense;
  final bool selected;
  final bool divider;
  final bool showYear;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = showYear ? longDate(expense.date) : shortDate(expense.date);
    return Semantics(
      container: true,
      checked: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              SelectionCircle(selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                  decoration: divider
                      ? const BoxDecoration(border: topHairline)
                      : null,
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
                            Text('Last added $date', style: AppText.subhead),
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.tooltip,
    required this.icon,
    required this.iconSize,
    required this.strokeWidth,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String tooltip;
  final List<String> icon;
  final double iconSize;
  final double strokeWidth;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        minimumSize: const Size.square(44),
        padding: EdgeInsets.zero,
        backgroundColor: background,
        disabledBackgroundColor: background,
      ),
      icon: StrokeIcon(
        icon,
        color: foreground,
        size: Size.square(iconSize),
        strokeWidth: strokeWidth,
      ),
    );
  }
}
