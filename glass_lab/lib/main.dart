import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/glass/renderer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Inter', 'OFL-Inter.txt'),
      ('JetBrains Mono', 'OFL-JetBrainsMono.txt'),
      ('Schibsted Grotesk', 'OFL-SchibstedGrotesk.txt'),
      ('Noto Sans', 'OFL-Noto.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('fonts/$file'));
    }
  });
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Start compiling the glass shader while the first frame builds.
  GlassRenderer.loadProgram();
  runApp(const GlassLabApp());
}
