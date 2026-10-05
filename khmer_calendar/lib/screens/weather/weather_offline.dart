import 'package:flutter/material.dart';

import '../../i18n.dart';

class WeatherOffline extends StatelessWidget {
  const WeatherOffline({required this.lang, required this.onRetry});
  final Lang lang;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(t(lang, 'wxOfflineTitle'), style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(t(lang, 'wxOfflineBody'), textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: Text(t(lang, 'wxRetry'))),
          ],
        ),
      ),
    );
  }
}
