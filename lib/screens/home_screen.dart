import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_exception.dart';
import '../models/download_item.dart';
import '../models/video_info.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';
import '../services/youtube_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/add_to_playlist_sheet.dart';
import '../widgets/download_confirm_sheet.dart';
import '../widgets/download_history_tile.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/search_result_tile.dart';
import '../widgets/settings_bottom_sheet.dart';

/// 앱의 메인 화면.
///
/// 검색바·검색 결과·다운로드 기록을 통합 표시.
/// 검색 미입력 시 최근 다운로드 목록, 검색 시 YouTube 결과를 표시.
/// [SearchProvider]·[DownloadProvider]·[HistoryProvider]를
/// 구독하여 검색·다운로드·재생 워크플로우를 조율.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _searchScrollController = ScrollController();
  final _historyScrollController = ScrollController();

  /// 스트리밍 준비 중인 영상 ID.
  String? _streamingVideoId;

  @override
  void initState() {
    super.initState();
    _searchScrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _searchScrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final searchProvider = context.read<SearchProvider>();
    if (searchProvider.results.isNotEmpty &&
        _searchScrollController.position.pixels >=
            _searchScrollController.position.maxScrollExtent - 200) {
      searchProvider.loadMore();
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _focusNode.unfocus();
      context.read<SearchProvider>().search(query);
    }
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<SearchProvider>().clear();
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

  Future<void> _onStreamTap(VideoInfo info) async {
    if (_streamingVideoId != null) return;
    setState(() => _streamingVideoId = info.videoId);

    try {
      final youtubeService = context.read<YouTubeService>();
      final streamUrl = await youtubeService.getAudioStreamUrl(info.videoId);

      if (!mounted) return;

      final streamItem = DownloadItem.streaming(
        videoId: info.videoId,
        title: info.title,
        streamUrl: streamUrl.toString(),
        thumbnailUrl: info.thumbnailUrl,
        channelName: info.channelName,
        channelId: info.channelId,
        artistName: info.artistName,
        keywords: info.keywords,
        durationInMs: info.duration.inMilliseconds,
      );

      context.read<PlayerProvider>().playTrack(streamItem);
    } catch (e) {
      if (mounted) {
        final msg = e is AppException ? e.userMessage : 'Streaming failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _streamingVideoId = null);
    }
  }

  void _onResultTap(VideoInfo info) {
    _showDownloadSheet(info);
  }

  Future<void> _onDownloadTap(VideoInfo info) async {
    final downloadProvider = context.read<DownloadProvider>();
    if (downloadProvider.status.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A download is already in progress')),
      );
      return;
    }
    await _performDownload(info);
  }

  Future<void> _performDownload(VideoInfo searchResult) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing download...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final youtubeService = context.read<YouTubeService>();
      final videoInfo =
          await youtubeService.fetchVideoInfo(searchResult.videoId);

      if (!mounted) return;

      final settings = context.read<SettingsProvider>().settings;
      final downloadProvider = context.read<DownloadProvider>();
      final historyProvider = context.read<HistoryProvider>();

      final item = await downloadProvider.startDownload(
        videoInfo: videoInfo,
        savePath: settings.savePath,
      );

      if (item != null && mounted) {
        historyProvider.addItem(item);
        context.read<RecommendationProvider>().invalidateCache();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: ${item.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is AppException ? e.userMessage : 'Download failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  void _showDownloadSheet(VideoInfo info) {
    DownloadConfirmSheet.show(
      context,
      videoInfo: info,
      onDownload: () {
        Navigator.of(context).pop();
        _onDownloadTap(info);
      },
      onStream: () {
        Navigator.of(context).pop();
        _onStreamTap(info);
      },
    );
  }

  /// 검색이 활성 상태인지 판별.
  bool _isSearchActive(SearchProvider provider) {
    return provider.query.isNotEmpty ||
        provider.results.isNotEmpty ||
        provider.isLoading;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
              child: Row(
                children: [
                  Container(
                    width: AppSizes.headerIconBox,
                    height: AppSizes.headerIconBox,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                    tooltip: '설정',
                    icon: const Icon(Icons.settings_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () => SettingsBottomSheet.show(context),
                  ),
                ],
              ),
            ),

            // 검색바
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: _buildSearchBar(),
            ),

            // 메인 콘텐츠: 검색 결과 또는 최근 다운로드
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, searchProvider, _) {
                  if (_isSearchActive(searchProvider)) {
                    return _buildSearchContent(searchProvider);
                  }
                  return _buildRecentDownloads();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: AppSizes.searchBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: AppColors.textTertiary, size: AppSizes.iconMl),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: AppTextStyles.inputText,
              decoration: const InputDecoration(
                hintText: 'Search music...',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          ListenableBuilder(
            listenable: _searchController,
            builder: (context, _) {
              if (_searchController.text.isNotEmpty) {
                return IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textTertiary,
                    size: AppSizes.iconMd,
                  ),
                  onPressed: _onClearSearch,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  /// 검색 활성 시: 로딩·에러·빈 결과·결과 목록.
  Widget _buildSearchContent(SearchProvider provider) {
    if (provider.isLoading && provider.results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: AppSizes.iconHero, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Search failed', style: AppTextStyles.sectionHeader),
              const SizedBox(height: AppSpacing.sm),
              Text(
                provider.error!,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(onPressed: _onSearch, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (provider.results.isEmpty && provider.query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off,
                size: AppSizes.iconHero, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text('No results found', style: AppTextStyles.subtitle),
          ],
        ),
      );
    }
    return _buildSearchResultsList(provider);
  }

  Widget _buildSearchResultsList(SearchProvider provider) {
    return Selector<DownloadProvider, (bool, String?)>(
      selector: (_, dp) => (dp.status.isActive, dp.currentVideoId),
      builder: (context, data, _) {
        final (isActive, currentVideoId) = data;

        return ListView.builder(
          controller: _searchScrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          itemCount:
              provider.results.length + (provider.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.results.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: AppSizes.strokeWidth,
                  ),
                ),
              );
            }
            final result = provider.results[index];
            final isThisDownloading =
                isActive && currentVideoId == result.videoId;

            return SearchResultTile(
              videoInfo: result,
              onTap: () => _onResultTap(result),
              onDownload: () => _onDownloadTap(result),
              onStream: () => _onStreamTap(result),
              isDownloading: isThisDownloading,
              isStreamLoading: _streamingVideoId == result.videoId,
              downloadDisabled: isActive && !isThisDownloading,
            ).animate().fadeIn(
                  duration: AppDurations.fast,
                  delay: Duration(
                      milliseconds: (index * AppDurations.staggerFastMs).clamp(0, AppDurations.staggerMaxMs)),
                );
          },
        );
      },
    );
  }

  /// 검색 미입력 시: 최근 다운로드 목록.
  Widget _buildRecentDownloads() {
    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        final recent = history.recentItems;

        return CustomScrollView(
          controller: _historyScrollController,
          slivers: [
            // 섹션 헤더
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Recent Downloads (${history.recentCount})',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),

            // 목록
            if (recent.isEmpty)
              const SliverToBoxAdapter(child: EmptyStateWidget()),
            if (recent.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = recent[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: DownloadHistoryTile(
                          item: item,
                          onDelete: () => history.removeItem(index),
                          onTap: () => _playFromHistory(recent, index),
                          onAddToQueue: () {
                            HapticFeedback.lightImpact();
                            context
                                .read<PlayerProvider>()
                                .addToQueue(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to queue'),
                              ),
                            );
                          },
                          isFavorite: item.isFavorite,
                          onToggleFavorite: () => context
                              .read<HistoryProvider>()
                              .toggleFavorite(item),
                          onAddToPlaylist: () => AddToPlaylistSheet.show(
                              context,
                              videoId: item.videoId),
                        ).animate().fadeIn(
                            duration: AppDurations.normal, delay: Duration(milliseconds: index * AppDurations.staggerMs)),
                      );
                    },
                    childCount: recent.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        );
      },
    );
  }
}
