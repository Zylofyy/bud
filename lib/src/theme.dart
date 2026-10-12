import 'package:flutter/material.dart';

/// Colors taken from the Budget App UI design.
abstract final class AppColors {
  static const accent = Color(0xFF0067D6);
  static const background = Color(0xFFF2F2F7);
  static const card = Color(0xFFFFFFFF);
  static const label = Color(0xFF000000);
  static const secondaryLabel = Color(0xFF6C6C70);
  static const placeholder = Color(0xFFAEAEB2);
  static const separator = Color(0xFFE3E3E8);
  static const track = Color(0xFFE5E5EA);
  static const chevron = Color(0xFFB4B4B9);
  static const grabber = Color(0xFFC7C7CC);
  static const destructive = Color(0xFFD70015);
  static const buttonFill = Color(0xFFE3E3E8);
  static const fieldFill = Color(0xFFEEEEF0);
  static const disabledLabel = Color(0xFF8E8E93);
  static const closeIcon = Color(0xFF3C3C43);
}

const currencySymbol = r'$';
const defaultMonthlyBudget = 2400.0;

const _tabular = [FontFeature.tabularFigures()];

/// Text styles from the design. Every style sets [TextStyle.letterSpacing] so
/// Material's default tracking never leaks in.
abstract final class AppText {
  static const largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.34,
    color: AppColors.label,
  );
  static const body = TextStyle(
    fontSize: 17,
    letterSpacing: 0,
    color: AppColors.label,
  );
  static const bodySecondary = TextStyle(
    fontSize: 17,
    letterSpacing: 0,
    color: AppColors.secondaryLabel,
    fontFeatures: _tabular,
  );
  static const headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.label,
  );
  static const subhead = TextStyle(
    fontSize: 15,
    letterSpacing: 0,
    color: AppColors.secondaryLabel,
    fontFeatures: _tabular,
  );
  static const subheadStrong = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.label,
  );
  static const caption = TextStyle(
    fontSize: 13,
    letterSpacing: 0,
    color: AppColors.secondaryLabel,
    fontFeatures: _tabular,
  );
  static const sectionHeader = TextStyle(
    fontSize: 13,
    letterSpacing: 0.26,
    color: AppColors.secondaryLabel,
  );
  static const hero = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0,
    fontFeatures: _tabular,
  );
  static const amount = TextStyle(
    fontSize: 17,
    letterSpacing: 0,
    color: AppColors.label,
    fontFeatures: _tabular,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.accent).copyWith(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    surface: AppColors.background,
    onSurface: AppColors.label,
    error: AppColors.destructive,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionHandleColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.25),
    ),
  );
}
