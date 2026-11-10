import 'package:flutter/material.dart';
import 'song.dart';
import 'theme.dart';
import 'widgets.dart';
import 'yt_service.dart';

Future<List<List<Song>>>? _feed;

Future<List<List<Song>>> homeFeed() => _feed ??= _fetchFeed();

Future<List<List<Song>>> _fetchFeed() {
  final yt = YtService();
  return Future.wait<List<Song>>([
    yt.trending(),
    yt.newRelease(),
    yt.hotPlaylist(),
  ]);
}

/// Dipanggil saat splash supaya data sudah jalan sebelum beranda tampil.
void preloadHome() => homeFeed();

void resetHomeFeed() => _feed = null;

class HomeScreen extends StatefulWidget {
  final VoidCallback onAbout;
  const HomeScreen({super.key, required this.onAbout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<List<Song>>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await homeFeed();
    if (!mounted) return;
    setState(() => _data = d);
  }

  Future<void> _retry() async {
    setState(() => _data = null);
    resetHomeFeed();
    await _load();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final data = _data;
    final empty = data != null && data.every((l) => l.isEmpty);

    return Scaffold(
      body: RefreshIndicator(
        color: C.accent,
        backgroundColor: C.raised,
        onRefresh: _retry,
        child: ListView(
          padding: EdgeInsets.only(top: top + 14, bottom: 24),
          children: [
            _header(),
            if (data == null)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (empty)
              _error()
            else ...[
              const SectionTitle('Lagi ramai'),
              _featuredRow(data[0]),
              const SectionTitle('Rilis terbaru'),
              ..._tiles(data[1]),
              const SectionTitle('Buat santai'),
              ..._tiles(data[2]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 10, 4),
        child: Row(children: [
          const LogoMark(size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: const TextStyle(fontSize: 12, color: C.muted)),
                const Text('Junpacong',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: C.text,
                        letterSpacing: -0.4)),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onAbout,
            icon: const Icon(Icons.info_outline_rounded, color: C.muted),
          ),
        ]),
      );

  Widget _error() => Padding(
        padding: const EdgeInsets.only(top: 100, left: 32, right: 32),
        child: Column(children: [
          const Text('Belum bisa memuat lagu.\nPeriksa koneksi internet kamu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.muted, fontSize: 14, height: 1.5)),
          const SizedBox(height: 12),
          TextButton(onPressed: _retry, child: const Text('Coba lagi')),
        ]),
      );

  Widget _featuredRow(List<Song> songs) => SizedBox(
        height: 208,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: songs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (ctx, i) => GestureDetector(
            onTap: () => playAndOpen(ctx, songs[i], songs),
            child: SizedBox(
              width: 148,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Cover(songs[i].thumbnail, size: 148, radius: 6),
                  const SizedBox(height: 8),
                  Text(songs[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: C.text)),
                  const SizedBox(height: 1),
                  Text(songs[i].artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: C.muted)),
                ],
              ),
            ),
          ),
        ),
      );

  List<Widget> _tiles(List<Song> songs) => [
        for (final s in songs.take(6))
          SongTile(song: s, onTap: () => playAndOpen(context, s, songs)),
      ];
}
