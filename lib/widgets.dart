import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'audio_handler.dart';
import 'player_screen.dart';
import 'song.dart';
import 'theme.dart';

void openPlayer(BuildContext context) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => const PlayerScreen(),
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: a,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      ),
      child: child,
    ),
  ));
}

void playAndOpen(BuildContext context, Song song, List<Song> queue) {
  audioHandler.playSong(song, context: queue);
  openPlayer(context);
}

class Cover extends StatelessWidget {
  final String url;
  final double size;
  final double radius;
  const Cover(this.url, {super.key, this.size = 48, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => const ColoredBox(color: C.raised),
          errorWidget: (_, __, ___) => const ColoredBox(
            color: C.raised,
            child: Icon(Icons.music_note_rounded, color: C.muted),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: C.text,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  const SongTile({super.key, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snap) {
        final current = snap.data?.id == song.id;
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              Cover(song.thumbnail),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: current ? C.accent : C.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: C.muted),
                    ),
                  ],
                ),
              ),
              if (song.duration > Duration.zero) ...[
                const SizedBox(width: 12),
                Text(
                  song.fmtDuration,
                  style: const TextStyle(fontSize: 12, color: C.muted),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}
