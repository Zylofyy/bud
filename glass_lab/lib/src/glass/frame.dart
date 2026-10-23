import 'dart:ui';

/// Material settings for a demo's glass.
class GlassStyle {
  const GlassStyle({
    required this.mul,
    required this.add,
    required this.blur,
    required this.rim,
    this.shadow = 0,
  });

  /// Background brightness multiplier.
  final double mul;

  /// Tint added to the background, rgb 0–1.
  final List<double> add;

  /// Background blur radius (source pixels).
  final double blur;

  /// Rim light strength.
  final double rim;

  /// Drop shadow strength.
  final double shadow;

  GlassStyle brighten(double by) => GlassStyle(
    mul: mul,
    add: [for (final v in add) v + by],
    blur: blur,
    rim: rim,
    shadow: shadow,
  );
}

/// One rounded rectangle of the glass field, in source pixels.
class GlassShape {
  const GlassShape({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.r,
    this.fade = 0,
    this.taper = 0,
  });

  final double cx;
  final double cy;
  final double w;
  final double h;
  final double r;

  /// Pushes the distance field out, shrinking the shape from every side.
  final double fade;

  /// Egg taper: narrower top, wider bottom.
  final double taper;
}

/// Where a content layer is drawn this frame. [nat] is the layer point that
/// lands on [now]; the layer is scaled around it.
class Content {
  const Content({
    required this.nat,
    required this.now,
    double s = 1,
    double? sx,
    double? sy,
    required this.alpha,
    this.blur = 0,
    this.free = false,
  }) : sx = sx ?? s,
       sy = sy ?? s;

  final Offset nat;
  final Offset now;
  final double sx;
  final double sy;
  final double alpha;

  /// Blur radius (source pixels).
  final double blur;

  /// Drawn over the whole stage instead of inside the glass.
  final bool free;
}

/// The light pill behind a pressed button or menu item.
class Highlight {
  const Highlight({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.r,
    required this.a,
  });

  final double cx;
  final double cy;
  final double w;
  final double h;
  final double r;
  final double a;
}

/// Everything the glass shader needs for one frame. Lengths are in source
/// (recording) pixels.
class GlassFrame {
  GlassFrame({required this.glass});

  GlassStyle glass;
  GlassShape? a;
  GlassShape? b;

  /// Smooth-minimum blend radius between [a] and [b].
  double blend = 0;
  double alpha = 1;
  double lens = 0;
  double lensW = 30;
  double opaque = 0;
  List<double> opaqueColor = const [0, 0, 0];

  /// How much the background is darkened, 0–1.
  double dim = 0;
  Content? c0;
  Content? c1;
  Highlight? hi;
  bool debug = false;
}
