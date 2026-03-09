import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/history_provider.dart';
import '../providers/playback_history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../widgets/create_playlist_sheet.dart';
import '../widgets/empty_state_widget.dart';
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
                    width: AppSizes.headerIconBox,
                    height: AppSizes.headerIconBox,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.library_music,
                      color: Colors.white,
                      size: AppSizes.iconMd,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'My Library',
                    style: AppTextStyles.sectionHeader,
                  ),
                ],
              ),
            ),

            // Hero section
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.lg),
                  GradientText(
                    text: 'My Library',
                    style: AppTextStyles.heroTitle,
                    gradient: AppColors.headingGradient,
                  ).animate().fadeIn(duration: AppDurations.emphasis).slideY(
                        begin: -0.2,
                        end: 0,
                      ),
                  const SizedBox(height: 6),
                  Text(
                    'Your music collection',
                    style: AppTextStyles.subtitle,
                  ).animate().fadeIn(duration: AppDurations.emphasis, delay: 100.ms),
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ),

            // Quick Access Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
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
                        const SizedBox(width: AppSpacing.sm),
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
                        const SizedBox(width: AppSpacing.sm),
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
            Consumer<PlaybackHistoryProvider>(
              builder: (context, playback, _) {
                final recentTracks = playback.getRecentTracks(10);
                if (recentTracks.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
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
                      const SizedBox(height: AppSpacing.sm),
                      Selector<PlayerProvider, DownloadItem?>(
                        selector: (_, p) => p.currentTrack,
                        builder: (context, currentTrack, _) {
                          return RecentPlayHorizontalList(
                            tracks: recentTracks,
                            currentTrack: currentTrack,
                            onTap: (item) {
                              final player = context.read<PlayerProvider>();
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
                          );
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
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
                child: Divider(color: AppColors.divider),
              ),
            ),

            // Playlists header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
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
                          icon: const Icon(Icons.add, size: AppSizes.iconMsl),
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
                    child: EmptyStateWidget(
                      icon: Icons.queue_music,
                      title: 'No playlists yet',
                      description: 'Tap "+ Create" to make your first playlist',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
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
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                                duration: AppDurations.normal,
                                delay: Duration(milliseconds: (index * AppDurations.staggerMs).clamp(0, AppDurations.staggerMaxLongMs)),
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
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }
}
