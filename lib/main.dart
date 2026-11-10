import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_gate.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const JunpacongApp());
}

class JunpacongApp extends StatelessWidget {
  const JunpacongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Junpacong',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashGate(),
    );
  }
}
