import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../demos/catalog.dart';
import '../glass/clock.dart';
import '../glass/demo.dart';
import '../theme.dart';
import '../widgets/controls.dart';
import '../widgets/glass_stage.dart';
import '../widgets/notes.dart';

/// One demo, full size: the live screen, its open and close buttons, the
/// playback controls and the analysis notes.
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key, required this.info});

  final DemoInfo info;

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final _clock = LabClock();
  late final GlassDemo _demo = widget.info.create(_clock);
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

  @override
  Widget build(BuildContext context) {
    final lab = context.lab;
    final info = widget.info;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Fit the screen and its buttons in the first view; notes scroll below.
            final stageHeight = math.max(220.0, constraints.maxHeight - 150);
            final stageWidth = math.min(
              constraints.maxWidth - 32,
              stageHeight * info.aspect,
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 56 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          color: lab.ink,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(info.title, style: LabText.h2(lab)),
                              const SizedBox(height: 2),
                              Text(info.source, style: LabText.src(lab)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: SizedBox(
                      width: stageWidth,
                      child: AspectRatio(
                        aspectRatio: info.aspect,
                        child: StageFrame(
                          child: GlassStage(
                            demo: _demo,
                            semanticLabel: info.stageLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      LabButton(
                        label: info.openLabel,
                        onPressed: _demo.cmdOpen,
                      ),
                      LabButton(
                        label: info.closeLabel,
                        onPressed: _demo.cmdClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  PlaybackControls(clock: _clock, demo: _demo),
                  const SizedBox(height: 22),
                  NotesPanel(info: info),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
