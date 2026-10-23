import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../glass/demo.dart';
import '../glass/renderer.dart';
import '../theme.dart';

/// The device-screen frame around a stage: rounded, outlined and lifted.
class StageFrame extends StatelessWidget {
  const StageFrame({super.key, required this.child, this.radius = 22});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: lab.line, spreadRadius: 1),
          const BoxShadow(
            color: Color(0x8C000000),
            offset: Offset(0, 18),
            blurRadius: 40,
            spreadRadius: -24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(color: const Color(0xFF000000), child: child),
      ),
    );
  }
}

/// A live glass demo: runs the demo's clock, draws it with the glass shader
/// and, when [interactive], turns touches into presses inside the screen.
class GlassStage extends StatefulWidget {
  const GlassStage({
    super.key,
    required this.demo,
    this.interactive = true,
    this.showHud = true,
    this.semanticLabel,
  });

  final GlassDemo demo;
  final bool interactive;
  final bool showHud;
  final String? semanticLabel;

  @override
  State<GlassStage> createState() => _GlassStageState();
}

class _GlassStageState extends State<GlassStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  GlassRenderer? _renderer;
  int? _pointer;
  Offset _downAt = Offset.zero;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    final loaded = GlassRenderer.program;
    if (loaded != null) {
      _renderer = GlassRenderer(loaded);
    } else {
      GlassRenderer.loadProgram().then((program) {
        if (mounted) setState(() => _renderer = GlassRenderer(program));
      });
    }
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    widget.demo.clock.advance(dt);
    widget.demo.update();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _renderer?.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent e) {
    if (_pointer != null || _size.isEmpty) return;
    _pointer = e.pointer;
    _downAt = e.localPosition;
    final d = widget.demo;
    d.onDown(
      e.localPosition.dx / _size.width * d.width,
      e.localPosition.dy / _size.height * d.height,
    );
  }

  void _move(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    // A drag is a scroll, not a press.
    if ((e.localPosition - _downAt).distance > kTouchSlop) {
      _pointer = null;
      widget.demo.cancelPress();
    }
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    widget.demo.onUp();
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    widget.demo.cancelPress();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        widget.demo.resize(_size, dpr);
        Widget stage = CustomPaint(
          size: _size,
          painter: _StagePainter(widget.demo, _renderer),
        );
        if (widget.interactive) {
          stage = Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: _cancel,
            child: stage,
          );
        }
        return Semantics(
          label: widget.semanticLabel,
          image: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              stage,
              if (widget.showHud)
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _Hud(demo: widget.demo),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.demo, this.renderer) : super(repaint: demo.repaint);

  final GlassDemo demo;
  final GlassRenderer? renderer;

  @override
  void paint(Canvas canvas, Size size) {
    final r = renderer;
    if (r == null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF000000),
      );
      return;
    }
    demo.paint(canvas, size, r);
  }

  @override
  bool shouldRepaint(_StagePainter old) =>
      old.demo != demo || old.renderer != renderer;
}

/// The recording-style status pill: phase, frame and milliseconds.
class _Hud extends StatelessWidget {
  const _Hud({required this.demo});

  final GlassDemo demo;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            color: const Color(0x9E0A0A0C),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: demo.hudLive,
                  builder: (context, live, _) => Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: live
                          ? const Color(0xFFFF453A)
                          : const Color(0xFF6B6F78),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                ValueListenableBuilder<String>(
                  valueListenable: demo.hudLabel,
                  builder: (context, label, _) => Text(
                    label,
                    style: LabText.mono(
                      const Color(0xFFF2F3F5),
                      size: 11,
                      weight: FontWeight.w500,
                    ).copyWith(letterSpacing: 0.44, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
