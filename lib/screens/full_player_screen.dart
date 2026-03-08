import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/seek_bar.dart';
import 'queue_screen.dart';

/// 전체 화면 플레이어.
///
/// 미니 플레이어에서 탭하여 진입. 큰 앨범아트, 곡 정보,
/// 시크바, 컨트롤(이전/재생/다음), 셔플/반복 토글 제공.
class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().setFullPlayerOpen(true);
    });
  }

  @override
  void dispose() {
    _playerProvider?.setFullPlayerOpen(false);
    super.dispose();
  }

  PlayerProvider? _playerProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playerProvider = context.read<PlayerProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer2<PlayerProvider, HistoryProvider>(
            builder: (context, player, history, _) {
              final track = player.currentTrack;
              if (track == null) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => history.toggleFavorite(track),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    track.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: track.isFavorite
                        ? AppColors.error
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          Consumer<PlayerProvider>(
            builder: (context, player, _) {
              final track = player.currentTrack;
              if (track == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(
                  Icons.playlist_add,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => AddToPlaylistSheet.show(
                  context,
                  videoId: track.videoId,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.queue_music, color: AppColors.textSecondary),
            onPressed: () => QueueScreen.show(context),
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, player, _) {
          final track = player.currentTrack;
          if (track == null) {
            return const Center(
              child: Text(
                'No track playing',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            );
          }

          final title = track.fileName.endsWith('.m4a')
              ? track.fileName.substring(0, track.fileName.length - 4)
              : track.fileName;
          final artist = track.artistName ?? track.channelName ?? '';

          return Column(
            children: [
              const Spacer(),
              // 앨범아트
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: track.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _placeholderArt(),
                            errorWidget: (context, url, error) => _placeholderArt(),
                          )
                        : _placeholderArt(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 곡 정보
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (artist.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 시크바
              const SeekBar(),
              const SizedBox(height: 16),
              // 컨트롤
              _buildControls(context, player),
              const Spacer(flex: 2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 셔플
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: player.isShuffleEnabled
                  ? AppColors.primary
                  : AppColors.textTertiary,
            ),
            onPressed: () => player.toggleShuffle(),
          ),
          // 이전
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 36),
            color: AppColors.textPrimary,
            onPressed: () => player.skipPrevious(),
          ),
          // 재생/일시정지
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: IconButton(
              icon: Icon(
                player.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: Colors.white,
              ),
              onPressed: () {
                player.isPlaying ? player.pause() : player.resume();
              },
            ),
          ),
          // 다음
          IconButton(
            icon: const Icon(Icons.skip_next, size: 36),
            color: AppColors.textPrimary,
            onPressed: () => player.skipNext(),
          ),
          // 반복
          IconButton(
            icon: Icon(
              _loopModeIcon(player.loopMode),
              color: player.loopMode != LoopMode.off
                  ? AppColors.primary
                  : AppColors.textTertiary,
            ),
            onPressed: () => player.cycleLoopMode(),
          ),
        ],
      ),
    );
  }

  IconData _loopModeIcon(LoopMode mode) {
    return switch (mode) {
      LoopMode.one => Icons.repeat_one,
      _ => Icons.repeat,
    };
  }

  Widget _placeholderArt() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.music_note,
        color: AppColors.primaryLight,
        size: 80,
      ),
    );
  }
}
