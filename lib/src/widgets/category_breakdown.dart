import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../budget_store.dart';
import '../format.dart';
import '../theme.dart';
import 'grouped.dart';
import 'stroke_icon.dart';

/// "Spending by Category": a stacked bar plus a two-column legend.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({super.key, required this.totals});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Spending by Category'),
        const SizedBox(height: 7),
        GroupedCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: totals.isEmpty
              ? const Text(
                  'Add an expense to see where your money goes.',
                  style: AppText.subhead,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExcludeSemantics(child: _StackedBar(totals: totals)),
                    const SizedBox(height: 18),
                    _Legend(totals: totals),
                  ],
                ),
        ),
      ],
    );
  }
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.totals});

  final List<CategoryTotal> totals;

  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: 22,
        color: AppColors.track,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth - _gap * (totals.length - 1);
            final widths = segmentWidths([
              for (final t in totals) t.total,
            ], math.max(0, available));
            return Row(
              children: [
                for (var i = 0; i < totals.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Container(width: widths[i], color: totals[i].category.color),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Splits [available] between [values] proportionally, giving each segment at
/// least [minWidth] and sharing what's left among the others.
List<double> segmentWidths(
  List<double> values,
  double available, {
  double minWidth = 4,
}) {
  final widths = List<double?>.filled(values.length, null);
  var space = available;
  while (true) {
    final open = [
      for (var i = 0; i < values.length; i++)
        if (widths[i] == null) i,
    ];
    final total = open.fold(0.0, (sum, i) => sum + values[i]);
    final tooSmall = [
      for (final i in open)
        if (total <= 0 || values[i] / total * space < minWidth) i,
    ];
    if (tooSmall.isEmpty) {
      for (final i in open) {
        widths[i] = values[i] / total * space;
      }
      break;
    }
    for (final i in tooSmall) {
      widths[i] = minWidth;
      space = math.max(0, space - minWidth);
    }
  }
  return [for (final w in widths) w!];
}

class _Legend extends StatelessWidget {
  const _Legend({required this.totals});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: [
            for (final t in totals)
              SizedBox(
                width: itemWidth,
                child: MergeSemantics(
                  child: Row(
                    children: [
                      IconTile(
                        color: t.category.color,
                        iconPath: t.category.iconPath,
                        size: 30,
                        radius: 8,
                        iconSize: 17,
                        strokeWidth: 2.2,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.category.name,
                              style: AppText.subheadStrong,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${formatMoney(t.total)} · ${t.shareLabel}',
                              style: AppText.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
