import 'dart:math' as math;
import 'dart:ui';

import '../glass/demo.dart';
import '../glass/draw_kit.dart';
import '../glass/frame.dart';
import '../glass/motion.dart';

// Demo 2 · Library → New Playlist sheet (1000028969.mp4, 794×1640).

class SheetHit extends Hit {
  const SheetHit(super.kind, {this.check = false, super.hold});

  /// The checklist button (pressable, but opens nothing).
  final bool check;
}

class SheetDemo extends GlassDemo {
  SheetDemo(super.clock, {super.loop, super.firstAuto});

  static const W = 794.0, H = 1640.0;

  static final bg = rgb(26, 25, 27);
  static final red = rgb(249, 38, 64);

  // Toolbar capsule and the sheet it becomes.
  static const tcx = 567.0, tcy = 107.5, tw = 216.0, th = 87.0;
  static const scx = 397.0, scy = 924.0, sw = 794.0, sh = 1552.0, sTop = 148.0;

  static const springsOpen = AxisSprings(
    cx: Spring(0.476, 0.661, 0, -0.007),
    cy: Spring(0.379, 0.738, 0, -0.017),
    w: Spring(0.414, 0.689, 0, -0.019),
    h: Spring(0.441, 0.691, 0, -0.016),
  );
  static const springsClose = AxisSprings(
    cx: Spring(0.291, 0.82, 7.98, 0),
    cy: Spring(0.297, 0.82, 8.13, 0.018),
    w: Spring(0.246, 0.82, 1.89, 0),
    h: Spring(0.305, 0.82, 6.5, 0),
  );

  static final tL = ScreenText([
    (700, 68, 'Library', 217),
    (400, 34, 'Playlists', 119),
    (600, 28, 'Not Playing', 140),
    (600, 34, 'New Playlist', 190),
  ]);

  bool _pressX = false;

  @override
  double get width => W;
  @override
  double get height => H;
  @override
  double get pressDur => 0.11;
  @override
  double get openDur => 0.7;
  @override
  double get closeDur => 0.55;
  @override
  String get idleHint => 'tap add playlist';
  @override
  String get openHint => 'tap ✕';
  @override
  final glass = const GlassStyle(
    mul: 1.35,
    add: [0.067, 0.067, 0.07],
    blur: 12,
    rim: 0.1,
    shadow: 0.12,
  );

  @override
  List<LayerSpec> layers() => [
    LayerSpec(
      const Rect.fromLTWH(459, 64, 216, 87),
      (c) => _drawToolbarIcons(c),
    ),
    LayerSpec(
      const Rect.fromLTWH(0, 148, 794, 1492),
      (c) => _drawSheetContent(c, _pressX),
    ),
  ];

  @override
  void onPressChanged() {
    final x = press?.kind == HitKind.close;
    if (x != _pressX) {
      _pressX = x;
      rebuildLayer(1);
    }
  }

  @override
  Hit defaultOpen() => const SheetHit(HitKind.open);

  @override
  Hit defaultClose() => const SheetHit(HitKind.close, hold: 0.06);

  @override
  Hit? hit(double x, double y) {
    if (phase == Phase.idle) {
      if (x > 459 && x < 570 && y > 60 && y < 156) {
        return const SheetHit(HitKind.open);
      }
      if (x >= 570 && x < 680 && y > 60 && y < 156) {
        return const SheetHit(HitKind.press, check: true);
      }
      return null;
    }
    if (phase == Phase.open &&
        math.sqrt(math.pow(x - 47, 2) + math.pow(y - 216, 2)) < 60) {
      return const SheetHit(HitKind.close);
    }
    return null;
  }

  static void _libIcon(Canvas c, String kind, double x, double y, Color col) {
    switch (kind) {
      case 'playlists':
        line(c, [x - 17, y - 8, x - 2, y - 8], col, 3.4);
        line(c, [x - 17, y, x - 2, y], col, 3.4);
        line(c, [x - 17, y + 8, x - 6, y + 8], col, 3.4);
        line(c, [x + 9, y + 9, x + 9, y - 15, x + 17, y - 11], col, 3.4);
        ellipse(c, x + 4, y + 10, 6.5, 5, -0.4, col);
      case 'artists':
        circle(c, x + 7, y - 7, 8.5, fill: col);
        line(c, [x + 1, y - 1, x - 13, y + 14], col, 5);
      case 'albums':
        strokeRR(c, x - 13, y - 9, 26, 24, 4, col, 3.2);
        line(c, [x - 9, y - 15, x + 9, y - 15], col, 3);
        line(c, [x - 5, y - 20, x + 5, y - 20], col, 3);
      case 'songs':
        line(c, [x + 3, y + 9, x + 3, y - 15, x + 12, y - 11], col, 3.6);
        ellipse(c, x - 3, y + 10, 7.5, 6, -0.4, col);
    }
  }

  static void _drawToolbarIcons(Canvas c) {
    final fc = rgb(52, 51, 53);
    // add playlist (text.badge.plus)
    const x = 507.0, y = 107.0;
    circle(c, x - 12, y - 9, 10.5, fill: white);
    line(c, [x - 17.5, y - 9, x - 6.5, y - 9], fc, 3);
    line(c, [x - 12, y - 14.5, x - 12, y - 3.5], fc, 3);
    line(c, [x + 4, y - 11, x + 22, y - 11], white, 3.6);
    line(c, [x + 4, y, x + 22, y], white, 3.6);
    line(c, [x - 22, y + 12, x + 22, y + 12], white, 3.6);
    // checklist
    const cc = 624.0;
    circle(c, cc - 13, y - 10, 8, stroke: white, lw: 3);
    line(c, [cc - 17, y - 10, cc - 14, y - 7, cc - 9, y - 14], white, 2.6);
    line(c, [cc + 2, y - 10, cc + 22, y - 10], white, 3.6);
    circle(c, cc - 13, y + 11, 8, stroke: white, lw: 3);
    line(c, [cc + 2, y + 11, cc + 22, y + 11], white, 3.6);
  }

  @override
  void scene(Canvas c) {
    fillRect(c, 0, 0, W, H, bg);
    // window controls pill
    fillRR(c, 25, 85, 84, 44, 22, rgb(78, 77, 81));
    circle(c, 45, 107, 7, fill: rgb(214, 96, 86));
    circle(c, 67, 107, 7, fill: rgb(232, 182, 84));
    circle(c, 89, 107, 7, fill: rgb(110, 182, 88));
    tL(c, 'Library', 146, 107, 68, 700, white);
    // avatar
    circle(c, 742, 107, 42, fill: rgb(61, 52, 79));
    tL(c, 'CY', 742, 107, 30, 600, white, TextAlign.center);
    const items = [
      ('playlists', 'Playlists', 224.0),
      ('artists', 'Artists', 327.0),
      ('albums', 'Albums', 431.0),
      ('songs', 'Songs', 535.0),
    ];
    for (final (k, s, y) in items) {
      _libIcon(c, k, 51, y, red);
      tL(c, s, 111, y, 34, 400, white);
      chevronR(c, 752, y, 9, rgb(81, 80, 82), 3.4);
      fillRect(c, 111, y + 51, 655, 1.5, rgb(49, 48, 50));
    }
    // mini player
    fillRR(c, 12, 1376, 768, 93, 46.5, rgb(51, 50, 52));
    fillRR(c, 40, 1395, 54, 54, 10, rgb(78, 77, 81));
    _libIcon(c, 'songs', 67, 1422, rgb(150, 149, 155));
    tL(c, 'Not Playing', 116, 1422, 28, 600, white);
    fillPoly(c, [627, 1404, 652, 1422, 627, 1440], white);
    final ff = rgb(105, 104, 108);
    fillPoly(c, [706, 1408, 726, 1422, 706, 1436], ff);
    fillPoly(c, [727, 1408, 747, 1422, 727, 1436], ff);
    // tab bar
    fillRR(c, 15, 1487, 770, 131, 65.5, rgb(51, 50, 52));
    fillRR(c, 384, 1497, 209, 111, 55.5, rgb(30, 29, 33));
    const ty = 1533.0, ly = 1577.0;
    // home
    fillPoly(c, [
      118, ty - 20, 140, ty - 2, 134, ty - 2, 134, ty + 18, //
      102, ty + 18, 102, ty - 2, 96, ty - 2,
    ], white);
    tL(c, 'Home', 118, ly, 20, 500, white, TextAlign.center);
    // radio
    circle(c, 304, ty, 5, fill: white);
    for (final (r0, a) in const [(13.0, 0.9), (22.0, 0.95)]) {
      arc(c, 304, ty, r0, -a, a, white, 3.4);
      arc(c, 304, ty, r0, math.pi - a, math.pi + a, white, 3.4);
    }
    tL(c, 'Radio', 304, ly, 20, 500, white, TextAlign.center);
    // library (selected)
    final sel = rgb(254, 57, 84), selBg = rgb(30, 29, 33);
    line(c, [477, ty - 22, 497, ty - 22], sel, 3);
    fillRR(c, 472, ty - 16, 30, 34, 6, sel);
    line(c, [490, ty + 8, 490, ty - 8, 496, ty - 6], selBg, 3);
    circle(c, 486, ty + 9, 4.5, fill: selBg);
    tL(c, 'Library', 487, ly, 20, 500, sel, TextAlign.center);
    // search
    circle(c, 669, ty - 4, 13, stroke: white, lw: 3.6);
    line(c, [679, ty + 6, 689, ty + 16], white, 4);
    tL(c, 'Search', 673, ly, 20, 500, white, TextAlign.center);
    resizeArc(c, W, H);
  }

  static void _drawSheetContent(Canvas c, bool pressX) {
    circle(c, 47, 216, 43.5, fill: pressX ? rgb(92, 91, 96) : rgb(53, 52, 56));
    line(c, [36, 205, 58, 227], white, 3.6);
    line(c, [58, 205, 36, 227], white, 3.6);
    tL(c, 'New Playlist', 397, 216, 34, 600, white, TextAlign.center);
    circle(c, 742, 216, 43.5, fill: rgb(69, 68, 72));
    line(c, [729, 217, 738, 228, 756, 202], white, 3.6);
    fillRR(c, 216, 320, 360, 358, 12, rgb(39, 38, 42));
    circle(c, 396, 499, 63, fill: rgb(249, 39, 63));
    photoGlyph(c, 396, 499, 46, 36, white, 3.4);
    tL(
      c,
      'Playlist Title',
      397,
      840,
      42,
      600,
      rgb(55, 53, 56),
      TextAlign.center,
    );
    fillRect(c, 395.5, 814, 3.2, 52, rgb(249, 39, 63));
    fillRect(c, 20, 885, 754, 1.5, rgb(54, 53, 55));
  }

  @override
  GlassFrame params(Phase phase, double dt) {
    final p = GlassFrame(glass: glass)
      ..lensW = 26
      ..opaqueColor = const [26 / 255, 25 / 255, 27 / 255];
    final pr = press;
    final pressedTb =
        pr != null && (pr.kind == HitKind.open || pr.kind == HitKind.press);
    if (phase == Phase.idle || phase == Phase.pressOpen) {
      p.b = const GlassShape(cx: tcx, cy: tcy, w: tw, h: th, r: 43.5);
      p.c0 = const Content(
        nat: Offset(tcx, tcy),
        now: Offset(tcx, tcy),
        alpha: 1,
      );
      p.lens = 5;
      if (pressedTb) {
        final check = pr is SheetHit && pr.check;
        p.hi = Highlight(
          cx: check ? 624 : 510,
          cy: 107.5,
          w: 104,
          h: 72,
          r: 36,
          a: 0.42,
        );
      }
      return p;
    }
    double cx, cy, w, h, rad;
    if (phase == Phase.opening || phase == Phase.open) {
      final t = phase == Phase.open ? 9.0 : dt;
      const sp = springsOpen;
      cx = lerp(tcx, scx, sp.cx.at(t));
      cy = lerp(tcy, scy, sp.cy.at(t));
      w = lerp(tw, sw, sp.w.at(t));
      h = lerp(th, sh, sp.h.at(t));
      rad = lerp(math.min(w, h) / 2, 55, ss(0.0, 0.2, t));
      final top = cy - h / 2;
      p.opaque = ss(0.0, 0.11, t);
      p.dim = 0.35 * ss(0, 0.12, t);
      p.lens = lerp(14, 0, ss(0.05, 0.25, t));
      p.c0 = Content(
        nat: const Offset(tcx, tcy),
        now: Offset(cx, top + 43.5),
        alpha: 1 - ss(0, 0.045, t),
        blur: 6 * ss(0, 0.05, t),
      );
      p.c1 = Content(
        nat: const Offset(scx, sTop),
        now: Offset(cx, top),
        s: w / sw,
        alpha: ss(-0.01, 0.09, t),
        blur: 5 * (1 - ss(0.02, 0.12, t)),
      );
      if (t < 0.02) {
        p.hi = Highlight(
          cx: 510 + (cx - tcx),
          cy: top + 43.5,
          w: 104,
          h: 72,
          r: 36,
          a: 0.42 * (1 - t / 0.02),
        );
      }
    } else {
      final t = phase == Phase.pressClose ? 0.0 : dt;
      const sp = springsClose;
      cx = lerp(scx, tcx, sp.cx.at(t));
      cy = lerp(scy, tcy, sp.cy.at(t));
      w = lerp(sw, tw, sp.w.at(t));
      h = lerp(sh, th, sp.h.at(t));
      rad = lerp(55, math.min(w, h) / 2, ss(0.04, 0.18, t));
      rad = math.min(rad, math.min(w, h) / 2);
      final top = cy - h / 2;
      p.opaque = 1 - ss(0, 0.06, t);
      p.dim = 0.35 * (1 - ss(0, 0.07, t));
      p.lens =
          lerp(0, 12, ss(0.04, 0.16, t)) * (1 - ss(0.3, 0.5, t)) +
          5 * ss(0.3, 0.5, t);
      p.c1 = Content(
        nat: const Offset(scx, sTop),
        now: Offset(cx, top),
        s: w / sw,
        alpha: 1 - ss(0, 0.1, t),
        blur: 8 * ss(0, 0.06, t),
      );
      p.c0 = Content(
        nat: const Offset(tcx, tcy),
        now: Offset(cx, top + math.min(43.5, h / 2)),
        alpha: ss(0.07, 0.15, t),
      );
    }
    p.b = GlassShape(cx: cx, cy: cy, w: w, h: h, r: rad);
    return p;
  }
}
