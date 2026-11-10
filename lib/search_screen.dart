import 'package:flutter/material.dart';
import 'song.dart';
import 'theme.dart';
import 'widgets.dart';
import 'yt_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<Song> _results = [];
  bool _searching = false;
  bool _searched = false;

  static const _genres = [
    'Pop Indonesia',
    'Hip-Hop',
    'Lofi',
    'K-Pop',
    'Rock',
    'Akustik',
    'Dangdut',
    'Klasik',
  ];

  Future<void> _search(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searched = true;
      _results = [];
    });
    final r = await YtService().search(q);
    if (!mounted) return;
    setState(() {
      _results = r;
      _searching = false;
    });
  }

  void _clear() {
    _ctrl.clear();
    setState(() {
      _results = [];
      _searched = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: C.text, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: C.surface,
                hintText: 'Cari lagu atau artis',
                hintStyle: const TextStyle(color: C.muted),
                prefixIcon: const Icon(Icons.search_rounded, color: C.muted),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clear,
                        icon: const Icon(Icons.close_rounded, color: C.muted),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Expanded(child: _body()),
        ]),
      ),
    );
  }

  Widget _body() {
    if (_searching) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_searched && _results.isEmpty) {
      return Center(
        child: Text('Tidak ada hasil untuk "${_ctrl.text.trim()}"',
            style: const TextStyle(color: C.muted, fontSize: 14)),
      );
    }
    if (_results.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _results.length,
        itemBuilder: (ctx, i) => SongTile(
          song: _results[i],
          onTap: () => playAndOpen(ctx, _results[i], _results),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Jelajahi',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: C.text,
                  letterSpacing: -0.2)),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.1,
          children: [
            for (final g in _genres)
              Material(
                color: C.surface,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _ctrl.text = g;
                    _search('$g musik');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(g,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: C.text)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
