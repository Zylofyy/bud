// Renders demo frames and app screens to PNG for visual checks. Skipped
// unless FRAMES_OUT names an output directory:
//   FRAMES_OUT=/some/dir flutter test test/render_frames_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_lab/src/app.dart';
import 'package:glass_lab/src/demos/catalog.dart';
import 'package:glass_lab/src/glass/clock.dart';
import 'package:glass_lab/src/glass/demo.dart';
import 'package:glass_lab/src/glass/renderer.dart';

import 'support.dart';

final out = Platform.environment['FRAMES_OUT'];

Future<void> savePng(ui.Image img, String name) async {
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render demo frames', () async {
    await loadFonts();
    final program = await GlassRenderer.loadProgram();
    for (final info in demos) {
      final clock = LabClock();
      final demo = info.create(clock, loop: false);
      final renderer = GlassRenderer(program);
      const width = 340.0;
      final size = Size(width, width / info.aspect);
      demo.resize(size, 1);
      Future<void> shot(String name) async {
        demo.update();
        final rec = ui.PictureRecorder();
        demo.paint(ui.Canvas(rec), size, renderer);
        await savePng(
          await rec.endRecording().toImage(
            size.width.round(),
            size.height.round(),
          ),
          '${info.id}_$name',
        );
      }

      await shot('0_idle');
      demo.cmdOpen();
      for (final ms in [17, 50, 83, 133, 250]) {
        clock.time.value = demo.pt + ms / 1000;
        await shot('1_open_${ms}ms');
      }
      clock.time.value = demo.pt + 2;
      demo.update();
      await shot('2_open');
      demo.debugShapes = true;
      demo.cmdClose();
      for (final ms in [50, 120, 200]) {
        clock.time.value = demo.pt + ms / 1000;
        await shot('3_close_${ms}ms');
      }
      expect(demo.phase, Phase.closing);
    }
  }, skip: out == null);

  testWidgets('render screens', (tester) async {
    await tester.runAsync(() async {
      await loadFonts();
      await GlassRenderer.loadProgram();
    });
    final view = tester.view;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 2.625;
    final key = GlobalKey();
    Future<void> capture(String name) async {
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(
        () async => savePng(await boundary.toImage(pixelRatio: 1), name),
      );
    }

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: const GlassLabApp()),
      );
      await capture('screen_home_${mode.name}');
      await tester.tap(find.text(demos[0].title));
      await tester.pump();
      await capture('screen_menu_${mode.name}');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -900));
      await capture('screen_menu_notes_${mode.name}');
      await tester.pumpWidget(const SizedBox());
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  }, skip: out == null);
}
