import 'package:flutter/material.dart';
import 'audio_handler.dart';
import 'bottom_nav.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'mini_player.dart';
import 'search_screen.dart';
import 'theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _idx = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onAbout: _showAbout),
      const SearchScreen(),
      const LibraryScreen(),
    ];
    audioHandler.failTick.addListener(_onFail);
  }

  @override
  void dispose() {
    audioHandler.failTick.removeListener(_onFail);
    super.dispose();
  }

  void _onFail() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          'Lagu ini tidak bisa diputar.\n${_short(audioHandler.lastError)}',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ));
  }

  String _short(String? e) {
    if (e == null) return '';
    final one = e.replaceAll(RegExp(r'\s+'), ' ');
    return one.length > 160 ? '${one.substring(0, 160)}…' : one;
  }

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          LogoMark(size: 64),
          SizedBox(height: 14),
          Text('Junpacong',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: C.text,
                  letterSpacing: -0.4)),
          SizedBox(height: 4),
          Text('Dibuat oleh Muhammad Ady Afriansyah',
              style: TextStyle(fontSize: 13, color: C.muted)),
          SizedBox(height: 22),
          _InfoRow('Versi', '1.0.0'),
          Divider(),
          _InfoRow('Sumber audio', 'YouTube'),
          Divider(),
          _InfoRow('Iklan', 'Tidak ada'),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNav(selected: _idx, onTap: (i) => setState(() => _idx = i)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Text(label, style: const TextStyle(color: C.muted, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: C.text, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
