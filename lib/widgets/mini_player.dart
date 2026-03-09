import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../screens/full_player_screen.dart';
import '../app.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'add_to_playlist_sheet.dart';

/// 하단 고정 미니 플레이어 위젯.
///
/// 진행 바·썸네일·곡명·아티스트와 즐겨찾기·플레이리스트 추가·재생/일시정지 버튼 표시.
/// 탭 시 [FullPlayerScreen]으로 이동.
/// [App]의 builder에서 글로벌로 표시되어 모든 화면에서 접근 가능.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Consumer2<PlayerProvider, HistoryProvider>(
      builder: (context, player, history, _) {
        final track = player.currentTrack;
        if (track == null || !player.isMiniPlayerVisible) {
          return const SizedBox.shrink();
        }
        if (player.isFullPlayerOpen) return const SizedBox.shrink();

        final title = track.fileName.endsWith('.m4a')
            ? track.fileName.substring(0, track.fileName.length - 4)
            : track.fileName;
        final artist = track.artistName ?? track.channelName ?? '';
        final progress = player.duration.inMilliseconds > 0
            ? player.position.inMilliseconds / player.duration.inMilliseconds
            : 0.0;

        return AnimatedSize(
          duration: AppDurations.normal,
          curve: Curves.easeInOut,
          child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              top: BorderSide(color: cs.border, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 진행 바
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: AppSpacing.xxs,
                backgroundColor: cs.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  cs.primary,
                ),
              ),
              // 컨트롤 영역
              SizedBox(
                height: AppSizes.miniPlayerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      // 썸네일 + 곡 정보 (탭 → FullPlayerScreen)
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: '전체 플레이어 열기: $title',
                          child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            appNavigatorKey.currentState?.push(
                              MaterialPageRoute(
                                builder: (_) => const FullPlayerScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                child: SizedBox(
                                  width: AppSizes.miniPlayerArt,
                                  height: AppSizes.miniPlayerArt,
                                  child: track.thumbnailUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: track.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) =>
                                              _placeholderIcon(context),
                                          errorWidget: (_, _, _) =>
                                              _placeholderIcon(context),
                                        )
                                      : _placeholderIcon(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    if (artist.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: cs.textTertiary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                      ),
                      if (!track.isStreaming) ...[
                        // 즐겨찾기 토글
                        _controlButton(
                          context: context,
                          icon: track.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: AppSizes.iconMd,
                          color: track.isFavorite
                              ? cs.error
                              : cs.textSecondary,
                          onPressed: () => history.toggleFavorite(track),
                        ),
                        // 플레이리스트에 추가
                        _controlButton(
                          context: context,
                          icon: Icons.playlist_add,
                          size: AppSizes.iconMl,
                          color: cs.textSecondary,
                          onPressed: () {
                            final navContext =
                                appNavigatorKey.currentState?.overlay?.context;
                            if (navContext != null) {
                              AddToPlaylistSheet.show(
                                navContext,
                                videoId: track.videoId,
                              );
                            }
                          },
                        ),
                      ],
                      // 재생/일시정지
                      SizedBox(
                        width: AppSizes.touchTarget,
                        height: AppSizes.touchTarget,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: AnimatedSwitcher(
                            duration: AppDurations.fast,
                            child: Icon(
                              player.isPlaying ? Icons.pause : Icons.play_arrow,
                              key: ValueKey(player.isPlaying),
                              size: AppSizes.iconXl,
                              color: cs.textPrimary,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            player.isPlaying
                                ? player.pause()
                                : player.resume();
                          },
                          disabledColor:
                              cs.textTertiary.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _controlButton({
    required BuildContext context,
    required IconData icon,
    required double size,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final cs = AppColorScheme.of(context);
    return SizedBox(
      width: AppSizes.touchTarget,
      height: AppSizes.touchTarget,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: size, color: color),
        onPressed: onPressed,
        disabledColor: cs.textTertiary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    final cs = AppColorScheme.of(context);
    return Container(
      color: cs.primarySurface,
      child: Icon(
        Icons.music_note,
        color: cs.primaryLight,
        size: AppSizes.iconMl,
      ),
    );
  }
}
