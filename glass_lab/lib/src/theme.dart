import 'package:flutter/material.dart';

const displayFont = 'Schibsted Grotesk';
const monoFont = 'JetBrains Mono';

/// Bundled Noto subsets for the few symbols the text fonts lack (✕ ✓, ⋯, ⅒).
const symbolFallback = ['Lab Symbols', 'Lab Math', 'Lab Fractions'];

/// The lab's colour tokens, light and dark, from the artifact.
@immutable
class LabColors extends ThemeExtension<LabColors> {
  const LabColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.rec,
    required this.chip,
    required this.series,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;

  /// Accent for hovers and focus.
  final Color rec;
  final Color chip;

  /// Centre x, centre y, width, height.
  final List<Color> series;

  static const light = LabColors(
    bg: Color(0xFFECEEF2),
    surface: Color(0xFFF7F8FA),
    ink: Color(0xFF14161B),
    muted: Color(0xFF5A606C),
    line: Color(0xFFD4D8DF),
    rec: Color(0xFFD92D2F),
    chip: Color(0xFFE2E5EA),
    series: [
      Color(0xFF2A78D6),
      Color(0xFFEB6834),
      Color(0xFF1BAF7A),
      Color(0xFFEDA100),
    ],
  );

  static const dark = LabColors(
    bg: Color(0xFF0D0E11),
    surface: Color(0xFF15171B),
    ink: Color(0xFFE7E9EE),
    muted: Color(0xFF8E94A1),
    line: Color(0xFF262930),
    rec: Color(0xFFFF5A5C),
    chip: Color(0xFF1E2127),
    series: [
      Color(0xFF3987E5),
      Color(0xFFD95926),
      Color(0xFF199E70),
      Color(0xFFC98500),
    ],
  );

  @override
  LabColors copyWith() => this;

  @override
  LabColors lerp(LabColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return LabColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      ink: c(ink, other.ink),
      muted: c(muted, other.muted),
      line: c(line, other.line),
      rec: c(rec, other.rec),
      chip: c(chip, other.chip),
      series: [
        for (var i = 0; i < series.length; i++) c(series[i], other.series[i]),
      ],
    );
  }
}

extension LabTheme on BuildContext {
  LabColors get lab => Theme.of(this).extension<LabColors>()!;
}

ThemeData buildTheme(Brightness brightness) {
  final lab = brightness == Brightness.dark ? LabColors.dark : LabColors.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: displayFont,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lab.rec,
      brightness: brightness,
      surface: lab.surface,
    ),
    scaffoldBackgroundColor: lab.bg,
    splashFactory: InkRipple.splashFactory,
    extensions: [lab],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: lab.ink,
      displayColor: lab.ink,
      fontFamilyFallback: symbolFallback,
    ),
    iconTheme: IconThemeData(color: lab.ink),
  );
}

/// Text styles from the artifact.
abstract final class LabText {
  static TextStyle h1(LabColors c) => TextStyle(
    fontFamily: displayFont,
    fontFamilyFallback: symbolFallback,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.05,
    letterSpacing: -0.64,
    color: c.ink,
  );

  static TextStyle lede(LabColors c) => TextStyle(
    fontFamily: displayFont,
    fontFamilyFallback: symbolFallback,
    fontSize: 16,
    height: 1.5,
    color: c.muted,
  );

  static TextStyle h2(LabColors c) => TextStyle(
    fontFamily: displayFont,
    fontFamilyFallback: symbolFallback,
    fontWeight: FontWeight.w700,
    fontSize: 21,
    height: 1.25,
    letterSpacing: -0.21,
    color: c.ink,
  );

  static TextStyle h3(LabColors c) => TextStyle(
    fontFamily: displayFont,
    fontFamilyFallback: symbolFallback,
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 1.4,
    color: c.ink,
  );

  static TextStyle body(LabColors c) => TextStyle(
    fontFamily: displayFont,
    fontFamilyFallback: symbolFallback,
    fontSize: 15,
    height: 1.5,
    color: c.muted,
  );

  static TextStyle src(LabColors c) => TextStyle(
    fontFamily: monoFont,
    fontFamilyFallback: symbolFallback,
    fontSize: 12,
    height: 1.5,
    color: c.muted,
  );

  /// Uppercase mono label, e.g. "SPEED" or "FRAME BY FRAME".
  static TextStyle label(LabColors c) => TextStyle(
    fontFamily: monoFont,
    fontFamilyFallback: symbolFallback,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 1.5,
    letterSpacing: 0.88,
    color: c.muted,
  );

  static TextStyle button(Color color) => TextStyle(
    fontFamily: monoFont,
    fontFamilyFallback: symbolFallback,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle mono(
    Color color, {
    double size = 12,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: monoFont,
    fontFamilyFallback: symbolFallback,
    fontWeight: weight,
    fontSize: size,
    height: 1.45,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
