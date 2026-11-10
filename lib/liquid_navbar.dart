import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiquidNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const LiquidNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<LiquidNavBar> createState() => _LiquidNavBarState();
}

class _LiquidNavBarState extends State<LiquidNavBar>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _posAnim;
  double _fromPos = 0;

  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.search_rounded, Icons.search_outlined, 'Cari'),
    _NavItem(Icons.library_music_rounded, Icons.library_music_outlined, 'Library'),
    _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _posAnim = Tween<double>(
      begin: widget.selectedIndex.toDouble(),
      end: widget.selectedIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(LiquidNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _fromPos = _posAnim.value;
      _posAnim = Tween<double>(
        begin: _fromPos,
        end: widget.selectedIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 72 + bottom,
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1F),
        border: Border(top: BorderSide(color: Color(0xFF1F1F3D), width: 0.5)),
      ),
      child: AnimatedBuilder(
        animation: _posAnim,
        builder: (_, __) => Stack(children: [
          CustomPaint(
            painter: _LiquidPainter(_posAnim.value),
            child: const SizedBox.expand(),
          ),
          Row(
            children: List.generate(_items.length, (i) {
              final selected = widget.selectedIndex == i;
              final dist = (_posAnim.value - i).abs().clamp(0.0, 1.0);
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onItemTapped(i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        transform: Matrix4.translationValues(
                            0, selected ? -6 : 0, 0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            selected
                                ? _items[i].activeIcon
                                : _items[i].icon,
                            key: ValueKey(selected),
                            color: selected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF6B7280),
                            size: 24,
                            shadows: selected
                                ? [
                                    const Shadow(
                                      color: Color(0xFF7C3AED),
                                      blurRadius: 12,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _items[i].label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ]),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon, icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

class _LiquidPainter extends CustomPainter {
  final double pos;
  _LiquidPainter(this.pos);

  @override
  void paint(Canvas canvas, Size size) {
    final tabW = size.width / 4;
    final cx = (pos + 0.5) * tabW;
    final cy = size.height * 0.42;

    // Liquid stretch: sin of fractional position
    final frac = (pos - pos.floorToDouble()).abs();
    final stretch = 1.0 + math.sin(frac * math.pi) * 0.5;
    final r = tabW * 0.28;

    // Outer glow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 2.6 * stretch,
        height: r * 2.6 / math.max(stretch, 1),
      ),
      Paint()
        ..color = const Color(0xFF7C3AED).withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Inner blob
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 2 * stretch,
        height: r * 2 / math.max(stretch, 1),
      ),
      Paint()..color = const Color(0xFF7C3AED).withOpacity(0.18),
    );
  }

  @override
  bool shouldRepaint(_LiquidPainter old) => old.pos != pos;
}
