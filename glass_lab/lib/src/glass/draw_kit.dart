import 'dart:math' as math;

import 'package:flutter/painting.dart';

// Canvas drawing kit for the recreated screens. Coordinates are source video
// pixels; the caller scales the canvas.

const screenFont = 'Inter';

Color rgb(int r, int g, int b, [double a = 1]) => Color.fromRGBO(r, g, b, a);

const white = Color(0xFFFFFFFF);

Paint fillPaint(Color c) => Paint()..color = c;

Paint strokePaint(Color c, double lw) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = lw
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// A rounded rectangle; like canvas `roundRect`, oversized radii shrink to fit.
RRect rrect(double x, double y, double w, double h, double r) =>
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      Radius.circular(math.max(0, math.min(r, math.min(w, h) / 2))),
    );

void fillRR(
  Canvas c,
  double x,
  double y,
  double w,
  double h,
  double r,
  Color col,
) => c.drawRRect(rrect(x, y, w, h, r), fillPaint(col));

void strokeRR(
  Canvas c,
  double x,
  double y,
  double w,
  double h,
  double r,
  Color col,
  double lw,
) => c.drawRRect(rrect(x, y, w, h, r), strokePaint(col, lw));

void fillRect(Canvas c, double x, double y, double w, double h, Color col) =>
    c.drawRect(Rect.fromLTWH(x, y, w, h), fillPaint(col));

Path polyline(List<double> pts, {bool close = false}) {
  final p = Path()..moveTo(pts[0], pts[1]);
  for (var i = 2; i < pts.length; i += 2) {
    p.lineTo(pts[i], pts[i + 1]);
  }
  if (close) p.close();
  return p;
}

/// A round-capped polyline through x, y pairs.
void line(Canvas c, List<double> pts, Color col, double lw) =>
    c.drawPath(polyline(pts), strokePaint(col, lw));

/// A filled polygon through x, y pairs.
void fillPoly(Canvas c, List<double> pts, Color col) =>
    c.drawPath(polyline(pts, close: true), fillPaint(col));

void circle(
  Canvas c,
  double x,
  double y,
  double r, {
  Color? fill,
  Color? stroke,
  double lw = 1,
}) {
  if (fill != null) c.drawCircle(Offset(x, y), r, fillPaint(fill));
  if (stroke != null) c.drawCircle(Offset(x, y), r, strokePaint(stroke, lw));
}

/// A clockwise arc stroke from angle [a0] to [a1].
void arc(
  Canvas c,
  double x,
  double y,
  double r,
  double a0,
  double a1,
  Color col,
  double lw,
) => c.drawPath(
  Path()..addArc(Rect.fromCircle(center: Offset(x, y), radius: r), a0, a1 - a0),
  strokePaint(col, lw),
);

void ellipse(
  Canvas c,
  double x,
  double y,
  double rx,
  double ry,
  double rot,
  Color col,
) {
  c.save();
  c.translate(x, y);
  c.rotate(rot);
  c.drawOval(
    Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
    fillPaint(col),
  );
  c.restore();
}

void dots(Canvas c, double x, double y, double gap, double r, Color col) {
  for (final o in [-gap, 0.0, gap]) {
    circle(c, x + o, y, r, fill: col);
  }
}

void chevronR(Canvas c, double x, double y, double s, Color col, double lw) =>
    line(c, [x - s * 0.5, y - s, x + s * 0.5, y, x - s * 0.5, y + s], col, lw);

void photoGlyph(
  Canvas c,
  double x,
  double y,
  double w,
  double h,
  Color col,
  double lw,
) {
  final frame = rrect(x - w / 2, y - h / 2, w, h, h * 0.18);
  c.drawRRect(frame, strokePaint(col, lw));
  c.save();
  c.clipRRect(frame);
  fillPoly(c, [
    x - w / 2, y + h * 0.36, //
    x - w * 0.12, y - h * 0.05,
    x + w * 0.1, y + h * 0.2,
    x + w * 0.24, y + h * 0.06,
    x + w / 2, y + h * 0.36,
    x + w / 2, y + h / 2,
    x - w / 2, y + h / 2,
  ], col);
  c.restore();
  circle(c, x + w * 0.2, y - h * 0.18, h * 0.12, fill: col);
}

/// The window resize handle in the corner of the iPad-style recordings.
void resizeArc(Canvas c, double w, double h) => arc(
  c,
  w - 42,
  h - 42,
  28,
  0.08,
  math.pi / 2 - 0.08,
  const Color.fromRGBO(255, 255, 255, 0.92),
  5,
);

/// A reference measurement: [ref] set at [weight] and [size] measured
/// [refWidth] source pixels wide in the recording.
typedef TextCalibration = (
  int weight,
  double size,
  String ref,
  double refWidth,
);

/// Draws screen text matched to a recording. Each string is stretched
/// horizontally by the factor that makes the nearest calibration's reference
/// string as wide as it was on screen.
class ScreenText {
  ScreenText(this.calibration);

  final List<TextCalibration> calibration;

  static final Map<String, double> _fit = {};
  static final Map<String, TextPainter> _painters = {};

  static TextPainter painter(String s, double size, int weight, Color color) {
    final key = '$s|$size|$weight|${color.toARGB32()}';
    return _painters.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: screenFont,
            fontSize: size,
            fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
            color: color,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
    });
  }

  /// Width of [s] before calibration.
  static double measure(String s, double size, int weight) =>
      painter(s, size, weight, white).width;

  /// The stretch factor of the calibration nearest to [weight] and [size].
  double fit(double size, int weight) {
    TextCalibration? best;
    var bestD = double.infinity;
    for (final c in calibration) {
      final d = (c.$1 - weight).abs() * 2 + (c.$2 - size).abs();
      if (d < bestD) {
        bestD = d;
        best = c;
      }
    }
    final (w, sz, ref, refW) = best!;
    return _fit.putIfAbsent('$w|$sz|$ref', () {
      final measured = measure(ref, sz, w);
      return measured > 0 ? refW / measured : 1;
    });
  }

  /// Draws [s] with its cap height centred on [y].
  void call(
    Canvas c,
    String s,
    double x,
    double y,
    double size,
    int weight,
    Color color, [
    TextAlign align = TextAlign.left,
  ]) {
    final fx = fit(size, weight);
    final tp = painter(s, size, weight, color);
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final dx = switch (align) {
      TextAlign.center => -tp.width / 2,
      TextAlign.right => -tp.width,
      _ => 0.0,
    };
    c.save();
    c.translate(x, y + size * 0.352);
    c.scale(fx, 1);
    tp.paint(c, Offset(dx, -baseline));
    c.restore();
  }
}
