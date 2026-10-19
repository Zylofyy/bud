import 'package:flutter/material.dart';

import '../theme.dart';
import 'stroke_icon.dart';

/// White rounded card that clips ink ripples of the rows inside it.
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: AppColors.card,
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

/// Small uppercase heading above a grouped card.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.padding});

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        header: true,
        child: Text(title.toUpperCase(), style: AppText.sectionHeader),
      ),
    );
  }
}

/// A row inside a [GroupedCard]: inset on the left, with a hairline above
/// every row but the first.
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    required this.child,
    this.divider = true,
    this.minHeight = 52,
  });

  final Widget child;
  final bool divider;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsets.only(right: 16),
        alignment: Alignment.centerLeft,
        decoration: divider ? const BoxDecoration(border: topHairline) : null,
        child: child,
      ),
    );
  }
}

const topHairline = Border(top: BorderSide(color: AppColors.separator));

/// The circle on a selectable row: empty, or filled with a check.
class SelectionCircle extends StatelessWidget {
  const SelectionCircle({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.accent : null,
        border: selected
            ? null
            : Border.all(color: AppColors.grabber, width: 1.5),
      ),
      child: selected
          ? const StrokeIcon(
              AppIcons.check,
              color: Colors.white,
              size: Size.square(15),
              strokeWidth: 3.2,
            )
          : null,
    );
  }
}
