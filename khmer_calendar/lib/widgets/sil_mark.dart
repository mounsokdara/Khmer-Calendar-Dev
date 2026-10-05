import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

const _silSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="12" cy="3.15" rx="1.45" ry="1.2" fill="currentColor"/>
  <circle cx="12" cy="6.7" r="2.55" fill="currentColor"/>
  <path fill="currentColor" d="M7 11.1c.9-1.5 2.6-2.45 5-2.45s4.1.95 5 2.45c1.25 2.05.35 4.25-1.7 5.45-1.05.6-2.2.95-3.3.95s-2.25-.35-3.3-.95c-2.05-1.2-2.95-3.4-1.7-5.45z"/>
  <path fill="currentColor" d="M5.1 18.55c2.05-1.55 4.4-2.3 6.9-2.3s4.85.75 6.9 2.3c-2.05.85-4.4 1.3-6.9 1.3s-4.85-.45-6.9-1.3z"/>
</svg>
''';


class SilMark extends StatelessWidget {
  const SilMark({super.key, this.size = 14});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _silSvg,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(silColor, BlendMode.srcIn),
    );
  }
}
