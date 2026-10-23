import 'dart:math' as math;
import 'dart:ui';

import '../glass/demo.dart';
import '../glass/draw_kit.dart';
import '../glass/frame.dart';
import '../glass/motion.dart';

// Demo 1 · Music track ⋯ menu (1000028968.mp4, 756×1050).

class MenuRow {
  const MenuRow(
    this.n,
    this.title,
    this.sub,
    this.y, {
    this.e = false,
    this.cut = false,
    this.dim = false,
    this.mark = false,
  });

  final int n;
  final String title;
  final List<String> sub;
  final double y;

  /// Explicit badge.
  final bool e;

  /// Cut off by the top of the recording.
  final bool cut;
  final bool dim;
  final bool mark;
}

class MenuHit extends Hit {
  const MenuHit.open(MenuRow this.row) : item = null, super(HitKind.open);

  const MenuHit.close({this.item, super.hold})
    : row = null,
      super(HitKind.close);

  final MenuRow? row;

  /// 'lib', 'share' or 'pl' (Add to Playlist).
  final String? item;
}

class MenuRect {
  MenuRect(MenuRow row) {
    var top = row.y - 44;
    if (top + h > MenuDemo.H - 12) top = row.y + 44 - h;
    y = top;
  }

  final double x = 293, w = 458, h = 245;
  late final double y;

  double get cx => x + w / 2;
  double get cy => y + h / 2;
}

class MenuDemo extends GlassDemo {
  MenuDemo(super.clock, {super.loop, super.firstAuto}) {
    row = rows[4];
    mr = MenuRect(row);
  }

  static const W = 756.0, H = 1050.0;

  static final bg = rgb(28, 36, 71);
  static const glassFill = [45, 59, 102];
  static final title = rgb(249, 252, 255);
  static final sub = rgb(150, 161, 201);
  static final num = rgb(149, 160, 200);
  static final dimTitle = rgb(69, 79, 116);
  static final dimSub = rgb(85, 96, 133);
  static final dotsCol = rgb(163, 173, 222);
  static final dotsPressed = rgb(225, 231, 255);
  static final sep = rgb(52, 60, 96);

  static const rows = [
    MenuRow(2, 'Metro Boomin)', ['Yung Lean'], 26, e: true, cut: true),
    MenuRow(3, 'Track 3', ['unknown'], 149, dim: true),
    MenuRow(4, 'RHYNO', ['Travis Scott'], 271, e: true),
    MenuRow(5, 'Sexy Magic', [
      'CA7RIEL & Paco Amoroso, PinkPantheress,',
      'Fred again.. & Etienne de Crécy',
    ], 394),
    MenuRow(
      6,
      'Flower In A Hurricane',
      ['Justice, King Gizzard & The Lizard Wizard,', 'Tame Impala & SZA'],
      551,
      mark: true,
    ),
    MenuRow(7, 'Track 7', ['unknown'], 709, dim: true),
    MenuRow(8, 'Last Thing You Need', ['Morgan Wallen'], 832, mark: true),
    MenuRow(9, 'Track 9', ['unknown'], 954, dim: true),
    MenuRow(10, 'Good Luck, Babe!', ['Chappell Roan'], 1076),
  ];
  static const seps = [99.0, 222, 344, 502, 659, 782, 904, 1028];
  static const btnX = 706.0;

  static const springsOpen = AxisSprings(
    cx: Spring(0.469, 0.906, 14.6),
    cy: Spring(0.329, 0.753, 37.0),
    w: Spring(0.444, 0.862, 12.8),
    h: Spring(0.274, 0.993, 28.7),
  );
  static const springsClose = AxisSprings(
    cx: Spring(0.545, 0.567, 0, 0.017),
    cy: Spring(0.414, 0.827, -21.9, 0.027),
    w: Spring(0.445, 0.873, 0.36, 0.017),
    h: Spring(0.647, 0.5, 0, 0.047),
  );

  static final tM = ScreenText([
    (400, 33, 'Flower In A Hurricane', 305),
    (400, 26, 'Travis Scott', 141),
    (400, 30, 'Add to Playlist', 192),
    (500, 21, 'Add to Library', 150),
  ]);

  late MenuRow row;
  late MenuRect mr;

  @override
  double get width => W;
  @override
  double get height => H;
  @override
  double get pressDur => 0.06;
  @override
  double get openDur => 0.62;
  @override
  double get closeDur => 0.26;
  @override
  String get idleHint => 'tap ⋯';
  @override
  String get openHint => 'tap to dismiss';
  @override
  final glass = const GlassStyle(
    mul: 1.35,
    add: [0.028, 0.04, 0.024],
    blur: 13,
    rim: 0.13,
    shadow: 0.16,
  );

  @override
  List<LayerSpec> layers() {
    final r = row, m = mr;
    return [
      LayerSpec(
        Rect.fromLTWH(btnX - 30, r.y - 20, 60, 40),
        (c) => dots(c, btnX, r.y, 12, 3.5, dotsPressed),
      ),
      LayerSpec(
        Rect.fromLTWH(m.x, m.y, m.w, m.h),
        (c) => _drawMenuContent(c, m),
      ),
    ];
  }

  @override
  void prepareOpen(Hit hit) {
    final r = (hit as MenuHit).row;
    if (r != null && r != row) {
      row = r;
      mr = MenuRect(row);
      buildLayers();
    }
  }

  @override
  Hit defaultOpen() => MenuHit.open(rows[4]);

  @override
  Hit defaultClose() => const MenuHit.close();

  @override
  Hit? hit(double x, double y) {
    if (phase == Phase.idle) {
      for (final r in rows) {
        if (!r.cut && (x - btnX).abs() < 40 && (y - r.y).abs() < 40) {
          return MenuHit.open(r);
        }
      }
      return null;
    }
    if (phase == Phase.open) {
      final m = mr;
      String? item;
      if (x > m.x && x < m.x + m.w && y > m.y && y < m.y + m.h) {
        item = y < m.y + 137 ? (x < m.cx ? 'lib' : 'share') : 'pl';
      }
      return MenuHit.close(item: item, hold: 0.1);
    }
    return null;
  }

  @override
  void scene(Canvas c) {
    fillRect(c, 0, 0, W, H, bg);
    for (final s in seps) {
      fillRect(c, 82, s - 0.75, 652, 1.5, sep);
    }
    final hideRow =
        phase == Phase.opening || phase == Phase.open || phase == Phase.closing
        ? row
        : null;
    final pressedRow = press is MenuHit ? (press as MenuHit).row : null;
    for (final r in rows) {
      final tc = r.dim ? dimTitle : title, sc = r.dim ? dimSub : sub;
      if (!r.cut) tM(c, '${r.n}', 41, r.y, 31, 400, num, TextAlign.center);
      tM(c, r.title, 84, r.y, 33, 400, tc);
      if (r.e) {
        final tw = ScreenText.measure(r.title, 33, 400) * tM.fit(33, 400);
        final bx = 84 + tw + 12;
        fillRR(c, bx, r.y - 11.5, 23, 23, 5, rgb(170, 178, 214));
        tM(c, 'E', bx + 11.5, r.y, 16, 700, bg, TextAlign.center);
      }
      for (var i = 0; i < r.sub.length; i++) {
        tM(c, r.sub[i], 82, r.y + 41 + i * 34, 26, 400, sc);
      }
      if (r.mark) circle(c, 4, r.y, 5, fill: rgb(147, 159, 201));
      if (!r.cut && r != hideRow) {
        dots(c, btnX, r.y, 12, 3.5, pressedRow == r ? dotsPressed : dotsCol);
      }
    }
  }

  static void _drawMenuContent(Canvas c, MenuRect m) {
    final fill = rgb(glassFill[0], glassFill[1], glassFill[2]);
    final yTop = m.y + 49, yLab = m.y + 90.5;
    final xL = m.x + 127, xR = m.x + 341;
    // Add to Library: plus.circle.fill
    circle(c, xL, yTop, 17, fill: white);
    line(c, [xL - 8, yTop, xL + 8, yTop], fill, 3.6);
    line(c, [xL, yTop - 8, xL, yTop + 8], fill, 3.6);
    tM(c, 'Add to Library', xL, yLab, 21, 500, white, TextAlign.center);
    // Share: square.and.arrow.up.fill
    fillRR(c, xR - 14, yTop - 5, 28, 23, 5, white);
    fillRect(c, xR - 5, yTop - 6, 10, 6, fill);
    line(c, [xR, yTop + 7, xR, yTop - 2], fill, 3.4);
    line(c, [xR, yTop - 2, xR, yTop - 19], white, 3.4);
    line(c, [xR - 7, yTop - 12, xR, yTop - 19, xR + 7, yTop - 12], white, 3.4);
    tM(c, 'Share', xR, yLab, 21, 500, white, TextAlign.center);
    fillRect(
      c,
      m.x + 49,
      m.y + 136.5,
      369,
      1.5,
      const Color.fromRGBO(255, 255, 255, 0.12),
    );
    // Add to Playlist row
    final ry = m.y + 191, ix = m.x + 76;
    circle(c, ix - 9, ry - 9, 8, fill: white);
    line(c, [ix - 13, ry - 9, ix - 5, ry - 9], fill, 2.4);
    line(c, [ix - 9, ry - 13, ix - 9, ry - 5], fill, 2.4);
    line(c, [ix + 4, ry - 10, ix + 20, ry - 10], white, 3);
    line(c, [ix + 4, ry, ix + 20, ry], white, 3);
    line(c, [ix - 17, ry + 10, ix + 20, ry + 10], white, 3);
    tM(c, 'Add to Playlist', m.x + 121, ry, 30, 400, white);
  }

  @override
  GlassFrame params(Phase phase, double dt) {
    final r = row, m = mr;
    final bx = btnX - 4, by = r.y - 2;
    final p = GlassFrame(glass: glass)..lensW = 28;
    if (phase == Phase.idle || phase == Phase.pressOpen) return p;
    double cx, cy, w, h, rad, alpha;
    if (phase == Phase.opening || phase == Phase.open) {
      final t = phase == Phase.open ? 9.0 : dt;
      const sp = springsOpen;
      cx = lerp(bx, m.cx, sp.cx.at(t));
      cy = lerp(by, m.cy, sp.cy.at(t));
      w = lerp(44, m.w, sp.w.at(t));
      h = lerp(44, m.h, sp.h.at(t));
      rad = lerp(math.min(w, h) / 2, 34, ss(0.06, 0.25, t));
      p.lens = lerp(24, 6, ss(0.08, 0.4, t));
      alpha = 0.35 + 0.65 * ss(0, 0.07, t);
      p.c0 = Content(
        nat: Offset(btnX, r.y),
        now: Offset(cx + 4, cy + 2),
        s: 1 + t * 3,
        alpha: 1 - ss(0, 0.05, t),
        blur: 4 + 8 * ss(0, 0.05, t),
      );
      p.c1 = Content(
        nat: Offset(m.cx, m.cy),
        now: Offset(cx, cy),
        s: 0.94 + 0.06 * ss(0, 0.15, t),
        alpha: clamp01(0.15 + 0.85 * t / 0.12),
        blur: 14 * (1 - ss(0.1, 0.19, t)),
      );
    } else {
      final t = phase == Phase.pressClose ? 0.0 : dt;
      const sp = springsClose;
      cx = lerp(m.cx, bx, sp.cx.at(t));
      cy = lerp(m.cy, by, sp.cy.at(t));
      w = lerp(m.w, 44, sp.w.at(t));
      h = lerp(m.h, 44, sp.h.at(t));
      h = math.max(h, 30);
      rad = math.min(lerp(34, 400, ss(0.04, 0.16, t)), math.min(w, h) / 2);
      alpha = 1 - ss(0.08, 0.2, t);
      p.lens = lerp(8, 22, ss(0.02, 0.12, t));
      p.c1 = Content(
        nat: Offset(m.cx, m.cy),
        now: Offset(cx, cy),
        s: lerp(1, 0.88, ss(0.02, 0.12, t)),
        alpha: 1 - ss(0.02, 0.12, t),
        blur: 11 * ss(0.02, 0.1, t),
      );
      p.c0 = Content(
        nat: Offset(btnX, r.y),
        now: Offset(btnX, r.y),
        alpha: ss(0.15, 0.23, t),
        free: true,
      );
      final item = press is MenuHit ? (press as MenuHit).item : null;
      if (phase == Phase.pressClose && item != null) {
        p.hi = item == 'pl'
            ? Highlight(
                cx: m.cx,
                cy: m.y + 191,
                w: m.w - 24,
                h: 86,
                r: 22,
                a: 0.08,
              )
            : Highlight(
                cx: item == 'lib' ? m.x + 120 : m.x + 340,
                cy: m.y + 70,
                w: 200,
                h: 112,
                r: 22,
                a: 0.08,
              );
      }
    }
    p.b = GlassShape(cx: cx, cy: cy, w: w, h: h, r: rad);
    p.alpha = alpha;
    return p;
  }
}
