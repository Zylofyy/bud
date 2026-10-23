import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'frame.dart';

/// A content layer, sharp and pre-softened. [rect] is the layer's extent in
/// source pixels, padding included.
class LayerImages {
  LayerImages({required this.rect, required this.sharp, required this.soft});

  final Rect rect;
  final ui.Image sharp;
  final ui.Image soft;

  void dispose() {
    sharp.dispose();
    soft.dispose();
  }
}

/// Binds a [GlassFrame] to the glass fragment shader and draws it. Each stage
/// on screen needs its own renderer, because a shader holds its uniforms.
class GlassRenderer {
  GlassRenderer(ui.FragmentProgram program)
    : _shader = program.fragmentShader() {
    final s = _shader;
    _res = s.getUniformVec2('uRes');
    _dpr = s.getUniformFloat('uDpr');
    _a = s.getUniformVec4('uA');
    _ar = s.getUniformVec2('uAr');
    _b = s.getUniformVec4('uB');
    _br = s.getUniformVec2('uBr');
    _bt = s.getUniformFloat('uBt');
    _k = s.getUniformFloat('uK');
    _alpha = s.getUniformFloat('uAlpha');
    _glass = s.getUniformVec4('uGlass');
    _glass2 = s.getUniformVec4('uGlass2');
    _opq = s.getUniformVec4('uOpq');
    _misc = s.getUniformVec4('uMisc');
    _c0r = s.getUniformVec4('uC0r');
    _c0x = s.getUniformVec4('uC0x');
    _c0m = s.getUniformVec4('uC0m');
    _c0free = s.getUniformFloat('uC0free');
    _c1r = s.getUniformVec4('uC1r');
    _c1x = s.getUniformVec4('uC1x');
    _c1m = s.getUniformVec4('uC1m');
    _hi = s.getUniformVec4('uHi');
    _hi2 = s.getUniformVec2('uHi2');
    _soft = s.getUniformFloat('uSoft');
  }

  static Future<ui.FragmentProgram>? _loading;
  static ui.FragmentProgram? _program;

  /// The glass program, once [loadProgram] has finished.
  static ui.FragmentProgram? get program => _program;

  static Future<ui.FragmentProgram> loadProgram() =>
      _loading ??= ui.FragmentProgram.fromAsset('shaders/glass.frag')
          .then((p) => _program = p);

  /// Blur (Gaussian sigma, source pixels) of the softened content copy that
  /// large content blurs sample from.
  static const softSigma = 2.0;

  // Sampler indices, in declaration order.
  static const _sBg = 0, _sBgBlur = 1, _sT0 = 2, _sT1 = 4;

  final ui.FragmentShader _shader;
  late final ui.UniformVec2Slot _res, _ar, _br, _hi2;
  late final ui.UniformFloatSlot _dpr, _bt, _k, _alpha, _c0free, _soft;
  late final ui.UniformVec4Slot _a, _b, _glass, _glass2, _opq, _misc;
  late final ui.UniformVec4Slot _c0r, _c0x, _c0m, _c1r, _c1x, _c1m, _hi;

  static ui.Image? _blank;

  static ui.Image get blank => _blank ??= () {
    final rec = ui.PictureRecorder();
    Canvas(rec);
    final pic = rec.endRecording();
    final img = pic.toImageSync(1, 1);
    pic.dispose();
    return img;
  }();

  void _sampler(int index, ui.Image image) =>
      _shader.setImageSampler(index, image, filterQuality: FilterQuality.low);

  void _shape(
    ui.UniformVec4Slot u,
    ui.UniformVec2Slot ur,
    GlassShape? s,
    double k,
  ) {
    if (s == null) {
      u.set(0, 0, 0, 0);
      ur.set(0, 10000);
      return;
    }
    u.set(
      s.cx * k,
      s.cy * k,
      math.max(0, s.w / 2) * k,
      math.max(0, s.h / 2) * k,
    );
    ur.set(math.max(0, s.r) * k, s.fade * k);
  }

  void _content(
    ui.UniformVec4Slot r,
    ui.UniformVec4Slot x,
    ui.UniformVec4Slot m,
    int sampler,
    Content? c,
    LayerImages? layer,
    double k,
  ) {
    if (c == null || layer == null || !(c.alpha > 0.002)) {
      r.set(0, 0, 1, 1);
      x.set(0, 0, 1, 1);
      m.set(0, 0, 0, 0);
      _sampler(sampler, blank);
      _sampler(sampler + 1, blank);
      return;
    }
    final rect = layer.rect;
    r.set(rect.left * k, rect.top * k, rect.width * k, rect.height * k);
    x.set(
      c.now.dx * k,
      c.now.dy * k,
      math.max(c.sx, 0.05),
      math.max(c.sy, 0.05),
    );
    m.set(c.nat.dx * k, c.nat.dy * k, c.alpha, c.blur * k);
    _sampler(sampler, layer.sharp);
    _sampler(sampler + 1, layer.soft);
  }

  /// Draws [f] over [size]. [k] is logical pixels per source pixel.
  void draw(
    Canvas canvas,
    Size size,
    GlassFrame f, {
    required double k,
    required double dpr,
    required ui.Image bg,
    required ui.Image bgBlur,
    required List<LayerImages?> layers,
  }) {
    _res.set(size.width, size.height);
    _dpr.set(dpr);
    _shape(_a, _ar, f.a, k);
    _shape(_b, _br, f.b, k);
    _bt.set(f.b?.taper ?? 0);
    _k.set(f.blend * k);
    _alpha.set(f.alpha);
    final g = f.glass;
    _glass.set(g.mul, g.add[0], g.add[1], g.add[2]);
    _glass2.set(g.blur * k, f.lens * k, f.lensW * k, g.rim);
    final oc = f.opaqueColor;
    _opq.set(f.opaque, oc[0], oc[1], oc[2]);
    _misc.set(f.dim, g.shadow, f.debug ? 1 : 0, k * 1.8);
    _content(_c0r, _c0x, _c0m, _sT0, f.c0, layers[0], k);
    _content(_c1r, _c1x, _c1m, _sT1, f.c1, layers[1], k);
    _c0free.set(f.c0 != null && f.c0!.free ? 1 : 0);
    final h = f.hi;
    if (h != null && h.a > 0) {
      _hi.set(h.cx * k, h.cy * k, h.w / 2 * k, h.h / 2 * k);
      _hi2.set(h.r * k, h.a);
    } else {
      _hi.set(0, 0, 0, 0);
      _hi2.set(0, 0);
    }
    _soft.set(softSigma * k);
    _sampler(_sBg, bg);
    _sampler(_sBgBlur, bgBlur);
    canvas.drawRect(Offset.zero & size, Paint()..shader = _shader);
  }

  void dispose() => _shader.dispose();
}
