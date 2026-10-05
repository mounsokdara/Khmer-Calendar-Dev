import 'package:flutter/material.dart';

import '../../weather.dart';

class CloudPhoto extends StatelessWidget {
  const CloudPhoto({super.key, required this.city});
  final City city;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: cityPhotoUrl(city),
      builder: (context, snap) {
        final url = snap.data;
        if (url == null || url.isEmpty) {
          return Container(
            color: const Color(0xFF38618D),
            alignment: Alignment.center,
            child: const Icon(Icons.location_city, color: Colors.white54, size: 48),
          );
        }
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => Container(color: const Color(0xFF38618D)),
        );
      },
    );
  }
}
