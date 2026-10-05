import 'package:flutter/material.dart';

import '../i18n.dart';
import '../store.dart';
import '../theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.store});
  final AppStore store;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _bar;
  String _file = 'fonts/KantumruyPro.ttf';

  static const _files = [
    'fonts/KantumruyPro.ttf',
    'icons/icon-512.png',
    'weather/phnom-penh.jpg',
    'zodiac/rat.svg',
    'calendar/chhankitek',
  ];

  @override
  void initState() {
    super.initState();
    _bar = AnimationController(vsync: this, duration: const Duration(milliseconds: 720))..forward();
    _bar.addListener(() {
      final i = (_bar.value * (_files.length - 1)).floor().clamp(0, _files.length - 1);
      if (_files[i] != _file) setState(() => _file = _files[i]);
    });
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.store.lang;
    return AnimatedBuilder(
      animation: _bar,
      builder: (context, _) {
        final pct = (_bar.value * 100).round();
        return Scaffold(
          body: Stack(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD9786C), Color(0xFF9A3B38), Color(0xFF5C1A1C), Color(0xFF3A0F14)],
                    stops: [0, 0.42, 0.78, 1],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Positioned(
                top: -80,
                right: -90,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: const BoxDecoration(color: Color(0x47FFB4A0), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -110,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(color: Color(0x7350141E), shape: BoxShape.circle),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [
                              BoxShadow(color: Color(0x47000000), blurRadius: 40, offset: Offset(0, 18)),
                              BoxShadow(color: Color(0x1FFFFFFF), spreadRadius: 10),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/icons/icon-512.png',
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) {
                                return const Icon(Icons.calendar_month, size: 64, color: Color(0xFF9A3B38));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          t(lang, 'appName'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, height: 1.25),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t(lang, 'splashTag'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xC7FFFFFF), fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 36),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: _bar.value.clamp(0.04, 1),
                            minHeight: 4,
                            backgroundColor: const Color(0x47FFFFFF),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _file,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xB8FFFFFF), fontSize: 12),
                        ),
                        Text('$pct%', style: const TextStyle(color: Color(0xE0FFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Text('Version $appVersion', textAlign: TextAlign.center, style: TextStyle(color: Color(0x9EFFFFFF), fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }
}
