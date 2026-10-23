import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'clock.dart';
import 'frame.dart';
import 'renderer.dart';

enum Phase { idle, pressOpen, opening, open, pressClose, closing }

enum HitKind { open, close, press }

/// What a press landed on. Demos subclass it to carry their own details.
class Hit {
  const Hit(this.kind, {this.hold = 0.08});

  final HitKind kind;

  /// How long the looping demo holds this press before releasing.
  final double hold;
}

/// A content layer: [rect] (source pixels) and how to draw it.
class LayerSpec {
  const LayerSpec(this.rect, this.draw);

  final Rect rect;
  final void Function(Canvas c) draw;
}

class _Signal extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// One recreated recording: its screen, its glass and the press → open →
/// press → close cycle, driven by a [LabClock].
///
/// Listeners hear about phase and loop changes; [repaint] fires when the
/// stage needs drawing.
abstract class GlassDemo extends ChangeNotifier {
  GlassDemo(this.clock, {this.loop = true, double firstAuto = 0.6})
    : autoNext = firstAuto;

  final LabClock clock;

  // ── The recording ──

  /// Source video size in pixels.
  double get width;
  double get height;

  double get pressDur;
  double get openDur;
  double get closeDur;
  String get idleHint;
  String get openHint;
  GlassStyle get glass;

  /// The two content layers: what the glass starts as, and what it becomes.
  List<LayerSpec> layers();

  Hit defaultOpen();
  Hit defaultClose();

  /// What a press at [x], [y] (source pixels) does, if anything.
  Hit? hit(double x, double y);

  void prepareOpen(Hit hit) {}
  void onClosed() {}

  /// Draws the screen behind the glass.
  void scene(Canvas c);

  /// The glass for [phase], [dt] seconds after it began.
  GlassFrame params(Phase phase, double dt);

  // ── State ──

  Phase phase = Phase.idle;

  /// Clock time the current phase began.
  double pt = 0;
  Hit? press;
  double pressT = 0;
  bool loop;
  double autoNext;
  bool _dirty = true;
  bool _debugShapes = false;

  final _repaint = _Signal();
  Listenable get repaint => _repaint;

  final hudLabel = ValueNotifier<String>('idle');
  final hudLive = ValueNotifier<bool>(false);

  bool get debugShapes => _debugShapes;
  set debugShapes(bool v) {
    _debugShapes = v;
    _dirty = true;
    notifyListeners();
  }

  void setLoop(bool on) {
    loop = on;
    if (on) autoNext = clock.t + 0.3;
    notifyListeners();
  }

  void _stopLoop() {
    if (!loop) return;
    loop = false;
    notifyListeners();
  }

  void _setPhase(Phase p) {
    phase = p;
    pt = clock.t;
    _dirty = true;
    notifyListeners();
  }

  // ── Input ──

  void onDown(double x, double y) {
    _stopLoop();
    final h = hit(x, y);
    if (h == null) return;
    press = h;
    pressT = clock.t;
    if (h.kind == HitKind.open) {
      prepareOpen(h);
      _setPhase(Phase.pressOpen);
    } else if (h.kind == HitKind.close) {
      _setPhase(Phase.pressClose);
    } else {
      _setPhase(phase);
    }
    onPressChanged();
    refreshBg();
  }

  void onUp() {
    final h = press;
    if (h == null) return;
    press = null;
    if (h.kind == HitKind.open && phase == Phase.pressOpen) {
      beginOpen();
    } else if (h.kind == HitKind.close && phase == Phase.pressClose) {
      beginClose();
    }
    onPressChanged();
    refreshBg();
  }

  void cancelPress() {
    if (press == null) return;
    press = null;
    _setPhase(
      phase == Phase.pressOpen
          ? Phase.idle
          : phase == Phase.pressClose
          ? Phase.open
          : phase,
    );
    onPressChanged();
    refreshBg();
  }

  /// Called when [press] starts or ends, for layers that show it.
  void onPressChanged() {}

  void beginOpen() {
    _setPhase(Phase.opening);
    refreshBg();
  }

  void beginClose() {
    _setPhase(Phase.closing);
    refreshBg();
  }

  /// The open button under the stage: plays the open without a press.
  void cmdOpen() {
    if (phase != Phase.idle) return;
    _stopLoop();
    prepareOpen(defaultOpen());
    press = null;
    _setPhase(Phase.opening);
    refreshBg();
  }

  /// The close button under the stage.
  void cmdClose() {
    if (phase != Phase.open) return;
    _stopLoop();
    press = null;
    _setPhase(Phase.closing);
    refreshBg();
  }

  void _auto() {
    if (!loop || clock.t < autoNext) return;
    final t = clock.t;
    switch (phase) {
      case Phase.idle:
        final h = defaultOpen();
        press = h;
        pressT = t;
        prepareOpen(h);
        _setPhase(Phase.pressOpen);
        onPressChanged();
        refreshBg();
        autoNext = t + pressDur;
      case Phase.pressOpen:
        press = null;
        onPressChanged();
        beginOpen();
        autoNext = t + openDur + 1.25;
      case Phase.open:
        final h = defaultClose();
        press = h;
        pressT = t;
        _setPhase(Phase.pressClose);
        onPressChanged();
        refreshBg();
        autoNext = t + h.hold;
      case Phase.pressClose:
        press = null;
        onPressChanged();
        beginClose();
        autoNext = t + closeDur + 1.0;
      case Phase.opening || Phase.closing:
        break;
    }
  }

  /// Runs once per frame: loops the demo, ends finished phases and asks for
  /// a repaint when something moved.
  void update() {
    if (k == 0) return;
    _auto();
    final dt = clock.t - pt;
    if (phase == Phase.opening && dt >= openDur) {
      _setPhase(Phase.open);
      refreshBg();
    }
    if (phase == Phase.closing && dt >= closeDur) {
      _setPhase(Phase.idle);
      onClosed();
      refreshBg();
    }
    final animating = phase != Phase.idle && phase != Phase.open;
    if (!animating && !_dirty && press == null) return;
    _dirty = false;
    _repaint.ping();
    final elapsed = clock.t - pt;
    final f = (elapsed * 60 + 1e-6).floor().toString().padLeft(2, '0');
    final ms = (elapsed * 1000).round();
    hudLabel.value = switch (phase) {
      Phase.idle => 'idle · $idleHint',
      Phase.pressOpen || Phase.pressClose => 'press',
      Phase.opening => 'opening · f $f · $ms ms',
      Phase.open => 'open · $openHint',
      Phase.closing => 'closing · f $f · $ms ms',
    };
    hudLive.value = phase == Phase.opening || phase == Phase.closing;
  }

  // ── Rasterising ──

  /// Logical pixels per source pixel.
  double k = 0;
  double _dpr = 1;

  /// Texture pixels per source pixel.
  double _px = 1;
  ui.Image? _bg;
  ui.Image? _bgBlur;
  final List<LayerImages?> _layers = [null, null];

  void resize(Size size, double dpr) {
    final nk = size.width / width;
    if (nk == k && dpr == _dpr) return;
    k = nk;
    _dpr = dpr;
    var scale = math.min(dpr, 3.0);
    final longest = math.max(size.width, size.height) * scale;
    if (longest > 4096) scale *= 4096 / longest;
    _px = k * scale;
    buildLayers();
    refreshBg();
  }

  static ui.Image _record(int w, int h, void Function(Canvas c) draw) {
    final rec = ui.PictureRecorder();
    draw(Canvas(rec));
    final pic = rec.endRecording();
    final img = pic.toImageSync(w, h);
    pic.dispose();
    return img;
  }

  /// [src] scaled by [factor] and blurred by [sigma] source pixels.
  ui.Image _blurred(ui.Image src, double factor, double sigma, TileMode mode) {
    final w = math.max(1, (src.width * factor).round());
    final h = math.max(1, (src.height * factor).round());
    final s = sigma * _px * factor;
    return _record(w, h, (c) {
      final paint = Paint()..filterQuality = FilterQuality.medium;
      if (s > 0.3) {
        paint.imageFilter = ui.ImageFilter.blur(
          sigmaX: s,
          sigmaY: s,
          tileMode: mode,
        );
      }
      c.drawImageRect(
        src,
        Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        paint,
      );
    });
  }

  LayerImages _rasterLayer(LayerSpec spec) {
    const pad = 40.0;
    final x = spec.rect.left - pad, y = spec.rect.top - pad;
    final w = math.max(2, ((spec.rect.width + pad * 2) * _px).ceil());
    final h = math.max(2, ((spec.rect.height + pad * 2) * _px).ceil());
    final sharp = _record(w, h, (c) {
      c.scale(_px);
      c.translate(-x, -y);
      spec.draw(c);
    });
    return LayerImages(
      rect: Rect.fromLTWH(x, y, w / _px, h / _px),
      sharp: sharp,
      soft: _blurred(sharp, 0.5, GlassRenderer.softSigma, TileMode.decal),
    );
  }

  void buildLayers() {
    if (k == 0) return;
    final specs = layers();
    for (var i = 0; i < 2; i++) {
      _layers[i]?.dispose();
      _layers[i] = i < specs.length ? _rasterLayer(specs[i]) : null;
    }
    _dirty = true;
  }

  /// Rebuilds one layer, e.g. to show a pressed button inside it.
  void rebuildLayer(int i) {
    if (k == 0) return;
    _layers[i]?.dispose();
    _layers[i] = _rasterLayer(layers()[i]);
    _dirty = true;
  }

  void refreshBg() {
    if (k == 0) return;
    final w = math.max(1, (width * _px).round());
    final h = math.max(1, (height * _px).round());
    final bg = _record(w, h, (c) {
      c.scale(_px);
      scene(c);
    });
    _bg?.dispose();
    _bgBlur?.dispose();
    _bg = bg;
    _bgBlur = _blurred(bg, 0.5, glass.blur * 0.5, TileMode.clamp);
    _dirty = true;
  }

  /// Draws the stage at [size] (logical pixels).
  void paint(Canvas canvas, Size size, GlassRenderer renderer) {
    final bg = _bg, bgBlur = _bgBlur;
    if (bg == null || bgBlur == null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF000000),
      );
      return;
    }
    final f = params(phase, clock.t - pt)..debug = _debugShapes;
    renderer.draw(
      canvas,
      size,
      f,
      k: k,
      dpr: _dpr,
      bg: bg,
      bgBlur: bgBlur,
      layers: _layers,
    );
  }

  @override
  void dispose() {
    _bg?.dispose();
    _bgBlur?.dispose();
    for (final l in _layers) {
      l?.dispose();
    }
    _repaint.dispose();
    hudLabel.dispose();
    hudLive.dispose();
    super.dispose();
  }
}
