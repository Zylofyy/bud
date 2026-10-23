import 'package:flutter/services.dart';

/// Loads the bundled fonts, which widget tests don't load by themselves.
Future<void> loadFonts() async {
  for (final (family, files) in const [
    (
      'Inter',
      ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold', 'Inter-Bold'],
    ),
    (
      'Schibsted Grotesk',
      [
        'SchibstedGrotesk-Regular',
        'SchibstedGrotesk-Medium',
        'SchibstedGrotesk-Bold',
      ],
    ),
    ('JetBrains Mono', ['JetBrainsMono-Regular', 'JetBrainsMono-Medium']),
    ('Lab Symbols', ['NotoSansSymbols2-Subset']),
    ('Lab Math', ['NotoSansMath-Subset']),
    ('Lab Fractions', ['NotoSans-Subset']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(rootBundle.load('fonts/$f.ttf'));
    }
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}
