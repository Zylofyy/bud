import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../demos/catalog.dart';
import '../glass/motion.dart';
import '../theme.dart';

/// A demo's analysis: frame-by-frame notes, the fitted springs and the
/// measured-vs-rebuilt open curve.
class NotesPanel extends StatelessWidget {
  const NotesPanel({super.key, required this.info});

  final DemoInfo info;

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lab.surface,
        border: Border.all(color: lab.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('FRAME BY FRAME', style: LabText.label(lab)),
          const SizedBox(height: 14),
          _Phases(phases: info.phases),
          const SizedBox(height: 14),
          Text('FITTED SPRINGS · OPEN', style: LabText.label(lab)),
          const SizedBox(height: 14),
          _SpringTable(springs: info.springs),
          const SizedBox(height: 14),
          CurveChart(info: info),
        ],
      ),
    );
  }
}

class _Phases extends StatelessWidget {
  const _Phases({required this.phases});

  final List<(String, String)> phases;

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        for (final (frames, text) in phases)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 6, top: 2),
                child: Text(
                  frames,
                  style: LabText.mono(lab.ink, weight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: displayFont,
                    fontSize: 14,
                    height: 1.5,
                    color: lab.muted,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: 9,
    margin: const EdgeInsets.only(right: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _SpringTable extends StatelessWidget {
  const _SpringTable({required this.springs});

  final AxisSprings springs;

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    final head = LabText.mono(lab.muted, weight: FontWeight.w500);
    final cell = LabText.mono(lab.ink);
    final border = BoxDecoration(
      border: Border(bottom: BorderSide(color: lab.line)),
    );
    Widget c(String s, TextStyle st, {bool left = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        s,
        style: st,
        textAlign: left ? TextAlign.left : TextAlign.right,
      ),
    );
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.3)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: border,
          children: [
            c('channel', head, left: true),
            c('response', head),
            c('damping', head),
            c('v₀', head),
          ],
        ),
        for (final ch in Channel.values)
          TableRow(
            decoration: border,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    _Swatch(lab.series[ch.index]),
                    Flexible(child: Text(ch.label, style: cell)),
                  ],
                ),
              ),
              c('${springs[ch].response.toStringAsFixed(3)} s', cell),
              c(springs[ch].damping.toStringAsFixed(2), cell),
              c(springs[ch].v0.toStringAsFixed(1), cell),
            ],
          ),
      ],
    );
  }
}

/// Measured frames (dots) against the fitted springs (lines), normalised
/// from 0 to rest. Touch the plot to read values off it.
class CurveChart extends StatefulWidget {
  const CurveChart({super.key, required this.info});

  final DemoInfo info;

  @override
  State<CurveChart> createState() => _CurveChartState();
}

class _CurveChartState extends State<CurveChart> {
  int? _selected;
  bool _showTable = false;

  void _pick(Offset local, double width) {
    final g = _ChartGeometry(widget.info);
    final sx = local.dx / width * _ChartGeometry.wd;
    final tt =
        (sx - _ChartGeometry.x0) /
        (_ChartGeometry.x1 - _ChartGeometry.x0) *
        _ChartGeometry.tMax;
    var best = 0;
    for (var i = 0; i < g.data.length; i++) {
      if ((g.data[i][0] - tt).abs() < (g.data[best][0] - tt).abs()) best = i;
    }
    setState(() => _selected = best);
  }

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    final info = widget.info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'OPEN: MEASURED (DOTS) VS REBUILT (LINES), NORMALISED 0 → REST',
          style: LabText.label(lab),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Semantics(
              label:
                  'Normalised progress over time for ${info.id}: measured frames versus fitted springs',
              child: GestureDetector(
                onTapDown: (d) => _pick(d.localPosition, w),
                onHorizontalDragStart: (d) => _pick(d.localPosition, w),
                onHorizontalDragUpdate: (d) => _pick(d.localPosition, w),
                onLongPress: () => setState(() => _selected = null),
                child: CustomPaint(
                  size: Size(w, w * _ChartGeometry.hd / _ChartGeometry.wd),
                  painter: _ChartPainter(_ChartGeometry(info), lab, _selected),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final ch in Channel.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Swatch(lab.series[ch.index]),
                  Text(ch.label, style: LabText.mono(lab.muted, size: 11)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _showTable = !_showTable),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _showTable ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: 18,
                  color: lab.muted,
                ),
                Text(
                  'Measured frames (${info.measured.length})',
                  style: LabText.mono(lab.muted, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        if (_showTable) _MeasuredTable(data: info.measured),
      ],
    );
  }
}

class _ChartGeometry {
  _ChartGeometry(DemoInfo info)
    : data = info.measured,
      springs = info.springs,
      lo = info.chartLo,
      hi = info.chartHi;

  static const wd = 320.0,
      hd = 178.0,
      x0 = 30.0,
      x1 = 312.0,
      y0 = 12.0,
      y1 = 150.0,
      tMax = 450.0;

  final List<List<double>> data;
  final AxisSprings springs;
  final double lo;
  final double hi;

  double x(double t) => x0 + (x1 - x0) * t / tMax;
  double y(double v) => y1 - (y1 - y0) * (v.clamp(lo, hi) - lo) / (hi - lo);
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.g, this.lab, this.selected);

  final _ChartGeometry g;
  final LabColors lab;
  final int? selected;

  void _text(Canvas c, String s, double x, double y, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: LabText.mono(lab.muted, size: 9.5).copyWith(height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final dx = align == TextAlign.right
        ? -tp.width
        : (align == TextAlign.center ? -tp.width / 2 : 0.0);
    tp.paint(c, Offset(x + dx, y - base));
    tp.dispose();
  }

  void _dashed(Canvas c, double xa, double xb, double y, Paint p) {
    for (var x = xa; x < xb; x += 6) {
      c.drawLine(Offset(x, y), Offset(math.min(x + 3, xb), y), p);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _ChartGeometry.wd;
    canvas.save();
    canvas.scale(scale);
    const x0 = _ChartGeometry.x0, x1 = _ChartGeometry.x1;
    for (final v in const [0.0, 0.5, 1.0]) {
      final p = Paint()
        ..color = lab.line
        ..strokeWidth = v == 1 ? 1.4 : 1;
      if (v == 1) {
        canvas.drawLine(Offset(x0, g.y(v)), Offset(x1, g.y(v)), p);
      } else {
        _dashed(canvas, x0, x1, g.y(v), p);
      }
      _text(
        canvas,
        v == 1 ? 'rest' : v.toStringAsFixed(1),
        x0 - 6,
        g.y(v) + 3.5,
        TextAlign.right,
      );
    }
    for (var t = 0; t <= _ChartGeometry.tMax; t += 100) {
      _text(
        canvas,
        '$t${t == 400 ? ' ms' : ''}',
        g.x(t.toDouble()),
        _ChartGeometry.y1 + 15,
        TextAlign.center,
      );
    }
    canvas.drawLine(
      const Offset(x0, _ChartGeometry.y1),
      const Offset(x1, _ChartGeometry.y1),
      Paint()..color = lab.muted,
    );
    for (final ch in Channel.values) {
      final fill = Paint()
        ..color = lab.series[ch.index].withValues(alpha: 0.75);
      final ring = Paint()
        ..color = lab.surface.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (final row in g.data) {
        if (row[0] > _ChartGeometry.tMax) continue;
        final o = Offset(g.x(row[0]), g.y(row[ch.index + 1]));
        canvas.drawCircle(o, 3.2, fill);
        canvas.drawCircle(o, 3.2, ring);
      }
    }
    for (final ch in Channel.values) {
      final path = Path();
      for (var t = 0; t <= _ChartGeometry.tMax; t += 4) {
        final o = Offset(g.x(t.toDouble()), g.y(g.springs[ch].at(t / 1000)));
        t == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = lab.series[ch.index]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final sel = selected;
    if (sel != null) {
      final row = g.data[sel];
      final sx = g.x(row[0]);
      canvas.drawLine(
        Offset(sx, _ChartGeometry.y0),
        Offset(sx, _ChartGeometry.y1),
        Paint()..color = lab.ink.withValues(alpha: 0.5),
      );
    }
    canvas.restore();
    if (sel != null) _tooltip(canvas, size, scale, g.data[sel]);
  }

  void _tooltip(Canvas canvas, Size size, double scale, List<double> row) {
    final lines = [
      '${row[0].round()} ms   meas / fit',
      for (final ch in Channel.values)
        '${ch.label.padRight(8)} ${row[ch.index + 1].toStringAsFixed(2)} / '
            '${g.springs[ch].at(row[0] / 1000).toStringAsFixed(2)}',
    ];
    final tp = TextPainter(
      text: TextSpan(
        text: lines.join('\n'),
        style: LabText.mono(lab.bg, size: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width + 16, h = tp.height + 12;
    final cx = (g.x(row[0]) * scale).clamp(
      math.min(90.0, size.width / 2),
      math.max(size.width - 90, size.width / 2),
    );
    final box = Rect.fromLTWH(cx - w / 2, 6 - h, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(6)),
      Paint()..color = lab.ink,
    );
    tp.paint(canvas, box.topLeft + const Offset(8, 6));
    tp.dispose();
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.selected != selected || old.lab != lab || old.g.data != g.data;
}

class _MeasuredTable extends StatelessWidget {
  const _MeasuredTable({required this.data});

  final List<List<double>> data;

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    final head = LabText.mono(lab.muted, size: 11, weight: FontWeight.w500);
    final cell = LabText.mono(lab.ink, size: 11);
    final border = BoxDecoration(
      border: Border(bottom: BorderSide(color: lab.line)),
    );
    Widget row(List<String> cells, TextStyle st, {BoxDecoration? deco}) =>
        Container(
          decoration: deco ?? border,
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              for (final s in cells)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(s, style: st, textAlign: TextAlign.right),
                  ),
                ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(['ms', for (final ch in Channel.values) ch.label], head),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final r in data)
                row([
                  '${r[0].round()}',
                  for (final v in r.skip(1)) v.toStringAsFixed(3),
                ], cell),
            ],
          ),
        ),
      ],
    );
  }
}
