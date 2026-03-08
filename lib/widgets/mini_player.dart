import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../screens/full_player_screen.dart';
import '../app.dart';
import '../theme/app_colors.dart';
import 'add_to_playlist_sheet.dart';

/// 하단 고정 미니 플레이어 위젯.
///
/// 진행 바·썸네일·곡명·아티스트와 즐겨찾기·플레이리스트 추가·재생/일시정지·닫기 버튼 표시.
/// 탭 시 [FullPlayerScreen]으로 이동.
/// [App]의 builder에서 글로벌로 표시되어 모든 화면에서 접근 가능.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
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

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 진행 바
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 2,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
              // 컨트롤 영역
              SizedBox(
                height: 62,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // 썸네일 + 곡 정보 (탭 → FullPlayerScreen)
                      Expanded(
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
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: track.thumbnailUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: track.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) =>
                                              _placeholderIcon(),
                                          errorWidget: (_, _, _) =>
                                              _placeholderIcon(),
                                        )
                                      : _placeholderIcon(),
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
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (artist.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
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
                      // 즐겨찾기 토글
                      _controlButton(
                        icon: track.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: track.isFavorite
                            ? AppColors.error
                            : AppColors.textSecondary,
                        onPressed: () => history.toggleFavorite(track),
                      ),
                      // 플레이리스트에 추가
                      _controlButton(
                        icon: Icons.playlist_add,
                        size: 22,
                        color: AppColors.textSecondary,
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
                      // 재생/일시정지
                      _controlButton(
                        icon: player.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        size: 28,
                        color: AppColors.textPrimary,
                        onPressed: () {
                          player.isPlaying
                              ? player.pause()
                              : player.resume();
                        },
                      ),
                      // 닫기 (정지)
                      _controlButton(
                        icon: Icons.close,
                        size: 18,
                        color: AppColors.textTertiary,
                        onPressed: () => player.stop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _controlButton({
    required IconData icon,
    required double size,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: size, color: color),
        onPressed: onPressed,
        disabledColor: AppColors.textTertiary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      color: AppColors.primarySurface,
      child: const Icon(
        Icons.music_note,
        color: AppColors.primaryLight,
        size: 22,
      ),
    );
  }
}
