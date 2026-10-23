import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The lab's playback clock. Demos read [t] (seconds); the speed, pause and
/// single-frame step controls only change how fast it advances.
///
/// Listeners hear about speed and pause changes; [time] updates every frame.
class LabClock extends ChangeNotifier {
  final time = ValueNotifier<double>(0);
  double _speed = 1;
  bool _paused = false;

  double get t => time.value;
  double get speed => _speed;
  bool get paused => _paused;

  set speed(double value) {
    if (value == _speed) return;
    _speed = value;
    notifyListeners();
  }

  set paused(bool value) {
    if (value == _paused) return;
    _paused = value;
    notifyListeners();
  }

  /// Advances by a real frame interval, capped like the original's 50 ms.
  void advance(double realDt) {
    if (_paused) return;
    time.value += math.min(0.05, realDt) * _speed;
  }

  /// Pauses and moves forward one 60 fps frame.
  void step() {
    paused = true;
    time.value += 1 / 60;
  }

  @override
  void dispose() {
    time.dispose();
    super.dispose();
  }
}
