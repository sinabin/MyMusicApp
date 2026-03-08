import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/playback_history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/track_list_tile.dart';

/// 최근 재생 기록 화면.
///
/// 시간 구간별로 그룹화하여 표시 (Today, Yesterday, This Week, Earlier).
/// Clear 버튼으로 전체 기록 삭제 가능.
class RecentPlaysScreen extends StatelessWidget {
  const RecentPlaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        title: const Text(
          'Recent Plays',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Consumer<PlaybackHistoryProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textSecondary,
                ),
                onPressed: provider.recentCount == 0
                    ? null
                    : () => _showClearDialog(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer2<PlaybackHistoryProvider, PlayerProvider>(
        builder: (context, playback, player, _) {
          final grouped = playback.getGroupedRecentTracks();
          if (grouped.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    color: AppColors.textTertiary,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No plays yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Songs you play will appear here',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          final sections = grouped.entries.toList();
          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
            ),
            itemCount: sections.fold<int>(
              0,
              (sum, e) => sum + 1 + e.value.length,
            ),
            itemBuilder: (context, index) {
              int current = 0;
              for (final section in sections) {
                if (index == current) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      section.key.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }
                current++;
                if (index < current + section.value.length) {
                  final item = section.value[index - current];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: TrackListTile(
                      item: item,
                      isCurrentTrack:
                          player.currentTrack?.videoId == item.videoId,
                      onTap: () {
                        final allTracks = sections
                            .expand((e) => e.value)
                            .toList();
                        final playAll = context
                            .read<SettingsProvider>()
                            .settings
                            .playAllOnTap;
                        if (playAll) {
                          final idx = allTracks.indexOf(item);
                          context
                              .read<PlayerProvider>()
                              .playAll(allTracks, startIndex: idx);
                        } else {
                          context.read<PlayerProvider>().playTrack(item);
                        }
                      },
                      onAddToQueue: () {
                        context.read<PlayerProvider>().addToQueue(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to queue')),
                        );
                      },
                      isFavorite: item.isFavorite,
                      onToggleFavorite: () {
                        context
                            .read<HistoryProvider>()
                            .toggleFavorite(item);
                      },
                      onAddToPlaylist: () {
                        AddToPlaylistSheet.show(
                          context,
                          videoId: item.videoId,
                        );
                      },
                    ),
                  );
                }
                current += section.value.length;
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  void _showClearDialog(
    BuildContext context,
    PlaybackHistoryProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Clear History',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to clear all play history?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
