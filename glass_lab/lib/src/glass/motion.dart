import 'dart:math' as math;

double clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

double lerp(double a, double b, double t) => a + (b - a) * t;

/// Smoothstep from [a] to [b].
double ss(double a, double b, double x) {
  final t = clamp01((x - a) / (b - a));
  return t * t * (3 - 2 * t);
}

/// Damped spring step response from 0 to 1 (SwiftUI-style response and
/// damping ratio, normalised initial velocity [v0]).
double spr(double t, double response, double damping, double v0) {
  if (t <= 0) return 0;
  final w = 2 * math.pi / response;
  if (damping < 1) {
    final wd = w * math.sqrt(1 - damping * damping);
    final b = (v0 - damping * w) / wd;
    return 1 +
        math.exp(-damping * w * t) * (-math.cos(wd * t) + b * math.sin(wd * t));
  }
  return 1 - math.exp(-w * t) * (1 + (w - v0) * t);
}

/// A spring fitted to one channel of a recording.
class Spring {
  const Spring(this.response, this.damping, [this.v0 = 0, this.delay = 0]);

  final double response;
  final double damping;
  final double v0;

  /// Seconds the channel starts late (negative: early).
  final double delay;

  double at(double t) => spr(t - delay, response, damping, v0);
}

/// Springs for the four measured channels of a glass shape.
class AxisSprings {
  const AxisSprings({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
  });

  final Spring cx;
  final Spring cy;
  final Spring w;
  final Spring h;

  Spring operator [](Channel c) => switch (c) {
    Channel.cx => cx,
    Channel.cy => cy,
    Channel.w => w,
    Channel.h => h,
  };
}

enum Channel {
  cx('centre x'),
  cy('centre y'),
  w('width'),
  h('height');

  const Channel(this.label);

  final String label;
}
