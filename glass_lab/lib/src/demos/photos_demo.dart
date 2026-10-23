import 'dart:math' as math;
import 'dart:ui';

import '../glass/demo.dart';
import '../glass/draw_kit.dart';
import '../glass/frame.dart';
import '../glass/motion.dart';

// Demo 3 · Photos toolbar → menu, the gooey one (1000028970.mp4, 716×1640).

class PhotosHit extends Hit {
  const PhotosHit(super.kind, {this.x = 0, this.item, super.hold});

  /// Centre of the pressed toolbar icon.
  final double x;

  /// The pressed menu item's highlight.
  final Highlight? item;
}

class PhotosDemo extends GlassDemo {
  PhotosDemo(super.clock, {super.loop, super.firstAuto});

  static const W = 716.0, H = 1640.0;

  // Toolbar capsule, the ⋯ button in it, and the menu.
  static const ccx = 486.5, ccy = 107.5, cw = 417.0, ch = 87.0;
  static const dotsX = 650.0;
  static const mx = 224.0,
      my = 63.0,
      mw = 471.0,
      mh = 654.0,
      mcx = 459.5,
      mcy = 390.0;

  static const springsOpen = AxisSprings(
    cx: Spring(0.389, 0.733, 0, -0.028),
    cy: Spring(0.311, 0.582, 11.8, 0.009),
    w: Spring(0.345, 0.739, 0, -0.012),
    h: Spring(0.368, 0.728, 3.77, 0.002),
  );

  static final tP = ScreenText([
    (400, 30, 'Start Slideshow', 211),
    (500, 23, 'Duplicate', 99),
  ]);

  static final _f = rgb(29, 29, 29);

  @override
  double get width => W;
  @override
  double get height => H;
  @override
  double get pressDur => 0.1;
  @override
  double get openDur => 0.62;
  @override
  double get closeDur => 0.5;
  @override
  String get idleHint => 'tap ⋯';
  @override
  String get openHint => 'tap to dismiss';
  @override
  final glass = const GlassStyle(
    mul: 1.35,
    add: [0.114, 0.114, 0.114],
    blur: 10,
    rim: 0.16,
    shadow: 0,
  );

  @override
  List<LayerSpec> layers() => [
    LayerSpec(const Rect.fromLTWH(278, 64, 417, 87), _drawToolbarIcons),
    LayerSpec(const Rect.fromLTWH(mx, my, mw, mh), _drawMenu),
  ];

  @override
  Hit defaultOpen() => const PhotosHit(HitKind.open);

  @override
  Hit defaultClose() => const PhotosHit(HitKind.close, hold: 0.05);

  @override
  Hit? hit(double x, double y) {
    if (phase == Phase.idle) {
      if (x > 600 && x < 700 && y > 55 && y < 160) {
        return const PhotosHit(HitKind.open);
      }
      if (x > 278 && x <= 600 && y > 55 && y < 160) {
        return PhotosHit(
          HitKind.press,
          x: x < 380
              ? 326.5
              : x < 490
              ? 435.5
              : 541.5,
        );
      }
      return null;
    }
    if (phase == Phase.open) {
      Highlight? item;
      if (x > mx && x < mx + mw && y > my && y < my + mh) {
        item = y < 200
            ? Highlight(
                cx: x < 384
                    ? 308
                    : x < 535
                    ? 460
                    : 610,
                cy: 131,
                w: 140,
                h: 120,
                r: 24,
                a: 0.07,
              )
            : Highlight(
                cx: mcx,
                cy: y < 311
                    ? 256
                    : y < 403
                    ? 365
                    : y < 480
                    ? 441
                    : y < 572
                    ? 518
                    : 646,
                w: mw - 26,
                h: y < 572 ? 74 : 104,
                r: 24,
                a: 0.07,
              );
      }
      return PhotosHit(HitKind.close, item: item, hold: 0.1);
    }
    return null;
  }

  static void _drawToolbarIcons(Canvas c) {
    const y = 107.5;
    // sliders (slider.horizontal.3)
    const sx = 326.5;
    for (final (dy, kx) in const [(-14.0, 9.0), (0.0, -9.0), (14.0, 7.0)]) {
      line(c, [sx - 21, y + dy, sx + 21, y + dy], white, 3);
      fillRR(c, sx + kx - 7, y + dy - 5.5, 14, 11, 5.5, _f);
      strokeRR(c, sx + kx - 7, y + dy - 5.5, 14, 11, 5.5, white, 2.8);
    }
    // info
    const ix = 435.5;
    circle(c, ix, y, 20.5, stroke: white, lw: 3);
    circle(c, ix, y - 9.5, 2.6, fill: white);
    line(c, [ix - 4, y - 2, ix, y - 2, ix, y + 10], white, 3);
    line(c, [ix - 5, y + 10.5, ix + 5, y + 10.5], white, 3);
    // trash
    const tx = 541.5;
    line(c, [tx - 20, y - 16, tx + 20, y - 16], white, 3.2);
    line(
      c,
      [tx - 7, y - 16, tx - 7, y - 22, tx + 7, y - 22, tx + 7, y - 16],
      white,
      3,
    );
    line(
      c,
      [tx - 15, y - 16, tx - 12, y + 21, tx + 12, y + 21, tx + 15, y - 16],
      white,
      3.2,
    );
    for (final o in const [-6.0, 0.0, 6.0]) {
      line(c, [tx + o, y - 9, tx + o, y + 14], white, 2.4);
    }
    dots(c, dotsX, y, 20, 4.6, white);
  }

  static void _menuIcon(Canvas c, String kind, double x, double y) {
    final f = _f;
    switch (kind) {
      case 'copy':
        fillRR(c, x - 7, y - 19, 20, 26, 4, white);
        fillRR(c, x - 14, y - 11, 21, 27, 4, f);
        fillRR(c, x - 12, y - 9, 18, 24, 3.5, white);
      case 'dup':
        strokeRR(c, x - 12, y - 18, 25, 25, 5, white, 3);
        fillRR(c, x - 6, y - 11, 25, 25, 5, white);
        line(c, [x + 6.5, y - 5, x + 6.5, y + 8], f, 3);
        line(c, [x, y + 1.5, x + 13, y + 1.5], f, 3);
      case 'hide':
        c.drawPath(
          Path()
            ..moveTo(x - 23, y - 4)
            ..quadraticBezierTo(x, y - 26, x + 23, y - 4)
            ..quadraticBezierTo(x, y + 18, x - 23, y - 4),
          fillPaint(white),
        );
        circle(c, x, y - 4, 7.5, fill: f);
        circle(c, x, y - 4, 4.5, fill: white);
        line(c, [x - 15, y - 20, x + 15, y + 12], f, 6);
        line(c, [x - 15, y - 20, x + 15, y + 12], white, 3);
      case 'slideshow':
        strokeRR(c, x - 19, y - 14, 38, 28, 5, white, 3);
        fillPoly(c, [x - 5, y - 7, x + 8, y, x - 5, y + 7], white);
      case 'addto':
        strokeRR(c, x - 17, y - 16, 34, 26, 5, white, 2.8);
        fillRR(c, x - 22, y - 9, 36, 27, 5, f);
        photoGlyph(c, x - 4, y + 4.5, 34, 25, white, 2.8);
      case 'info':
        circle(c, x, y, 15, stroke: white, lw: 2.8);
        circle(c, x, y - 7, 2.2, fill: white);
        line(c, [x - 3, y - 1.5, x, y - 1.5, x, y + 8], white, 2.6);
        line(c, [x - 4, y + 8.5, x + 4, y + 8.5], white, 2.6);
      case 'edits':
        for (final (dy, kx) in const [(-10.0, 6.0), (0.0, -6.0), (10.0, 4.0)]) {
          line(c, [x - 16, y + dy, x + 16, y + dy], white, 2.5);
          fillRR(c, x + kx - 5.5, y + dy - 4.5, 11, 9, 4.5, f);
          strokeRR(c, x + kx - 5.5, y + dy - 4.5, 11, 9, 4.5, white, 2.3);
        }
      case 'save':
        photoGlyph(c, x - 3, y - 2, 34, 27, white, 2.8);
        circle(c, x + 14, y + 11, 10.5, fill: f);
        circle(c, x + 14, y + 11, 8.5, fill: white);
        line(c, [x + 10, y + 11, x + 18, y + 11], f, 2.4);
        line(c, [x + 14, y + 7, x + 14, y + 15], f, 2.4);
    }
  }

  static void _drawMenu(Canvas c) {
    final w = rgb(238, 238, 238);
    _menuIcon(c, 'copy', 308, 112);
    tP(c, 'Copy', 308, 154, 23, 500, w, TextAlign.center);
    _menuIcon(c, 'dup', 460, 112);
    tP(c, 'Duplicate', 460, 154, 23, 500, w, TextAlign.center);
    _menuIcon(c, 'hide', 610, 114);
    tP(c, 'Hide', 610, 154, 23, 500, w, TextAlign.center);
    for (final y in const [200.0, 311, 572]) {
      fillRect(
        c,
        264,
        y - 0.75,
        392,
        1.5,
        const Color.fromRGBO(255, 255, 255, 0.065),
      );
    }
    _menuIcon(c, 'slideshow', 290, 256);
    tP(c, 'Start Slideshow', 336, 256, 30, 400, w);
    for (final (k, s, y) in const [
      ('addto', 'Add To', 365.0),
      ('info', 'Adjust Info', 441.0),
      ('edits', 'Edits', 518.0),
    ]) {
      _menuIcon(c, k, 290, y);
      tP(c, s, 336, y, 30, 400, w);
      chevronR(c, 648, y, 9, w, 3.4);
    }
    _menuIcon(c, 'save', 290, 646);
    tP(c, 'Save Video Frame', 336, 628, 30, 400, w);
    tP(c, 'as Photo', 336, 664, 30, 400, w);
  }

  @override
  void scene(Canvas c) {
    fillRect(c, 0, 0, W, H, const Color(0xFF000000));
    fillRR(c, 471, 14, 92, 36, 18, rgb(235, 52, 52));
    circle(c, 517, 32, 10, stroke: white, lw: 3);
    circle(c, 517, 32, 4.5, fill: white);
    // wifi
    for (final r0 in const [18.0, 11.0]) {
      arc(c, 600, 42, r0, -math.pi * 0.75, -math.pi * 0.25, white, 4);
    }
    circle(c, 600, 40, 3.5, fill: white);
    final battery = rrect(628, 20, 54, 25, 8);
    c.drawRRect(battery, fillPaint(const Color.fromRGBO(255, 255, 255, 0.38)));
    c.save();
    c.clipRRect(battery);
    fillRect(c, 628, 20, 27, 25, white);
    c.restore();
    tP(c, '48', 655, 32.5, 19, 700, const Color(0xFF000000), TextAlign.center);
    resizeArc(c, W, H);
  }

  @override
  GlassFrame params(Phase phase, double dt) {
    final p = GlassFrame(glass: glass)..lensW = 34;
    if (phase == Phase.idle || phase == Phase.pressOpen) {
      p.a = const GlassShape(cx: ccx, cy: ccy, w: cw, h: ch, r: 43.5);
      p.c0 = const Content(
        nat: Offset(ccx, ccy),
        now: Offset(ccx, ccy),
        alpha: 1,
      );
      p.lens = 3;
      p.lensW = 26;
      final pr = press;
      if (pr != null) {
        final pt = clamp01((clock.t - pressT) / 0.06);
        p.glass = glass.brighten(0.045 * pt);
        if (pr.kind == HitKind.press && pr is PhotosHit) {
          p.hi = Highlight(cx: pr.x, cy: ccy, w: 80, h: 70, r: 35, a: 0.1 * pt);
        }
      }
      return p;
    }
    if (phase == Phase.opening || phase == Phase.open) {
      final t = phase == Phase.open ? 9.0 : dt;
      const sp = springsOpen;
      final cx = lerp(dotsX, mcx, sp.cx.at(t)),
          cy = lerp(107, mcy, sp.cy.at(t));
      final w = lerp(40, mw, sp.w.at(t)), h = lerp(40, mh, sp.h.at(t));
      p.b = GlassShape(
        cx: cx,
        cy: cy,
        w: w,
        h: h,
        r: lerp(math.min(w, h) / 2, 56, ss(0.07, 0.22, t)),
        taper: 0.2 * ss(0.02, 0.05, t) * (1 - ss(0.07, 0.14, t)),
      );
      // The capsule drains into the droplet: its right end retracts fast, the
      // left end lags as a thinning tail.
      if (t <= 0.1) {
        final l = lerp(278, 540, ss(-0.02, 0.06, t)),
            r = lerp(695, 590, ss(-0.01, 0.035, t));
        final ah = lerp(87, 20, ss(0, 0.05, t)),
            acy = lerp(107.5, 124, ss(0, 0.04, t));
        p.a = GlassShape(
          cx: (l + r) / 2,
          cy: acy,
          w: math.max(r - l, ah),
          h: ah,
          r: ah / 2,
          fade: 120 * ss(0.035, 0.07, t),
        );
      }
      final e = ss(-0.01, 0.04, t);
      p.blend = 44 * (1 - ss(0.1, 0.26, t));
      p.lens =
          lerp(5, 38, ss(0, 0.06, t)) * (1 - ss(0.15, 0.48, t)) +
          4 * ss(0.15, 0.48, t);
      p.lensW = lerp(30, 58, ss(0, 0.08, t));
      p.c0 = Content(
        nat: const Offset(ccx, ccy),
        now: Offset(ccx + 18 * e, ccy + 8 * e),
        sx: 1 - 0.3 * e,
        sy: 1 - 0.15 * e,
        alpha: 1 - ss(0.005, 0.035, t),
        blur: 6 * ss(0, 0.035, t),
      );
      p.c1 = Content(
        nat: const Offset(mcx, mcy),
        now: Offset(cx, cy),
        alpha: ss(0.02, 0.17, t),
        blur: 10 * (1 - ss(0.11, 0.2, t)),
      );
      return p;
    }
    // closing
    final t = phase == Phase.pressClose ? 0.0 : dt;
    final cx = lerp(mcx, 482, spr(t, 0.42, 0.85, 0)),
        cy = lerp(mcy, 150, spr(t, 0.41, 0.6, -10.8));
    final shrink = 1 - ss(0.15, 0.27, t);
    final w = lerp(mw, 92, spr(t, 0.4, 0.95, 1.5)) * shrink;
    final h = lerp(mh, 92, spr(t, 0.42, 0.86, 1.8)) * shrink;
    if (t <= 0.31) {
      p.b = GlassShape(
        cx: cx,
        cy: cy,
        w: w,
        h: h,
        r: math.min(lerp(56, 400, ss(0.04, 0.16, t)), math.min(w, h) / 2),
        fade: 120 * ss(0.2, 0.3, t),
      );
    }
    if (t >= 0.04) {
      // A tip grows out of the menu's top-right corner, travels up and
      // becomes the capsule.
      final u = ss(0.04, 0.135, t);
      final sx = cx + w / 2 - 58, sy = cy - h / 2 + 52;
      final aw = lerp(64, cw, spr(t - 0.085, 0.49, 0.79, 9.5));
      final ah = lerp(64, ch, spr(t - 0.07, 0.42, 0.8, 8));
      final acx = lerp(566, ccx, spr(t - 0.085, 0.576, 0.878, 11.8));
      final acy = lerp(114, ccy, spr(t - 0.07, 0.45, 0.85, 6));
      p.a = GlassShape(
        cx: lerp(sx, acx, u),
        cy: lerp(sy, acy, u),
        w: aw,
        h: ah,
        r: math.min(aw, ah) / 2,
        fade: 70 * (1 - ss(0.04, 0.075, t)),
      );
    }
    p.blend = 46 * (1 - ss(0.3, 0.45, t));
    p.lensW = 34;
    p.lens =
        24 * ss(0, 0.08, t) * (1 - ss(0.12, 0.22, t)) + 3 * ss(0.12, 0.22, t);
    p.c1 = Content(
      nat: const Offset(mcx, mcy),
      now: Offset(cx, cy),
      s: lerp(1, 0.86, ss(0, 0.12, t)),
      alpha: 1 - ss(-0.01, 0.065, t),
      blur: 14 * ss(0, 0.06, t),
    );
    p.c0 = Content(
      nat: const Offset(ccx, ccy),
      now: Offset(ccx, ccy),
      alpha: ss(0.1, 0.18, t),
    );
    final pr = press;
    if (phase == Phase.pressClose && pr is PhotosHit && pr.item != null) {
      p.hi = pr.item;
    }
    return p;
  }
}
