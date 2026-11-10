import 'package:flutter/material.dart';
import 'audio_handler.dart';
import 'home_screen.dart';
import 'main_scaffold.dart';
import 'store.dart';
import 'theme.dart';

/// Layar pembuka: tampil singkat (~1,3 detik) sambil menyiapkan audio,
/// data lokal, dan feed beranda di belakang layar.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const _minShow = Duration(milliseconds: 1300);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/splash.jpg'), context);
  }

  Future<void> _boot() async {
    preloadHome();
    try {
      await Future.wait([
        initAudio(),
        Store.load(),
        Future.delayed(_minShow),
      ]);
    } catch (_) {}
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _ready
          ? const MainScaffold(key: ValueKey('app'))
          : const _SplashView(key: ValueKey('splash')),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: C.bg,
      child: Stack(fit: StackFit.expand, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          builder: (_, v, child) => Opacity(opacity: v, child: child),
          child: Image.asset('assets/splash.jpg', fit: BoxFit.cover),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.55, 1.0],
              colors: [Color(0x66000000), Color(0x00000000), C.bg],
            ),
          ),
        ),
        Positioned(
          left: 28,
          right: 28,
          bottom: 64,
          child: Row(children: const [
            LogoMark(size: 46),
            SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Junpacong',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: C.text,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'musik tanpa iklan',
                  style: TextStyle(fontSize: 13, color: C.muted),
                ),
              ],
            ),
          ]),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeInOut,
            builder: (_, v, __) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                child: const SizedBox(height: 3, child: ColoredBox(color: C.accent)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
