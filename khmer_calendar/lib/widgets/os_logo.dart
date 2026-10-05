import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OsLogo extends StatelessWidget {
  const OsLogo(this.name, {super.key, this.size = 32});
  final String name;
  final double size;

  static const names = {'android', 'windows', 'macos', 'linux'};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        'assets/os/$name.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
