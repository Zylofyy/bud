# Glass Lab

The [Liquid Glass Morph Lab](https://claude.ai/artifact/7tVGoeKRCdZqC74nKCpdop)
as a native Android app, built with Flutter. Three iOS 26 screen recordings,
measured frame by frame at 60 fps, rebuilt as live liquid-glass shaders.

- **Home**: the three demos, each playing on a loop as a live preview, and how
  the rebuild works. Tap a demo to open it.
- **Track ⋯ menu**: tap any ⋯ in the Music track list. A glass droplet grows
  out of the button, drops past its spot and climbs back into the menu.
- **New Playlist sheet**: tap the add-playlist button in the Library toolbar.
  The capsule itself grows into the sheet, turns opaque and dims the library.
  Tap ✕ to send it back.
- **Photos toolbar menu**: tap ⋯ in the Photos toolbar. The capsule drains
  into a droplet that pinches off as a teardrop and squares up into the menu;
  tap anywhere to close it.

Each demo screen has the lab's controls: the open and close buttons under the
screen, playback speed (1×, ½×, ¼×, ⅒×), **Pause** and **+1 frame** to step
one 60 fps frame at a time, **Loop demo**, and **Show shapes**, which outlines
the two rounded rectangles the glass is built from. Below them are the
frame-by-frame notes, the fitted springs and the measured-vs-rebuilt curve
(touch it to read values off it).

## How it's built

The glass is one fragment shader, `shaders/glass.frag`, ported from the
artifact's WebGL shader: two rounded rectangles joined with a smooth minimum,
a lens that samples the background and content from further inside the shape
near the edge, and a rim light. Each frame's shapes, lens, blur and content
placement come from the same spring fits and timings as the artifact.

The screens behind the glass are drawn with Flutter's canvas in the
recordings' pixel coordinates and rasterised to textures. WebGL's mipmaps
aren't available to Flutter shaders, so the blurs read from pre-blurred
copies instead. Rendered side by side with the artifact, frames match to
within about 1% on average.

## Run it

Needs the Flutter SDK (3.47 or later) and an Android device or emulator.

```sh
flutter pub get
flutter run
```

Build an APK to install directly:

```sh
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```

The release build is signed with the debug key. Before publishing to Google
Play, add your own signing config in `android/app/build.gradle.kts`.

## Tests

```sh
flutter analyze
flutter test
```

`test/render_frames_test.dart` also writes demo frames and app screens to PNG
when `FRAMES_OUT` names a directory:

```sh
FRAMES_OUT=/tmp/frames flutter test test/render_frames_test.dart
FRAMES_OUT=/tmp/frames flutter test --enable-impeller test/render_frames_test.dart
```

## Layout

```
shaders/glass.frag               the liquid glass shader
fonts/                           Inter (screen text), Schibsted Grotesk and
                                 JetBrains Mono (UI), Noto symbol subsets
lib/
  main.dart                      app entry, font licences
  src/
    app.dart                     MaterialApp, light and dark themes
    theme.dart                   the lab's colours and text styles
    glass/
      motion.dart                springs and easing
      clock.dart                 playback clock: speed, pause, frame step
      frame.dart                 one frame of glass: shapes, lens, content
      renderer.dart              binds a frame to the shader
      demo.dart                  press → open → close cycle, rasterising
      draw_kit.dart              canvas helpers and calibrated screen text
    demos/
      menu_demo.dart             Music track ⋯ menu
      sheet_demo.dart            Library → New Playlist sheet
      photos_demo.dart           Photos toolbar menu
      catalog.dart               notes, measured frames and fitted springs
    screens/
      home_screen.dart           demo picker with live previews
      demo_screen.dart           one demo with controls and notes
    widgets/
      glass_stage.dart           the live, touchable stage
      controls.dart              playback controls
      notes.dart                 frame notes, spring table, curve chart
```
