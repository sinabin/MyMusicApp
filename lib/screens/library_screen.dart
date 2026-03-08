import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/playback_history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/format_utils.dart';
import '../widgets/create_playlist_sheet.dart';
import '../widgets/gradient_text.dart';
import '../widgets/library_quick_card.dart';
import '../widgets/playlist_tile.dart';
import '../widgets/recent_play_horizontal_list.dart';
import 'all_songs_screen.dart';
import 'favorites_screen.dart';
import 'playlist_detail_screen.dart';
import 'recent_plays_screen.dart';

/// 라이브러리 메인 화면.
///
/// Quick Access 카드(Favorites·Recent·All Songs), 최근 재생,
/// 플레이리스트 목록을 표시. [MainShell]의 3번째 탭으로 사용.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistProvider>().loadPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.scaffoldBackground,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.library_music,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My Library',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Hero section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  GradientText(
                    text: 'My Library',
                    style: AppTextStyles.heroTitle,
                    gradient: AppColors.headingGradient,
                  ).animate().fadeIn(duration: 600.ms).slideY(
                        begin: -0.2,
                        end: 0,
                      ),
                  const SizedBox(height: 6),
                  Text(
                    'Your music collection',
                    style: AppTextStyles.subtitle,
                  ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
                  const SizedBox(height: 24),
                ]),
              ),
            ),

            // Quick Access Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Consumer2<HistoryProvider, PlaybackHistoryProvider>(
                  builder: (context, history, playback, _) {
                    return Row(
                      children: [
                        LibraryQuickCard(
                          icon: Icons.favorite,
                          label: 'Favorites',
                          count: history.favorites.length,
                          color: AppColors.error,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavoritesScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        LibraryQuickCard(
                          icon: Icons.history,
                          label: 'Recent',
                          count: playback.recentCount,
                          color: AppColors.secondary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecentPlaysScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        LibraryQuickCard(
                          icon: Icons.music_note,
                          label: 'All Songs',
                          count: history.count,
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllSongsScreen(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Recently Played
            Consumer2<PlaybackHistoryProvider, PlayerProvider>(
              builder: (context, playback, player, _) {
                final recentTracks = playback.getRecentTracks(10);
                if (recentTracks.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recently Played',
                              style: AppTextStyles.sectionHeader,
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RecentPlaysScreen(),
                                ),
                              ),
                              child: const Text(
                                'See All >',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      RecentPlayHorizontalList(
                        tracks: recentTracks,
                        currentTrack: player.currentTrack,
                        onTap: (item) {
                          final playAll = context
                              .read<SettingsProvider>()
                              .settings
                              .playAllOnTap;
                          if (playAll) {
                            final idx = recentTracks.indexOf(item);
                            player.playAll(recentTracks, startIndex: idx);
                          } else {
                            player.playTrack(item);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // Divider
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Divider(color: AppColors.divider),
              ),
            ),

            // Playlists header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Consumer<PlaylistProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Playlists (${provider.count})',
                          style: AppTextStyles.sectionHeader,
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              CreatePlaylistSheet.show(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Playlists list
            Consumer<PlaylistProvider>(
              builder: (context, provider, _) {
                if (provider.playlists.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.queue_music,
                            color: AppColors.textTertiary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No playlists yet',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "+ Create" to make your first playlist',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final playlist = provider.playlists[index];
                        final tracks =
                            provider.getTracksForPlaylist(playlist);
                        final urls = tracks
                            .take(4)
                            .map((t) => t.thumbnailUrl)
                            .toList();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PlaylistTile(
                            playlist: playlist,
                            thumbnailUrls: urls,
                            subtitle: FormatUtils.trackCount(
                              tracks.length,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(
                                  playlist: playlist,
                                ),
                              ),
                            ),
                            onDelete: () =>
                                provider.deletePlaylist(playlist),
                          ).animate().fadeIn(
                                duration: 300.ms,
                                delay: (index * 50).clamp(0, 500).ms,
                              ),
                        );
                      },
                      childCount: provider.playlists.length,
                    ),
                  ),
                );
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
