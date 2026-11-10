import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'song.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Koleksi',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: C.text,
                      letterSpacing: -0.5)),
            ),
          ),
          TabBar(
            controller: _tab,
            labelColor: C.text,
            unselectedLabelColor: C.muted,
            indicatorColor: C.accent,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: C.line,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Disukai'), Tab(text: 'Terakhir diputar')],
          ),
          Expanded(
            child: TabBarView(controller: _tab, children: [
              _SongList(
                source: Store.liked,
                empty: 'Belum ada lagu yang disukai.\nKetuk ikon hati di pemutar.',
              ),
              _SongList(
                source: Store.recent,
                empty: 'Belum ada riwayat putar.',
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SongList extends StatelessWidget {
  final ValueListenable<List<Song>> source;
  final String empty;
  const _SongList({required this.source, required this.empty});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Song>>(
      valueListenable: source,
      builder: (ctx, songs, _) {
        if (songs.isEmpty) {
          return Center(
            child: Text(empty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: C.muted, fontSize: 14, height: 1.6)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: songs.length,
          itemBuilder: (_, i) => SongTile(
            song: songs[i],
            onTap: () => playAndOpen(ctx, songs[i], songs),
          ),
        );
      },
    );
  }
}
