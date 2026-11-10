import 'dart:convert';

class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  final Duration duration;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    this.duration = Duration.zero,
  });

  String get fmtDuration {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnail': thumbnail,
        'duration': duration.inSeconds,
      };

  factory Song.fromJson(Map<String, dynamic> j) => Song(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: j['artist'] as String,
        thumbnail: j['thumbnail'] as String,
        duration: Duration(seconds: (j['duration'] as int?) ?? 0),
      );

  static String encodeList(List<Song> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());

  static List<Song> decodeList(String src) {
    final list = jsonDecode(src) as List;
    return list.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
  }
}
