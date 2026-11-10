import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'song.dart';

class YtService {
  // ⚠️ Jangan share API key ini ke orang lain
  static const _apiKey = 'AIzaSyBs34lhBXoKi1OpD5aXW6RxQqGlbYyqh5U';
  static const _base = 'https://www.googleapis.com/youtube/v3';

  static final YtService _i = YtService._();
  factory YtService() => _i;
  YtService._();

  final _yt = YoutubeExplode();

  /// Cari lagu pakai YouTube Data API v3
  Future<List<Song>> search(String query, {int max = 20}) async {
    try {
      // ── 1. Search videos ──────────────────────────────────
      final searchUri = Uri.parse('$_base/search').replace(queryParameters: {
        'part': 'snippet',
        'type': 'video',
        'q': query,
        'maxResults': '$max',
        'regionCode': 'ID',
        'key': _apiKey,
      });

      final searchResp = await http.get(searchUri);
      if (searchResp.statusCode != 200) {
        // Quota habis atau key invalid → fallback ke scrape
        return _searchFallback(query);
      }

      final searchData =
          jsonDecode(searchResp.body) as Map<String, dynamic>;
      final items = (searchData['items'] as List?) ?? [];
      if (items.isEmpty) return [];

      // ── 2. Ambil durasi via videos.list ──────────────────
      final ids =
          items.map((e) => e['id']['videoId'] as String).join(',');

      final detailUri =
          Uri.parse('$_base/videos').replace(queryParameters: {
        'part': 'contentDetails',
        'id': ids,
        'key': _apiKey,
      });

      final detailResp = await http.get(detailUri);
      final Map<String, Duration> durations = {};
      if (detailResp.statusCode == 200) {
        final detailData =
            jsonDecode(detailResp.body) as Map<String, dynamic>;
        for (final d in (detailData['items'] as List? ?? [])) {
          durations[d['id'] as String] =
              _parseDuration(d['contentDetails']['duration'] as String? ?? '');
        }
      }

      // ── 3. Map ke Song ───────────────────────────────────
      return items.map((e) {
        final id = e['id']['videoId'] as String;
        final snippet = e['snippet'] as Map<String, dynamic>;
        final thumbs = snippet['thumbnails'] as Map<String, dynamic>?;
        final thumb = (thumbs?['medium']?['url'] ??
                'https://img.youtube.com/vi/$id/mqdefault.jpg')
            as String;

        return Song(
          id: id,
          title: _unescape(snippet['title'] as String? ?? 'Unknown'),
          artist: snippet['channelTitle'] as String? ?? 'Unknown',
          thumbnail: thumb,
          duration: durations[id] ?? Duration.zero,
        );
      }).toList();
    } catch (_) {
      return _searchFallback(query);
    }
  }

  /// Fallback ke youtube_explode_dart jika API gagal / quota habis
  Future<List<Song>> _searchFallback(String query) async {
    try {
      final results = await _yt.search.search(query);
      return results
          .whereType<SearchVideo>()
          .take(20)
          .map((v) => Song(
                id: v.id.value,
                title: v.title,
                artist: v.author,
                thumbnail:
                    'https://img.youtube.com/vi/${v.id.value}/mqdefault.jpg',
                duration: _parseClock(v.duration),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// "3:45" atau "1:02:10" -> Duration
  Duration _parseClock(String? s) {
    if (s == null || s.isEmpty) return Duration.zero;
    final parts = s.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    var sec = 0;
    for (final p in parts) {
      sec = sec * 60 + p;
    }
    return Duration(seconds: sec);
  }

  String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  /// Parse durasi ISO 8601 → Duration  (mis. "PT3M45S")
  Duration _parseDuration(String s) {
    final m = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(s);
    if (m == null) return Duration.zero;
    return Duration(
      hours:   int.tryParse(m.group(1) ?? '') ?? 0,
      minutes: int.tryParse(m.group(2) ?? '') ?? 0,
      seconds: int.tryParse(m.group(3) ?? '') ?? 0,
    );
  }

  /// Pesan error terakhir (untuk ditampilkan saat lagu gagal diputar).
  String? lastError;

  static const _vrUa =
      'com.google.android.apps.youtube.vr.oculus/1.60.19 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip';

  /// Cari stream audio yang benar-benar bisa diunduh.
  /// Mencoba beberapa client YouTube berurutan dan menguji tiap URL
  /// dengan permintaan kecil sebelum dipakai.
  Future<YtAudioSource?> resolve(String videoId) async {
    final attempts = <(List<YoutubeApiClient>?, Map<String, String>)>[
      ([YoutubeApiClient.androidVr], {'User-Agent': _vrUa}),
      ([YoutubeApiClient.ios], <String, String>{}),
      (null, <String, String>{}),
    ];
    final errors = <String>[];
    for (final (clients, headers) in attempts) {
      final tag = clients == null ? 'default' : clients.first.toString();
      try {
        final manifest = clients == null
            ? await _yt.videos.streamsClient.getManifest(videoId)
            : await _yt.videos.streamsClient
                .getManifest(videoId, ytClients: clients);
        final audio = manifest.audioOnly.toList();
        if (audio.isEmpty) {
          errors.add('$tag: tidak ada audio');
          continue;
        }
        final m4a =
            audio.where((a) => a.container == StreamContainer.mp4).toList();
        final pool = m4a.isNotEmpty ? m4a : audio;
        pool.sort((a, b) => a.bitrate.compareTo(b.bitrate));
        final info = pool.last;
        final src = YtAudioSource(info, headers);
        final code = await src.probe();
        if (code < 400) return src;
        errors.add('$tag: HTTP $code');
      } catch (e) {
        errors.add('$tag: $e');
      }
    }
    lastError = errors.join(' | ');
    return null;
  }

  // ── Preset query untuk home screen ──────────────────────
  Future<List<Song>> trending()    => search('top hits musik Indonesia');
  Future<List<Song>> newRelease()  => search('lagu baru Indonesia rilis terbaru');
  Future<List<Song>> hotPlaylist() => search('lofi study playlist chill');
}

/// Sumber audio just_audio yang mengambil data YouTube per potongan kecil
/// (seperti yang dilakukan yt-dlp), karena YouTube menolak permintaan
/// tanpa batas ukuran (HTTP 403 / "Source error").
class YtAudioSource extends StreamAudioSource {
  final AudioOnlyStreamInfo info;
  final Map<String, String> headers;
  static final _http = http.Client();
  static const _chunk = 2 * 1024 * 1024;

  YtAudioSource(this.info, this.headers);

  int get _total => info.size.totalBytes;

  Uri _ranged(int start, int endInclusive) {
    final u = info.url;
    return u.replace(queryParameters: {
      ...u.queryParameters,
      'range': '$start-$endInclusive',
    });
  }

  /// Uji ambil 2 byte pertama; kembalikan kode HTTP (0 kalau gagal total).
  Future<int> probe() async {
    try {
      final r = await _http
          .get(_ranged(0, 1), headers: headers)
          .timeout(const Duration(seconds: 12));
      return r.statusCode;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    var stop = end ?? _total;
    if (stop > _total) stop = _total;
    if (stop - start > _chunk) stop = start + _chunk;

    final req = http.Request('GET', _ranged(start, stop - 1))
      ..headers.addAll(headers);
    final resp = await _http.send(req);
    if (resp.statusCode >= 400) {
      YtService().lastError = 'HTTP ${resp.statusCode} saat mengunduh audio';
      throw Exception('HTTP ${resp.statusCode}');
    }
    return StreamAudioResponse(
      sourceLength: _total,
      contentLength: stop - start,
      offset: start,
      stream: resp.stream,
      contentType:
          info.container == StreamContainer.mp4 ? 'audio/mp4' : 'audio/webm',
    );
  }
}
