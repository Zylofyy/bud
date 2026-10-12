import 'package:flutter/material.dart';

import '../theme.dart';

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
