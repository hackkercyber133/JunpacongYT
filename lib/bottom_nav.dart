import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.selected, required this.onTap});

  static const _items = [
    (Icons.home_filled, Icons.home_outlined, 'Beranda'),
    (Icons.search_rounded, Icons.search_rounded, 'Cari'),
    (Icons.favorite_rounded, Icons.favorite_border_rounded, 'Koleksi'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Material(
      color: C.surface,
      child: Container(
        padding: EdgeInsets.only(bottom: bottom),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: C.line)),
        ),
        height: 60 + bottom,
        child: Row(
          children: List.generate(_items.length, (i) {
            final (on, off, label) = _items[i];
            final active = i == selected;
            final color = active ? C.accent : C.muted;
            return Expanded(
              child: InkResponse(
                radius: 40,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(i);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(active ? on : off, color: color, size: 24),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
