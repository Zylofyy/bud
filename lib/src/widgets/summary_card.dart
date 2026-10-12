import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../budget_store.dart';
import '../format.dart';
import '../theme.dart';
import 'grouped.dart';

/// "Left to Spend" / "Over Budget By" card with the progress ring.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final pct = s.percentUsed.round();
    return Semantics(
      container: true,
      label: 'Budget summary',
      child: GroupedCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.isOver ? 'Over Budget By' : 'Left to Spend',
                    style: AppText.subhead.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMoney(s.left),
                      maxLines: 1,
                      style: AppText.hero.copyWith(
                        color: s.isOver
                            ? AppColors.destructive
                            : AppColors.label,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Spent ${formatMoney(s.spent)} of ${formatMoney(s.budget)}',
                    style: AppText.subhead,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            BudgetRing(
              percent: s.percentUsed,
              color: s.isOver ? AppColors.destructive : AppColors.accent,
              label: '$pct%',
              semanticLabel: '$pct% of budget used',
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetRing extends StatelessWidget {
  const BudgetRing({
    super.key,
    required this.percent,
    required this.color,
    required this.label,
    required this.semanticLabel,
  });

  final double percent;
  final Color color;
  final String label;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 84,
        child: CustomPaint(
          painter: _RingPainter(fraction: percent / 100, color: color),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppText.amount.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  static const _radius = 34.0;
  static const _stroke = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawCircle(center, _radius, paint..color = AppColors.track);

    final sweep = fraction.clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: _radius),
      -math.pi / 2,
      sweep,
      false,
      paint
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
