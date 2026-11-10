import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'audio_handler.dart';
import 'theme.dart';
import 'widgets.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snap) {
        final item = snap.data;
        if (item == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => openPlayer(context),
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            decoration: BoxDecoration(
              color: C.raised,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 6, 6),
                child: Row(children: [
                  Cover(item.artUri?.toString() ?? '', size: 44, radius: 6),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: C.text)),
                        Text(item.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: C.muted)),
                      ],
                    ),
                  ),
                  StreamBuilder<PlaybackState>(
                    stream: audioHandler.playbackState,
                    builder: (context, ps) {
                      final st = ps.data;
                      final loading =
                          st?.processingState == AudioProcessingState.loading;
                      final playing = st?.playing ?? false;
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        if (loading)
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          IconButton(
                            onPressed: () => playing
                                ? audioHandler.pause()
                                : audioHandler.play(),
                            icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: C.text,
                                size: 28),
                          ),
                        IconButton(
                          onPressed: () => audioHandler.skipToNext(),
                          icon: const Icon(Icons.skip_next_rounded,
                              color: C.text, size: 26),
                        ),
                      ]);
                    },
                  ),
                ]),
              ),
              StreamBuilder<Duration>(
                stream: audioHandler.positionStream,
                builder: (context, pos) {
                  final total = audioHandler.dur?.inMilliseconds ?? 0;
                  final v = total > 0
                      ? ((pos.data?.inMilliseconds ?? 0) / total).clamp(0.0, 1.0)
                      : 0.0;
                  return LinearProgressIndicator(
                    value: v,
                    minHeight: 2,
                    backgroundColor: C.line,
                  );
                },
              ),
            ]),
          ),
        );
      },
    );
  }
}
