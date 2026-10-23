import 'package:flutter/material.dart';

import '../glass/clock.dart';
import '../glass/demo.dart';
import '../theme.dart';

/// A small mono button. With [selected] set it's a toggle, inked when on.
class LabButton extends StatelessWidget {
  const LabButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected,
    this.tooltip,
  });

  final String label;
  final VoidCallback onPressed;
  final bool? selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    final on = selected ?? false;
    Widget button = Semantics(
      button: true,
      toggled: selected,
      child: Material(
        color: on ? lab.ink : lab.chip,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          highlightColor: on ? null : lab.rec.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            child: Text(label, style: LabText.button(on ? lab.bg : lab.ink)),
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip, child: button);
    return button;
  }
}

/// The playback strip: speed, pause, single-frame step, loop, shape outlines
/// and the clock.
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key, required this.clock, required this.demo});

  final LabClock clock;
  final GlassDemo demo;

  static const _speeds = [(1.0, '1×'), (0.5, '½×'), (0.25, '¼×'), (0.1, '⅒×')];

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: lab.surface,
        border: Border.all(color: lab.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge([clock, demo]),
        builder: (context, _) => Wrap(
          spacing: 18,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SPEED', style: LabText.label(lab)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: lab.chip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (speed, label) in _speeds)
                        _Segment(
                          label: label,
                          selected: clock.speed == speed,
                          onTap: () => clock.speed = speed,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabButton(
                  label: clock.paused ? 'Play' : 'Pause',
                  selected: clock.paused,
                  onPressed: () => clock.paused = !clock.paused,
                ),
                const SizedBox(width: 8),
                LabButton(
                  label: '+1 frame',
                  tooltip: 'Advance one 60 fps frame',
                  onPressed: clock.step,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabButton(
                  label: 'Loop demo',
                  selected: demo.loop,
                  onPressed: () => demo.setLoop(!demo.loop),
                ),
                const SizedBox(width: 8),
                LabButton(
                  label: 'Show shapes',
                  selected: demo.debugShapes,
                  onPressed: () => demo.debugShapes = !demo.debugShapes,
                ),
              ],
            ),
            ValueListenableBuilder<double>(
              valueListenable: clock.time,
              builder: (context, t, _) => Text(
                't ${t.toStringAsFixed(3)} s · f ${(t * 60).floor()}',
                style: LabText.mono(lab.muted, weight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? lab.surface : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: selected ? BorderSide(color: lab.line) : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Text(label, style: LabText.button(lab.ink)),
          ),
        ),
      ),
    );
  }
}
