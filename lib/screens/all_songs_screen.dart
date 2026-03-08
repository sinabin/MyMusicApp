import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/song_list_screen.dart';

/// 전체 곡 목록 화면.
///
/// [SongListScreen] 공통 위젯을 활용하여 다운로드된 모든 곡을 표시.
/// Play All·Shuffle 버튼과 정렬·즐겨찾기 기능 제공.
class AllSongsScreen extends StatelessWidget {
  const AllSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        return SongListScreen(
          title: 'All Songs',
          items: history.items,
          showSortOptions: true,
          showFavoriteButton: true,
          headerWidget: _buildHeaderButtons(context),
          emptyState: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_off, size: 48, color: AppColors.textTertiary),
                SizedBox(height: 12),
                Text(
                  'No songs yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Download music to see it here',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          onTap: (item) {
            final player = context.read<PlayerProvider>();
            final playAll =
                context.read<SettingsProvider>().settings.playAllOnTap;
            if (playAll) {
              final idx = history.items.indexOf(item);
              player.playAll(history.items, startIndex: idx);
            } else {
              player.playTrack(item);
            }
          },
          onAddToQueue: (item) {
            context.read<PlayerProvider>().addToQueue(item);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to queue')),
            );
          },
          onToggleFavorite: (item) {
            context.read<HistoryProvider>().toggleFavorite(item);
          },
          onAddToPlaylist: (item) {
            AddToPlaylistSheet.show(context, videoId: item.videoId);
          },
        );
      },
    );
  }

  Widget _buildHeaderButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Consumer<HistoryProvider>(
            builder: (context, history, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: history.items.isEmpty
                      ? null
                      : () {
                          context
                              .read<PlayerProvider>()
                              .playAll(history.items);
                        },
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Play All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<HistoryProvider>(
            builder: (context, history, _) {
              return OutlinedButton.icon(
                onPressed: history.items.isEmpty
                    ? null
                    : () async {
                        final player = context.read<PlayerProvider>();
                        await player.playAll(history.items);
                        await player.toggleShuffle();
                      },
                icon: const Icon(Icons.shuffle, size: 20),
                label: const Text('Shuffle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
