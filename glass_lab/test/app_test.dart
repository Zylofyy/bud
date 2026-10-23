import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_lab/src/app.dart';
import 'package:glass_lab/src/demos/catalog.dart';
import 'package:glass_lab/src/demos/menu_demo.dart';
import 'package:glass_lab/src/glass/clock.dart';
import 'package:glass_lab/src/glass/demo.dart';
import 'package:glass_lab/src/glass/renderer.dart';
import 'package:glass_lab/src/screens/demo_screen.dart';
import 'package:glass_lab/src/theme.dart';

// The stages animate forever, so these tests pump fixed durations instead of
// pumpAndSettle.
Widget wrap(Widget home) =>
    MaterialApp(theme: buildTheme(Brightness.light), home: home);

Future<void> pumpFor(WidgetTester tester, Duration d) async {
  const step = Duration(milliseconds: 16);
  for (var t = Duration.zero; t < d; t += step) {
    await tester.pump(step);
  }
}

void main() {
  setUpAll(() async {
    await GlassRenderer.loadProgram();
  });

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 2.625;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('home lists the three demos and opens one', (tester) async {
    await tester.pumpWidget(const GlassLabApp());
    await tester.pump();

    expect(find.text('Liquid Glass Morph Lab'), findsOneWidget);
    for (final d in demos.take(2)) {
      expect(find.text(d.title), findsOneWidget);
    }

    await tester.tap(find.text(demos[1].title));
    await pumpFor(tester, const Duration(milliseconds: 600));

    expect(find.byType(DemoScreen), findsOneWidget);
    expect(find.text('Tap add playlist'), findsOneWidget);
    expect(find.text('Tap ✕'), findsOneWidget);
    expect(find.text('SPEED'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byType(DemoScreen), findsNothing);

    await tester.scrollUntilVisible(find.text(demos[2].title), 200);
    expect(find.text(demos[2].title), findsOneWidget);
    await tester.scrollUntilVisible(find.text('How the rebuild works'), 300);
    expect(find.text('How the rebuild works'), findsOneWidget);
  });

  testWidgets('demo screen plays the open and close', (tester) async {
    await tester.pumpWidget(wrap(DemoScreen(info: demos[0])));
    await tester.pump();

    await tester.ensureVisible(find.text('Loop demo'));
    await tester.tap(find.text('Loop demo'));
    await tester.pump();

    await tester.ensureVisible(find.text('Tap ⋯ on track 6'));
    await tester.tap(find.text('Tap ⋯ on track 6'));
    await tester.pump();
    await pumpFor(tester, const Duration(milliseconds: 100));
    expect(find.textContaining('opening · f'), findsOneWidget);

    await pumpFor(tester, const Duration(milliseconds: 700));
    expect(find.text('open · tap to dismiss'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(find.text('idle · tap ⋯'), findsOneWidget);
  });

  testWidgets('pausing stops the clock and +1 frame steps it', (tester) async {
    await tester.pumpWidget(wrap(DemoScreen(info: demos[2])));
    await pumpFor(tester, const Duration(milliseconds: 200));

    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    final frozen = find.textContaining('t 0.');
    expect(frozen, findsOneWidget);
    final before = (tester.widget<Text>(frozen)).data;
    await pumpFor(tester, const Duration(milliseconds: 300));
    expect(tester.widget<Text>(find.textContaining('t 0.')).data, before);

    await tester.tap(find.text('+1 frame'));
    await tester.pump();
    expect(
      tester.widget<Text>(find.textContaining('t 0.')).data,
      isNot(before),
    );
    expect(find.text('Play'), findsOneWidget);
  });

  group('demo state machine', () {
    test('looping presses, opens, presses and closes', () {
      final clock = LabClock();
      final demo = MenuDemo(clock)..resize(const Size(378, 525), 1);
      final seen = <Phase>[];
      for (var i = 0; i < 60 * 6; i++) {
        clock.advance(1 / 60);
        demo.update();
        if (seen.isEmpty || seen.last != demo.phase) seen.add(demo.phase);
      }
      expect(seen.take(6), [
        Phase.idle,
        Phase.pressOpen,
        Phase.opening,
        Phase.open,
        Phase.pressClose,
        Phase.closing,
      ]);
      demo.dispose();
    });

    test('a touch on another row opens that row\'s menu', () {
      final clock = LabClock();
      final demo = MenuDemo(clock, loop: false)
        ..resize(const Size(378, 525), 1);
      final row = MenuDemo.rows[6];
      demo.onDown(MenuDemo.btnX, row.y);
      expect(demo.phase, Phase.pressOpen);
      expect(demo.row, row);
      demo.onUp();
      expect(demo.phase, Phase.opening);
      demo.dispose();
    });

    test('a drag cancels the press', () {
      final clock = LabClock();
      final demo = MenuDemo(clock, loop: false)
        ..resize(const Size(378, 525), 1);
      demo.onDown(MenuDemo.btnX, MenuDemo.rows[4].y);
      demo.cancelPress();
      expect(demo.phase, Phase.idle);
      expect(demo.press, isNull);
      demo.dispose();
    });

    test('presses outside the buttons do nothing but stop the loop', () {
      final clock = LabClock();
      final demo = MenuDemo(clock)..resize(const Size(378, 525), 1);
      demo.onDown(100, 100);
      expect(demo.loop, isFalse);
      expect(demo.phase, Phase.idle);
      demo.dispose();
    });
  });
}
