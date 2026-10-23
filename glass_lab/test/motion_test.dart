import 'package:flutter_test/flutter_test.dart';
import 'package:glass_lab/src/demos/catalog.dart';
import 'package:glass_lab/src/glass/motion.dart';

void main() {
  test('springs start at 0 and settle at 1', () {
    for (final d in demos) {
      for (final ch in Channel.values) {
        final s = d.springs[ch];
        expect(s.at(-0.1), 0);
        expect(s.at(3), closeTo(1, 1e-3), reason: '${d.id} ${ch.name}');
      }
    }
  });

  test('critically damped and overdamped springs settle too', () {
    expect(spr(2, 0.3, 1, 0), closeTo(1, 1e-3));
    expect(spr(2, 0.3, 1.4, 5), closeTo(1, 1e-3));
  });

  test('the fitted springs follow the measured frames', () {
    // The rebuild is only as good as its fit; keep it within a few percent.
    for (final d in demos) {
      var sum = 0.0, n = 0;
      for (final row in d.measured) {
        for (final ch in Channel.values) {
          sum += (d.springs[ch].at(row[0] / 1000) - row[ch.index + 1]).abs();
          n++;
        }
      }
      expect(sum / n, lessThan(0.06), reason: d.id);
    }
  });

  test('smoothstep clamps and eases', () {
    expect(ss(0, 1, -1), 0);
    expect(ss(0, 1, 2), 1);
    expect(ss(0, 1, 0.5), 0.5);
    expect(lerp(2, 4, 0.25), 2.5);
  });
}
