import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
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
    final provider = _playerProvider;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider?.setFullPlayerOpen(false);
    });
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
    final cs = AppColorScheme.of(context);

    return Scaffold(
      backgroundColor: cs.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: '플레이어 닫기',
          icon: const Icon(Icons.keyboard_arrow_down, size: AppSizes.iconXl),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Selector<PlayerProvider, DownloadItem?>(
            selector: (_, p) => p.currentTrack,
            builder: (context, track, _) {
              if (track == null || track.isStreaming) {
                return const SizedBox.shrink();
              }
              final cs = AppColorScheme.of(context);
              return IconButton(
                tooltip: 'Favorite',
                onPressed: () =>
                    context.read<HistoryProvider>().toggleFavorite(track),
                icon: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: Icon(
                    track.isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(track.isFavorite),
                    color: track.isFavorite
                        ? cs.error
                        : cs.textSecondary,
                    size: AppSizes.iconLg,
                  ),
                ),
              );
            },
          ),
          Selector<PlayerProvider, DownloadItem?>(
            selector: (_, p) => p.currentTrack,
            builder: (context, track, _) {
              if (track == null || track.isStreaming) {
                return const SizedBox.shrink();
              }
              final cs = AppColorScheme.of(context);
              return IconButton(
                tooltip: '플레이리스트에 추가',
                icon: Icon(
                  Icons.playlist_add,
                  color: cs.textSecondary,
                ),
                onPressed: () => AddToPlaylistSheet.show(
                  context,
                  videoId: track.videoId,
                ),
              );
            },
          ),
          IconButton(
            tooltip: '재생 큐',
            icon: Icon(Icons.queue_music, color: cs.textSecondary),
            onPressed: () => QueueScreen.show(context),
          ),
        ],
      ),
      body: Selector<PlayerProvider, DownloadItem?>(
        selector: (_, p) => p.currentTrack,
        builder: (context, track, _) {
          if (track == null) {
            final cs = AppColorScheme.of(context);
            return Center(
              child: Text(
                'No track playing',
                style: TextStyle(color: cs.textTertiary),
              ),
            );
          }

          final title = track.fileName.endsWith('.m4a')
              ? track.fileName.substring(0, track.fileName.length - 4)
              : track.fileName;
          final artist = track.artistName ?? track.channelName ?? '';

          final screenWidth = MediaQuery.of(context).size.width;
          final artPadding = screenWidth > 400 ? AppSpacing.hero : AppSpacing.xxl;
          final cs = AppColorScheme.of(context);

          return Column(
            children: [
              const Spacer(),
              // 앨범아트
              Padding(
                padding: EdgeInsets.symmetric(horizontal: artPadding),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: track.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _placeholderArt(AppColorScheme.of(context)),
                            errorWidget: (context, url, error) => _placeholderArt(AppColorScheme.of(context)),
                          )
                        : _placeholderArt(cs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // 곡 정보
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                child: Column(
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleLarge,
                    ),
                    if (artist.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(color: cs.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // 시크바
              const SeekBar(fullSize: true),
              const SizedBox(height: AppSpacing.lg),
              // 컨트롤
              _buildControls(context),
              const Spacer(flex: 2),
            ],
          );
        },
      ),
    );
  }

  /// 셔플·반복 활성 시 아이콘 아래 표시하는 점 인디케이터.
  Widget _activeDot(AppColorScheme cs) {
    return Container(
      width: AppSpacing.xs,
      height: AppSpacing.xs,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryLight,
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Selector<PlayerProvider, (bool, bool, LoopMode)>(
      selector: (_, p) => (p.isPlaying, p.isShuffleEnabled, p.loopMode),
      builder: (context, data, _) {
        final (isPlaying, isShuffleActive, loopMode) = data;
        final isRepeatActive = loopMode != LoopMode.off;
        final player = context.read<PlayerProvider>();
        final cs = AppColorScheme.of(context);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 셔플
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Shuffle',
                    icon: AnimatedSwitcher(
                      duration: AppDurations.fast,
                      child: Icon(
                        Icons.shuffle,
                        key: ValueKey(isShuffleActive),
                        color: isShuffleActive
                            ? cs.primary
                            : cs.textTertiary,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      player.toggleShuffle();
                    },
                  ),
                  if (isShuffleActive) _activeDot(cs) else const SizedBox(height: AppSpacing.xs),
                ],
              ),
              // 이전
              IconButton(
                tooltip: 'Previous',
                icon: const Icon(Icons.skip_previous, size: AppSizes.iconXxxl),
                color: cs.textPrimary,
                onPressed: () => player.skipPrevious(),
              ),
              // 재생/일시정지
              Container(
                width: AppSizes.playButtonSize,
                height: AppSizes.playButtonSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: IconButton(
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  icon: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      key: ValueKey(isPlaying),
                      size: AppSizes.iconXxl,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    isPlaying ? player.pause() : player.resume();
                  },
                ),
              ),
              // 다음
              IconButton(
                tooltip: 'Next',
                icon: const Icon(Icons.skip_next, size: AppSizes.iconXxxl),
                color: cs.textPrimary,
                onPressed: () => player.skipNext(),
              ),
              // 반복
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Repeat',
                    icon: AnimatedSwitcher(
                      duration: AppDurations.fast,
                      child: Icon(
                        _loopModeIcon(loopMode),
                        key: ValueKey(loopMode),
                        color: isRepeatActive
                            ? cs.primary
                            : cs.textTertiary,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      player.cycleLoopMode();
                    },
                  ),
                  if (isRepeatActive) _activeDot(cs) else const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _loopModeIcon(LoopMode mode) {
    return switch (mode) {
      LoopMode.one => Icons.repeat_one,
      _ => Icons.repeat,
    };
  }

  Widget _placeholderArt(AppColorScheme cs) {
    return Container(
      color: cs.surfaceVariant,
      child: Icon(
        Icons.music_note,
        color: cs.primaryLight,
        size: AppSizes.iconMega,
      ),
    );
  }
}
