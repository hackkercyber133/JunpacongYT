import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'song.dart';
import 'store.dart';
import 'yt_service.dart';

late JunpacongHandler audioHandler;

Future<void> initAudio() async {
  audioHandler = await AudioService.init<JunpacongHandler>(
    builder: () => JunpacongHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mady.junpacong.channel',
      androidNotificationChannelName: 'Junpacong',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_stat_music',
    ),
  );
}

class JunpacongHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _rnd = math.Random();
  Song? currentSong;
  bool _loading = false;
  int _token = 0;

  // NB: nama `queue` sudah dipakai BaseAudioHandler, jadi pakai `_songs`.
  final List<Song> _songs = [];
  int _index = -1;

  /// Naik tiap lagu gagal diputar, UI mendengarkan ini untuk tampilkan pesan.
  final failTick = ValueNotifier<int>(0);
  String? lastError;
  final shuffle = ValueNotifier<bool>(false);

  /// 0 = mati, 1 = ulang semua, 2 = ulang satu lagu
  final repeat = ValueNotifier<int>(0);

  JunpacongHandler() {
    _player.playbackEventStream.listen((_) => _broadcast());
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onComplete();
    });
    _player.durationStream.listen((d) {
      final cur = mediaItem.value;
      if (d != null && cur != null && cur.duration != d) {
        mediaItem.add(cur.copyWith(duration: d));
      }
    });
  }

  void _broadcast() {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _loading
          ? AudioProcessingState.loading
          : const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
    ));
  }

  Future<void> playSong(Song song, {List<Song>? context}) async {
    final token = ++_token;
    currentSong = song;
    if (context != null) {
      _songs
        ..clear()
        ..addAll(context);
      _index = _songs.indexWhere((s) => s.id == song.id);
      if (_index < 0) {
        _songs
          ..clear()
          ..add(song);
        _index = 0;
      }
    }
    _loading = true;
    _player.pause();
    _broadcast();
    mediaItem.add(MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: Uri.tryParse(song.thumbnail),
      duration: song.duration > Duration.zero ? song.duration : null,
    ));

    final src = await YtService().resolve(song.id);
    if (token != _token) return; // user sudah pindah lagu lain
    if (src == null) {
      lastError = YtService().lastError;
      _fail();
      return;
    }
    try {
      await _player.setAudioSource(src);
    } catch (e) {
      if (token == _token) {
        lastError = YtService().lastError ?? e.toString();
        _fail();
      }
      return;
    }
    if (token != _token) return;
    _loading = false;
    _broadcast();
    Store.addRecent(song);
    _player.play();
  }

  void _fail() {
    _loading = false;
    _broadcast();
    failTick.value++;
  }

  int? _nextIndex({bool auto = false}) {
    if (_songs.isEmpty) return null;
    if (auto && repeat.value == 2) return _index;
    if (shuffle.value && _songs.length > 1) {
      int i;
      do {
        i = _rnd.nextInt(_songs.length);
      } while (i == _index);
      return i;
    }
    if (_index < _songs.length - 1) return _index + 1;
    if (repeat.value == 1) return 0;
    return null;
  }

  void _onComplete() {
    final i = _nextIndex(auto: true);
    if (i == null) return;
    _index = i;
    playSong(_songs[i]);
  }

  void toggleShuffle() => shuffle.value = !shuffle.value;
  void cycleRepeat() => repeat.value = (repeat.value + 1) % 3;

  @override
  Future<void> skipToNext() async {
    final i = _nextIndex();
    if (i == null) return;
    _index = i;
    await playSong(_songs[i]);
  }

  @override
  Future<void> skipToPrevious() async {
    if (pos.inSeconds > 3 || _index <= 0) {
      await seek(Duration.zero);
      return;
    }
    _index--;
    await playSong(_songs[_index]);
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Duration get pos => _player.position;
  Duration? get dur => _player.duration;
}
