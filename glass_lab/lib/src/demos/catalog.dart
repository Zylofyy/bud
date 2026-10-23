import '../glass/clock.dart';
import '../glass/demo.dart';
import '../glass/motion.dart';
import 'menu_demo.dart';
import 'photos_demo.dart';
import 'sheet_demo.dart';

/// A demo as the lab presents it: the recording, the frame-by-frame notes and
/// the measured open curve the springs were fitted to.
class DemoInfo {
  const DemoInfo({
    required this.id,
    required this.title,
    required this.source,
    required this.summary,
    required this.width,
    required this.height,
    required this.openLabel,
    required this.closeLabel,
    required this.stageLabel,
    required this.phases,
    required this.springs,
    required this.measured,
    required this.chartLo,
    required this.chartHi,
    required this.create,
  });

  final String id;
  final String title;
  final String source;
  final String summary;
  final double width;
  final double height;
  final String openLabel;
  final String closeLabel;

  /// Describes the stage for screen readers.
  final String stageLabel;

  /// Frame-by-frame notes: (frames, what happens).
  final List<(String, String)> phases;

  /// The fitted open springs.
  final AxisSprings springs;

  /// Measured open progress per channel, normalised 0 → rest:
  /// [ms, centre x, centre y, width, height].
  final List<List<double>> measured;
  final double chartLo;
  final double chartHi;

  final GlassDemo Function(LabClock clock, {bool loop, double firstAuto})
  create;

  double get aspect => width / height;
}

GlassDemo _menu(LabClock c, {bool loop = true, double firstAuto = 0.6}) =>
    MenuDemo(c, loop: loop, firstAuto: firstAuto);
GlassDemo _sheet(LabClock c, {bool loop = true, double firstAuto = 0.6}) =>
    SheetDemo(c, loop: loop, firstAuto: firstAuto);
GlassDemo _photos(LabClock c, {bool loop = true, double firstAuto = 0.6}) =>
    PhotosDemo(c, loop: loop, firstAuto: firstAuto);

const demos = [
  DemoInfo(
    id: 'menu',
    title: 'Track ⋯ menu',
    source: '1000028968.mp4 · 756×1050 · 60 fps · 506 frames',
    summary:
        'A droplet grows out of the ⋯ button, drops past its spot and '
        'climbs back into the menu.',
    width: MenuDemo.W,
    height: MenuDemo.H,
    openLabel: 'Tap ⋯ on track 6',
    closeLabel: 'Dismiss',
    stageLabel: 'Recreated Music track list. Tap a ⋯ button to open its menu.',
    phases: [
      (
        'f −3…0',
        'Press. The ⋯ glyph brightens for 3 frames (50 ms) before anything moves.',
      ),
      (
        'f 1',
        'A 44 px glass droplet replaces the glyph. The dots stay inside it, blurred, and fade by f 3.',
      ),
      (
        'f 1–10',
        'Height lands first (≈150 ms), width at ≈200 ms. The menu text is laid out at full size, centred on the blob and heavily blurred; it sharpens between f 6 and f 10.',
      ),
      (
        'f 4–17',
        'The centre drops 27 px past its resting point and climbs back. That overshoot is the signature of this morph; size barely overshoots (≈2%).',
      ),
      ('f 4–15', 'Corners go from a full ellipse to the 34 px menu radius.'),
      (
        'close',
        '≈180 ms. The menu sinks about 25 px, then shrinks toward the button. Content is gone by f 5, the blob fades out near button size, and the ⋯ returns at f 9–12.',
      ),
    ],
    springs: MenuDemo.springsOpen,
    measured: [
      [0, 0.027, -0.076, 0.005, -0.078],
      [17, 0.311, 0.586, 0.254, 0.41],
      [33, 0.451, 0.898, 0.376, 0.62],
      [50, 0.557, 1.083, 0.522, 0.771],
      [67, 0.661, 1.229, 0.632, 0.863],
      [83, 0.754, 1.312, 0.722, 0.927],
      [100, 0.828, 1.344, 0.797, 0.961],
      [117, 0.885, 1.331, 0.856, 0.98],
      [133, 0.929, 1.287, 0.9, 0.995],
      [150, 0.959, 1.242, 0.931, 1.0],
      [167, 0.981, 1.191, 0.983, 1.0],
      [183, 0.995, 1.146, 0.986, 1.005],
      [200, 1.0, 1.102, 1.0, 1.01],
      [217, 1.005, 1.07, 1.005, 1.005],
      [233, 1.016, 1.045, 1.019, 1.005],
      [250, 1.016, 1.019, 1.019, 1.005],
      [267, 1.016, 1.006, 1.019, 1.005],
      [283, 1.016, 0.994, 1.019, 1.005],
      [300, 1.019, 0.994, 1.017, 1.005],
      [317, 1.019, 0.987, 1.017, 1.0],
      [333, 1.019, 0.987, 1.017, 1.0],
      [350, 1.0, 0.987, 1.0, 1.0],
      [367, 1.0, 0.987, 1.0, 1.0],
      [383, 1.0, 0.994, 1.0, 1.005],
      [400, 1.0, 0.994, 1.0, 1.005],
    ],
    chartLo: -0.1,
    chartHi: 1.4,
    create: _menu,
  ),
  DemoInfo(
    id: 'sheet',
    title: 'New Playlist sheet',
    source: '1000028969.mp4 · 794×1640 · 60 fps · 466 frames',
    summary:
        'The toolbar capsule itself grows into the sheet, turning '
        'opaque and dimming the library behind it.',
    width: SheetDemo.W,
    height: SheetDemo.H,
    openLabel: 'Tap add playlist',
    closeLabel: 'Tap ✕',
    stageLabel:
        'Recreated Music Library. Tap the add-playlist button to open '
        'the New Playlist sheet; tap the close button to dismiss.',
    phases: [
      (
        'f −7…0',
        'Press. A light pill appears behind the add-playlist icon inside the toolbar capsule.',
      ),
      (
        'f 0–3',
        "The capsule itself becomes the sheet. Toolbar icons cross-fade out by f 3 while the sheet's ✕ and ✓ fade in.",
      ),
      (
        'f 1–12',
        'One shape grows to full width by ≈150 ms and full height by ≈200 ms. Sheet content is scaled by the current width and pinned to the top edge, so it reads as a zoom.',
      ),
      (
        'f 2–10',
        'The glass turns opaque and the library dims to 65% brightness.',
      ),
      (
        'close',
        '≈200 ms. The dim lifts within 4 frames. The sheet shrinks back into the capsule, the toolbar icons fade in from f 5, and the capsule lands with a slight bounce.',
      ),
    ],
    springs: SheetDemo.springsOpen,
    measured: [
      [17, 0.1, 0.132, 0.145, 0.102],
      [34, 0.168, 0.249, 0.237, 0.189],
      [50, 0.335, 0.34, 0.325, 0.28],
      [67, 0.418, 0.475, 0.384, 0.404],
      [84, 0.541, 0.536, 0.578, 0.445],
      [100, 0.591, 0.693, 0.625, 0.602],
      [117, 0.632, 0.779, 0.77, 0.693],
      [134, 0.738, 0.854, 0.825, 0.777],
      [150, 0.915, 0.953, 0.95, 0.888],
      [184, 1.0, 0.962, 1.0, 0.938],
      [200, 1.0, 1.004, 1.0, 0.995],
      [234, 1.0, 1.0, 1.0, 1.0],
    ],
    chartLo: 0,
    chartHi: 1.1,
    create: _sheet,
  ),
  DemoInfo(
    id: 'photos',
    title: 'Photos toolbar menu',
    source: '1000028970.mp4 · 716×1640 · 60 fps · 522 frames',
    summary:
        'The capsule drains into ⋯, a droplet pinches off as a teardrop '
        'and squares up into the menu.',
    width: PhotosDemo.W,
    height: PhotosDemo.H,
    openLabel: 'Tap ⋯',
    closeLabel: 'Dismiss',
    stageLabel:
        'Recreated Photos viewer toolbar. Tap the ⋯ button to open the '
        'menu; tap anywhere to close it.',
    phases: [
      (
        'f −6…0',
        'Press. The whole toolbar capsule brightens (mean luma 41 → 52).',
      ),
      (
        'f 1–3',
        'The capsule drains toward ⋯ and squeezes its icons. A droplet pinches off below it, so for two frames the shape is a teardrop.',
      ),
      (
        'f 3–6',
        'The droplet becomes an egg and grows down and left. Menu text is revealed through it at full size, blurred.',
      ),
      (
        'f 8–11',
        'It squares up into a squircle. Content near the edges is visibly stretched by the glass lens: the icons, the chevrons and "as Photo".',
      ),
      (
        'f 12–25',
        'Both axes overshoot by about 3% (and the centre by 13%), then settle. The menu is fully at rest at f 27 (≈450 ms).',
      ),
      (
        'close',
        '≈350 ms. The menu shrinks and sinks, then a bulge reaches up to the reforming capsule. The two shapes merge, and the drip under the capsule retracts.',
      ),
    ],
    springs: PhotosDemo.springsOpen,
    measured: [
      [50, 0.388, 0.479, 0.341, 0.34],
      [66, 0.515, 0.684, 0.485, 0.461],
      [83, 0.631, 0.862, 0.61, 0.57],
      [100, 0.731, 0.993, 0.717, 0.668],
      [116, 0.815, 1.078, 0.805, 0.756],
      [133, 0.881, 1.118, 0.872, 0.839],
      [150, 0.931, 1.133, 0.93, 0.907],
      [166, 0.971, 1.127, 0.97, 0.958],
      [183, 0.997, 1.117, 0.998, 0.993],
      [200, 1.011, 1.099, 1.014, 1.016],
      [216, 1.024, 1.078, 1.026, 1.029],
      [233, 1.029, 1.06, 1.03, 1.036],
      [250, 1.029, 1.044, 1.03, 1.037],
      [266, 1.026, 1.032, 1.028, 1.036],
      [283, 1.024, 1.021, 1.026, 1.033],
      [300, 1.021, 1.012, 1.023, 1.028],
      [316, 1.016, 1.007, 1.019, 1.023],
      [333, 1.013, 1.004, 1.016, 1.016],
      [350, 1.011, 1.0, 1.014, 1.013],
      [366, 1.005, 1.0, 1.009, 1.01],
      [383, 1.005, 0.996, 1.005, 1.007],
      [400, 1.005, 0.998, 1.005, 1.005],
      [416, 1.003, 0.998, 1.002, 1.002],
      [433, 1.003, 0.998, 1.002, 1.002],
      [450, 1.0, 1.0, 1.0, 1.0],
    ],
    chartLo: 0,
    chartHi: 1.2,
    create: _photos,
  ),
];

/// How the rebuild works: (heading, text). Inline `code` is marked with
/// backticks.
const method = [
  (
    'Measured, then fitted',
    "Every frame was diffed against a still to get the glass shape's bounding box. Centre, width and height were then fitted separately to a damped spring (response, damping ratio, initial velocity). Most per-axis fits land within a few pixels of the measured frames.",
  ),
  (
    'Two shapes, one surface',
    'The glass is a signed distance field: two rounded rectangles joined with a smooth minimum. As the source collapses and the target grows, the blend radius creates the teardrop and the drip. The field then goes back to one hard-edged shape.',
  ),
  (
    'Lens and rim',
    'Near the edge, the background and content are sampled from further inside the shape (`p − n·lens`), which gives the stretched-edge refraction. The lens is strongest mid-morph. A thin rim light favours the top-left and bottom-right.',
  ),
  (
    'Content placement',
    'The menus keep their content at full size, centred on the moving blob, and only blur and fade it. The sheet scales its content with its width and pins it to the top, which is why it reads as a zoom rather than a reveal.',
  ),
];
