import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Palet warna Junpacong. Hangat, diambil dari suasana foto:
/// jalan malam + lampu jalan (amber) di atas arang gelap.
class C {
  static const bg = Color(0xFF11100E);
  static const surface = Color(0xFF1A1816);
  static const raised = Color(0xFF252220);
  static const line = Color(0xFF2F2B27);
  static const text = Color(0xFFECE5D8);
  static const muted = Color(0xFF8E877B);
  static const accent = Color(0xFFE9A23B);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.accent,
      onPrimary: C.bg,
      surface: C.surface,
      onSurface: C.text,
    ),
    splashColor: const Color(0x14FFFFFF),
    highlightColor: Colors.transparent,
    dividerTheme: const DividerThemeData(color: C.line, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.accent),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: C.accent,
      selectionHandleColor: C.accent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.raised,
      contentTextStyle: TextStyle(color: C.text, fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Logo: huruf J yang ujungnya kepala not musik.
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    const top = 0.155, sx = 0.65, y1 = 0.565, r = 0.24;
    final head = Offset((sx - r - 0.03) * s, (y1 + r) * s);

    final path = Path()
      ..moveTo(sx * s, top * s)
      ..lineTo(sx * s, y1 * s)
      ..arcTo(
        Rect.fromCircle(center: Offset((sx - r) * s, y1 * s), radius: r * s),
        0,
        math.pi / 2,
        false,
      )
      ..lineTo(head.dx, head.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = C.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.13 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(head, 0.105 * s, Paint()..color = C.accent);
  }

  @override
  bool shouldRepaint(_) => false;
}
