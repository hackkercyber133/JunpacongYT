import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'audio_handler.dart';
import 'song.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double? _drag;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snap) {
            final item = snap.data;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: C.text, size: 32),
                  ),
                  const Spacer(),
                  const Text('Sedang diputar',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: C.muted)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ]),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: LayoutBuilder(
                        builder: (_, c) => Cover(
                          item?.artUri?.toString() ?? '',
                          size: c.maxWidth,
                          radius: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _info(item),
              const SizedBox(height: 18),
              _seek(),
              const SizedBox(height: 8),
              _controls(),
              const SizedBox(height: 28),
            ]);
          },
        ),
      ),
    );
  }

  Widget _info(MediaItem? item) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 18),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item?.title ?? '—',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: C.text,
                    height: 1.2,
                    letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(item?.artist ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: C.muted)),
          ]),
        ),
        ValueListenableBuilder<List<Song>>(
          valueListenable: Store.liked,
          builder: (_, __, ___) {
            final song = audioHandler.currentSong;
            final liked = song != null && Store.isLiked(song.id);
            return IconButton(
              onPressed: song == null ? null : () => Store.toggleLike(song),
              icon: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? C.accent : C.muted,
                size: 26,
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _seek() {
    return StreamBuilder<Duration?>(
      stream: audioHandler.durationStream,
      builder: (context, durSnap) {
        final dur = durSnap.data ?? audioHandler.dur ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: audioHandler.positionStream,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final progress = dur.inMilliseconds > 0
                ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;
            final shown = _drag ?? progress;
            final shownPos = _drag != null
                ? Duration(milliseconds: (_drag! * dur.inMilliseconds).round())
                : pos;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: C.accent,
                    inactiveTrackColor: C.line,
                    thumbColor: C.text,
                    overlayColor: Color(0x22E9A23B),
                  ),
                  child: Slider(
                    value: shown,
                    onChanged: dur.inMilliseconds > 0
                        ? (v) => setState(() => _drag = v)
                        : null,
                    onChangeEnd: (v) {
                      audioHandler.seek(
                          Duration(milliseconds: (v * dur.inMilliseconds).round()));
                      setState(() => _drag = null);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(shownPos),
                          style: const TextStyle(fontSize: 12, color: C.muted)),
                      Text(_fmt(dur),
                          style: const TextStyle(fontSize: 12, color: C.muted)),
                    ],
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        ValueListenableBuilder<bool>(
          valueListenable: audioHandler.shuffle,
          builder: (_, on, __) => IconButton(
            onPressed: audioHandler.toggleShuffle,
            icon: Icon(Icons.shuffle_rounded,
                color: on ? C.accent : C.muted, size: 24),
          ),
        ),
        IconButton(
          onPressed: () => audioHandler.skipToPrevious(),
          icon: const Icon(Icons.skip_previous_rounded, color: C.text, size: 38),
        ),
        StreamBuilder<PlaybackState>(
          stream: audioHandler.playbackState,
          builder: (context, snap) {
            final st = snap.data;
            final playing = st?.playing ?? false;
            final ps = st?.processingState;
            final busy = ps == AudioProcessingState.loading ||
                ps == AudioProcessingState.buffering;
            return GestureDetector(
              onTap: () => playing ? audioHandler.pause() : audioHandler.play(),
              child: Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: C.text,
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: C.bg),
                      )
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: C.bg,
                        size: 38),
              ),
            );
          },
        ),
        IconButton(
          onPressed: () => audioHandler.skipToNext(),
          icon: const Icon(Icons.skip_next_rounded, color: C.text, size: 38),
        ),
        ValueListenableBuilder<int>(
          valueListenable: audioHandler.repeat,
          builder: (_, mode, __) => IconButton(
            onPressed: audioHandler.cycleRepeat,
            icon: Icon(
                mode == 2 ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                color: mode > 0 ? C.accent : C.muted,
                size: 24),
          ),
        ),
      ]),
    );
  }
}
