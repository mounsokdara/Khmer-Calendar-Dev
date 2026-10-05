import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../calendar/chhankitek.dart';
import '../i18n.dart';

const animalSlug = {
  'ជូត': 'rat',
  'ឆ្លូវ': 'ox',
  'ខាល': 'tiger',
  'ថោះ': 'rabbit',
  'រោង': 'dragon',
  'ម្សាញ់': 'snake',
  'មមី': 'horse',
  'មមែ': 'goat',
  'វក': 'monkey',
  'រកា': 'rooster',
  'ច': 'dog',
  'កុរ': 'pig',
};

String animalLabel(String animal, Lang lang) => lang == Lang.en ? (zodiacEn[animal] ?? animal) : animal;

class AnimalArt extends StatelessWidget {
  const AnimalArt({super.key, required this.animal, this.size = 40});
  final String animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final slug = animalSlug[animal] ?? 'horse';
    return SvgPicture.asset(
      'assets/zodiac/$slug.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
    );
  }
}
