import 'package:flutter/material.dart';

import '../demos/catalog.dart';
import '../glass/clock.dart';
import '../glass/demo.dart';
import '../theme.dart';
import '../widgets/glass_stage.dart';
import 'demo_screen.dart';

/// Picks a demo. Each card plays its demo on a loop as a live preview.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 28, 16, 56 + bottom),
          children: [
            Text('Liquid Glass Morph Lab', style: LabText.h1(lab)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text:
                        'Your three iOS 26 screen recordings, measured frame by '
                        'frame at 60 fps and rebuilt as live glass shaders. ',
                  ),
                  TextSpan(
                    text: 'Pick a demo, then tap the buttons inside its screen',
                    style: TextStyle(
                      color: lab.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ', or let it loop. Slow the clock down or step one frame '
                        'at a time to compare against the originals.',
                  ),
                ],
              ),
              style: LabText.lede(lab),
            ),
            const SizedBox(height: 28),
            for (var i = 0; i < demos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _DemoCard(info: demos[i], index: i),
              ),
            const SizedBox(height: 14),
            const _Method(),
          ],
        ),
      ),
    );
  }
}

class _DemoCard extends StatefulWidget {
  const _DemoCard({required this.info, required this.index});

  final DemoInfo info;
  final int index;

  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  final _clock = LabClock();
  late final GlassDemo _demo = widget.info.create(
    _clock,
    firstAuto: 0.6 + widget.index * 0.55,
  );
  bool _checkedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedMotion) {
      _checkedMotion = true;
      if (MediaQuery.disableAnimationsOf(context)) _demo.loop = false;
    }
  }

  @override
  void dispose() {
    _demo.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _open() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DemoScreen(info: widget.info)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    final info = widget.info;
    return Material(
      color: lab.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: lab.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                child: AspectRatio(
                  aspectRatio: info.aspect,
                  child: StageFrame(
                    radius: 10,
                    child: GlassStage(
                      demo: _demo,
                      interactive: false,
                      showHud: false,
                      semanticLabel: 'Preview of ${info.title}',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.title, style: LabText.h2(lab)),
                    const SizedBox(height: 2),
                    Text(info.source, style: LabText.mono(lab.muted, size: 11)),
                    const SizedBox(height: 10),
                    Text(
                      info.summary,
                      style: TextStyle(
                        fontFamily: displayFont,
                        fontSize: 14,
                        height: 1.45,
                        color: lab.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: lab.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method();

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    return Container(
      padding: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: lab.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How the rebuild works', style: LabText.h2(lab)),
          for (final (heading, text) in method) ...[
            const SizedBox(height: 18),
            Text(heading, style: LabText.h3(lab)),
            const SizedBox(height: 4),
            Text.rich(_withCode(text, lab), style: LabText.body(lab)),
          ],
        ],
      ),
    );
  }

  /// Splits `code` spans out of [text].
  static TextSpan _withCode(String text, LabColors lab) {
    final parts = text.split('`');
    return TextSpan(
      children: [
        for (var i = 0; i < parts.length; i++)
          TextSpan(
            text: parts[i],
            style: i.isOdd
                ? LabText.mono(lab.ink, size: 12.5).copyWith(height: 1.5)
                : null,
          ),
      ],
    );
  }
}
