import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/player_provider.dart';
import '../screens/full_player_screen.dart';
import '../theme/app_colors.dart';

/// 하단 고정 미니 플레이어 위젯.
///
/// 진행 바·썸네일·곡명·아티스트와 이전/재생·일시정지/다음/닫기 버튼 표시.
/// 탭 시 [FullPlayerScreen]으로 이동.
/// [App]의 builder에서 글로벌로 표시되어 모든 화면에서 접근 가능.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
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

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
            );
          },
          child: Container(
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
                        // 썸네일
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
                        // 곡 정보
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
                        // 이전 곡
                        _controlButton(
                          icon: Icons.skip_previous,
                          size: 22,
                          color: AppColors.textSecondary,
                          onPressed: player.queue.length > 1
                              ? () => player.skipPrevious()
                              : null,
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
                        // 다음 곡
                        _controlButton(
                          icon: Icons.skip_next,
                          size: 22,
                          color: AppColors.textSecondary,
                          onPressed: player.queue.length > 1
                              ? () => player.skipNext()
                              : null,
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
