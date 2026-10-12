import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Line icons from the design: SVG path data drawn as rounded strokes.
abstract final class AppIcons {
  static const plus = ['M12 5v14', 'M5 12h14'];
  static const close = ['M6 6l12 12', 'M18 6L6 18'];
  static const check = ['M5 12.5l4.5 4.5L19 7'];

  /// Drawn in an 8×14 box.
  static const chevron = ['M1 1l6 6-6 6'];
}

class StrokeIcon extends StatelessWidget {
  const StrokeIcon(
    this.paths, {
    super.key,
    required this.color,
    this.size = const Size.square(24),
    this.strokeWidth = 2,
    this.viewBox = const Size.square(24),
  });

  final List<String> paths;
  final Color color;
  final Size size;
  final double strokeWidth;
  final Size viewBox;

  @override
  Widget build(BuildContext context) {
    final hex = (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final svg = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'viewBox="0 0 ${viewBox.width} ${viewBox.height}" fill="none" '
      'stroke="#$hex" stroke-opacity="${color.a}" stroke-width="$strokeWidth" '
      'stroke-linecap="round" stroke-linejoin="round">',
    );
    for (final d in paths) {
      svg.write('<path d="$d"/>');
    }
    svg.write('</svg>');
    return ExcludeSemantics(
      child: SvgPicture.string(
        svg.toString(),
        width: size.width,
        height: size.height,
      ),
    );
  }
}

/// A rounded colored square holding a white category icon.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.color,
    required this.iconPath,
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.strokeWidth,
  });

  final Color color;
  final String iconPath;
  final double size;
  final double radius;
  final double iconSize;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: StrokeIcon(
        [iconPath],
        color: const Color(0xFFFFFFFF),
        size: Size.square(iconSize),
        strokeWidth: strokeWidth,
      ),
    );
  }
}
