import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'song.dart';

/// Penyimpanan lokal: lagu disukai + riwayat putar.
class Store {
  static final liked = ValueNotifier<List<Song>>([]);
  static final recent = ValueNotifier<List<Song>>([]);

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final l = p.getString('liked_songs');
      final r = p.getString('recent_songs');
      if (l != null && l.isNotEmpty) liked.value = Song.decodeList(l);
      if (r != null && r.isNotEmpty) recent.value = Song.decodeList(r);
    } catch (_) {
      // data rusak: mulai dari kosong
    }
  }

  static bool isLiked(String id) => liked.value.any((s) => s.id == id);

  static Future<void> toggleLike(Song s) async {
    final list = List<Song>.from(liked.value);
    final i = list.indexWhere((e) => e.id == s.id);
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.insert(0, s);
    }
    liked.value = list;
    final p = await SharedPreferences.getInstance();
    await p.setString('liked_songs', Song.encodeList(list));
  }

  static Future<void> addRecent(Song s) async {
    final list = List<Song>.from(recent.value)..removeWhere((e) => e.id == s.id);
    list.insert(0, s);
    if (list.length > 30) list.removeRange(30, list.length);
    recent.value = list;
    final p = await SharedPreferences.getInstance();
    await p.setString('recent_songs', Song.encodeList(list));
  }
}
