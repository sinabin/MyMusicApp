import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/song_list_screen.dart';

/// 즐겨찾기 곡 목록 화면.
///
/// [SongListScreen] 공통 위젯을 활용하여 즐겨찾기된 곡만 표시.
/// 하트 토글 시 목록에서 즉시 제거.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        return SongListScreen(
          title: 'Favorites',
          items: history.favorites,
          showFavoriteButton: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.shuffle,
                color: AppColors.textSecondary,
              ),
              onPressed: history.favorites.isEmpty
                  ? null
                  : () async {
                      final player = context.read<PlayerProvider>();
                      await player.playAll(history.favorites);
                      await player.toggleShuffle();
                    },
            ),
          ],
          emptyState: const EmptyStateWidget(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            description: 'Tap the heart icon on any song\nto add it to your favorites',
          ),
          onTap: (item) {
            final player = context.read<PlayerProvider>();
            final playAll =
                context.read<SettingsProvider>().settings.playAllOnTap;
            if (playAll) {
              final idx = history.favorites.indexOf(item);
              player.playAll(history.favorites, startIndex: idx);
            } else {
              player.playTrack(item);
            }
          },
          onAddToQueue: (item) {
            HapticFeedback.lightImpact();
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
}
