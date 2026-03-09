import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/download_item.dart';
import '../providers/history_provider.dart';
import '../services/file_service.dart';
import '../providers/playback_history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/download_history_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/recent_play_horizontal_list.dart';
import '../widgets/settings_bottom_sheet.dart';
import 'search_screen.dart';

/// 앱의 메인 화면 — 최근 활동 허브.
///
/// 최근 재생(가로 스크롤)과 최근 다운로드(세로 리스트)를 표시.
/// 검색은 AppBar의 검색 아이콘을 통해 [SearchScreen]으로 이동.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  void _playFromHistory(List<DownloadItem> items, int index) {
    final player = context.read<PlayerProvider>();
    final playAll = context.read<SettingsProvider>().settings.playAllOnTap;
    if (playAll) {
      player.playAll(items, startIndex: index);
    } else {
      player.playTrack(items[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = AppColorScheme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
                child: Row(
                  children: [
                    Container(
                      width: AppSizes.headerIconBox,
                      height: AppSizes.headerIconBox,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: AppSizes.iconMd),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'MyMusicApp',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '검색',
                      icon: Icon(Icons.search,
                          color: cs.textSecondary),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchScreen()),
                      ),
                    ),
                    IconButton(
                      tooltip: '설정',
                      icon: Icon(Icons.settings_outlined,
                          color: cs.textSecondary),
                      onPressed: () => SettingsBottomSheet.show(context),
                    ),
                  ],
                ),
              ),
            ),

            // 최근 재생
            _buildRecentlyPlayed(),

            // 최근 다운로드 헤더
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              sliver: SliverToBoxAdapter(
                child: Consumer<HistoryProvider>(
                  builder: (context, history, _) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
                      child: Text(
                        'Recent Downloads (${history.recentCount})',
                        style: AppTextStyles.sectionHeader,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 최근 다운로드 목록
            _buildRecentDownloads(),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }

  /// 최근 재생 섹션 (가로 스크롤).
  Widget _buildRecentlyPlayed() {
    return Consumer<PlaybackHistoryProvider>(
      builder: (context, playback, _) {
        final recentTracks = playback.getRecentTracks(10);
        if (recentTracks.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.sm),
                child: Text(
                  'Recently Played',
                  style: AppTextStyles.sectionHeader,
                ),
              ),
              Selector<PlayerProvider, DownloadItem?>(
                selector: (_, p) => p.currentTrack,
                builder: (context, currentTrack, _) {
                  return RecentPlayHorizontalList(
                    tracks: recentTracks,
                    currentTrack: currentTrack,
                    fileService: context.read<FileService>(),
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
    );
  }

  /// 최근 다운로드 목록 (세로 리스트).
  Widget _buildRecentDownloads() {
    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        final recent = history.recentItems;

        if (recent.isEmpty) {
          return const SliverToBoxAdapter(child: EmptyStateWidget());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = recent[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: DownloadHistoryTile(
                    item: item,
                    fileService: context.read<FileService>(),
                    onDelete: () => history.removeItem(item),
                    onTap: () => _playFromHistory(recent, index),
                    onAddToQueue: () {
                      HapticFeedback.lightImpact();
                      context.read<PlayerProvider>().addToQueue(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to queue')),
                      );
                    },
                    isFavorite: item.isFavorite,
                    onToggleFavorite: () =>
                        context.read<HistoryProvider>().toggleFavorite(item),
                    onAddToPlaylist: () => AddToPlaylistSheet.show(context,
                        videoId: item.videoId),
                  ).animate().fadeIn(
                      duration: AppDurations.normal,
                      delay: Duration(
                          milliseconds: index * AppDurations.staggerMs)),
                );
              },
              childCount: recent.length,
            ),
          ),
        );
      },
    );
  }
}
